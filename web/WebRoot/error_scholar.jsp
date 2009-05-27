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