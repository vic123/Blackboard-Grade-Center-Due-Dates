<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
   "http://www.w3.org/TR/html4/loose.dtd">

<%-- 
    Document   : gc_period_duedates
    Created on : Jul 21, 2011, 2:18:26 PM
    Author     : vic

Errors reported at the top of file and in <bbNG:learningSystemPage>
are because of: http://netbeans.org/bugzilla/show_bug.cgi?id=172334
Bug 172334 - is already defined in SimplifiedJSPServlet error
--%>
<%@page contentType="text/html"
        language="java"
        import="idla.gc_duedates.GCDDLog,
                idla.gc_duedates.GCDDUtil,
                idla.gc_duedates.GCDDConstants,
                idla.gc_duedates.GradingPeriodHelperHashBean,
                idla.gc_duedates.GradingPeriodHelper,
                idla.gc_duedates.LineitemHelper,
                idla.gc_duedates.GCDDException,
                blackboard.data.user.*,
                blackboard.data.ReceiptOptions,
                blackboard.data.ReceiptMessage,
                blackboard.servlet.tags.InlineReceiptTag,
                blackboard.platform.log.LogService,
                blackboard.platform.plugin.PlugInUtil,
                blackboard.platform.context.Context,
		blackboard.platform.context.ContextManagerFactory,
                blackboard.platform.gradebook2.GradingPeriod,
                blackboard.platform.gradebook2.GradableItem,
                blackboard.persist.Id,
                java.util.Comparator,
                java.util.ArrayList,
                java.util.List"
        errorPage="error.jsp"
        pageEncoding="UTF-8"
        session="true"
                %>

<%@ taglib uri="/bbUI" prefix="bbUI"%>
<%@ taglib uri="/bbData" prefix="bbData"%>
<%@ taglib uri="/bbNG" prefix="bbNG"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core"    prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt"     prefix="fmt"%>


<%!
    String strLogMessages;
    String strSaveWarnings;

    String PAGE_TITLE;
    String ICON_URL;
    Comparator<GradingPeriod> cmSortByTitle;
    //<jsp:useBean.../> creates local variable in _jspService() method of 
    //generated gc_005fperiod_005fduedates_jsp extends org.apache.jasper.runtime.HttpJspBase class.
    //But, for example, stepSubmitButton generation code is placed outside of _jspService()
    //and cannot see requestScope from there.
    //While variables declared in this block are created as class memebers and are visible from everywhere
    //_requestScope will be assigned value of requestScope
    idla.gc_duedates.GCDDRequestScopeBean _requestScope = null;

