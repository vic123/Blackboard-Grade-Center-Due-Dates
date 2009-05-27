<%@ taglib uri="/bbUI" prefix="bbUI"%>
<%@ page import="java.io.PrintWriter, java.lang.reflect.Array, java.util.*" %>
<%@ page isErrorPage = "true" %>

<bbUI:docTemplate>
<bbUI:receipt type="FAIL" title="Error">
<p>Please report this error on the <a href="http://projects.oscelot.org/gf/project/gc_duedates/tracker/">bug-tracker</a> page
<b><%=exception.getMessage()%></b><br>
<pre>
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

	// now display a stack trace of the exception
  PrintWriter pw = new PrintWriter( out );
  exception.printStackTrace( pw );
%>
</pre>
</bbUI:receipt>
</bbUI:docTemplate>
