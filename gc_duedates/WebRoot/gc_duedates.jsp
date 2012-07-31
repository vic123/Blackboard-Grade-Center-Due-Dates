<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
   "http://www.w3.org/TR/html4/loose.dtd">

<%--
    Document   : gc_duedates
    Created on : Jun 13, 2009, 4:51:29 PM
    Author     : vic

Error reported at the top of file is because of:
http://netbeans.org/bugzilla/show_bug.cgi?id=172334
Bug 172334 - is already defined in SimplifiedJSPServlet error

Missing of <!DOCTYPE... tag causes bad rendering of inventoryList in IE -
page goes to the right exceeding browser area
(adding horizontal browser scroll bar),
inventoryList is created without vertical scroll bar
--%>


<%@ page 
		contentType="text/html"
		language="java" 
		import="java.util.*,
				java.lang.reflect.Array,
				java.util.Calendar,
				java.io.StringWriter,
				java.io.PrintWriter,
                                blackboard.platform.gradebook2.GradableItem,
                                blackboard.data.user.User,
				blackboard.data.ReceiptOptions,
				blackboard.data.ReceiptMessage,
				blackboard.platform.plugin.PlugInUtil,
                                blackboard.platform.log.LogService,
                                blackboard.persist.Id,
                                blackboard.servlet.tags.InlineReceiptTag,
                                blackboard.platform.gradebook2.GradebookType,
                                blackboard.platform.gradebook2.impl.GradebookTypeDAO,
                                idla.gc_duedates.GCDDLog,
                                idla.gc_duedates.GCDDException,
                                idla.gc_duedates.LineitemHelperHashBean,
                                idla.gc_duedates.GCDDRequestScopeBean,
                                idla.gc_duedates.GradingPeriodHelper,
                                idla.gc_duedates.SettingsBean,
                                idla.gc_duedates.GCDDUtil,
                                idla.gc_duedates.LineitemHelper
                                "
		errorPage="error.jsp"
		pageEncoding="UTF-8" 
		session="true"
%>

 
<%@ taglib uri="/bbUI" prefix="bbUI"%>
<%@ taglib uri="/bbData" prefix="bbData"%>
<%@ taglib uri="/bbNG" prefix="bbNG"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core"    prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt"     prefix="fmt"%>

<!-- gc_duedates.jsp
-->

<%!
//1) Servlet declaration section: 
//Global data members

	String strLogMessages;
	String strSaveWarnings;

	//variables declared as class members for availability from inside inner classes and code blocks
	String PAGE_TITLE;
	String ICON_URL;

	Comparator<GradableItem> cmSortByColumnOrder;
        Comparator<GradableItem> cmSortByGradingPeriod;
        Comparator<GradableItem> cmSortByName;
        Comparator<GradableItem> cmSortByType;
        Comparator<GradableItem> cmSortByIsAvailable;
        Comparator<GradableItem> cmSortByHasDueDate;
	Comparator<GradableItem> cmSortByDueDate;
	LineitemHelper.ComparatorSortByMinutesPerPoint cmSortByMinutesPerPoint;
    //requered for cmSortByGradingPeriod comparator which is inner class and wants requestScope to have final modifier
        GCDDRequestScopeBean requestScopeCopy;

//end of servlet declaration section
//Below are several objects injected as beans
%>


<jsp:useBean id="requestScope" scope="request" class="idla.gc_duedates.GCDDRequestScopeBean"/>
<jsp:useBean id="settings" scope="request" class="idla.gc_duedates.SettingsBean"/>
<jsp:useBean id="lineitemHelperHash" scope="request" class="idla.gc_duedates.LineitemHelperHashBean"/>


