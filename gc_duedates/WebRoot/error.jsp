<%@ taglib uri="/bbNG" prefix="bbNG"%>
<%@ page import="java.io.PrintWriter, java.lang.reflect.Array, java.util.*, blackboard.platform.plugin.PlugInUtil" %>
<%@ page isErrorPage = "true" %>

<% 
	String PAGE_TITLE = "Grade Center Due Dates";
	String ICON_URL = PlugInUtil.getUri( "IDLA", "gradecenter_duedates", "DueDates.jpg"); 
%>
<bbNG:learningSystemPage>
<bbNG:form >
    <bbNG:breadcrumbBar environment="CTRL_PANEL">
    	<bbNG:breadcrumb><%= PAGE_TITLE%></bbNG:breadcrumb>
    </bbNG:breadcrumbBar>
	<bbNG:pageHeader>
	    <bbNG:pageTitleBar iconUrl="<%=ICON_URL%>">
    	    <%= PAGE_TITLE %>
    	</bbNG:pageTitleBar>
    </bbNG:pageHeader>

<p>An unhandled exception occurred, if you think this is a bug then please create 
<a href="http://projects.oscelot.org/gf/project/gc_duedates/tracker/">bug-tracker</a> 
entry and supplement (copy/paste) text from this page. It contains exception message, stack trace, any form request parameters and list of log messages collected after page reload.</p>
<b><%=exception.getCause().getMessage()%></b><br>
<pre>
<%
	//display a stack trace of the exception
	out.print ("<b>Stack trace: </b>" );
	PrintWriter pw = new PrintWriter( out );
	exception.getCause().printStackTrace( pw );

	out.print ("<br> <b>Parameters: </b> <br>" );

	Enumeration<String> keys = request.getParameterNames();
	ArrayList<String> keys_list = Collections.list(keys);
	Comparator<String> cmSortByName = new Comparator<String>() {
      public int compare(String s1, String s2) {
      	return s1.compareTo(s2);
      }
    };
	java.util.Collections.sort(keys_list, cmSortByName);
	for (String s_temp: keys_list) {
		out.print (s_temp);
		// If the same key has multiple values (check boxes)
		String[] valueArray = request.getParameterValues(s_temp);
		if (Array.getLength(valueArray) > 1) {
			for (int i = 0; i < Array.getLength(valueArray); i++) {
				out.print (s_temp + "[" + i + "]:" + valueArray[i]);
				out.print ("<br>");
			}
		} else {
		      //To retrieve a single value
		    String value = request.getParameter(s_temp);
	    	out.print (": " + value);
			out.print ("<br>");    	
		}
   }
	out.print ("<br> <b>Log: </b> <br>" );
	out.print (exception.getMessage());   
%>
</pre>
</bbNG:form>
</bbNG:learningSystemPage>