

<%@ taglib uri="/bbUI" prefix="bbUI" %>

<%@ page import="java.util.Date" %>
<%@ page import="java.util.Calendar" %>
<%@ page import="java.util.ArrayList" %>

<%@ page import="java.text.SimpleDateFormat" %>

<%@ page import="blackboard.platform.*" %>
<%@ page import="blackboard.platform.intl.*" %>
<%@ page import="blackboard.servlet.data.*" %>
<%@ page import="blackboard.servlet.tags.DatePickerTag, blackboard.util.StringUtil" %>

<%
   boolean is24 = DateSelectionUtils.getIs24Hour();
   
   BbLocale currentLocale = BbServiceManager.getLocaleManager().getLocale();
   String localeCode = currentLocale.getLocale();
   
   //STRING EXTRACTION
    BundleManager bundleMgr   = (BundleManager)BbServiceManager.safeLookupService(BundleManager.class);
    BbResourceBundle _localeBundle = bundleMgr.getBundle("LocaleSettings");
    BbResourceBundle _bundle  = bundleMgr.getBundle("tags");
    String SELECT_DATE      = _bundle.getString("date.select");

    String dateOrder = _localeBundle.getString("LOCALE_SETTINGS.DATE_ORDER.00519");
    String orderFirst,orderSecond,orderThird=null;
    try {
     orderFirst = dateOrder.substring(0,1);
     orderSecond = dateOrder.substring(1,2);
     orderThird = dateOrder.substring(2,3);
    }
    catch (Exception ex)
    {
        orderFirst="M";
        orderSecond="D";
        orderThird="Y";
    }


    //BbServiceManager.getLogService().logDebug("Order:"+orderFirst+orderSecond+orderThird);
   DatePickerTag tag =
     (DatePickerTag)pageContext.findAttribute(DatePickerTag.DATE_PICKER_TAG_ATTRIBUTE);
   DatePicker dateAvail =
     (DatePicker)pageContext.findAttribute(DatePickerTag.DATE_PICKER_ATTRIBUTE);


