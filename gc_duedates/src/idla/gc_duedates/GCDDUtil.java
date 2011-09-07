package idla.gc_duedates;

import blackboard.platform.log.*;
import blackboard.data.course.CourseMembership;
import blackboard.persist.Id;
import blackboard.platform.plugin.PlugInUtil;

import javax.servlet.http.HttpSession;
import javax.servlet.http.HttpServletRequest;
import java.lang.reflect.Array;
import java.util.Enumeration;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.Collections;


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
        boolean do_deny = false;
        if(c_mem == null) do_deny = true;
        else if (c_mem.getRole() != CourseMembership.Role.INSTRUCTOR
                        && c_mem.getRole() != CourseMembership.Role.TEACHING_ASSISTANT
                        && c_mem.getRole() != CourseMembership.Role.COURSE_BUILDER) {
                do_deny = true;
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
}
