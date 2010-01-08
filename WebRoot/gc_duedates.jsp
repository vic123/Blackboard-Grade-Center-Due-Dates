<%@ page 
		contentType="text/html"
		language="java" 
		import="java.util.*,
				java.lang.reflect.Array,
				java.util.Calendar,
				java.io.StringWriter,
				java.io.PrintWriter,
				blackboard.data.user.*,
				blackboard.data.course.*,
				blackboard.data.gradebook.*,
				blackboard.data.ReceiptOptions,
				blackboard.data.ReceiptMessage,
				blackboard.persist.*,
				blackboard.persist.course.*,
				blackboard.persist.gradebook.*,
				blackboard.platform.log.*,
				blackboard.platform.persistence.PersistenceServiceFactory,  
				blackboard.platform.plugin.PlugInUtil,
				blackboard.db.DbUtil, 
				blackboard.servlet.tags.DatePickerTag,
				blackboard.servlet.tags.InlineReceiptTag, 
				blackboard.servlet.data.DatePicker, 
				blackboard.platform.context.Context,
				blackboard.platform.context.ContextManager,
				blackboard.platform.context.ContextManagerFactory"
		errorPage="error.jsp"           
		pageEncoding="UTF-8" 
		session="true"
%>

 
<%@ taglib uri="/bbUI" prefix="bbUI"%>
<%@ taglib uri="/bbData" prefix="bbData"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core"    prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt"     prefix="fmt"%>

<!-- gc_duedates.jsp -->