%>
<jsp:useBean id="requestScope" scope="request" class="idla.gc_duedates.GCDDRequestScopeBean"/>
<jsp:useBean id="settings" scope="request" class="idla.gc_duedates.SettingsBean"/>
<jsp:useBean id="gradingPeriodHelperHash" scope="request" class="idla.gc_duedates.GradingPeriodHelperHashBean"/>
<%
try {
    strLogMessages = "";
    strSaveWarnings = "";
    _requestScope = requestScope;

    GCDDUtil.logRequestParamters(session, request);

    requestScope.init(session, request, response, settings);
    //authentication
    if (!PlugInUtil.ensureAuthenticatedUser(request, response)) return;
    User.SystemRole sessionUserSystemRole = requestScope.getSessionUser().getSystemRole();
    GCDDLog.logForward(LogService.Verbosity.INFORMATION, "requestScope.getSessionUser().getUserName(): " + requestScope.getSessionUser().getUserName()
    		+ "; sessionUserSystemRole.getDisplayName(): " + sessionUserSystemRole.getDisplayName(), this);
    //check user role permission
    if (sessionUserSystemRole != User.SystemRole.SYSTEM_ADMIN) {
        if (!GCDDUtil.checkCourseMembershipRole(requestScope)) return;
    }

    PAGE_TITLE = "Grade Center Due Dates - set due dates by grading period";
    ICON_URL = PlugInUtil.getUri(GCDDConstants.VENDOR_ID, GCDDConstants.HANDLE, "DueDates.jpg");

    String formAction = request.getParameter("idlaGCPeriodDueDatesActionParam");
    GCDDLog.logForward(LogService.Verbosity.DEBUG, "request.getParameter(\"idlaGCPeriodDueDatesActionParam\"): " + formAction);
    if (formAction == null) formAction = "";

    cmSortByTitle = new Comparator<GradingPeriod>() {
      public int compare(GradingPeriod gp1, GradingPeriod gp2) {
        String s1 = gp1.getTitle();
        String s2 = gp2.getTitle();
        int compare = s1.toLowerCase().compareTo(s2.toLowerCase());
        return compare;
      }
    };
%>

<%
    gradingPeriodHelperHash.loadGradingPeriodsByCourseId(requestScope);

    if (formAction.equals("save")) {
        //save modified data, set any success/warning session status and refresh page
        GCDDLog.logForward(LogService.Verbosity.INFORMATION, "Entering if (formAction.equals(\"save\")) {", this );
        int gp_cnt = Integer.parseInt(request.getParameter("gradingPeriodCountParam"));
        GCDDLog.logForward(LogService.Verbosity.DEBUG, "for (int i = 0; i < gp_cnt; i++) {", this);
        GradingPeriodHelper gph = null;
        String gp_id_str = "not set";
        String gp_title_str = "not set";
        for (int i = 0; i < gp_cnt; i++) {
                try {
                        gph = null;
                        gp_id_str = request.getParameter(GradingPeriodHelper.ID_PARAM_NAME_BASE + i);
                        GCDDLog.logForward(LogService.Verbosity.DEBUG, "gp_id_str: " + gp_id_str, this);
                        Id gp_id = requestScope.getPersistenceManager().generateId(GradingPeriod.DATA_TYPE, gp_id_str);
                        GCDDLog.logForward(LogService.Verbosity.DEBUG, "gp_id: " + gp_id.toString(), this);
                        gp_title_str = request.getParameter(GradingPeriodHelper.TITLE_PARAM_NAME_BASE + i);
                        GCDDLog.logForward(LogService.Verbosity.DEBUG, "gp_title_str: " + gp_title_str, this);
                        String gp_duedate_str = request.getParameter(GradingPeriodHelper.DUEDATE_PARAM_NAME_BASE + i + "_date");
                        if (gp_duedate_str == null) gp_duedate_str = "";
                        if ("".equals(gp_duedate_str)) continue;
                        gph = gradingPeriodHelperHash.hashMap.get(gp_id.toExternalString());
                        if (gph == null) {
                                strSaveWarnings = strSaveWarnings + "<br> <br> Period Name: " + gp_title_str + "; ID: "
                                        + gp_id_str + "; Period is missing (could be deleted by another user) on server and was not saved." + "<br>";
                                continue;
                        }
                        gph.setOldId(gp_id);
                        gph.setOldTitle(gp_title_str);
                        for (Object obj: gph.getLineitemHelperHash().hashMap.values()) {
                            LineitemHelper lih = (LineitemHelper) obj;
                            lih.fieldsList = new ArrayList<LineitemHelper.LineItemField>();
							//"_datetime" is not correctly updated by javascript when date is entered by hand
                            LineitemHelper.LineItemField lif
                                    = lih.new LineItemDueDateFieldForPeriod(GradingPeriodHelper.DUEDATE_PARAM_NAME_BASE + i + "_date", requestScope);
                            lih.fieldsList.add(lif);
                            lif.checkAndSet();
                            if (lih.needsSave()) {
                                GCDDLog.logForward(LogService.Verbosity.DEBUG, "liDbP.persist(li);", this);
                                GradableItem lineitem_old = requestScope.getGradebookManager().getGradebookItem(lih.lineitem.getId());
                                requestScope.getGradebookManager().persistGradebookItem(lih.lineitem);
                                //requestScope.getLineitemDbPersister().persist(lih.lineitem);
                                GCDDLog.logForward(LogService.Verbosity.DEBUG, "lih.lineitem.getId(): " + lih.lineitem.getId(), this);
                                GCDDLog.logForward(LogService.Verbosity.DEBUG, "lineitem_old.getId(): " + lineitem_old.getId(), this);
                                GCDDLog.logForward(LogService.Verbosity.DEBUG, "lih.lineitem.getDueDate(): " + lih.lineitem.getDueDate(), this);
                                GCDDLog.logForward(LogService.Verbosity.DEBUG, "lineitem_old.getDueDate(): " + lineitem_old.getDueDate(), this);
                                GCDDLog.logForward(LogService.Verbosity.DEBUG, "lih.lineitem.getId().getIsSet(): " + lih.lineitem.getId().getIsSet(), this);
                                GCDDLog.logForward(LogService.Verbosity.DEBUG, "lineitem_old.getId().getIsSet(): " + lineitem_old.getId().getIsSet(), this);
                                requestScope.getGradebookManager().handlesNotification(lih.lineitem, false, lineitem_old);
                                lih.strRowStatus = "Saved";
                            }
                        }
                } catch (Throwable t) {
                        GCDDLog.logForward(LogService.Verbosity.WARNING, t, "", this);
                        if (gph != null) gph.strRowStatus = "Error";
                        strSaveWarnings = strSaveWarnings + "<br> <br> Period Name: " + gp_title_str
                                        + ", ID: " + gp_id_str + "; Error occurred upon saving of period grade items, error message: " + GCDDUtil.constructExceptionMessage(t);
                }
        }

        GCDDLog.logForward(LogService.Verbosity.DEBUG, "strSaveWarnings = " + strSaveWarnings, this);

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
        //String formURL = requestScope.getRequest().getRequestURL().toString()
        //        + "?course_id=" + requestScope.getCourseId().toExternalString();
        //GCDDLog.logForward(LogService.Verbosity.DEBUG, "response.sendRedirect(), formURL: " + formURL, this);
        //response.sendRedirect(formURL);
        response.sendRedirect(requestScope.getIndividualDueDatesURL());

        return;
    } //if (formAction.equals("save") ) {

} catch (Throwable t) {
	GCDDLog.logForward(LogService.Verbosity.ERROR, t, "", this);
	throw new GCDDException (strLogMessages, t);
}

