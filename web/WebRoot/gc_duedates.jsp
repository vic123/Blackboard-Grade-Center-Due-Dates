<%@ include file="doctype.jspf" %>

<%@ page
		language="java" 
		import="java.util.*,
				java.lang.reflect.Array,
				java.util.Calendar,
				java.util.Date,
		        blackboard.base.*,
				blackboard.data.*,
				blackboard.data.user.*,
				blackboard.data.course.*,
				blackboard.data.gradebook.*,
				blackboard.persist.*,
				blackboard.persist.user.*,
				blackboard.persist.course.*,
				blackboard.persist.gradebook.*,
				blackboard.platform.*,
				blackboard.platform.log.*, 
				blackboard.platform.plugin.PlugInUtil,
				blackboard.servlet.util.DatePickerUtil"	
		errorPage="error.jsp"           
		pageEncoding="UTF-8"
%>
 
<%@ taglib uri="/bbUI" prefix="bbUI"%>
<%@ taglib uri="/bbData" prefix="bbData"%>
<%@ taglib uri="/bbNG" prefix="bbNG"%>
<%@ taglib uri="http://java.sun.com/jstl/core"    prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt"     prefix="fmt"%>

<!-- gc_duedates.jsp -->

<jsp:useBean id="itemForm" scope="request" class="org.oscelot.gc_duedates.struts.ModifyItemsDueDatesForm" />

<%!
	static Log log = LogServiceFactory.getInstance().getDefaultLog(); 	
	void logDebug(String s) { 
		//using higher severity log level for easier development testing, log is overfilled when all messages are of debug level
		//!! has to be modified to log.logDebug(s);  
		log.logWarning(s);
	}
	private static class MinutesPerPoint
	{
		Lineitem liPrev;
		Lineitem liNext;
		Calendar calPrev;
		Calendar calNext;
		String strRowStatus;
		float fPointsPossible;
		float fMinutesPerPoint;
		long lMinutesCount;
		
		public int DueDateOrder;

		public MinutesPerPoint(Lineitem liPrev_, Lineitem liNext_) {
			strRowStatus = "";
			liPrev = liPrev_;
			liNext = liNext_;
			assert (liNext_ != null);			
			refresh();
		}
		public void refresh() {
			calPrev = null;
			calNext = null;
			fPointsPossible = liNext.getPointsPossible();
			calNext = liNext.getOutcomeDefinition().getDueDate();
			if (liPrev == null) {
				fMinutesPerPoint = 0;
			} else { 
				calPrev = liPrev.getOutcomeDefinition().getDueDate();
				if (calPrev == null) {
					fMinutesPerPoint = 0;
				} else if (calNext != null) {
					lMinutesCount = (long) ((calNext.getTimeInMillis() - calPrev.getTimeInMillis()) / (1000 * 60));
					fMinutesPerPoint = lMinutesCount/fPointsPossible;
				}
			}
			if (calNext == null) fMinutesPerPoint = -1;
		}
	
		public String toString() {
			//if (calNext == null) return "";
			if (calNext == null || liPrev == null || calPrev == null) return "N/A / " + fPointsPossible + " = N/A";
			else return lMinutesCount + " / " + fPointsPossible + " = " + fMinutesPerPoint;
		} 
	}
	
	private static class ComparatorSortByMinutesPerPoint implements Comparator<Lineitem> {
		public java.util.HashMap<String, MinutesPerPoint> minutesPerPointHash;
		ComparatorSortByMinutesPerPoint (java.util.HashMap<String, MinutesPerPoint> minutesPerPointHash_) {
			minutesPerPointHash = minutesPerPointHash_;
		} 
   		public int compare(Lineitem li1, Lineitem li2) {
	   		MinutesPerPoint minpp1 = minutesPerPointHash.get(li1.getId().toExternalString()); 
	   		MinutesPerPoint minpp2 = minutesPerPointHash.get(li2.getId().toExternalString() );
	        if (minpp1.liPrev == null) return -1;
	        if (minpp2.liPrev == null) return 1;
	        return Float.compare (minpp1.fMinutesPerPoint, minpp2.fMinutesPerPoint); 
		}
   	}
   	
	
	
%>

<bbNG:learningSystemPage  ctxId="ctx">
<!-- 
	log.getLogFileName() = "<%= log.getLogFileName() %>" <br>
	log.getLogName() = "<%= log.getLogName() %>"
	<p>
 -->