<%
//Pre-visualization (response generation) processing:
//a)Logs form parameters on INFORMATION level
//b)Initializes requestScope bean
//c)Setups URL links, declares inline Comparator classes for bbNG:listElement tags.
//d)Authorises user by role of INSTRUCTOR, TEACHING_ASSISTANT or COURSE_BUILDER
//e)Obtains currently persisted GradableItems for a course
//f)In case of "save" (submit) action, creates ancestors of LineitemField from form parameters and
//    using LineitemHelper interface compares posted data with currently saved one.
//    Saves anything necessary and redirects response to itself.
   
try {
    //seem not used currently
    strLogMessages = "";
    //save warning messages displayed in bbNG:receipt are collected in strSaveWarnings
    strSaveWarnings = "";

    //Logging of request and form paramters
    GCDDUtil.logRequestParamters(session, request);

    requestScope.init(session, request, response, settings);
    requestScopeCopy = requestScope;

    PAGE_TITLE = "Grade Center Due Dates - individual due dates (all assignments listed)";
    //special Blackboard API funttion for constructing of path the resourse located in plugin's WebRoot dir
    ICON_URL = PlugInUtil.getUri("IDLA", "gradecenter_duedates", "DueDates.jpg");

    //create comparators for each column of the list (attribute of LineItem)

    //cmSortByColumnOrder is not used currently
    cmSortByColumnOrder = new Comparator<GradableItem>() {
        public int compare(GradableItem li1, GradableItem li2) {
            return li1.getPosition() - li2.getPosition();
        }
    };

    cmSortByGradingPeriod = new Comparator<GradableItem>() {
        public int compare(GradableItem li1, GradableItem li2) {
            String s1 = GradingPeriodHelper.getGradingPeriodTitle(li1, requestScopeCopy);
            String s2 = GradingPeriodHelper.getGradingPeriodTitle(li2, requestScopeCopy);
            int compare = GCDDUtil.nullSafeStringComparator(s1, s2);
            if (compare == 0) return cmSortByName.compare(li1, li2);
            return compare;
        }
    };


    cmSortByName = new Comparator<GradableItem>() {
        public int compare(GradableItem li1, GradableItem li2) {
            String s1 = (String)li1.getTitle();
            String s2 = (String)li2.getTitle();
            int compare = GCDDUtil.nullSafeStringComparator(s1, s2);
            return compare;
        }
    };


    cmSortByType = new Comparator<GradableItem>() {
        public int compare(GradableItem li1, GradableItem li2) {
            String s1 = null;
            String s2 = null;
            try {
            GradebookType gradeBookType = 
                    (GradebookType)GradebookTypeDAO.get().loadById(li1.getCategoryId());
            s1 = gradeBookType.getTitle();
            } catch (blackboard.persist.KeyNotFoundException knfe) {}
            try {
            GradebookType gradeBookType =
                    (GradebookType)GradebookTypeDAO.get().loadById(li2.getCategoryId());
            s2 = gradeBookType.getTitle();
            } catch (blackboard.persist.KeyNotFoundException knfe) {}
            //String s1 = (String)li1.getCategory();
            //String s2 = (String)li2.getCategory();
            int compare = GCDDUtil.nullSafeStringComparator(s1, s2);
            return compare;
        }
    };
    
    cmSortByIsAvailable = new Comparator<GradableItem>() {
        public int compare(GradableItem li1, GradableItem li2) {
            boolean is_av1 = li1.isVisibleToStudents();
            boolean is_av2 = li2.isVisibleToStudents();
            return Boolean.valueOf(is_av1).compareTo(is_av2);
        }
    };

    //cmSortByHasDueDate is not used currently
    cmSortByHasDueDate = new Comparator<GradableItem>() {
        public int compare(GradableItem li1, GradableItem li2) {
            boolean has_dd1 = (li1.getDueDate() != null);
            boolean has_dd2 = (li2.getDueDate() != null);
            return Boolean.valueOf(has_dd1).compareTo(has_dd2);
        }
    };
    
    cmSortByDueDate = new Comparator<GradableItem>() {
        public int compare(GradableItem li1, GradableItem li2) {
            Calendar cal1, cal2;
            cal1 = li1.getDueDate();
            cal2 = li2.getDueDate();
            if (cal1 != null && cal2 != null) return cal1.compareTo(cal2);
            else {
                if (cal1 == null && cal2 == null) return 0;
                if (cal1 == null) return -1;
                if (cal2 == null) return 1;
            }
            throw new AssertionError("cmSortByDueDate - reached unexpected flow of control point.");
        }
    };
    //cmSortByMinutesPerPoint is not used currently
    cmSortByMinutesPerPoint = new LineitemHelper.ComparatorSortByMinutesPerPoint(lineitemHelperHash.hashMap);

    //authentication
    if (!PlugInUtil.ensureAuthenticatedUser(request, response)) return;
    User.SystemRole sessionUserSystemRole = requestScope.getSessionUser().getSystemRole();
    GCDDLog.logForward(LogService.Verbosity.INFORMATION, "sessionUser.getUserName(): " + requestScope.getSessionUser().getUserName()
    		+ "; sessionUserSystemRole.getDisplayName(): " + sessionUserSystemRole.getDisplayName(), this);
    //check user role permission
    if (sessionUserSystemRole != User.SystemRole.SYSTEM_ADMIN) {
        if (!GCDDUtil.checkCourseMembershipRole(requestScope)) return;
    }

    lineitemHelperHash.loadLineitemsByCourseId(requestScope);
    GCDDLog.logForward(LogService.Verbosity.DEBUG, "lineitemHelperHash.liPhysicalList.size(): " + lineitemHelperHash.liPhysicalList.size(), this);
    String formAction = request.getParameter("idlaGCDueDatesActionParam");
    GCDDLog.logForward(LogService.Verbosity.DEBUG, "request.getParameter(\"idlaGCDueDatesActionParam\"): " + formAction, this);
    if (formAction == null) formAction = "";
	if (formAction.equals("save")) {
            //save modified data, set any success/warning session status and refresh page
            GCDDLog.logForward(LogService.Verbosity.INFORMATION, "Entering if (formAction.equals(\"save\")) {", this);
            int li_cnt = Integer.parseInt(request.getParameter("lineitemCountParam"));
            GCDDLog.logForward(LogService.Verbosity.DEBUG, "for (int i = 0; i < li_cnt; i++) {", this);
            LineitemHelper lih = null;
            String li_id_str = "not set";
            String li_name_str = "not set";
            for (int i = 0; i < li_cnt; i++) {
                try {
                        lih = null;
                        li_id_str = request.getParameter(LineitemHelper.liIdParamNameBase + i);
                        GCDDLog.logForward(LogService.Verbosity.DEBUG, "li_id_str: " + li_id_str, this);
                        Id li_id = requestScope.getPersistenceManager().generateId(GradableItem.DATA_TYPE, li_id_str);
                        GCDDLog.logForward(LogService.Verbosity.DEBUG, "li_id: " + li_id.toString(), this);
                        li_name_str = request.getParameter(LineitemHelper.liNameParamNameBase + i);
                        GCDDLog.logForward(LogService.Verbosity.DEBUG, "li_name_str: " + li_name_str, this);
                        lih = lineitemHelperHash.hashMap.get(li_id.toExternalString());
                        if (lih == null) {
                                strSaveWarnings = strSaveWarnings + "<br> <br> Column Name: " + li_name_str
                                        + "; ID: " + li_id_str + "; Column is missing (could be deleted by another user) on server and was not saved." + "<br>";
                                continue;
                        }
                        lih.paramIndex = i;
                        LineitemHelper.LineItemField lif = lih.new LineItemIsAvailableField(LineitemHelper.liIsAvailableParamNameBase + i, requestScope);
                        lih.fieldsList = new ArrayList<LineitemHelper.LineItemField>();
                        lih.fieldsList.add(lif);
			//"_datetime" is not correctly updated by javascript when date is entered by hand
                        lif = lih.new LineItemDueDateField(LineitemHelper.liDueDateParamNameBase + i, requestScope);
                        lih.fieldsList.add(lif);
                        for (LineitemHelper.LineItemField lif_temp: lih.fieldsList) {
                                lif_temp.checkAndSet();
                        }
                        if (lih.needsSave()) {
                                GCDDLog.logForward(LogService.Verbosity.DEBUG, "liDbP.persist(li);", this);
                                GradableItem lineitem_old = requestScope.getGradebookManager().getGradebookItem(lih.lineitem.getId());
                                requestScope.getGradebookManager().persistGradebookItem(lih.lineitem);
                                requestScope.getGradebookManager().handlesNotification(lih.lineitem, false, lineitem_old);
                                lih.strRowStatus = "Saved";
                        }
                } catch (Throwable t) {
                        GCDDLog.logForward(LogService.Verbosity.WARNING, t, "", this);
                        if (lih != null) lih.strRowStatus = "Error";
                        strSaveWarnings = strSaveWarnings + "<br> <br> Column Name: " + li_name_str
                                + ", ID: " + li_id_str + "; Error occurred upon saving of column, error message: " + GCDDUtil.constructExceptionMessage(t) ;

                }
            }

            GCDDLog.logForward(LogService.Verbosity.INFORMATION, "strSaveWarnings = " + strSaveWarnings, this);

            ReceiptOptions	ro = new ReceiptOptions();
            ReceiptMessage rm;
            if (strSaveWarnings.length() != 0) {
                    rm = new ReceiptMessage("WARNING - Not all modifications were saved, some error(s) occurred:"
                                                                    + strSaveWarnings,
                                                            ReceiptMessage.messageTypeEnum.WARNING);
            } else rm = new ReceiptMessage("Changes Saved", ReceiptMessage.messageTypeEnum.SUCCESS);
            ro.addMessage(rm);
            request.getSession().setAttribute(InlineReceiptTag.RECEIPT_KEY, ro);
            //logForward(LogService.Verbosity.DEBUG, "response.sendRedirect" + formURL + "&uuid=" + sessionTag.randomUUID);
            // Retrieve the course identifier from the URL and construct formURL for response.sendRedirect(formURL) to itself
            String formURL = request.getRequestURL().toString() + "?course_id="
                    + requestScope.getCourseId().toExternalString();
            if ("on".equals(requestScope.getRequest().getParameter("isCommonDueTimeParam"))) {
              formURL = formURL + "&isCommonDueTimeParam=on";
            }
            String str_com_dt = requestScope.getRequest().getParameter("commonDueTimeParam_time");
            if (!GCDDUtil.isStringBlank(str_com_dt)) {
                formURL = formURL + "&isCommonDueTimeParam=" + str_com_dt;
            }
            //when commonDueTime datetime picker is not enabled, it passes only commonDueTimeParam_datetime parameter
            //, omitting commonDueTimeParam_time one.
            //datetime format is different from date+time formats concatenation
            //, things become too complex for nothing
            //Disabled commonDueTime does not preserve its value
            formURL = response.encodeRedirectURL(formURL);
            GCDDLog.logForward(LogService.Verbosity.DEBUG, "response.sendRedirect(), formURL: " + formURL, this);
            response.sendRedirect(formURL);
            return;
	} //if (formAction.equals("save") ) {
%>

<%
//try block is split here because of java.lang.IllegalStateException upon response.sendRedirect happening after docTemplate tags.
//While JSP block cannot overlap with bbUI tag
     
} catch (Throwable t) {
	GCDDLog.logForward(LogService.Verbosity.ERROR, t, "", this);
	throw new GCDDException (strLogMessages, t);
}

