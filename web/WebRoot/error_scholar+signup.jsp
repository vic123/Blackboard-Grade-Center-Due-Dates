<%@ page import="blackboard.plugin.beyond.bbAS.Constants" %>
<%@ page import="org.apache.log4j.Logger" %>
<%@ taglib uri="/bbNG" prefix="bbNG" %>
<%@ taglib uri="/bbData" prefix="bbData" %>
<%@ page isErrorPage="true" %>
<bbData:context authentication="N">
  <bbNG:genericPage>
    <%
      Object theError = exception;
      if( null == theError )
      {
        // check the struts error
        theError = request.getAttribute( Constants.ERROR );
      }

      // write the error to the custom logs
      if( theError instanceof Throwable )
      {
        Logger.getLogger( this.getClass() ).error( "", (Throwable) theError );
      }
      else
      {
        Logger.getLogger( this.getClass() ).error( theError );
      }

      if( theError instanceof Throwable )
      {
        Throwable theThrowable = (Throwable) theError;
    %>
    <bbNG:error exception="<%= theThrowable %>"/>
    <%
      }
    %>
  </bbNG:genericPage>
</bbData:context>
		
		
		
<%@ taglib uri="/bbUI" prefix="bbUI"%>
<%@ page import="java.io.PrintWriter"%>

<bbUI:docTemplate>
<bbUI:receipt type="FAIL" title="Error">
<p>Sorry, an error has occurred in the Sign-up Tool<br>
We would be grateful if you could report this to Dr <a href='mailto:malcolm.murray@durham.ac.uk'>Malcolm Murray</a><br>Thanks</p>
Or better still report this bug on the Sign-Up tool site <a href="http://community.learningobjects.com/tracker/?group_id=27">bug-tracker</a> page
<p>The following code might help him solve it!</p>
<b><%=exception.getMessage()%></b><br>
<pre>
<%
	// now display a stack trace of the exception
  PrintWriter pw = new PrintWriter( out );
  exception.printStackTrace( pw );
%>
</pre>
</bbUI:receipt>
</bbUI:docTemplate>
