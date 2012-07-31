<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
   "http://www.w3.org/TR/html4/loose.dtd">

<%-- 
    Document   : settings
    Created on : Jul 13, 2011, 4:51:29 PM
    Author     : vic

Error reported at the top of file is because of:
http://netbeans.org/bugzilla/show_bug.cgi?id=172334
Bug 172334 - is already defined in SimplifiedJSPServlet error
--%>

<%@page contentType="text/html" 
        pageEncoding="UTF-8"
        import="idla.gc_duedates.GCDDLog,
                idla.gc_duedates.GCDDUtil,
                idla.gc_duedates.GCDDConstants,
                blackboard.data.user.*,
                blackboard.data.ReceiptOptions,
                blackboard.data.ReceiptMessage,
                blackboard.servlet.tags.InlineReceiptTag,
                blackboard.platform.log.LogService,
                blackboard.platform.plugin.PlugInUtil,
                blackboard.platform.context.Context,
		blackboard.platform.context.ContextManagerFactory"
                %>

<%@ taglib uri="/bbUI" prefix="bbUI"%>
<%@ taglib uri="/bbData" prefix="bbData"%>
<%@ taglib uri="/bbNG" prefix="bbNG"%>

<%!
    String PAGE_TITLE;
    String ICON_URL;
%>

<%
    GCDDUtil.logRequestParamters(session, request);
    Context ctx = ContextManagerFactory.getInstance().getContext();
    //authentication
    if (!PlugInUtil.ensureAuthenticatedUser(request, response)) return;
    User sessionUser = ctx.getUser();
    User.SystemRole sessionUserSystemRole = sessionUser.getSystemRole();
    GCDDLog.logForward(LogService.Verbosity.INFORMATION, "sessionUser.getUserName(): " + sessionUser.getUserName()
    		+ "; sessionUserSystemRole.getDisplayName(): " + sessionUserSystemRole.getDisplayName());
	//check user role permission
    if (sessionUserSystemRole != User.SystemRole.SYSTEM_ADMIN) {
        PlugInUtil.sendAccessDeniedRedirect(request, response);
        return;
    }

    PAGE_TITLE = "Grade Center Due Dates Settings";
    ICON_URL = PlugInUtil.getUri(GCDDConstants.VENDOR_ID, GCDDConstants.HANDLE, "DueDates.jpg");

    String formAction = request.getParameter("idlaGCDueDatesSettingsActionParam");
    GCDDLog.logForward(LogService.Verbosity.DEBUG, "request.getParameter(\"idlaGCDueDatesSettingsActionParam\"): " + formAction);
    if (formAction == null) formAction = "";
%>
<jsp:useBean id="settings" scope="request" class="idla.gc_duedates.SettingsBean"/>
<%
    if (formAction.equals("save")) {
        //save modified data, set any success/warning session status and refresh page
        GCDDLog.logForward(LogService.Verbosity.INFORMATION, "Entering if (formAction.equals(\"save\")) {" );
%>
<jsp:setProperty name="settings" property="showDueTime" value="false"/>
<jsp:setProperty name="settings" property="*" />
<jsp:setProperty name="settings" property="showDueTime" />
<%
                String sDT = request.getParameter("showDueTime");
                settings.saveSettings();
		ReceiptOptions	ro = new ReceiptOptions();
		ReceiptMessage rm;
		if (false) { //!!
			rm = new ReceiptMessage("WARNING - Not all modifications were saved, some error(s) occurred: <br>",
								ReceiptMessage.messageTypeEnum.WARNING);
		} else rm = new ReceiptMessage("Changes Saved", ReceiptMessage.messageTypeEnum.SUCCESS);
		ro.addMessage(rm);
		request.getSession().setAttribute(InlineReceiptTag.RECEIPT_KEY, ro);
                String formURL = request.getRequestURL().toString();
		GCDDLog.logForward(LogService.Verbosity.DEBUG, "response.sendRedirect(), formURL: " + formURL);
		response.sendRedirect(formURL);
		return;
	} //if (formAction.equals("save") ) {