<%!
//The code in this large file is not structured fine enough, this comment targets its easier assimilation.
//Its overall content can be split logically in next 3 parts
//1) Servlet declaration section: 
//Global data members, logging functions and declarations of LineitemHelper and LineItemField 
//inner classes. Inside LineitemHelper are declared 
//ancestors of LineItemField - LineItemIsAvailableField, LineItemDateField and LineItemDueDateField classes, 
//which are closely integrated and accessing fields of its container - LineitemHelper.
//LineitemHelper is created from Blackboard API's Lineitem object. In case of save action
//ancestors of LineItemField are created from form parameters as its members too and data from just read from DB 
//Lineitem is used for compare with LineItemField(s) and taking a decision whether DB has to be updated or not.      
	String strLogMessages;
	String strSaveWarnings;
	static Log log = LogServiceFactory.getInstance().getDefaultLog();
	//log forwarding functions - intoroduced for easier production of log messages
	//without necessity of modifying of server log settings
	//assumes that active server log level is at least WARNING 
	void logForward(LogService.Verbosity verbosity, String message) {
		strLogMessages = strLogMessages + "<br>" + verbosity.toExternalString() + "	" + message  ;
		message = "IDLA.gradecenter_duedates	" + verbosity.toExternalString() + "	Session: " + servletSession.getId() + "	" + message;
		//using higher severity log level for easier development testing, log is overfilled when all messages are of debug level
		//actual log.logWarning has to be commented out in production release, but may be uncommented for collecting of log messages  
		if (verbosity.getLevelAsInt() > LogService.Verbosity.WARNING.getLevelAsInt()) {
			log.logWarning(message); //!!
		}
		log.log(message, verbosity);
	}
	void logForward(LogService.Verbosity verbosity, java.lang.Throwable error, String message) {
		//strLogMessages = strLogMessages + verbosity.toExternalString() + "	" + message + "<br>" ;
		strLogMessages = strLogMessages + verbosity.toExternalString() + "	" + error.getMessage() + "<br>" ;
		StringWriter sw = new StringWriter();
		PrintWriter pw = new PrintWriter(sw, true);
		error.printStackTrace(pw);
		//strLogMessages = strLogMessages + verbosity.toString() + "	" + sw.toString() + "<br>" ;
		message = "IDLA.gradecenter_duedates	Session: " + servletSession.getId() + "	" + message;
		//using higher severity log level for easier development testing, log is overfilled when all messages are of debug level
		//actual log.logWarning has to be commented out in production release, but may be uncommented for collecting of log messages  
		if (verbosity.getLevelAsInt() > LogService.Verbosity.WARNING.getLevelAsInt()) {
			log.logWarning(message, error); //!!
		}
		log.log(message, error, verbosity);
	}

	class GCDuedatesException extends Exception {
		private static final long serialVersionUID = 0x9C86F94BDD670411L;
		GCDuedatesException(String message, Throwable cause) {
			super (message, cause);
		}
		GCDuedatesException(String message) {
			super (message);
		}
	}
	 	
	//variables declared as class members for availability from inside inner classes and code blocks
	public BbPersistenceManager bbPm;
	String formURL;
	HttpServletRequest servletRequest;
	HttpServletResponse servletResponse;
	HttpSession			servletSession;
	String courseIdParameter;
	String PAGE_TITLE;
	String ICON_URL;
	java.util.HashMap<String, LineitemHelper> lineitemHelperHash;
	
	Comparator<Lineitem> cmSortByColumnOrder;
    Comparator<Lineitem> cmSortByName;
    Comparator<Lineitem> cmSortByType;
    Comparator<Lineitem> cmSortByIsAvailable;
    Comparator<Lineitem> cmSortByHasDueDate;
	Comparator<Lineitem> cmSortByDueDate;
	ComparatorSortByMinutesPerPoint cmSortByMinutesPerPoint;
	
	ArrayList<Lineitem> liList;
	ArrayList<Lineitem> liPhysicalList;
	
	//direct accessing of DatePickerTag does not require manual construction of parameters name,
	//it becomes equal to liDueDateParamNameBase + '_' + li_index 
	//after dpt.setStartDateField(liDueDateParamName); and dpt.setDatePickerIndex(li_index); 
	//(!!)static final String liDueDateParamNameBase = "liDueDateParam_";
	static final String liDueDateParamNameBase = "liDueDateParam";
	static final String liIdParamNameBase = "liIdParam_";
	static final String liHasDueDateParamNameBase = "liHasDueDateParam_";
	static final String liIsAvailableParamNameBase =  "liIsAvailableParam_";
	static final String liNameParamNameBase =  "liNameParam_";
	
	//Lineitem Field is class for more centralized error handling of Lineitem fields setting and persisting
	//add easier capabilities for adding of more editable fields  
	private class  LineItemField {
		protected String value;
		String paramName;
		boolean isSet;
		public LineItemField (String paramName_) {
			paramName = paramName_;
			value = servletRequest.getParameter(paramName);
			logForward(LogService.Verbosity.INFORMATION, "LineItemField.paramName: " + paramName + ", value: " + value);
			if (value == null) value = "";
		}
		
		void checkAndSet() throws GCDuedatesException {
			isSet = false;
			checkAndSetInternal();
		}
		void checkAndSetInternal() throws GCDuedatesException {}
	} //private class  LineItemField {

	//LineitemHelper is "middle-way" surrounding class for 
	//specific ancestors of LineItemField - LineItemIsAvailableField and LineItemDueDateField. 
	//These internal classes access common members of LineitemHelper "from inside".
	//Considerable part of LineitemHelper handles calculation and comparison of "by minutes per point" field which is currently hidden from user interface     
	private class LineitemHelper
	{
		Lineitem liPrev;
		Lineitem lineitem;
		Calendar calPrev;
		Calendar calendar;
		String strRowStatus;
		float fPointsPossible;
		float fMinutesPerPoint;
		long lMinutesCount;
		
		public int DueDateOrder; //used just for indexing, contains initial DueDateOrder, can become incorrect after save, but it should not influence behavior
		public boolean isDueDateConstructed; //quick flagging solution to avoid 2 datepicker controls to be created for one of the rows (first row is passed twice by InventoryList
		int paramIndex;
		List<LineItemField> fieldsList;

		public LineitemHelper(Lineitem liPrev_, Lineitem lineitem_) {
			strRowStatus = "";
			isDueDateConstructed = false;
			liPrev = liPrev_;
			lineitem = lineitem_;
			assert (lineitem_ != null);
			refresh();
		}
		
		public boolean needsSave() {
			for (LineItemField lif_temp: fieldsList) {
				if (lif_temp.isSet) return true;
			}
			return false;		
		}
		
		public void refresh() {
			calPrev = null;
			calendar = null;
			fPointsPossible = lineitem.getPointsPossible();
			calendar = lineitem.getOutcomeDefinition().getDueDate();
			if (liPrev == null) {
				fMinutesPerPoint = 0;
			} else { 
				calPrev = liPrev.getOutcomeDefinition().getDueDate();
				if (calPrev == null) {
					fMinutesPerPoint = 0;
				} else if (calendar != null) {
					lMinutesCount = (long) ((calendar.getTimeInMillis() - calPrev.getTimeInMillis()) / (1000 * 60));
					fMinutesPerPoint = lMinutesCount/fPointsPossible;
				}
			}
			if (calendar == null) fMinutesPerPoint = -1;
		}
	
		public String toString() {
			if (calendar == null || liPrev == null || calPrev == null) return "N/A / " + fPointsPossible + " = N/A";
			else return lMinutesCount + " / " + fPointsPossible + " = " + fMinutesPerPoint;
		}
		
		private class  LineItemIsAvailableField extends LineItemField {
			LineItemIsAvailableField(String paramName_) {
				super(paramName_);
			}
			void checkAndSetInternal() throws GCDuedatesException {
				boolean is_avail = value.equals("on");
				if (LineitemHelper.this.lineitem.getIsAvailable() != is_avail) {
					logForward(LogService.Verbosity.INFORMATION, "LineitemHelper.this.lineitem.setIsAvailable(is_avail);" + "is_avail: " + is_avail );
					LineitemHelper.this.lineitem.setIsAvailable(is_avail);
					isSet = true;
				}
			}
		} //private class  LineItemIsAvailable extends LineItemField {

		private class  LineItemDateField extends LineItemField {
			LineItemDateField(String paramName_) {
				super(paramName_);
				Calendar cal = Calendar.getInstance();
				String s_yyyy = servletRequest.getParameter(paramName+"_yyyy");
				String s_mm = servletRequest.getParameter(paramName+"_mm");
				String s_dd = servletRequest.getParameter(paramName+"_dd");
				String s_hh = servletRequest.getParameter(paramName+"_hh");
				String s_mi = servletRequest.getParameter(paramName+"_mi");
				String s_am = servletRequest.getParameter(paramName+"_am");
				logForward(LogService.Verbosity.DEBUG, paramName_ + " s_yyyy: " + s_yyyy + "; s_mm: " + s_mm
							 + "; s_dd: " + s_dd + "; s_hh: " + s_hh + "; s_mi: " + s_mi + "; s_am: " + s_am);
				if (s_yyyy != null) cal.set(Calendar.YEAR, Integer.parseInt(s_yyyy));
				if (s_mm != null) cal.set(Calendar.MONTH, Integer.parseInt(s_mm) - 1);
				if (s_dd != null) cal.set(Calendar.DAY_OF_MONTH, Integer.parseInt(s_dd));
				if (s_am != null) cal.set(Calendar.AM_PM, Integer.parseInt(s_am));
				//cal.set(Calendar.HOUR_OF_DAY, Integer.parseInt(s_hh) + 12 * Integer.parseInt(s_hh));
				if (s_hh != null) cal.set(Calendar.HOUR, Integer.parseInt(s_hh));
				if (s_mi != null) cal.set(Calendar.MINUTE, Integer.parseInt(s_mi));
				value = DbUtil.calendarToString(cal);
			}
		}
		private class  LineItemDueDateField extends LineItemDateField {
			LineItemField liHasDueDate;
			LineItemField isCommonDueTime;
			LineItemField commonDueTime;
			LineItemDueDateField(String paramName_) {
				super(paramName_);			
				liHasDueDate = new LineItemField(liHasDueDateParamNameBase + LineitemHelper.this.paramIndex);
				isCommonDueTime = new LineItemField("isCommonDueTimeParam");
				commonDueTime = new LineItemDateField("commonDueTimeParam_0");
			}
			
			void checkAndSetInternal() throws GCDuedatesException {
				Calendar saved_due_date = LineitemHelper.this.lineitem.getOutcomeDefinition().getDueDate();
				logForward(LogService.Verbosity.INFORMATION, "saved_due_date: " + saved_due_date);
				logForward(LogService.Verbosity.INFORMATION, "liHasDueDate.value: " + liHasDueDate.value);
				if (liHasDueDate.value.equals("on")) {
					Calendar due_date = DbUtil.stringToCalendar(value);
					if (due_date == null) {
						throw new GCDuedatesException("Due date is not set");
					}	
					logForward(LogService.Verbosity.DEBUG, "due_date: " + due_date);
					if (isCommonDueTime.value.equals("on")) {
						Calendar common_duetime = DbUtil.stringToCalendar(commonDueTime.value);
						logForward(LogService.Verbosity.DEBUG, "common_duetime: " + common_duetime.toString());
						due_date.set(Calendar.MILLISECOND, common_duetime.get(Calendar.MILLISECOND));
						due_date.set(Calendar.SECOND, common_duetime.get(Calendar.SECOND));
						due_date.set(Calendar.MINUTE, common_duetime.get(Calendar.MINUTE));
						due_date.set(Calendar.HOUR_OF_DAY, common_duetime.get(Calendar.HOUR_OF_DAY));						
					}  
					logForward(LogService.Verbosity.INFORMATION, "due_date: " + due_date);
					if ( saved_due_date == null) {
						logForward(LogService.Verbosity.INFORMATION, "getOutcomeDefinition().getDueDate() == null -> LineitemHelper.this.lineitem.getOutcomeDefinition().setDueDate(due_date);");
						LineitemHelper.this.lineitem.getOutcomeDefinition().setDueDate(due_date);
						isSet = true;
					} else if (saved_due_date.compareTo(due_date) != 0) {
								logForward(LogService.Verbosity.INFORMATION, "getOutcomeDefinition().getDueDate().compareTo(due_date) != 0 -> LineitemHelper.this.lineitem.getOutcomeDefinition().setDueDate(due_date);");
								LineitemHelper.this.lineitem.getOutcomeDefinition().setDueDate(due_date);
								isSet = true;
							} 
				} else if (saved_due_date != null) {
						logForward(LogService.Verbosity.INFORMATION, "LineitemHelper.this.lineitem.getOutcomeDefinition().setDueDate(null);");
						LineitemHelper.this.lineitem.getOutcomeDefinition().setDueDate(null);
						isSet = true;
					}
			} //void checkAndSetInternal() {
		} //private class  LineItemDueDate extends LineItemField {
	} //private class LineitemHelper

	private static class ComparatorSortByMinutesPerPoint implements Comparator<Lineitem> {
		public java.util.HashMap<String, LineitemHelper> lineitemHelperHash;
		ComparatorSortByMinutesPerPoint (java.util.HashMap<String, LineitemHelper> lineitemHelperHash_) {
			lineitemHelperHash = lineitemHelperHash_;
		} 
   		public int compare(Lineitem li1, Lineitem li2) {
	   		LineitemHelper minpp1 = lineitemHelperHash.get(li1.getId().toExternalString()); 
	   		LineitemHelper minpp2 = lineitemHelperHash.get(li2.getId().toExternalString() );
	        if (minpp1.liPrev == null) return -1;
	        if (minpp2.liPrev == null) return 1;
	        return Float.compare (minpp1.fMinutesPerPoint, minpp2.fMinutesPerPoint); 
		}
   	}