<%

	String PAGE_TITLE = "Grade Center Due Dates";
	String msg = null;
	//	String ICON_URL = "/images/DueDates.jpg";
	//String ICON_URL = PlugInUtil.getUri( "IDLA", "gradecenter_duedates", "images/DueDates.jpg");
	String ICON_URL = PlugInUtil.getUri( "IDLA", "gradecenter_duedates", "DueDates.jpg");
	java.util.HashMap<String, MinutesPerPoint> minutesPerPointHash = new java.util.HashMap<String, MinutesPerPoint>();
	
	String liDueDateParamNameBase = "liDueDateParam_";
	String liIdParamNameBase = "liIdParam_";
	String liHasDueDateParamNameBase = "liHasDueDateParam_";
	String liIsAvailableParamNameBase =  "liIsAvailableParam_";

%>
 <!-- 
	ICON_URL = "<%= ICON_URL %>"
	<p>
  --> 
<%	
	//null AV
	//String cancelURL = PlugInUtil.getEditableContentReturnURL(ctx.getContent().getParentId(), ctx.getCourseId());  
	
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
	ComparatorSortByMinutesPerPoint cmSortByMinutesPerPoint = new ComparatorSortByMinutesPerPoint(minutesPerPointHash);
%>

<%
	//Get a User instance via the page context
	logDebug("User sessionUser = ctx.getUser();");
	User sessionUser = ctx.getUser();
    //Get the User's Name and Id
    String sessionUserName = sessionUser.getUserName();
    Id sessionUserId = sessionUser.getId();
    String sessionUserBatchID = sessionUser.getBatchUid();
    User.SystemRole sessionUserSYSTEMRole = sessionUser.getSystemRole();
    String sessionUserSystemRoleString = sessionUserSYSTEMRole.toString();

	//Retrieve the Db persistence manager from the persistence service
	BbPersistenceManager bbPm = BbServiceManager.getPersistenceService().getDbPersistenceManager();
	// Retrieve the course identifier from the URL
	String courseIdParameter = request.getParameter("course_id");
	// Generate a persistence framework course Id to be used for loading the course
	// Ids are persistence framework object identifiers.
	Id courseId = bbPm.generateId(Course.DATA_TYPE, courseIdParameter);
	
	logDebug("LineitemDbLoader liLoader = (LineitemDbLoader)bbPm.getLoader(LineitemDbLoader.TYPE);");
	LineitemDbLoader liLoader = (LineitemDbLoader)bbPm.getLoader(LineitemDbLoader.TYPE);
	logDebug("ArrayList liList = liLoader.loadByCourseId(courseId);");
	//LogServiceFactory.getInstance().logError("\n************In manage_vendors.jsp, vendorListObject is null");
	logDebug("ArrayList liList = liLoader.loadByCourseId(courseId);");
	ArrayList<Lineitem> liList = (ArrayList<Lineitem>)liLoader.loadByCourseId(courseId);
	ArrayList<Lineitem> liNullDDList = new ArrayList<Lineitem>();
	ArrayList<Lineitem> liNotNullDDList = new ArrayList<Lineitem>();
	ArrayList<Lineitem> liPhysicalList = new ArrayList<Lineitem>();

	java.util.Collections.sort(liList, cmSortByDueDate);
	logDebug("for (li_temp: liList) {");
	Lineitem li_prev = null;

	for (Lineitem li_temp: liList) {
		if  (!(li_temp.getType().equals("Weighted Total") || li_temp.getType().equals("Total") ) 
			&& !(li_temp.getType().equals("") && (li_temp.getName().equals("Weighted Total") || li_temp.getName().equals("Total") || li_temp.getName().equals("Running Weighted Total") || li_temp.getName().equals("Running Total"))) 
			)	{
			MinutesPerPoint mpp = new MinutesPerPoint(li_prev, li_temp);
			mpp.DueDateOrder = liPhysicalList.size(); 
			liPhysicalList.add(li_temp);			
			minutesPerPointHash.put(li_temp.getId().toExternalString(), mpp);
		}			
		li_prev = li_temp;
	}
	//out.print ("str_li_id == null");
	//response.flushBuffer();
	//response.resetBuffer ();
	//response.reset();
	 
	
	String formAction = request.getParameter("idlaGCDueDatesActionParam");
	if (formAction != null) {
		if (formAction.equals("save")) {
			logDebug("LineitemDbPersister liDbP = (LineitemDbPersister)bbPm.getPersister(LineitemDbPersister.TYPE);");
			//out.print("Save detected");
			LineitemDbPersister liDbP = (LineitemDbPersister)bbPm.getPersister(LineitemDbPersister.TYPE);
			int li_cnt = Integer.parseInt(request.getParameter("lineitemCountParam"));
			String str_row_status = ""; 
			logDebug("for (int i = 0; i < li_cnt; i++) {");  
			for (int i = 0; i < li_cnt; i++) {
				str_row_status = "";
				//out.print(liIdParamNameBase + i);
				//out.print("<br>");
				String str_li_id = request.getParameter(liIdParamNameBase + i);
				logDebug(liIdParamNameBase + i + ": " + str_li_id);
				logDebug("Lineitem.LINEITEM_DATA_TYPE: " + Lineitem.LINEITEM_DATA_TYPE);
				Id li_id = bbPm.generateId(Lineitem.LINEITEM_DATA_TYPE, str_li_id);
				//Id li_id = Id.generateId(Lineitem.LINEITEM_DATA_TYPE, str_li_id);
				logDebug("li_id: " + li_id.toString());
				Lineitem li = minutesPerPointHash.get(li_id.toExternalString()).liNext;
				String str_li_is_avail = request.getParameter(liIsAvailableParamNameBase + i);
				if (str_li_is_avail == null) str_li_is_avail = "";
				logDebug(liIsAvailableParamNameBase + i + ": " + str_li_is_avail);  
				if (str_li_is_avail.equals("on")) {
					if (!(li.getIsAvailable())) {
						logDebug("li.setIsAvailable(true);");					
						li.setIsAvailable(true);
						str_row_status = "Saved";
					} 
				} else if (li.getIsAvailable()) {
						logDebug("li.setIsAvailable(false);");				
						li.setIsAvailable(false);
						str_row_status = "Saved";
					} 
				String li_has_duedate = request.getParameter(liHasDueDateParamNameBase + i);
				if (li_has_duedate == null) li_has_duedate = ""; 
				logDebug(liHasDueDateParamNameBase + i + ": " + li_has_duedate);				
				if (li_has_duedate.equals("on")) {
					String str_li_duedate = request.getParameter(liDueDateParamNameBase + i + "_datetime");
					logDebug(liDueDateParamNameBase + i + ": " + str_li_duedate);
					Calendar due_date = DatePickerUtil.pickerDatetimeStrToCal(str_li_duedate);
					logDebug("due_date: " + due_date.toString());
					String str_is_common_duetime = request.getParameter("isCommonDueTimeParam");
					logDebug("isCommonDueTimeParam: " + str_is_common_duetime);
					if (str_is_common_duetime == null) str_is_common_duetime = "";
					if (str_is_common_duetime.equals("on")) {
						String str_common_duetime = request.getParameter("commonDueTimeParam_datetime");
						logDebug("commonDueTimeParam: " + str_common_duetime);
						Calendar common_duetime = DatePickerUtil.pickerDatetimeStrToCal(str_common_duetime);
						logDebug("common_duetime: " + common_duetime.toString());
						due_date.set(Calendar.MILLISECOND, common_duetime.get(Calendar.MILLISECOND));
						due_date.set(Calendar.SECOND, common_duetime.get(Calendar.SECOND));
						due_date.set(Calendar.MINUTE, common_duetime.get(Calendar.MINUTE));
						due_date.set(Calendar.HOUR_OF_DAY, common_duetime.get(Calendar.HOUR_OF_DAY));						
					}  
					if (li.getOutcomeDefinition().getDueDate() == null) {
						logDebug("li.getOutcomeDefinition().getDueDate() == null -> li.getOutcomeDefinition().setDueDate(due_date);");
						li.getOutcomeDefinition().setDueDate(due_date);
						str_row_status = "Saved";
					} else if (li.getOutcomeDefinition().getDueDate().compareTo(due_date) != 0) {
								logDebug("li.getOutcomeDefinition().getDueDate().compareTo(due_date) != 0 -> li.getOutcomeDefinition().setDueDate(due_date);");
								li.getOutcomeDefinition().setDueDate(due_date);
								str_row_status = "Saved";
							}
				} else if (li.getOutcomeDefinition().getDueDate() != null) {
							logDebug("li.getOutcomeDefinition().setDueDate(null);");
							li.getOutcomeDefinition().setDueDate(null);
							str_row_status = "Saved";
						}
				if (str_row_status.equals("Saved")) {
					logDebug("liDbP.persist(li);");				
					liDbP.persist(li);
				}
				minutesPerPointHash.get(li_id.toExternalString()).strRowStatus = str_row_status;
			} //for (int i = 0; i < li_cnt; i++) {
		    for (Iterator<MinutesPerPoint> it = minutesPerPointHash.values().iterator(); it.hasNext(); ) {
   				MinutesPerPoint mpp = it.next();
   				mpp.refresh();
			}
		}
	}
	String str_hist_go_count = request.getParameter("idlaGCDueDatesHistoryGoCountParam");
	int hist_go_count = -1;
	if (str_hist_go_count != null) hist_go_count = Integer.parseInt(str_hist_go_count) - 1;
	String js_hist_go_count = "history.go(" + hist_go_count + ");";
	logDebug("hist_go_count: " + hist_go_count);
	logDebug("js_hist_go_count: " + js_hist_go_count);
