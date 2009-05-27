<%@ include file="doctype.jspf" %>

<%@ page language="java" import="java.util.*" pageEncoding="ISO-8859-1"%>
<%@page import="java.lang.reflect.Array,
				blackboard.persist.*,
                blackboard.data.*,
                blackboard.platform.*,
                blackboard.portal.data.*,
                blackboard.platform.intl.*,
                blackboard.portal.servlet.*,
                blackboard.platform.servlet.InlineReceiptUtil, blackboard.data.ReceiptOptions"
		errorPage="/error.jsp"
%>
<%@ taglib uri="/bbNG" prefix="bbNG"%>

<jsp:useBean id="itemForm" scope="request" class="org.oscelot.gc_duedates.struts.ModifyItemsDueDatesForm" />

<bbNG:learningSystemPage  ctxId="ctx">

<%
String strHasDueDates[];
String strHasDueDate1s[];
String strDueDate1[];

strHasDueDates = request.getParameterValues("hasDueDateParam");
strHasDueDate1s = request.getParameterValues("hasDueDate1Param");
strDueDate1 = request.getParameterValues("DueDate1Param");

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


/*
	LineitemDbPersister liDbP = (LineitemDbPersister)bbPm.getPersister(LineitemDbPersister.TYPE);
	logDebug("Lineitem li1 = (Lineitem)liList.get(0);");
	Lineitem li1 = (Lineitem)liList.get(0);
	logDebug("java.util.Calendar due_date = li1.getOutcomeDefinition().getDueDate();");
	//java.util.	
	Calendar due_date = li1.getOutcomeDefinition().getDueDate();
	//due_date.set(2001, 1, 1);
	//logDebug("li1.getOutcomeDefinition().setDueDate(due_date);");
	//li1.getOutcomeDefinition().setDueDate(due_date); 
	//liDbP.persist(li1);

	li1 = (Lineitem)liList.get(2);
	logDebug("due_date = li1.getOutcomeDefinition().getDueDate();");
	due_date = li1.getOutcomeDefinition().getDueDate();
	//due_date.set(2001, 1, 1);
	//li1.getOutcomeDefinition().setDueDate(due_date); 
	//liDbP.persist(li1);
*/

/*

String path = request.getContextPath();
String basePath = request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+path+"/";

PortalRequestContext prc = PortalUtil.getPortalRequestContext(pageContext);
BbResourceBundle _bundle = BundleManagerFactory.getInstance().getBundle("portal_view");
String receiptText= _bundle.getString("moduletype.receipt.msg");

StringBuilder receiptURL = new StringBuilder("index.jsp");
receiptURL.append("&").append(InlineReceiptUtil.SIMPLE_STRING_KEY).append("=");
receiptURL.append(receiptText);

*/
 //session.setAttribute( InlineReceiptUtil.RECEIPT_KEY, new ReceiptOptions(receiptText) );  
// response.sendRedirect(prc.getRootRelativeUrl(receiptURL.toString()));
// response.sendRedirect("gc_duedates.jsp");
%>

</bbNG:learningSystemPage>