//end of servlet declaration section	
%>


<%
//2)Pre-visualization (response generation) processing:
//a)Logs form parameters on INFORMATION level
//b)Setups URL links, declares inline Comparator classes for bbUI:listElement tags.
//c)Authorises user by role of INSTRUCTOR, TEACHING_ASSISTANT or COURSE_BUILDER
//d)Obtains currently persisted Lineitems for a course
//e)In case of "save" (submit) action, creates ancestors of LineitemField from form parameters and 
//using LineitemHelper interface compares posted data with currently saved one. 
//Saves anything necessary and redirects response to itself.
   
 

//(!!-title)Grade Center Due Dates
try {
	strLogMessages = "";
	strSaveWarnings = "";

	//set variables declared in current class for availability from inner classes 
	//(inherited ones - i.e. session, request and response are not visible from inner classes) 
	servletSession = session;
	servletRequest = request;
	servletResponse = response;
	
	//obtaing of context through bbData:context tag at this point caused IllegalStateException 
	//upon response.sendRedirect(formURL) after saving of lineitems.
	logForward(LogService.Verbosity.INFORMATION, "session.getId(): " + session.getId());	
	Context ctx = ContextManagerFactory.getInstance().getContext();


	//Logging of request and form paramters BEGIN
	//save request and form paramters in log
	logForward(LogService.Verbosity.INFORMATION, "request.getRemoteHost(): " + request.getRemoteHost());
	logForward(LogService.Verbosity.INFORMATION, "request.getServerPort(): " + request.getServerPort());
	logForward(LogService.Verbosity.INFORMATION, "request.getRequestURL(): " + request.getRequestURL());
	logForward(LogService.Verbosity.INFORMATION, "request.getQueryString(): " + request.getQueryString());
	
	Enumeration<String> keys = servletRequest.getParameterNames();
	ArrayList<String> keys_list = Collections.list(keys);

	//comparator for java.util.Collections.sort just below 
	Comparator<String> cmSortParamsByName = new Comparator<String>() {
      public int compare(String s1, String s2) {
      	return s1.compareTo(s2);
      }
    };
	java.util.Collections.sort(keys_list, cmSortParamsByName);
	logForward(LogService.Verbosity.INFORMATION, "FORM PARAMETERS: " );
	for (String s_temp: keys_list) {
		// If the same key has multiple values (check boxes)
		String[] valueArray = request.getParameterValues(s_temp);
		if (Array.getLength(valueArray) > 1) {
			for (int i = 0; i < Array.getLength(valueArray); i++) {
				logForward(LogService.Verbosity.DEBUG, s_temp + "[" + i + "]:" + valueArray[i]);
			}
		} else {
		      //To retrieve a single value
		    String value = request.getParameter(s_temp);
		    logForward(LogService.Verbosity.INFORMATION, "Parameter " + s_temp + ": " + value);
		}
	}
	//Logging of request and form paramters END
	
	// Retrieve the course identifier from the URL and construct formURL for response.sendRedirect(formURL) to itself  
	courseIdParameter = request.getParameter("course_id");
	request.getSession().setAttribute("course_id", courseIdParameter);
	logForward(LogService.Verbosity.INFORMATION, "request.getParameter(\"course_id\"): " + courseIdParameter);
	formURL = request.getRequestURL().toString() + "?course_id=" + courseIdParameter;

	PAGE_TITLE = "Grade Center Due Dates";
	//special Blackboard API funttion for constructing of path the resourse located in plugin's WebRoot dir
	ICON_URL = PlugInUtil.getUri("IDLA", "gradecenter_duedates", "DueDates.jpg");
	lineitemHelperHash = new java.util.HashMap<String, LineitemHelper>();
	
	//create comparators for each column of the list (attribute of LineItem)
	cmSortByColumnOrder = new Comparator<Lineitem>() {
      public int compare(Lineitem li1, Lineitem li2) {
        return li1.getColumnOrder() - li2.getColumnOrder(); 
      }
    };

    cmSortByName = new Comparator<Lineitem>() {
      public int compare(Lineitem li1, Lineitem li2) {
        String s1 = (String)li1.getName();
        String s2 = (String)li2.getName();        
        int compare = s1.toLowerCase().compareTo(s2.toLowerCase());
        return compare;
      }
    };
    cmSortByType = new Comparator<Lineitem>() {
      public int compare(Lineitem li1, Lineitem li2) {
        String s1 = (String)li1.getType();
        String s2 = (String)li2.getType();        
        int compare = s1.toLowerCase().compareTo(s2.toLowerCase());
        return compare;
      }
    };
    
    cmSortByIsAvailable = new Comparator<Lineitem>() {
      public int compare(Lineitem li1, Lineitem li2) {
      	boolean is_av1 = li1.getIsAvailable();
      	boolean is_av2 = li2.getIsAvailable();
      	return Boolean.valueOf(is_av1).compareTo(is_av2);
      }
    };

    cmSortByHasDueDate = new Comparator<Lineitem>() {
      public int compare(Lineitem li1, Lineitem li2) {
      	boolean has_dd1 = (li1.getOutcomeDefinition().getDueDate() != null);
      	boolean has_dd2 = (li2.getOutcomeDefinition().getDueDate() != null);
      	return Boolean.valueOf(has_dd1).compareTo(has_dd2);
      }
    };
    
	cmSortByDueDate = new Comparator<Lineitem>() {
      public int compare(Lineitem li1, Lineitem li2) {
      	Calendar cal1, cal2;
      	cal1 = li1.getOutcomeDefinition().getDueDate();
      	cal2 = li2.getOutcomeDefinition().getDueDate(); 
      	if (cal1 != null && cal2 != null) return cal1.compareTo(cal2);
      	else {
      		if (cal1 == null && cal2 == null) return 0;
      		if (cal1 == null) return -1;
      		if (cal2 == null) return 1;
      	} 
      	throw new AssertionError("cmSortByDueDate - reached unexpected flow of control point.");
      }
    };
	cmSortByMinutesPerPoint = new ComparatorSortByMinutesPerPoint(lineitemHelperHash);
  	blackboard.platform.session.BbSessionManagerService sessionService = BbServiceManager.getSessionManagerService();
 
  	blackboard.platform.session.BbSession bbSession = sessionService.getSession( request );
	blackboard.platform.security.AccessManagerService accessManager = 
		(blackboard.platform.security.AccessManagerService) BbServiceManager.lookupService( blackboard.platform.security.AccessManagerService.class );
	if (! bbSession.isAuthenticated()) {
    	accessManager.sendLoginRedirect(request,response);
    	return;
  	}
	
	//Get a User instance via the page context	
	logForward(LogService.Verbosity.DEBUG, "User sessionUser = ctx.getUser();");
	User sessionUser = ctx.getUser();
    //Get the User's Name and Id
    User.SystemRole sessionUserSystemRole = sessionUser.getSystemRole();
    logForward(LogService.Verbosity.INFORMATION, "sessionUser.getUserName(): " + sessionUser.getUserName() 
    		+ "; sessionUserSystemRole.getDisplayName(): " + sessionUserSystemRole.getDisplayName());

	//Retrieve the Db persistence manager from the persistence service
	logForward(LogService.Verbosity.DEBUG, "bbPm = BbServiceManager.getPersistenceService().getDbPersistenceManager();");	
	//	bbPm = BbServiceManager.getPersistenceService().getDbPersistenceManager();
	bbPm = PersistenceServiceFactory.getInstance().getDbPersistenceManager();
	
	// Generate a persistence framework course Id to be used for loading the course
	// Ids are persistence framework object identifiers.
	Id courseId = bbPm.generateId(Course.DATA_TYPE, courseIdParameter);

	//check user role permission    
    if (sessionUserSystemRole != User.SystemRole.SYSTEM_ADMIN) {
		// perform a check based on course membership:
		CourseMembershipDbLoader cm_loader = CourseMembershipDbLoader.Default.getInstance();
		CourseMembership c_mem = cm_loader.loadByCourseAndUserId(courseId, sessionUser.getId());
		
		boolean do_deny = false; 
		if(c_mem == null) do_deny = true;
		else if (c_mem.getRole() != CourseMembership.Role.INSTRUCTOR 
				&& c_mem.getRole() != CourseMembership.Role.TEACHING_ASSISTANT
				&& c_mem.getRole() != CourseMembership.Role.COURSE_BUILDER) {
			do_deny = true;
		}
		if (do_deny) {
			//logForward(LogService.Verbosity.WARNING, "An unauthorized attempt of BB access.");
			throw new GCDuedatesException("Sorry, you cannot modify due dates for this course. Only course Instructor, Tesching Assistant or Course Builder are allowed to do this.");
			//(!!)
			//out.print ("<p>" + "Sorry, you cannot modify due dates for this course. Only course Instructor, Tesching Assistant or Course Builder are allowed to do this." + "</p>");
			//return;
		}
	}

	logForward(LogService.Verbosity.DEBUG, "LineitemDbLoader liLoader = (LineitemDbLoader)bbPm.getLoader(LineitemDbLoader.TYPE);");
	LineitemDbLoader liLoader = (LineitemDbLoader)bbPm.getLoader(LineitemDbLoader.TYPE);
	logForward(LogService.Verbosity.DEBUG, "liList = liLoader.loadByCourseId(courseId);");
	liList = (ArrayList<Lineitem>)liLoader.loadByCourseId(courseId);
	//liPhysicalList - will contain only regular gradebook columns, without total ones 
	liPhysicalList = new ArrayList<Lineitem>();
//!! - testing double datepicker problem 
//!!	java.util.Collections.sort(liList, cmSortByDueDate);
	Lineitem li_prev = null;
	logForward(LogService.Verbosity.DEBUG, "for (Lineitem li_temp: liList) {");
	for (Lineitem li_temp: liList) {
		//exclude total gradebook columns
		if  (!(li_temp.getType().equals("Weighted Total") || li_temp.getType().equals("Total") )
			//old (Lineitem) API does not set type of lineitem correctly, instead of this it returns "hardcoded" names for "total" columns   
			&& !(li_temp.getType().equals("") && (li_temp.getName().equals("Weighted Total") || li_temp.getName().equals("Total") || li_temp.getName().equals("Running Weighted Total") || li_temp.getName().equals("Running Total"))) 
			)	{
			LineitemHelper mpp = new LineitemHelper(li_prev, li_temp);
			mpp.DueDateOrder = liPhysicalList.size(); 
			liPhysicalList.add(li_temp);			
			lineitemHelperHash.put(li_temp.getId().toExternalString(), mpp);
		}			
		li_prev = li_temp;
	}
	logForward(LogService.Verbosity.DEBUG, "liPhysicalList.size(): " + liPhysicalList.size());	
	String formAction = request.getParameter("idlaGCDueDatesActionParam");
	logForward(LogService.Verbosity.DEBUG, "request.getParameter(\"idlaGCDueDatesActionParam\"): " + formAction);
	if (formAction == null) formAction = "";
	if (formAction.equals("save")) {
		//save modified data, set any success/warning session status and refresh page  		
		logForward(LogService.Verbosity.INFORMATION, "Entering if (formAction.equals(\"save\")) {" );		
		LineitemDbPersister liDbP = (LineitemDbPersister)bbPm.getPersister(LineitemDbPersister.TYPE);
		int li_cnt = Integer.parseInt(request.getParameter("lineitemCountParam"));
		logForward(LogService.Verbosity.DEBUG, "for (int i = 0; i < li_cnt; i++) {");
		LineitemHelper lih = null;   
		for (int i = 0; i < li_cnt; i++) {
			try {
				lih = null;
				LineItemField li_id_field = new LineItemField(liIdParamNameBase + i);
				logForward(LogService.Verbosity.DEBUG, "Id li_id = bbPm.generateId(Lineitem.LINEITEM_DATA_TYPE, li_id_field.value);");
				Id li_id = bbPm.generateId(Lineitem.LINEITEM_DATA_TYPE, li_id_field.value);
				logForward(LogService.Verbosity.DEBUG, "li_id: " + li_id.toString());
				lih = lineitemHelperHash.get(li_id.toExternalString());
				if (lih == null) {
					LineItemField li_name_field = new LineItemField(liNameParamNameBase + i);
					strSaveWarnings = strSaveWarnings + "Column Name: " + li_name_field.value + "ID: " + li_id_field.value + "; Column is missing (could be deleted by another user) on server and was not saved." + "<br>";   
					continue;
				} 
				lih.paramIndex = i;
				LineItemField lif = lih.new LineItemIsAvailableField(liIsAvailableParamNameBase + i);
				lih.fieldsList = new ArrayList<LineItemField>();
				lih.fieldsList.add(lif);
				lif = lih.new LineItemDueDateField(liDueDateParamNameBase + "_" + i);  
				lih.fieldsList.add(lif);
				for (LineItemField lif_temp: lih.fieldsList) {
					lif_temp.checkAndSet();
				}
				if (lih.needsSave()) {
					logForward(LogService.Verbosity.DEBUG, "liDbP.persist(li);");				
					liDbP.persist(lih.lineitem);
					lih.strRowStatus = "Saved";
				}
			} catch (Throwable t) {
				logForward(LogService.Verbosity.WARNING, t, "");
				if (lih != null) lih.strRowStatus = "Error";
				LineItemField li_name_field = new LineItemField(liNameParamNameBase + lih.paramIndex);
				strSaveWarnings = strSaveWarnings + "Column Name: " + li_name_field.value + "; Error occurred upon saving of column, error message: " + t.getClass().getName() + ": " + t.getMessage() + "<br>"; 
			}
		} 

		logForward(LogService.Verbosity.DEBUG, "strSaveWarnings = " + strSaveWarnings);
		
		ReceiptOptions	ro = new ReceiptOptions();
		ReceiptMessage rm;
		if (strSaveWarnings.length() != 0) {
			rm = new ReceiptMessage("WARNING - Not all modifications were saved, some error(s) occurred: <br>" 
									+ strSaveWarnings, 
								ReceiptMessage.messageTypeEnum.WARNING);
		} else rm = new ReceiptMessage("SAVE SUCCESSFUL", ReceiptMessage.messageTypeEnum.SUCCESS);
		ro.addMessage(rm);
		request.getSession().setAttribute(InlineReceiptTag.RECEIPT_KEY, ro);
		//logForward(LogService.Verbosity.DEBUG, "response.sendRedirect" + formURL + "&uuid=" + sessionTag.randomUUID);
		logForward(LogService.Verbosity.DEBUG, "response.sendRedirect(), formURL: " + formURL);
		response.sendRedirect(formURL);
		return;
	} //if (formAction.equals("save") ) {
%>

<%
//try block is split here because of java.lang.IllegalStateException upon response.sendRedirect happening after docTemplate tags.
//While JSP block cannot overlap with bbUI tag
     
} catch (Throwable t) {
	logForward(LogService.Verbosity.ERROR, t, "");   
	throw new GCDuedatesException (strLogMessages, t); 
}

