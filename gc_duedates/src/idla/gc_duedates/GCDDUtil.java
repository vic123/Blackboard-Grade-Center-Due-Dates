package idla.gc_duedates;

import blackboard.platform.log.*;
import blackboard.data.course.CourseMembership;
import blackboard.persist.Id;
import blackboard.platform.plugin.PlugInUtil;

import javax.servlet.http.HttpSession;
import javax.servlet.http.HttpServletRequest;
import java.lang.reflect.Array;
import java.text.SimpleDateFormat;
import java.text.ParseException;
import java.util.Enumeration;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Comparator;
import java.util.Collections;
import java.util.Date;



/**
 * Static utility functions for
 * a) logging of request parameters
 * b) authorization
 * c) null-safe string comparing
 * @author vic
 */

public class GCDDUtil {

    
    public static void logRequestParamters (HttpSession session, HttpServletRequest request) {
        if (GCDDLog.getOverridenSeverity(LogService.Verbosity.INFORMATION).getLevelAsInt()
                >= LogService.Verbosity.INFORMATION.getLevelAsInt()) return;

	GCDDLog.logForward(LogService.Verbosity.INFORMATION, "session.getId(): " + session.getId());
        GCDDLog.logForward(LogService.Verbosity.INFORMATION, "request.getRemoteHost(): " + request.getRemoteHost());
	GCDDLog.logForward(LogService.Verbosity.INFORMATION, "request.getServerPort(): " + request.getServerPort());
	GCDDLog.logForward(LogService.Verbosity.INFORMATION, "request.getRequestURL(): " + request.getRequestURL());
	GCDDLog.logForward(LogService.Verbosity.INFORMATION, "request.getQueryString(): " + request.getQueryString());

	Enumeration<String> keys = request.getParameterNames();
	ArrayList<String> keys_list = Collections.list(keys);

	//comparator for java.util.Collections.sort just below
	Comparator<String> cmSortParamsByName = new Comparator<String>() {
            public int compare(String s1, String s2) {
                return s1.compareTo(s2);
            }
        };
	java.util.Collections.sort(keys_list, cmSortParamsByName);
	GCDDLog.logForward(LogService.Verbosity.INFORMATION, "FORM PARAMETERS: " );
	for (String s_temp: keys_list) {
		// If the same key has multiple values (check boxes)
		String[] valueArray = request.getParameterValues(s_temp);
		if (Array.getLength(valueArray) > 1) {
			for (int i = 0; i < Array.getLength(valueArray); i++) {
				GCDDLog.logForward(LogService.Verbosity.INFORMATION, s_temp + "[" + i + "]:" + valueArray[i]);
			}
		} else {
		      //To retrieve a single value
		    String value = request.getParameter(s_temp);
		    GCDDLog.logForward(LogService.Verbosity.INFORMATION, "Parameter " + s_temp + ": " + value);
		}
	}
    }
    public static boolean checkCourseMembershipRole(GCDDRequestScopeBean requestScope)
        throws Exception {
	GCDDLog.logForward(LogService.Verbosity.INFORMATION, "Entered GCDDUtil.checkCourseMembershipRole()" );
	Id courseId = requestScope.getCourseId();
	//check user role permission
        // perform a check based on course membership:
        CourseMembership c_mem 
                = requestScope.getCourseMembershipDbLoader().loadByCourseAndUserId(requestScope.getCourseId(), requestScope.getSessionUser().getId());
        boolean do_deny = true;
        if(c_mem != null) {
            blackboard.platform.security.CourseRole c_role = c_mem.getRole().getDbRole();
            if (c_mem.getRole() == CourseMembership.Role.INSTRUCTOR
                        || c_mem.getRole() == CourseMembership.Role.TEACHING_ASSISTANT
                        || c_mem.getRole() == CourseMembership.Role.COURSE_BUILDER
                        || c_role.isActAsInstructor()) do_deny = false;
        }
        if (do_deny) PlugInUtil.sendAccessDeniedRedirect(requestScope.getRequest(), requestScope.getResponse());
        return !do_deny;
    }
    public static int nullSafeStringComparator(String txt, String otherTxt)
    {
        if ( txt == null )
            return otherTxt == null ? 0 : -1;
        if ( otherTxt == null )
              return 1;
        return txt.compareToIgnoreCase(otherTxt);
    }

    public static boolean isStringBlank (String str) {
        if (str == null) return true;
        if ("".equals(str.trim())) return true;
        return false;
    }
    public static Calendar dateStringToCalendar(String dateStr, String formatStr) throws ParseException {
        //if (isStringBlank(dateStr)) return null;
        //DbUtil.stringToCalendar(value);
        if (isStringBlank(dateStr)) throw new java.text.ParseException("Unparseable date: " + dateStr, 0);
        SimpleDateFormat _sdf = new SimpleDateFormat(formatStr);
        Calendar cal;
        Date date = _sdf.parse(dateStr);
        cal = Calendar.getInstance();
        cal.setTime(date);
        return cal;
    }

    public static String fixTimeString (String str) {
        if (isStringBlank(str)) return null;
        if (str.trim().startsWith("12")) {
            str = "0" + str.trim().substring(2);
        }
        return str;
    }

    public static String constructExceptionMessage(Throwable e) {
        GCDDLog.logForward(LogService.Verbosity.DEBUG, "Entered BbWsUtil.constructExceptionMessage() ");
        String msg = e.toString();
        Throwable cause_e = e;
        int loop_limit = 0;
        while (cause_e.getCause() != null) {
            cause_e = cause_e.getCause();
            msg += " <br> CAUSED BY: " + cause_e.toString();
            loop_limit++;
            if (loop_limit > 10) break;
        }
        return msg;
    }
}