%>

<bbNG:learningSystemPage>
<bbNG:form name="idlaGCPeriodDueDatesForm" method="post" action="gc_period_duedates.jsp" onsubmit="onPostAction(); return true;">

	<input type="hidden" name="course_id" id="course_id" value="<%= requestScope.getCourseId().toExternalString()%>"/>
	<input type="hidden" name="idlaGCPeriodDueDatesActionParam" id="idlaGCPeriodDueDatesActionParam" value="save"/>
	<input type="hidden" name="gradingPeriodCountParam" value="<%= gradingPeriodHelperHash.gpPhysicalList.size() %>"/>

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
    <%@ include file="/WEB-INF/js/gc_duedates.js" %>
	<%
		java.util.Calendar calDueDate = null;
		java.util.Calendar commonDueTime = null;
		String gpIdParamName;
		String gpDueDateParamName;
                String gpDueDateParamName_LabelFor;
		String gpTitleParamName;
		boolean isDueDateFirstPass = true;
                String modifyPeriodURLBase = "/webapps/gradebook/do/instructor/addModifyPeriods?course_id="
                        + requestScope.getCourseId().toExternalString()
                        + "&actionType=modify&id="; //?? PkId{key=";
                String modifyPeriodURL = null;
                //String editIndividualDueDatesURL = "<a href='gc_duedates.jsp?course_id=" + requestScope.getCourseId().toExternalString() + "'>Edit Individual Due Dates</a>";
                String editIndividualDueDatesURLButton = "<INPUT TYPE=\"BUTTON\" VALUE=\"Edit Individual Due Dates\" ONCLICK=\"window.location.href='gc_duedates.jsp?course_id="
                            + requestScope.getCourseId().toExternalString() + "'\">";
	%>
        <bbNG:step hideNumber="true" title="<%= editIndividualDueDatesURLButton%>">
        </bbNG:step>
	<bbNG:step hideNumber="true" title="Edit Due Dates by Grading Period">
            <c:if test="<%=(gradingPeriodHelperHash.gpPhysicalList.size()==0)%>">
                No grading periods are available for this class.
            </c:if >
            <bbNG:inventoryList className="GradingPeriod"
			collection="<%=gradingPeriodHelperHash.gpPhysicalList %>"
			showAll="true"
			objectVar="gp"
			initialSortCol="Title"
			>
			<%
				GCDDLog.logForward(LogService.Verbosity.DEBUG, "gp.getId(): " + gp.getId(), this);
				int gp_index = gradingPeriodHelperHash.hashMap.get(gp.getId().toExternalString()).DueDateOrder;
				GCDDLog.logForward(LogService.Verbosity.DEBUG, "gp_index: " + gp_index, this);
				gpIdParamName = GradingPeriodHelper.ID_PARAM_NAME_BASE + gp_index;
				gpDueDateParamName = GradingPeriodHelper.DUEDATE_PARAM_NAME_BASE + gp_index;
                                gpDueDateParamName_LabelFor = gpDueDateParamName + "_datetime";
				GCDDLog.logForward(LogService.Verbosity.DEBUG, "gpDueDateParamName : " + gpDueDateParamName + " gpDueDateParamName.length(): " + gpDueDateParamName.length());
				gpTitleParamName = GradingPeriodHelper.TITLE_PARAM_NAME_BASE + gp_index;
                                modifyPeriodURL = modifyPeriodURLBase + gp.getId().toExternalString();
                                        //??+ ",%20dataType=blackboard.platform.gradebook2.GradingPeriod,%20container=blackboard.persist.DatabaseContainer@113f501}";
			%>
    		<bbNG:listElement
				comparator="<%=cmSortByTitle%>"
				label="Name"
				name="Title"
				isRowHeader="true" >
                        <a href="<%= modifyPeriodURL %>"><%= gp.getTitle() %></a> 
                        <input type="hidden" name="<%= gpIdParamName %>" id="<%= gpIdParamName %>" value="<%= gp.getId().toExternalString()%>"/>
                        <input type="hidden" name="<%= gpTitleParamName %>" id="<%= gpTitleParamName %>" value="<%= gp.getTitle()%>"/>
                        <% GCDDLog.logForward(LogService.Verbosity.DEBUG, "Name - li_index: " + gp_index, this); %>
                        <% GCDDLog.logForward(LogService.Verbosity.DEBUG, "isDueDateFirstPass: " + isDueDateFirstPass, this); %>
                        
	    	</bbNG:listElement>
                <bbNG:listElement
                        label="Due Date"
                        name="DueDate" >
                        <c:if test="<%=isDueDateFirstPass == false%>">
                            <% GCDDLog.logForward(LogService.Verbosity.DEBUG, "Inside DueDate <bbNG:dataElement>", this); %>
                            <!-- non-empty label value should be provided in order markUnsavedChanges to show up -->
                            <bbNG:dataElement label=" " labelFor="<%=gpDueDateParamName_LabelFor%>">
                                <bbNG:datePicker
                                        baseFieldName = "<%= gpDueDateParamName%>"
                                        dateTimeValue="<%= null%>"
                                        showTime="false"
                                />
                            </bbNG:dataElement>
                        </c:if >
                        <% 	GCDDLog.logForward(LogService.Verbosity.DEBUG, "Due Date - li_index: " + gp_index, this);
                                GCDDLog.logForward(LogService.Verbosity.DEBUG, "lineitemHelperHash.get(gp.getId().toExternalString()).isDueDateConstructed: " + gradingPeriodHelperHash.hashMap.get(gp.getId().toExternalString()).isDueDateConstructed, this);
                                isDueDateFirstPass = false;
                        %>
                </bbNG:listElement>
            </bbNG:inventoryList>
	</bbNG:step>
	<!-- cancelUrl="gc_duedates.jsp" -->
	<!--  Cancel will bring us out of the form (back), only submit (and refresh?) will refresh it here - actually temp solution, has to be implemented with javascript-->
  <bbNG:stepSubmit hideNumber="true" title = "Submit"
  	instructions="Click Submit to save and go to individual due dates page. Cancel acts as browser's back button.">
  </bbNG:stepSubmit>
    Description of plugin processing is available <a href="http://projects.oscelot.org/gf/project/gc_duedates/wiki/?pagename=Grade+Center+Due+Dates+Building+Block+Description">here</a>.
<%
} catch (Throwable t) {
	GCDDLog.logForward(LogService.Verbosity.ERROR, t, "", this);
	throw new GCDDException (strLogMessages, t);
}

%>
</bbNG:dataCollection>
</bbNG:form>
</bbNG:learningSystemPage >