//3)Construction of response       
%>
<bbData:context entitlement="course.control_panel.VIEW">
<bbUI:docTemplateHead title="Grade Center Due Dates" >
</bbUI:docTemplateHead>
	
<bbUI:docTemplateBody>
<!--request.getRequestURL().toString()    -->
<FORM ACTION="gc_duedates.jsp?idlaGCDueDatesActionParam=save" name="idlaGCDueDatesForm" METHOD="POST" onsubmit="return onFormSubmit()">

	<input type="hidden" name="course_id" id="course_id" value="<%= courseIdParameter%>"/>
	<input type="hidden" name="idlaGCDueDatesActionParam" id="idlaGCDueDatesActionParam" value="save"/> 
	<input type="hidden" name="lineitemCountParam" value="<%= liPhysicalList.size()  %>"/> 
	
	<script language='javascript' type='text/javascript'>
	 //	document.getElementById('idlaGCDueDatesActionParam').value = '';
	
	//	function onFormSubmit() {
	//		document.getElementById('idlaGCDueDatesActionParam').value = 'save';
	//		return true;
	//  	}
	</script>
	<%
	try {      
		//this link does not work in BB v.9
		String urlCrtlPanelPage = "/bin/common/control_panel.pl?course_id=" + courseIdParameter;
	%>

    <bbUI:breadcrumbBar environment="CTRL_PANEL">
		<bbUI:breadcrumb
			href="<%=urlCrtlPanelPage%>">
			Control Panel
		</bbUI:breadcrumb>
		<bbUI:breadcrumb><%= PAGE_TITLE%></bbUI:breadcrumb>
    </bbUI:breadcrumbBar>
    <bbUI:inlineReceipt />
    <bbUI:titleBar iconUrl="<%=ICON_URL%>">
   	    <%= PAGE_TITLE %>
   	</bbUI:titleBar>
	<%  
		java.util.Calendar calDueDate = null;
		java.util.Calendar commonDueTime = null;
		String liIdParamName;			
		String liDueDateParamName;
		String liHasDueDateParamName;
		String liIsAvailableParamName;
		String liNameParamName;
		boolean isDueDateFirstPass = true;
	%>
	<bbUI:step title="Time part of all due dates" >
		Please specify if you would like to set time of all due dates to same value during submit
		<br/>
		<%
			commonDueTime = java.util.Calendar.getInstance();
			commonDueTime.clear();
			commonDueTime.set(0, 0, 0, 23, 59, 59);
		%>
		<bbUI:dataElement>
			<label for="isCommonDueTimeParam">Use same time for all due dates?</label>		
	      	<input type="checkbox" name="isCommonDueTimeParam" id="isCommonDueTimeParam" value="on">Time to use:
	      	<bbUI:datePicker startDateField="commonDueTimeParam" startDate="<%= commonDueTime %>"  hideDate="true" isShowTime="true" />
		</bbUI:dataElement>        
	</bbUI:step>	
	<bbUI:step title="Edit due dates">
	    <bbUI:list className="Lineitem" objectId="li"
			collection="<%=liPhysicalList %>" 
			initialSortCol="ColumnOrder"
			>
			<%
				calDueDate = li.getOutcomeDefinition().getDueDate();
				logForward(LogService.Verbosity.DEBUG, "li.getId(): " + li.getId());
				int li_index = lineitemHelperHash.get(li.getId().toExternalString()).DueDateOrder;
				logForward(LogService.Verbosity.DEBUG, "li_index: " + li_index);  
				liIdParamName = liIdParamNameBase + li_index; 			
				//(!!)liDueDateParamName = liDueDateParamNameBase + li_index;
				liDueDateParamName = liDueDateParamNameBase; 
				logForward(LogService.Verbosity.DEBUG, "liDueDateParamName : " + liDueDateParamName + " liDueDateParamName.length(): " + liDueDateParamName.length());
				liHasDueDateParamName = liHasDueDateParamNameBase + li_index; 
				liIsAvailableParamName =  liIsAvailableParamNameBase + li_index; 
				liNameParamName = liNameParamNameBase + li_index;
			%>		
	
			<bbUI:listElement
				comparator="<%=cmSortByColumnOrder%>" 
				label="Column" 
				name="ColumnOrder" >
	    	    	<%= li.getColumnOrder() %>
					<input type="hidden" name="<%= liIdParamName %>" id="<%= liIdParamName %>" value="<%= li.getId().toExternalString()%>"/>
					<input type="hidden" name="<%= liNameParamName %>" id="<%= liNameParamName %>" value="<%= li.getName()%>"/>
					<% logForward(LogService.Verbosity.DEBUG, "Column - li_index: " + li_index); %>
	    	</bbUI:listElement>
	    	
	    	<bbUI:listElement 
				comparator="<%=cmSortByName%>"    	
				label="Name" 
				name="Name" >
	    	    	<%= li.getName() %>
					<% logForward(LogService.Verbosity.DEBUG, "Name - li_index: " + li_index); %>    	    	
	    	</bbUI:listElement>
			<bbUI:listElement 
				comparator="<%=cmSortByType%>"
				label="Category" 
				name="Category" >
				<%= li.getType()  %>
				<% logForward(LogService.Verbosity.DEBUG, "Category - li_index: " + li_index); %>
			</bbUI:listElement>
			<bbUI:listElement 
				comparator="<%=cmSortByIsAvailable%>"
				label="Is Available?" 
				name="isAvailable" >
				<input name="<%= liIsAvailableParamName%>" type="checkbox"  
				<% if (li.getIsAvailable()) out.print ("checked"); %> >
				<% logForward(LogService.Verbosity.DEBUG, "Is Available - li_index: " + li_index); %>
			</bbUI:listElement>
			<bbUI:listElement 
				comparator="<%=cmSortByHasDueDate%>"
				label="Has Due Date?" 
				name="hasDueDate" >
				<input name="<%= liHasDueDateParamName%>" type="checkbox"  
				<% if (li.getOutcomeDefinition().getDueDate() != null) out.print ("checked"); %> >
				<% logForward(LogService.Verbosity.DEBUG, "Has Due Date - li_index: " + li_index); %>
			</bbUI:listElement>
			<bbUI:listElement 
				comparator="<%=cmSortByDueDate%>"		
				label="Due Date" 
				name="DueDate" > 
				<c:if test="<%=!isDueDateFirstPass%>">
					<% 
						//use of DatePickerTag here causes 
						//IOException in DatePickerTag: java.io.IOException: Illegal to flush within a custom tag
						logForward(LogService.Verbosity.DEBUG, "DatePickerTag dpt = new DatePickerTag() " + li_index);
						DatePickerTag dpt = new DatePickerTag();
						dpt.setPageContext(pageContext);
						//(!!)dpt.setParent()
						dpt.setStartDateField(liDueDateParamName);
						logForward(LogService.Verbosity.DEBUG, "calDueDate " + calDueDate);
						if (calDueDate == null) calDueDate = Calendar.getInstance();
						dpt.setStartDate(calDueDate);
						dpt.setIsShowTime(true);
						dpt.setDatePickerIndex(li_index);
						pageContext.setAttribute(DatePickerTag.DATE_PICKER_TAG_ATTRIBUTE, dpt, 2);
						DatePicker dp = new DatePicker(2, calDueDate);
						//DatePicker dp = new DatePicker(Calendar.HOUR, calDueDate);
						pageContext.setAttribute(DatePickerTag.DATE_PICKER_ATTRIBUTE, dp, 2);
						logForward(LogService.Verbosity.DEBUG, "<%@include ..." + li_index);
						pageContext.setAttribute(DatePickerTag.DATE_PICKER_INDEX_ATTRIBUTE, li_index, 2);
						//(!!)
						logForward(LogService.Verbosity.DEBUG, "pageContext.PAGE_SCOPE: " + PageContext.PAGE_SCOPE);
						logForward(LogService.Verbosity.DEBUG, "pageContext.REQUEST_SCOPE: " + PageContext.REQUEST_SCOPE);
						logForward(LogService.Verbosity.DEBUG, "pageContext.SESSION_SCOPE: " + PageContext.SESSION_SCOPE);					
					%>	
						<%@include file="/taglib/date-picker.jsp"%>
				</c:if >
				<% 	logForward(LogService.Verbosity.DEBUG, "Due Date - li_index: " + li_index);
					logForward(LogService.Verbosity.DEBUG, "lineitemHelperHash.get(li.getId().toExternalString()).isDueDateConstructed: " + lineitemHelperHash.get(li.getId().toExternalString()).isDueDateConstructed);
					isDueDateFirstPass = false;
				%>
			</bbUI:listElement>
		</bbUI:list>	
	</bbUI:step> 
	<!-- cancelUrl="gc_duedates.jsp" -->
	<!--  Cancel will bring us out of the form (back), only submit (and refresh?) will refresh it here - actually temp solution, has to be implemented with javascript-->
  <bbUI:stepSubmit title="Submit"
  	instructions="Click Submit to save and reload. Cancel acts as browser's back button."/> 
    Description of plugin processing is available <a href="http://projects.oscelot.org/gf/project/gc_duedates/wiki/?pagename=Grade+Center+Due+Dates+Building+Block+Description">here</a>.	
</FORM>


<%
} catch (Throwable t) {
	logForward(LogService.Verbosity.ERROR, t, "");   
	throw new GCDuedatesException (strLogMessages, t); 
}      

%>
</bbUI:docTemplateBody>
</bbData:context>

 