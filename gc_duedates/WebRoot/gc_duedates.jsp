<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<%@ page 
		language="java" 
		import="java.util.*,
				java.lang.reflect.Array,
				java.util.Calendar,
				java.io.StringWriter,
				java.io.PrintWriter,
				blackboard.data.user.*,
				blackboard.data.course.*,
				blackboard.data.gradebook.*,
				blackboard.persist.*,
				blackboard.persist.course.*,
				blackboard.persist.gradebook.*,
				blackboard.platform.log.*,
				blackboard.platform.persistence.PersistenceServiceFactory,  
				blackboard.platform.plugin.PlugInUtil,
				blackboard.servlet.util.DatePickerUtil"	
		errorPage="error.jsp"           
		pageEncoding="UTF-8" 
%>

 
<%@ taglib uri="/bbUI" prefix="bbUI"%>
<%@ taglib uri="/bbData" prefix="bbData"%>
<%@ taglib uri="/bbNG" prefix="bbNG"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core"    prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt"     prefix="fmt"%>

<!-- gc_duedates.jsp -->

<%!
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
			//log.logWarning(message);
		}
		log.log(message, verbosity);
		
		
		//log.log("strLogMessages: " + strLogMessages, verbosity);    
	}
	void logForward(LogService.Verbosity verbosity, java.lang.Throwable error, String message) {
		strLogMessages = strLogMessages + verbosity.toString() + "	" + message + "<br>" ;
		strLogMessages = strLogMessages + verbosity.toString() + "	" + error.getMessage() + "<br>" ;
		StringWriter sw = new StringWriter();
		PrintWriter pw = new PrintWriter(sw, true);
		error.printStackTrace(pw);
		strLogMessages = strLogMessages + verbosity.toString() + "	" + sw.toString() + "<br>" ;
		message = "IDLA.gradecenter_duedates	Session: " + servletSession.getId() + "	" + message;
		//using higher severity log level for easier development testing, log is overfilled when all messages are of debug level
		//actual log.logWarning has to be commented out in production release, but may be uncommented for collecting of log messages  
		if (verbosity.getLevelAsInt() > LogService.Verbosity.WARNING.getLevelAsInt()) {
			log.logWarning(message, error);
		}
		log.log(message, error, verbosity);
		//log.log("strLogMessages: " + strLogMessages, verbosity);
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
	 	
	//variables declared as class members for availability from inside inner classes
	public BbPersistenceManager bbPm;
	String formURL;
	HttpServletRequest servletRequest;
	HttpServletResponse servletResponse;
	HttpSession			servletSession;
	
	static final String liDueDateParamNameBase = "liDueDateParam_";
	static final String liIdParamNameBase = "liIdParam_";
	static final String liHasDueDateParamNameBase = "liHasDueDateParam_";
	static final String liIsAvailableParamNameBase =  "liIsAvailableParam_";
	static final String liNameParamNameBase =  "liNameParam_";

	//objects of this class will be stored in session scope under randomUUID key
	//and uniquely identify browser's page  
	private class SessionTag {
		String 	randomUUID;
		//String 	refererURL;
		//int 	historyGoBackCount;
		String	warningMessage;
		//boolean saveDone;
	}	

	//Lineitem Field is class for more centralized error handling of Lineitem fields setting and persisting
	//add easier capabilities for adding of more editable fields  
	private class  LineItemField {
		protected String value;
		String paramName;
		boolean isSet;
		public LineItemField (String paramName_) {
			paramName = paramName_;
			value = servletRequest.getParameter(paramName);
			logForward(LogService.Verbosity.INFORMATION, "LineItemField read parameter " + paramName + ": " + value);
			if (value == null) value = "";
		}
		
		void checkAndSet() throws GCDuedatesException {
			isSet = false;
			checkAndSetInternal();
		}
		void checkAndSetInternal() throws GCDuedatesException {}
	} //private class  LineItemField {
		
		//just trying to avoid re-writing of parameterized condtructor for every inherited class with this function 
	
	
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
		
		public int DueDateOrder; //used just for indexing, contains initial DueDateOrder, can become incrrect after save, but it should not influence behavior
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
			//if (calendar == null) return "";
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

		private class  LineItemDueDateField extends LineItemField {
			LineItemField liHasDueDate;
			LineItemField isCommonDueTime;
			LineItemField commonDueTime;
			LineItemDueDateField(String paramName_) {
				super(paramName_);			
				liHasDueDate = new LineItemField(liHasDueDateParamNameBase + LineitemHelper.this.paramIndex);
				isCommonDueTime = new LineItemField("isCommonDueTimeParam");
				commonDueTime = new LineItemField("commonDueTimeParam_datetime");
			}
			
			void checkAndSetInternal() throws GCDuedatesException {
				if (liHasDueDate.value.equals("on")) {
					Calendar due_date = DatePickerUtil.pickerDatetimeStrToCal(value);
					if (due_date == null) {
						throw new GCDuedatesException("Due date is not set");
					}	
					logForward(LogService.Verbosity.DEBUG, "due_date: " + due_date);
					if (isCommonDueTime.value.equals("on")) {
						Calendar common_duetime = DatePickerUtil.pickerDatetimeStrToCal(commonDueTime.value);
						logForward(LogService.Verbosity.DEBUG, "common_duetime: " + common_duetime.toString());
						due_date.set(Calendar.MILLISECOND, common_duetime.get(Calendar.MILLISECOND));
						due_date.set(Calendar.SECOND, common_duetime.get(Calendar.SECOND));
						due_date.set(Calendar.MINUTE, common_duetime.get(Calendar.MINUTE));
						due_date.set(Calendar.HOUR_OF_DAY, common_duetime.get(Calendar.HOUR_OF_DAY));						
					}  
					if (LineitemHelper.this.lineitem.getOutcomeDefinition().getDueDate() == null) {
						logForward(LogService.Verbosity.INFORMATION, "getOutcomeDefinition().getDueDate() == null -> LineitemHelper.this.lineitem.getOutcomeDefinition().setDueDate(due_date);");
						LineitemHelper.this.lineitem.getOutcomeDefinition().setDueDate(due_date);
						isSet = true;
					} else if (LineitemHelper.this.lineitem.getOutcomeDefinition().getDueDate().compareTo(due_date) != 0) {
								logForward(LogService.Verbosity.INFORMATION, "getOutcomeDefinition().getDueDate().compareTo(due_date) != 0 -> LineitemHelper.this.lineitem.getOutcomeDefinition().setDueDate(due_date);");
								LineitemHelper.this.lineitem.getOutcomeDefinition().setDueDate(due_date);
								isSet = true;
							} 
				} else if (LineitemHelper.this.lineitem.getOutcomeDefinition().getDueDate() != null) {
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

<bbNG:learningSystemPage  ctxId="ctx">
<%
try {
	strLogMessages = "";
	servletSession = session;
	logForward(LogService.Verbosity.INFORMATION, "session.getId(): " + session.getId());
	
	strSaveWarnings = "";
	servletRequest = request;
	servletResponse = response;

	//save paramters in log
	Enumeration<String> keys = servletRequest.getParameterNames();
	ArrayList<String> keys_list = Collections.list(keys);
	Comparator<String> cmSortParamsByName = new Comparator<String>() {
      public int compare(String s1, String s2) {
      	return s1.compareTo(s2);
      }
    };
	java.util.Collections.sort(keys_list, cmSortParamsByName);
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
		    logForward(LogService.Verbosity.DEBUG, s_temp + ": " + value);
		}
	}

	logForward(LogService.Verbosity.DEBUG, "request.getRemoteHost(): " + request.getRemoteHost());
	logForward(LogService.Verbosity.DEBUG, "request.getServerPort(): " + request.getServerPort());
	logForward(LogService.Verbosity.DEBUG, "request.getRequestURI(): " + request.getRequestURI());
	logForward(LogService.Verbosity.INFORMATION, "request.getRequestURL(): " + request.getRequestURL());
	logForward(LogService.Verbosity.INFORMATION, "request.getQueryString(): " + request.getQueryString());
	
	// Retrieve the course identifier from the URL
	String courseIdParameter = request.getParameter("course_id");
	logForward(LogService.Verbosity.INFORMATION, "request.getParameter(\"course_id\"): " + courseIdParameter);
	formURL = request.getRequestURL().toString() + "?course_id=" + courseIdParameter;
	String javascriptCancelOnClick = "javascript:window.location='" + formURL + "'";

	String PAGE_TITLE = "Grade Center Due Dates";
	String ICON_URL = PlugInUtil.getUri( "IDLA", "gradecenter_duedates", "DueDates.jpg");
	java.util.HashMap<String, LineitemHelper> lineitemHelperHash = new java.util.HashMap<String, LineitemHelper>();
	
	Comparator<Lineitem> cmSortByColumnOrder = new Comparator<Lineitem>() {
      public int compare(Lineitem li1, Lineitem li2) {
        return li1.getColumnOrder() - li2.getColumnOrder(); 
      }
    };

    Comparator<Lineitem> cmSortByName = new Comparator<Lineitem>() {
      public int compare(Lineitem li1, Lineitem li2) {
        String s1 = (String)li1.getName();
        String s2 = (String)li2.getName();        
        int compare = s1.toLowerCase().compareTo(s2.toLowerCase());
        return compare;
      }
    };
    Comparator<Lineitem> cmSortByType = new Comparator<Lineitem>() {
      public int compare(Lineitem li1, Lineitem li2) {
        String s1 = (String)li1.getType();
        String s2 = (String)li2.getType();        
        int compare = s1.toLowerCase().compareTo(s2.toLowerCase());
        return compare;
      }
    };
    
    Comparator<Lineitem> cmSortByIsAvailable = new Comparator<Lineitem>() {
      public int compare(Lineitem li1, Lineitem li2) {
      	boolean is_av1 = li1.getIsAvailable();
      	boolean is_av2 = li2.getIsAvailable();
      	return Boolean.valueOf(is_av1).compareTo(is_av2);
      }
    };

    Comparator<Lineitem> cmSortByHasDueDate = new Comparator<Lineitem>() {
      public int compare(Lineitem li1, Lineitem li2) {
      	boolean has_dd1 = (li1.getOutcomeDefinition().getDueDate() != null);
      	boolean has_dd2 = (li2.getOutcomeDefinition().getDueDate() != null);
      	return Boolean.valueOf(has_dd1).compareTo(has_dd2);
      }
    };
    
	Comparator<Lineitem> cmSortByDueDate = new Comparator<Lineitem>() {
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
	ComparatorSortByMinutesPerPoint cmSortByMinutesPerPoint = new ComparatorSortByMinutesPerPoint(lineitemHelperHash);
 
	//Get a User instance via the page context
	logForward(LogService.Verbosity.DEBUG, "User sessionUser = ctx.getUser();");
	User sessionUser = ctx.getUser();
    //Get the User's Name and Id
    User.SystemRole sessionUserSYSTEMRole = sessionUser.getSystemRole();

	//Retrieve the Db persistence manager from the persistence service
	logForward(LogService.Verbosity.DEBUG, "bbPm = BbServiceManager.getPersistenceService().getDbPersistenceManager();");	
//	bbPm = BbServiceManager.getPersistenceService().getDbPersistenceManager();
	bbPm = PersistenceServiceFactory.getInstance().getDbPersistenceManager();
	
	// Generate a persistence framework course Id to be used for loading the course
	// Ids are persistence framework object identifiers.
	Id courseId = bbPm.generateId(Course.DATA_TYPE, courseIdParameter);

	//check user role permission    
    if (sessionUserSYSTEMRole != User.SystemRole.SYSTEM_ADMIN) {
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
			//out.print ("<p>" + "Sorry, you cannot modify due dates for this course. Only course Instructor, Tesching Assistant or Course Builder are allowed to do this." + "</p>");
			//return;
		}
	}

	logForward(LogService.Verbosity.DEBUG, "LineitemDbLoader liLoader = (LineitemDbLoader)bbPm.getLoader(LineitemDbLoader.TYPE);");
	LineitemDbLoader liLoader = (LineitemDbLoader)bbPm.getLoader(LineitemDbLoader.TYPE);
	logForward(LogService.Verbosity.DEBUG, "ArrayList liList = liLoader.loadByCourseId(courseId);");
	ArrayList<Lineitem> liList = (ArrayList<Lineitem>)liLoader.loadByCourseId(courseId);
	ArrayList<Lineitem> liPhysicalList = new ArrayList<Lineitem>();
//!! - testing double datepicker problem 
//!!	java.util.Collections.sort(liList, cmSortByDueDate);
	Lineitem li_prev = null;
	logForward(LogService.Verbosity.DEBUG, "for (Lineitem li_temp: liList) {");
	for (Lineitem li_temp: liList) {
		if  (!(li_temp.getType().equals("Weighted Total") || li_temp.getType().equals("Total") ) 
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
//	if (formAction != null) {
//		String formAction1 = (String) request.getAttribute("idlaGCDueDatesActionAttrib");
//		logForward(LogService.Verbosity.DEBUG, "request.getAttribute(\"idlaGCDueDatesActionAttrib\"): " + formAction1);
//		if (formAction1 == null) formAction1 = "";  
//		if (formAction.equals("save") && !formAction1.equals("saved")) {
		if (formAction.equals("save") ) {
			request.setAttribute("idlaGCDueDatesActionAttrib", "saved");
			logForward(LogService.Verbosity.INFORMATION, "Entering if (formAction.equals(\"save\")) {" );		
			logForward(LogService.Verbosity.DEBUG, "LineitemDbPersister liDbP = (LineitemDbPersister)bbPm.getPersister(LineitemDbPersister.TYPE);");
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
					lif = lih.new LineItemDueDateField(liDueDateParamNameBase + i + "_datetime");  
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
					LineItemField li_id_field = new LineItemField(liIdParamNameBase + lih.paramIndex);
					strSaveWarnings = strSaveWarnings + "Column Name: " + li_name_field.value + "; Error occurred upon saving of column, error message: " + t.getMessage() + "<br>";				
				}
			} //for (int i = 0; i < li_cnt; i++) {
//			java.util.Collections.sort(liPhysicalList, cmSortByDueDate);
//			li_prev = null;
//			for (Lineitem li_temp: liPhysicalList) {
//   				LineitemHelper mpp = lineitemHelperHash.get(li_temp.getId().toExternalString());
//   				mpp.liPrev = li_prev; 
//   				mpp.refresh();
//			}
	
			SessionTag sessionTag = new SessionTag();
			sessionTag.randomUUID = UUID.randomUUID().toString();
			// This loop should never really be entered, uuid should be unique 
			// Trying to prevent collision in user random uuid 
			while( session.getAttribute( sessionTag.randomUUID ) != null ) { 
				sessionTag.randomUUID = UUID.randomUUID().toString(); 
			}
			logForward(LogService.Verbosity.INFORMATION, "sessionTag.randomUUID = " + sessionTag.randomUUID);
			sessionTag.warningMessage = strSaveWarnings;
			session.setAttribute(sessionTag.randomUUID, sessionTag);
//			sessionTag.saveDone = true;
			
			
			response.sendRedirect(formURL + "&uuid=" + sessionTag.randomUUID);
/*			if (strSaveWarnings.length() != 0) { 
				out.print ("<p> <font color=\"#FF0000\">" + "WARNING - Not all modifications were saved, some error(s) occurred: <br>"
						+ strSaveWarnings 
						+ "</font></p>");
			} else out.print ("<p> <font color=\"#00FF00\">" + "SAVE SUCCESSFULL" + "</font></p>");
*/			
		} //if (formAction.equals("save") ) {
		else {
//			sessionTag.historyGoBackCount--;
//			if (sessionTag.saveDone) {
				String uuid = request.getParameter("uuid");
				if (uuid != null) {
					SessionTag sessionTag = (SessionTag) session.getAttribute(uuid);
					if (sessionTag == null) {
						throw new GCDuedatesException ("Unknown session uuid (uuid: " + uuid + "), try restarting the session"); 
					}
					logForward(LogService.Verbosity.INFORMATION, "sessionTag.randomUUID: " + sessionTag.randomUUID);
					if (sessionTag.warningMessage.length() != 0) { 
						out.print ("<p> <font color=\"#FF0000\">" + "WARNING - Not all modifications were saved, some error(s) occurred: <br>"
								+ sessionTag.warningMessage 
								+ "</font></p>");
	//					sessionTag.warningMessage = "";
//-causes error upon reorder						session.removeAttribute(sessionTag.randomUUID);
					} else out.print ("<p> <font color=\"#00FF00\">" + "SAVE SUCCESSFULL" + "</font></p>");
	//				sessionTag.saveDone = false;
				}	

//			}
		} 
//	} if (formAction != null) {
//	String str_hist_go_count = (String) request.getAttribute("idlaGCDueDatesHistoryGoCountAttrib");
//	logForward(LogService.Verbosity.DEBUG, "request.getAttribute(\"idlaGCDueDatesHistoryGoCountAttrib\"): " + str_hist_go_count);
	
//	str_hist_go_count = (String) session.getValue("idlaGCDueDatesHistoryGoCountValue");
//	logForward(LogService.Verbosity.DEBUG, "session.getValue(\"idlaGCDueDatesHistoryGoCountValue\"): " + str_hist_go_count);	

//	if (str_hist_go_count == null) {	
//		str_hist_go_count = request.getParameter("idlaGCDueDatesHistoryGoCountParam");
//		logForward(LogService.Verbosity.DEBUG, "request.getParameter(\"idlaGCDueDatesHistoryGoCountParam\"): " + str_hist_go_count);	
//	}
//	int hist_go_count = -1;
//	if (str_hist_go_count != null) hist_go_count = Integer.parseInt(str_hist_go_count) - 1;
//	logForward(LogService.Verbosity.DEBUG, "hist_go_count: " + hist_go_count);
//	String js_hist_go_count;
//	if (sessionTag.refererURL != null) js_hist_go_count = "javascript:window.location='" + sessionTag.refererURL + "'";  	
//	else js_hist_go_count = "history.go(" + sessionTag.historyGoBackCount + ");";
		
	
//	logForward(LogService.Verbosity.DEBUG, "js_hist_go_count: " + js_hist_go_count);
//	request.setAttribute("idlaGCDueDatesHistoryGoCountAttrib", Integer.toString(hist_go_count));
//	str_hist_go_count = (String) request.getAttribute("idlaGCDueDatesHistoryGoCountAttrib");
//	logForward(LogService.Verbosity.DEBUG, "After setting - request.getAttribute(\"idlaGCDueDatesHistoryGoCountAttrib\"): " + str_hist_go_count);
//	session.putValue("idlaGCDueDatesHistoryGoCountValue", Integer.toString(hist_go_count));
//	str_hist_go_count = (String) session.getValue("idlaGCDueDatesHistoryGoCountValue");
//	logForward(LogService.Verbosity.DEBUG, "After setting - session.getValue(\"idlaGCDueDatesHistoryGoCountValue\"): " + str_hist_go_count);	
%>

<bbNG:form name="idlaGCDueDatesForm" method="post" action="gc_duedates.jsp" onsubmit="return onFormSubmit()">
<input type="hidden" name="course_id" id="course_id" value="<%= courseIdParameter%>"/>
<input type="hidden" name="idlaGCDueDatesActionParam" id="idlaGCDueDatesActionParam" value=""/>
<input type="hidden" name="lineitemCountParam" value="<%= liPhysicalList.size()  %>"/>

<bbNG:jsBlock> 
 <script language="javascript">  
 	document.getElementById('idlaGCDueDatesActionParam').value = '';

	function onFormSubmit() {
		document.getElementById('idlaGCDueDatesActionParam').value = 'save';
		return true;
  	}
  	var tbl = document.getElementById('datatable').value;
  	if (tbl != null) {
  		document.write('Hello World!');
  	}
  	
//  	for(var i=0; i < tbl.columns.length-1; i++) 
//  	{
//  		var col = pTable.columns[i];
//  	}
 </script>
</bbNG:jsBlock>


<bbNG:dataCollection markUnsavedChanges="false">
    <bbNG:breadcrumbBar environment="CTRL_PANEL">
    	<bbNG:breadcrumb><%= PAGE_TITLE%></bbNG:breadcrumb>
    </bbNG:breadcrumbBar>
	<bbNG:pageHeader>
	    <bbNG:pageTitleBar iconUrl="<%=ICON_URL%>">
    	    <%= PAGE_TITLE %>
    	</bbNG:pageTitleBar>
    </bbNG:pageHeader>
	<% 
		java.util.Calendar calDueDate = null;
		java.util.Calendar commonDueTime = null;
		//int iLineitemIndex = 3;
		String liIdParamName;			
		String liDueDateParamName, liDueDateParamName1, liDueDateParamName2, liDueDateParamName3;
		String liHasDueDateParamName;
		String liIsAvailableParamName;
		String liNameParamName;
		boolean isDueDateFirstPass = true;
	%>
	<bbNG:step title="Time part of all due dates" instructions="Please specify if you would like to set time of all due dates to same value during submit">
		<%
		commonDueTime = java.util.Calendar.getInstance();
		commonDueTime.clear();
		commonDueTime.set(0, 0, 0, 23, 59, 59);
		%>
		<bbNG:dataElement>
			<label for="isCommonDueTimeParam">Use same time for all due dates?</label>		
        	<bbNG:checkboxElement name="isCommonDueTimeParam" id="isCommonDueTimeParam" value="on" isSelected="false" helpText="" title="" optionLabel="Time to use:"/>
        	<bbNG:datePicker baseFieldName="commonDueTimeParam" dateTimeValue="<%= commonDueTime %>"  showDate="false" showTime="true" midnightWarning="??midnight warning??" suppressInstructions="true"/>
		</bbNG:dataElement>        
	</bbNG:step>	
	<bbNG:step title="Edit due dates">
    <bbNG:inventoryList className="Lineitem" 
		collection="<%=liPhysicalList %>" 
		showAll="true"
		objectVar="li" 
		initialSortCol="ColumnOrder"
		>

		<%
			calDueDate = li.getOutcomeDefinition().getDueDate();
			logForward(LogService.Verbosity.DEBUG, "li.getId(): " + li.getId());
			int li_index = lineitemHelperHash.get(li.getId().toExternalString()).DueDateOrder;
			logForward(LogService.Verbosity.DEBUG, "li_index: " + li_index);  
			liIdParamName = liIdParamNameBase + li_index; 			
			liDueDateParamName = liDueDateParamNameBase + li_index; 
			liDueDateParamName1 = liDueDateParamNameBase + "I_" + li_index;
			liDueDateParamName2 = liDueDateParamNameBase + "II_" + li_index;
			liDueDateParamName3 = liDueDateParamNameBase + "III_" + li_index; 
			logForward(LogService.Verbosity.DEBUG, "liDueDateParamName : " + liDueDateParamName + " liDueDateParamName.length(): " + liDueDateParamName.length());
			liHasDueDateParamName = liHasDueDateParamNameBase + li_index; 
			liIsAvailableParamName =  liIsAvailableParamNameBase + li_index; 
			liNameParamName = liNameParamNameBase + li_index;
		%>		

		<bbNG:listElement
			comparator="<%=cmSortByColumnOrder%>" 
			label="Column" 
			name="ColumnOrder" >
    	    	<%= li.getColumnOrder() %>
				<input type="hidden" name="<%= liIdParamName %>" id="<%= liIdParamName %>" value="<%= li.getId().toExternalString()%>"/>
				<input type="hidden" name="<%= liNameParamName %>" id="<%= liNameParamName %>" value="<%= li.getName()%>"/>
				<% logForward(LogService.Verbosity.DEBUG, "Column - li_index: " + li_index); %>
    	</bbNG:listElement>
    	
    	<bbNG:listElement 
			comparator="<%=cmSortByName%>"    	
			label="Name" 
			name="Name" 
			isRowHeader="true" >
    	    	<%= li.getName() %>
				<% logForward(LogService.Verbosity.DEBUG, "Name - li_index: " + li_index); %>    	    	
    	</bbNG:listElement>
		<bbNG:listElement 
			comparator="<%=cmSortByType%>"
			label="Category" 
			name="Category" >
			<%= li.getType()  %>
			<% logForward(LogService.Verbosity.DEBUG, "Category - li_index: " + li_index); %>
		</bbNG:listElement>
		<bbNG:listElement 
			comparator="<%=cmSortByIsAvailable%>"
			label="Is Available?" 
			name="isAvailable" >
			<input name="<%= liIsAvailableParamName%>" type="checkbox"  
			<% if (li.getIsAvailable()) out.print ("checked"); %> >
			<% logForward(LogService.Verbosity.DEBUG, "Is Available - li_index: " + li_index); %>
		</bbNG:listElement>
		<bbNG:listElement 
			comparator="<%=cmSortByHasDueDate%>"
			label="Has Due Date?" 
			name="hasDueDate" >
			<input name="<%= liHasDueDateParamName%>" type="checkbox"  
			<% if (li.getOutcomeDefinition().getDueDate() != null) out.print ("checked"); %> >
			<% logForward(LogService.Verbosity.DEBUG, "Has Due Date - li_index: " + li_index); %>
		</bbNG:listElement>
		<bbNG:listElement 
			comparator="<%=cmSortByDueDate%>"		
			label="Due Date" 
			name="DueDate" > 
			<c:if test="<%=!isDueDateFirstPass%>">
				<bbNG:dataElement>
					<bbNG:datePicker
						baseFieldName = "<%= liDueDateParamName %>" 
						dateTimeValue="<%= calDueDate %>"
						showTime="true"
					/>
				</bbNG:dataElement>
			</c:if >
			<% 	logForward(LogService.Verbosity.DEBUG, "Due Date - li_index: " + li_index);
				logForward(LogService.Verbosity.DEBUG, "lineitemHelperHash.get(li.getId().toExternalString()).isDueDateConstructed: " + lineitemHelperHash.get(li.getId().toExternalString()).isDueDateConstructed);
				isDueDateFirstPass = false;
			%>
		</bbNG:listElement>
	</bbNG:inventoryList>	
	</bbNG:step> 
	<!-- cancelUrl="gc_duedates.jsp" -->
	<!--  Cancel will bring us out of the form (back), only submit (and refresh?) will refresh it here - actually temp solution, has to be implemented with javascript-->
  <bbNG:stepSubmit title="Submit"  instructions="Click Submit to save and reload. Click Cancel to abandon changes and restore original data. Use regular Blackboard menu to navigate away from the building block (unsubmitted changes will be lost)." cancelOnClick="<%=javascriptCancelOnClick  %>">
  </bbNG:stepSubmit>
    Description of plugin processing is available <a href="http://projects.oscelot.org/gf/project/gc_duedates/wiki/?pagename=Grade+Center+Due+Dates+Building+Block+Description">here</a>.	
</bbNG:dataCollection> 
</bbNG:form>

<%
} catch (Throwable t) {
	logForward(LogService.Verbosity.ERROR, t, "");   
	throw new GCDuedatesException (strLogMessages, t); 
}      

%>
		
	
</bbNG:learningSystemPage >

 