if ( tag != null )
{

  int datePickerIndex = tag.getDatePickerIndex().intValue();

  String strFormName       = tag.getFormName();
  String strLabel1 = tag.getStartCaption();

  boolean isShowTime = tag.getIsShowTime();
  boolean hideDate = tag.getIsHideDate();

  // allow the user to rename the hidden fields (necessary for Struts compatibility)
  // support multiple date pickers per page
  String restrictStartDateField = tag.getStartDateField() + "_" + String.valueOf( datePickerIndex );

  Calendar startDate = (Calendar)tag.getStartDate();


  // allow the JSP page to control the date format used in the hidden field
  SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd hh:mm:ss");  //2001-09-13 18:28:43


  String optHtml = "";
  String selectHtml1 = "";
  String selectHtml2 = "";
  String selectHtml3 = "";
  // for js validation
  boolean isCheckPastDue = tag.getCheckPastDue();
  int checkPastDue = 0;
  if (isCheckPastDue)
  {
    checkPastDue = 1;
  }

  // only display js link once on a given page
  if ( datePickerIndex == 0 )
  {
%>
<SCRIPT type="text/javascript" src="/javascript/swap.js"></SCRIPT>
<script
 type='text/javascript'
 src="/javascript/md5.js">
</script>

<bbUI:jsResource file="/javascript/picker.js"/>

<script
 type="text/javascript"
 src="/javascript/datemenu.js">
</script>
<%

  } // end single display of js links
  /*
  // this script link should appear in the head of the jsp page calling this form element!
  <script	type="text/javascript" src="/javascript/validateForm.js"></script>
    */

  %>



<script
 type="text/javascript"
 language="JavaScript">
    <!--
    function <%=restrictStartDateField%>_updateHidden(el)
    {
      updateHiddenDate(el,'<%=restrictStartDateField%>','<%=restrictStartDateField%>')
    }


    function <%=restrictStartDateField%>_normalizeDate(mm,dd,yy) {
        reflectDay(mm,dd,yy);
         <%=restrictStartDateField%>_updateHidden(mm);
    }

    //-->

</script>

            <table cellspacing="0" cellpadding="0">
              <tr>
                <td>
                <% if ( StringUtil.notEmpty(strLabel1 ) )
                   {%>
                  <span class="fieldCaption"><%=strLabel1%></span>
                 <%}%>
                  <table border="0" cellpadding="0" cellspacing="0" width="100%">
<%if (!hideDate){%>
                    <tr>
                      <td nowrap="nowrap">

<% // use the dateOrder to figure out how to generate the order of the select boxes for data tag
selectHtml1 = tag.selectHtmlToString(orderFirst,dateAvail,restrictStartDateField);
selectHtml2 = tag.selectHtmlToString(orderSecond,dateAvail,restrictStartDateField);
selectHtml3 = tag.selectHtmlToString(orderThird,dateAvail,restrictStartDateField);
%>
<%=selectHtml1%>
<%=selectHtml2%>
<%=selectHtml3%>
                      </td>
                      <td>
                        <a href="javascript:showPicker('<%=restrictStartDateField%>', '<%=localeCode%>');">
                          <img src="/images/ci/icons/calendar_s.gif" alt="<%=SELECT_DATE%>" border="0" align="top"/>
                        </a>
                        <input type="hidden" name="<%=restrictStartDateField%>" value=""/>
                        <input type="hidden" name="pickdate" value=""/>
                        <input type="hidden" name="pickname" value=""/>
                      </td>
                    </tr>
<%}%>
                    <%
// determine whether to show the time stamp
if (isShowTime)
{
%>
                    <tr>
                      <td nowrap="nowrap">
                        <select name="<%=restrictStartDateField%>_hh" onchange="<%=restrictStartDateField%>_updateHidden(this)">
<%
// this is a utility function to clean up the in-page logic
dateAvail.setPeriod(Calendar.HOUR);
optHtml = tag.toXhtml(dateAvail);
%>                        <%= optHtml%>
                        </select> 
                        <select name="<%=restrictStartDateField%>_mi" onchange="<%=restrictStartDateField%>_updateHidden(this)">
<%
// this is a utility function to clean up the in-page logic
dateAvail.setPeriod(Calendar.MINUTE);
optHtml = tag.toXhtml(dateAvail);
%>                        <%= optHtml%>
                        </select>
                        <%if (!is24)
                          {
                          %>
                        <select name="<%=restrictStartDateField%>_am" onchange="<%=restrictStartDateField%>_updateHidden(this)">
<%
// this is a utility function to clean up the in-page logic
dateAvail.setPeriod(Calendar.AM_PM);
optHtml = tag.toXhtml(dateAvail);
%>                        <%= optHtml%>
                        </select>
                        <%}
                          else
                          {
                            %>
                            <INPUT TYPE="hidden" NAME="<%=restrictStartDateField%>_am" VALUE="0">
                            <%
                          }
                        %>
                      </td>
                      <td>&nbsp;<td>
                    </tr>

<%
}//end switch for isShowTime
%>
                  </table>
<%if (!hideDate){%>
<script
 type="text/javascript"
 language="JavaScript">
    <!--

    <%=restrictStartDateField%>_normalizeDate(document.<%=strFormName%>.<%=restrictStartDateField%>_mm,
                                      document.<%=strFormName%>.<%=restrictStartDateField%>_dd,
                                      document.<%=strFormName%>.<%=restrictStartDateField%>_yyyy);
    //-->

</script>
<% } //end hide date around script %>
                </td>
              </tr>



              <%

  Calendar endDate   = (Calendar)tag.getEndDate();

  if ( endDate != null )
  {

    String strEndChecked = "";
    if ( tag.getIsEndChecked() )
    {
      strEndChecked = "checked= \"checked\"";
    }
    String strLabel2            = tag.getEndCaption();
    String restrictEndDateField = tag.getEndDateField()   + "_" + String.valueOf( datePickerIndex );

%>
              <tr>
                <td>
                  <input
                   type="checkbox"
                   name="restrict_end_<%=datePickerIndex%>"
                   value="1"
                   <%=strEndChecked%>
                   onClick="<%=restrictEndDateField%>_updateHidden(this)"
                   /> &nbsp;


                <% if ( StringUtil.notEmpty(strLabel2 ) )
                   {%>
                  <span class="fieldCaption"><%=strLabel2%></span>
                 <%}%>
                  <table border="0" cellpadding="0" cellspacing="0" width="100%">
                    <tr>
                      <td nowrap="nowrap">
<script
 type="text/javascript"
 language="JavaScript">


                function <%=restrictEndDateField%>_updateHidden(el){
                    updateHiddenDate(el,'<%=restrictEndDateField%>','<%=restrictEndDateField%>')
                }


    function <%=restrictEndDateField%>_normalizeDate (mm,dd,yy) {
        reflectDay(mm,dd,yy);
         <%=restrictEndDateField%>_updateHidden(mm);
    }

    //-->
</script>
<% // use the dateOrder to figure out how to generate the order of the select boxes for data tag
selectHtml1 = tag.selectHtmlToString(orderFirst,dateAvail,restrictEndDateField);
selectHtml2 = tag.selectHtmlToString(orderSecond,dateAvail,restrictEndDateField);
selectHtml3 = tag.selectHtmlToString(orderThird,dateAvail,restrictEndDateField);
%>
<%=selectHtml1%>
<%=selectHtml2%>
<%=selectHtml3%>
                      </td>
                      <td>
                        <a href="javascript:showPicker('<%=restrictEndDateField%>', '<%=localeCode%>');">
                          <img src="/images/ci/icons/calendar_s.gif" alt="<%=SELECT_DATE%>" border="0" align="top"/>
                        </a>
                        <input  type="hidden" name="<%=restrictEndDateField%>" value=""/>
                      </td>
                    </tr>

<%

if (isShowTime)
{
%>
                    <tr>
                      <td nowrap="nowrap">
                        <select name="<%=restrictEndDateField%>_hh" onchange="<%=restrictEndDateField%>_updateHidden(this)">
<%
// this is a utility function to clean up the in-page logic
dateAvail.setPeriod(Calendar.HOUR);
optHtml = tag.toXhtml(dateAvail);
%>                        <%= optHtml%>
                        </select>
                        <select name="<%=restrictEndDateField%>_mi" onchange="<%=restrictEndDateField%>_updateHidden(this)">
<%
// this is a utility function to clean up the in-page logic
dateAvail.setPeriod(Calendar.MINUTE);
optHtml = tag.toXhtml(dateAvail);
%>                        <%= optHtml%>
                        </select>
                        <%if (!is24)
                          {
                          %>
                        <select name="<%=restrictEndDateField%>_am" onchange="<%=restrictEndDateField%>_updateHidden(this)">
<%
// this is a utility function to clean up the in-page logic
dateAvail.setPeriod(Calendar.AM_PM);
optHtml = tag.toXhtml(dateAvail);
%>                        <%= optHtml%>
                        </select>
                        <%}
                          else
                          {
                            %>
                            <INPUT TYPE="hidden" NAME="<%=restrictEndDateField%>_am" VALUE="0">
                            <%
                          }
                        %>
                      </td>
                      <td>&nbsp;</td>
                    </tr>

<%
}//end isShowTime
%>
                  </table>

<%
	if (!hideDate)
	{
%>
<script
 type="text/javascript"
 language="JavaScript">

    <!--
    <%=restrictEndDateField%>_normalizeDate(document.<%=strFormName%>.<%=restrictEndDateField%>_mm,
                                    document.<%=strFormName%>.<%=restrictEndDateField%>_dd,
                                    document.<%=strFormName%>.<%=restrictEndDateField%>_yyyy);
    //-->

</script>
<script
 type="text/javascript"
 language="JavaScript">
    <!--
    var chkTime = new Check_EventTime({name:"<%=restrictStartDateField%>",cmp_field:"<%=restrictEndDateField%>",cmp_restrict_flag:"restrict_end_<%=datePickerIndex%>",past_due:<%=checkPastDue%>,duration:1,cmp_ref_label:"<%=strLabel2%>",ref_label:"<%=strLabel1%>"});
    formCheckList.addElement(chkTime);
    //-->
</script>
<% } %>
                </td>
              </tr>

<%
  }    //end ifIsShowEnd

 else
 {
   // validate only the start time
   %>
<% if (!hideDate) { %>

<script type="text/javascript" language="JavaScript">
     // todo:
    var chkTime_<%=datePickerIndex%> = new Check_EventTime({name:"<%=restrictStartDateField%>",past_due:<%=checkPastDue%>,duration:1,ref_label:"<%=strLabel1%>"});
    formCheckList.addElement(chkTime_<%=datePickerIndex%>);
</script>
<% } %>
   <%
 }
%>
            </table>
<% } //end if tag != null%>