//3)Construction of response       
%>
<bbNG:learningSystemPage>
<%@ include file="/WEB-INF/js/gc_duedates.js" %>
<bbNG:form name="idlaGCDueDatesForm" method="post" action="gc_duedates.jsp" onsubmit="onPostAction(); return true;">

	<input type="hidden" name="course_id" id="course_id" value="<%= requestScope.getCourseId().toExternalString()%>"/>
	<input type="hidden" name="idlaGCDueDatesActionParam" id="idlaGCDueDatesActionParam" value="save"/> 
	<input type="hidden" name="lineitemCountParam" value="<%= lineitemHelperHash.liPhysicalList.size()  %>"/>
	
	<bbNG:dataCollection markUnsavedChanges="true">
	<%
	try {      
	%>
	
    <bbNG:breadcrumbBar environment="CTRL_PANEL">
    	<bbNG:breadcrumb><%= PAGE_TITLE%></bbNG:breadcrumb>
    </bbNG:breadcrumbBar>
    <bbNG:receipt />    
	<bbNG:pageHeader>
	    <bbNG:pageTitleBar iconUrl="<%=ICON_URL%>">
   	    <%= PAGE_TITLE %>
    	</bbNG:pageTitleBar>
    </bbNG:pageHeader>
    <%--
    <bbUI:caretList>
      <bbUI:caret title="Edit Due Dates By Grading Period"
                  href="gc_period_duedates.jsp?course_id=<%= requestScope.getCourseId().toExternalString()%>">
      </bbUI:caret>
    </bbUI:caretList>
    <%--@ include file="/WEB-INF/js/gc_duedates_beforeunload.js" --%>
	<%  
		java.util.Calendar calDueDate = null;
                boolean isCommonDueTime = false;
		java.util.Calendar commonDueTime = null;
		String liIdParamName;			
		String liDueDateParamName;
		String liHasDueDateParamName;
		String liIsAvailableParamName;
		String liNameParamName;
		boolean isDueDateFirstPass = true;
                String modifyColumnURLBase = "/webapps/gradebook/do/instructor/addModifyItemDefinition?actionType=modify&course_id=" + requestScope.getCourseId().toExternalString();
                String modifyColumnURL = null;
                String contentEditUrl = null;
                String colCategoryName = null;
                String colDescription = null;
                //String editPeriodDueDatesURL = "<a href='gc_period_duedates.jsp?course_id=" + requestScope.getCourseId().toExternalString() + "'>Edit Due Dates by Grading Period</a>";
                String editPeriodDueDatesURL = "<INPUT TYPE=\"BUTTON\" VALUE=\"Edit Due Dates by Grading Period\" ONCLICK=\"window.location.href='gc_period_duedates.jsp?course_id=" 
                            + requestScope.getCourseId().toExternalString() + "'\">";
                //<INPUT TYPE="BUTTON" VALUE="Home Page" ONCLICK="window.location.href='http://www.computerhope.com'">
                try {
                    blackboard.data.navigation.CourseToc courseToc
                            = blackboard.persist.navigation.CourseTocDbLoader.Default.getInstance().loadByCourseIdAndLabel(requestScope.getCourseId(), "COURSE_DEFAULT.Content.CONTENT_LINK.label");
                    GCDDLog.logForward(LogService.Verbosity.DEBUG, "courseToc.getContentId(): " + courseToc.getContentId().toExternalString(), this);
                    contentEditUrl = blackboard.platform.plugin.PlugInUtil.getEditableContentReturnURL(courseToc.getContentId().toExternalString(), requestScope.getCourseId().toExternalString());
                } catch (blackboard.persist.KeyNotFoundException knfe) { //!!
                    //contentEditUrl = "content area is probably deleted, don't know where to link ";
                    contentEditUrl = "";
                    GCDDLog.logForward(LogService.Verbosity.DEBUG, contentEditUrl, this);
                }
                String modifyPeriodURLBase = "/webapps/gradebook/do/instructor/addModifyPeriods?course_id="
                        + requestScope.getCourseId().toExternalString()
                        + "&actionType=modify&id="; //?? PkId{key=";
                String modifyPeriodURL = null;

	%>
        <bbNG:step hideNumber="true" title="<%= editPeriodDueDatesURL%>">
        </bbNG:step>

        <c:if test="<%=settings.isShowDueTime()%>">
            <bbNG:step title="Time part of all due dates" instructions="Please specify if you would like to set time of all due dates to same value during submit">
                <% 
                    isCommonDueTime = false;
                    String str_is_com_dt = request.getParameter("isCommonDueTimeParam");
                    if ("on".equals(str_is_com_dt)) isCommonDueTime = true;

                    GCDDLog.logForward(LogService.Verbosity.DEBUG, "str_is_com_dt: " + str_is_com_dt
                        + "; isCommonDueTime: " + isCommonDueTime, this);

                    commonDueTime = java.util.Calendar.getInstance();
                    commonDueTime.setTimeInMillis(settings.getCommonDueTime().getTimeInMillis());
                    String str_com_dt = request.getParameter("commonDueTimeParam" + "_time");
                    if (!GCDDUtil.isStringBlank(str_com_dt)) {
                        try {
                            str_com_dt = GCDDUtil.fixTimeString(str_com_dt);
                            commonDueTime = GCDDUtil.dateStringToCalendar(str_com_dt,
                                    settings.getTimeFormat());
                        } catch (Exception e) {
                            GCDDLog.logForward(LogService.Verbosity.DEBUG, e, "GCDDUtil.dateStringToCalendar(str_com_dt,...", this);
                        }
                    }
                    GCDDLog.logForward(LogService.Verbosity.DEBUG, "str_com_dt: " + str_com_dt
                        + "; commonDueTime: " + commonDueTime, this);
                %>
                <bbNG:dataElement>
                        <label for="isCommonDueTimeParam">Use same time for all due dates?</label>
                <bbNG:checkboxElement name="isCommonDueTimeParam" id="isCommonDueTimeParam" value="on" isSelected="<%= isCommonDueTime %>" helpText="" title="" optionLabel="Time to use:" OnClick="enableCommonDueTimeBox(this)"/>
                <bbNG:datePicker baseFieldName="commonDueTimeParam" dateTimeValue="<%= commonDueTime %>"  showDate="false" showTime="true" midnightWarning="??midnight warning??" suppressInstructions="true" displayOnly="<%= !isCommonDueTime%>"/>
                </bbNG:dataElement>
            </bbNG:step>
        </c:if >
	<bbNG:step hideNumber="true" title="Edit Individual Due Dates">
            <bbNG:inventoryList className="GradableItem"
                                collection="<%=lineitemHelperHash.liPhysicalList %>"
                                showAll="true"
                                objectVar="li"
                                initialSortCol="GradingPeriod"
                                >
                        <%
                            GCDDLog.logForward(LogService.Verbosity.DEBUG, "li.getId(): " + li.getId(), this);
                            calDueDate = li.getDueDate();
                            int li_index = lineitemHelperHash.hashMap.get(li.getId().toExternalString()).DueDateOrder;
                            GCDDLog.logForward(LogService.Verbosity.DEBUG, "li_index: " + li_index, this);
                            liIdParamName = LineitemHelper.liIdParamNameBase + li_index;
                            liDueDateParamName = LineitemHelper.liDueDateParamNameBase + li_index;
                            GCDDLog.logForward(LogService.Verbosity.DEBUG, "liDueDateParamName : " + liDueDateParamName + " liDueDateParamName.length(): " + liDueDateParamName.length(), this);
                            liHasDueDateParamName = LineitemHelper.liHasDueDateParamNameBase + li_index;
                            liIsAvailableParamName =  LineitemHelper.liIsAvailableParamNameBase + li_index;
                            liNameParamName = LineitemHelper.liNameParamNameBase + li_index;
                            modifyColumnURL = modifyColumnURLBase + "&id=" + li.getId().toExternalString();
                            blackboard.base.FormattedText ft = li.getDescriptionForDisplay();
                            GCDDLog.logForward(LogService.Verbosity.DEBUG, "ft.getText(): " + ft.getText());
                            colDescription = blackboard.util.TextFormat.stripTags(ft.getText());
                            GCDDLog.logForward(LogService.Verbosity.DEBUG, "colDescription: " + colDescription);
                            colCategoryName = "";
                            if (li.getCategoryId() != null) {
                                try {
                                    GradebookType gradeBookType =
                                            (GradebookType)GradebookTypeDAO.get().loadById(li.getCategoryId());
                                    colCategoryName = gradeBookType.getTitle();
                                    if (colCategoryName == null) colCategoryName = "";
                                    GCDDLog.logForward(LogService.Verbosity.DEBUG, "colCategoryName: " + colCategoryName, this);
                                    GCDDLog.logForward(LogService.Verbosity.DEBUG, "colCategoryName.length(): " + colCategoryName.length(), this);
                                    if (colCategoryName.endsWith(".name")) colCategoryName = colCategoryName.substring(0, colCategoryName.length() - 5);
                                    //if (contentEditUrl.length() != 0) colCategoryName = "<a href='" + contentEditUrl + "'>" + colCategoryName + "</a>";
                                } catch (blackboard.persist.KeyNotFoundException knfe) {}
                            }
                            modifyPeriodURL = "";
                            if (li.getGradingPeriodId() != null) {
                                modifyPeriodURL = modifyPeriodURLBase + li.getGradingPeriodId().toExternalString();
                            }
                        %>
                        <c:if test="<%=settings.isShowOrderColumn()%>">
                            <bbNG:listElement
                                    comparator="<%=cmSortByColumnOrder%>"
                                    label="Column"
                                    name="ColumnOrder" >
                                    <%= li.getPosition() %>
                                    <% GCDDLog.logForward(LogService.Verbosity.DEBUG, "Column - li_index: " + li_index, this); %>
                            </bbNG:listElement>
                        </c:if >

                        <bbNG:listElement
                                comparator="<%=cmSortByGradingPeriod%>"
                                label="Grading Period"
                                name="GradingPeriod"
                                isRowHeader="false" >
                            <c:if test="<%=(modifyPeriodURL.length() == 0)%>">
                                <%= GradingPeriodHelper.getGradingPeriodTitle(li, requestScope) %>
                            </c:if >
                            <c:if test="<%=(modifyPeriodURL.length() != 0)%>">
                            <a href="<%= modifyPeriodURL %>"><%= GradingPeriodHelper.getGradingPeriodTitle(li, requestScope) %></a>
                            </c:if >
                            <input type="hidden" name="<%= liIdParamName %>" id="<%= liIdParamName %>" value="<%= li.getId().toExternalString()%>"/>
                            <input type="hidden" name="<%= liNameParamName %>" id="<%= liNameParamName %>" value="<%= li.getTitle()%>"/>
                            <% GCDDLog.logForward(LogService.Verbosity.DEBUG, "GradingPeriodHelper.getGradingPeriodTitle(): " + GradingPeriodHelper.getGradingPeriodTitle(li, requestScope));
                            %>
                        </bbNG:listElement>

                        <bbNG:listElement
                                comparator="<%=cmSortByName%>"
                                label="Name"
                                name="Name"
                                isRowHeader="true" >
                            <a href="<%= modifyColumnURL %>" title="<%=colDescription%>">  <%= li.getTitle() %> </a>
                            <% GCDDLog.logForward(LogService.Verbosity.DEBUG, "Name - li_index: " + li_index);
                               GCDDLog.logForward(LogService.Verbosity.DEBUG, "li.getDescription(): " + li.getDescription());
                               GCDDLog.logForward(LogService.Verbosity.DEBUG, "li.getDescriptionForDisplay(): " + li.getDescriptionForDisplay());
                            %>
                        </bbNG:listElement>
                        <bbNG:listElement
                                comparator="<%=cmSortByType%>"
                                label="Category"
                                name="Category" >
                                <c:if test="<%=(contentEditUrl.length() == 0)%>">
                                    <%= colCategoryName %>
                                </c:if >
                                <c:if test="<%=(contentEditUrl.length() != 0)%>">
                                <a href="<%= contentEditUrl %>"><%= colCategoryName %></a>
                                </c:if >
                                <% GCDDLog.logForward(LogService.Verbosity.DEBUG, "Category - li_index: " + li_index, this); %>
                        </bbNG:listElement>
                        <bbNG:listElement
                                comparator="<%=cmSortByIsAvailable%>"
                                label="Is Available?"
                                name="isAvailable" >
                                <bbNG:dataElement label=" " >
                                <input name="<%= liIsAvailableParamName%>" type="checkbox" label=""
                                <% if (li.isVisibleToStudents()) out.print ("checked"); %> >
                                </bbNG:dataElement>
                                <% GCDDLog.logForward(LogService.Verbosity.DEBUG, "Is Available - li_index: " + li_index, this); %>
                        </bbNG:listElement>
                        <c:if test="<%=settings.isShowHasDueDateColumn()%>">
                            <bbNG:listElement
                                    comparator="<%=cmSortByHasDueDate%>"
                                    label="Has Due Date?"
                                    name="hasDueDate" >
                                    <bbNG:dataElement label=" " >
                                        <input name="<%= liHasDueDateParamName%>" id="<%= liHasDueDateParamName%>" type="checkbox"
                                        <% if (li.getDueDate() != null) out.print ("checked"); %> >
                                    </bbNG:dataElement>
                                    <% GCDDLog.logForward(LogService.Verbosity.DEBUG, "Has Due Date - li_index: " + li_index); %>
                            </bbNG:listElement>
                        </c:if >

                        <bbNG:listElement
                            comparator="<%=cmSortByDueDate%>"
                            label="Due Date"
                            name="DueDate" >

                            <c:if test="<%=!isDueDateFirstPass%>">
                                            <% GCDDLog.logForward(LogService.Verbosity.DEBUG, "Inside DueDate <bbNG:dataElement>", this); %>
                                            <bbNG:dataElement label=" ">
                                            <bbNG:datePicker
                                                    baseFieldName = "<%=liDueDateParamName%>"
                                                    dateTimeValue="<%= calDueDate%>"
                                                    showTime="${settings.showDueTime}"
                                                    label=""
                                            />
                                            </bbNG:dataElement>
                            </c:if >
                            <% 	GCDDLog.logForward(LogService.Verbosity.DEBUG, "Due Date - li_index: " + li_index, this);
                                    GCDDLog.logForward(LogService.Verbosity.DEBUG, "lineitemHelperHash.get(li.getId().toExternalString()).isDueDateConstructed: " + lineitemHelperHash.hashMap.get(li.getId().toExternalString()).isDueDateConstructed, this);
                                    isDueDateFirstPass = false;
                            %>
                        </bbNG:listElement>

                    </bbNG:inventoryList>
                </bbNG:step>
	<!-- cancelUrl="gc_duedates.jsp" -->
	<!--  Cancel will bring us out of the form (back), only submit (and refresh?) will refresh it here - actually temp solution, has to be implemented with javascript-->
  <bbNG:stepSubmit title="Submit" hideNumber="true"
  	instructions="Click Submit to save and reload. Cancel acts as browser's back button."/> 
    Description of plugin processing is available <a href="http://projects.oscelot.org/gf/project/gc_duedates/wiki/?pagename=Grade+Center+Due+Dates+Building+Block+Description">here</a>.	
<%
} catch (Throwable t) {
	GCDDLog.logForward(LogService.Verbosity.ERROR, t, "", this);
	throw new GCDDException (strLogMessages, t);
}      

%>
</bbNG:dataCollection> 
</bbNG:form>
</bbNG:learningSystemPage>
 