%>

<bbNG:form name="idlaGCDueDatesForm" method="post" action="gc_duedates.jsp" onsubmit="return onFormSubmit()">
<input type="hidden" name="course_id" id="course_id" value="<%= courseIdParameter%>"/>
<input type="hidden" name="course_id" id="course_id" value="<%= courseIdParameter%>"/>
<input type="hidden" name="idlaGCDueDatesActionParam" id="idlaGCDueDatesActionParam"/>
<input type="hidden" name="lineitemCountParam" value="<%= liPhysicalList.size()  %>"/>
<input type="hidden" name="idlaGCDueDatesHistoryGoCountParam" id="idlaGCDueDatesHistoryGoCountParam" value="<%= Integer.toString(hist_go_count) %>"/>

<bbNG:jsBlock> 
 <script language="javascript">  
	function onFormSubmit() {
		document.getElementById('idlaGCDueDatesActionParam').value = 'save';
		return true;
  	}
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
		String strDueDate = ""; 
		java.util.Calendar calDueDate = null;
		java.util.Calendar calDueDate1 = null;
		java.util.Calendar commonDueTime = null;
		//int iLineitemIndex = 3;
		String liIdParamName;			
		String liDueDateParamName;
		String liDueDateParamName2;			
		String liDueDateParamName1;
		String liHasDueDateParamName;
		String liIsAvailableParamName;
		
		
	%>
	
	<bbNG:step title="Time part of all due dates" instructions="Please specify if you would like to set time of all due dates to same value during submit">
		<%
		commonDueTime = java.util.Calendar.getInstance();
		commonDueTime.clear();
		commonDueTime.set(0, 0, 0, 23, 59, 59);
		%>
		<bbNG:dataElement>
			<label for="isCommonDueTimeParam">Use same time for all due dates?</label>		
        	<bbNG:checkboxElement name="isCommonDueTimeParam" id="isCommonDueTimeParam" value="true" isSelected="false" helpText="" title="" optionLabel="Time to use:"/>
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
			//calDueDate1 = li.getOutcomeDefinition().getDueDate(); 
			//if (calDueDate != null) strDueDate = calDueDate.toString();
			//else strDueDate = "";
			//logDebug("iLineitemIndex: " + iLineitemIndex);
			//logDebug("strDueDate: " + strDueDate);
			logDebug("Name: " + li.getName());
			int li_index = minutesPerPointHash.get(li.getId().toExternalString()).DueDateOrder;
			logDebug("li_index: " + li_index);  
			liIdParamName = liIdParamNameBase + li_index; //iLineitemIndex;			
			liDueDateParamName = liDueDateParamNameBase + li_index; //li.getColumnOrder();
			logDebug("liDueDateParamName : " + liDueDateParamName + " liDueDateParamName.length(): " + liDueDateParamName.length());
			//String liDueDateParamName1 = "asads_" + iLineitemIndex;
			//String liDueDateParamName1 = "asads_" + li.getColumnOrder();
			//liDueDateParamName2 = "asads_" + li.getColumnOrder();			
			//liDueDateParamName1 = "asads_" + String.valueOf(iLineitemIndex);
			//assert(liDueDateParamName2.equals(liDueDateParamName1));
			//assert(3 ==4);
			//logDebug("liDueDateParamName1 : " + liDueDateParamName1 + " liDueDateParamName1.length(): " + liDueDateParamName1.length());			
			//logDebug("liDueDateParamName2 : " + liDueDateParamName2 + " liDueDateParamName2.length(): " + liDueDateParamName2.length());
			
			//if (!liDueDateParamName2.equals(liDueDateParamName1)) throw new Exception("sdfsdfsdf");
			
			liHasDueDateParamName = liHasDueDateParamNameBase + li_index; //iLineitemIndex;
			liIsAvailableParamName =  liIsAvailableParamNameBase + li_index; //iLineitemIndex;
			//iLineitemIndex = ++iLineitemIndex; 
		%>		

		<bbNG:listElement name="BlankPrefixedColumn" label="Status">
			<%= minutesPerPointHash.get(li.getId().toExternalString()).strRowStatus %>
		</bbNG:listElement>
		

		<bbNG:listElement
			comparator="<%=cmSortByColumnOrder%>" 
			label="Column" 
			name="ColumnOrder" >
    	    	<%= li.getColumnOrder() %>
				<input type="hidden" name="<%= liIdParamName %>" id="<%= liIdParamName %>" value="<%= li.getId().toExternalString()%>"/>
    	</bbNG:listElement>
    	<bbNG:listElement 
			comparator="<%=cmSortByName%>"    	
			label="Name" 
			name="Name" 
			isRowHeader="true" >
    	    	<%= li.getName() %>
    	</bbNG:listElement>
		<bbNG:listElement 
			comparator="<%=cmSortByType%>"
			label="Type" 
			name="Type" >
			<%= li.getType()  %>
		</bbNG:listElement>
		<bbNG:listElement 
			comparator="<%=cmSortByIsAvailable%>"
			label="Is Available?" 
			name="isAvailable" >
			<input name="<%= liIsAvailableParamName%>" type="checkbox"  
			<% if (li.getIsAvailable()) out.print ("checked"); %> >
		</bbNG:listElement>
		<bbNG:listElement 
			comparator="<%=cmSortByHasDueDate%>"
			label="Has DueDate?" 
			name="hasDueDate" >
			<input name="<%= liHasDueDateParamName%>" type="checkbox"  
			<% if (li.getOutcomeDefinition().getDueDate() != null) out.print ("checked"); %> >
		</bbNG:listElement>
		<bbNG:listElement 
			comparator="<%=cmSortByDueDate%>"		
			label="Due Date" 
			name="DueDate" >
			<bbNG:dataElement>
				<bbNG:datePicker
					baseFieldName = "<%= liDueDateParamName %>" 
					dateTimeValue="<%= calDueDate %>"
					showTime="true"
				/>
			</bbNG:dataElement>
		</bbNG:listElement>
		<bbNG:listElement 
			comparator="<%=cmSortByMinutesPerPoint%>"
			label="Minutes per Point" 
			name="minutesPerPoint" >
			<%= minutesPerPointHash.get(li.getId().toExternalString()).toString()%>
		</bbNG:listElement>
	</bbNG:inventoryList>	
	</bbNG:step> 
	<!-- cancelUrl="gc_duedates.jsp" -->
	<!--  Cancel will bring us out of the form (back), only submit (and refresh?) will refresh it here - actually temp solution, has to be implemented with javascript-->
  <bbNG:stepSubmit title="Submit"  instructions="Click Submit to save and reload. Click Cancel to dismiss changes and go back." cancelOnClick="<%= js_hist_go_count %>">
  </bbNG:stepSubmit>
	
</bbNG:dataCollection> 
</bbNG:form>
		
	
</bbNG:learningSystemPage >

<!--  navItem="${navigationItem}" 
hideCourseMenu="<%=true%>"

<fmt:message var="strLpageTitle" key="dashboard.label" bundle="${bundles.avlrule}"/>
-->


<% 
Enumeration keys = request.getParameterNames();
	while (keys.hasMoreElements() )	{
	String key = (String)keys.nextElement();
	out.print (key);
      //To retrieve a single value
	
	// If the same key has multiple values (check boxes)
	String[] valueArray = request.getParameterValues(key);
	if (Array.getLength(valueArray) > 1) {
		for (int i = 0; i < Array.getLength(valueArray); i++) {
			out.print (key + "[" + i + "]:" + valueArray[i]);
			out.print ("<br>");
		}
	} else {
	    String value = request.getParameter(key);
    	out.print (": " + value);
		out.print ("<br>");    	
	}
   }   
%>