%>
<bbNG:genericPage>
<bbNG:form name="idlaGCDueDatesSettingsForm" method="post" action="settings.jsp" onsubmit="onPostAction(); return true;">
	<input type="hidden" name="idlaGCDueDatesSettingsActionParam" id="idlaGCDueDatesSettingsActionParam" value="save"/>

	<bbNG:dataCollection markUnsavedChanges="true">
	<%
	try {
	%>

    <bbNG:breadcrumbBar environment="SYS_ADMIN" navItem="admin_plugin_manage">
    	<bbNG:breadcrumb><%= PAGE_TITLE%></bbNG:breadcrumb>
    </bbNG:breadcrumbBar>
    <bbNG:receipt />
	<bbNG:pageHeader>
	    <bbNG:pageTitleBar iconUrl="<%=ICON_URL%>">
   	    <%= PAGE_TITLE %>
    	</bbNG:pageTitleBar>
    </bbNG:pageHeader>
    <%@ include file="/WEB-INF/js/gc_duedates.js" %>

    <%-- <jsp:useBean id="settings" scope="session" class="idla.gc_duedates.SettingsBean"/> --%>
	<bbNG:step hideNumber="true" title="Time part of all due dates" instructions="Please specify time value set upon submit of due date if time part of due date is not shown (next option)">
            <!-- labelFor="commonDueTime_time" - ?? 2011-08-17 15:27:43 - 'label' attribute is mandatory when 'labelFor' is specified (/webapps/IDLA-gradecenter_due-BB_bb60/settings.jsp, commonDueTime_time) -->
            <bbNG:dataElement label=" " >
        	<bbNG:datePicker baseFieldName="commonDueTime"
                                 dateTimeValue='${settings.commonDueTime}'  showDate="false" showTime="true" midnightWarning="??midnight warning??" suppressInstructions="true" displayOnly="false"/>
            </bbNG:dataElement>
	</bbNG:step>
	<bbNG:step hideNumber="true" title="Show time part of due dates" instructions="Allows editing of time part for individual and period due dates">
            <bbNG:dataElement label=" " >
        	<bbNG:checkboxElement name="showDueTime" id="showDueTime" value="true"
                                      displayOnly="false"  isSelected="${settings.showDueTime}" />
            </bbNG:dataElement>
	</bbNG:step>
	<bbNG:step hideNumber="true" title="Date and time formats" instructions="Format of date and time strings submitted by web pages">
            <bbNG:dataElement label="Date Format" >
        	<bbNG:textElement name="dateFormat" id="dateFormat" value="${settings.dateFormat}"
                                      displayOnly="false" />
            </bbNG:dataElement>
            <bbNG:dataElement label="Time Format" >
        	<bbNG:textElement name="timeFormat" id="timeFormat" value="${settings.timeFormat}"
                                      displayOnly="false" />
            </bbNG:dataElement>
	</bbNG:step>

        <bbNG:step hideNumber="true" title="Log Verbosity">
            <bbNG:dataElement label=" " labelFor="logSeverityOverride">
                <select name="logSeverityOverride" id="logSeverityOverride">
                    <OPTION value="0" <% if (settings.getLogSeverityOverride().compareTo("0") == 0) out.print("SELECTED"); %>>FATAL/AUDIT</OPTION>
                    <OPTION value="1" <% if (settings.getLogSeverityOverride().compareTo("1") == 0) out.print("SELECTED"); %>>ERROR</OPTION>
                    <OPTION value="2" <% if (settings.getLogSeverityOverride().compareTo("2") == 0) out.print("SELECTED"); %>>WARNING</OPTION>
                    <OPTION value="3" <% if (settings.getLogSeverityOverride().compareTo("3") == 0) out.print("SELECTED"); %>>INFORMATION</OPTION>
                    <OPTION value="4" <% if (settings.getLogSeverityOverride().compareTo("4") == 0) out.print("SELECTED"); %>>DEBUG</OPTION>
                    <OPTION value="5" <% if (settings.getLogSeverityOverride().compareTo("5") == 0) out.print("SELECTED"); %>>DEBUG2</OPTION>
                </select>
            </bbNG:dataElement>
        </bbNG:step>
  <bbNG:stepSubmit hideNumber="true" title="Submit" cancelUrl="/webapps/blackboard/admin/manage_plugins.jsp"
  	instructions="Click Submit to save and reload. Cancel acts as browser's back button."/>
<%
} catch (Throwable t) {
	GCDDLog.logForward(LogService.Verbosity.ERROR, t, "");
        throw t;
}

%>
</bbNG:dataCollection>
</bbNG:form>
</bbNG:genericPage>


