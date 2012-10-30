package idla.gc_duedates;

import blackboard.platform.log.LogService;
import blackboard.persist.Id;
import blackboard.platform.persistence.PersistenceServiceFactory;
import blackboard.persist.BbPersistenceManager;
import blackboard.platform.context.Context;
import blackboard.platform.context.ContextManagerFactory;
import blackboard.data.user.User;
import blackboard.persist.course.CourseMembershipDbLoader;

import blackboard.db.TransactionInterfaceFactory; //!!
import blackboard.platform.gradebook2.impl.GradebookManagerFacade; //!!
import blackboard.data.course.Course;
import blackboard.platform.gradebook2.GradebookManagerFactory;
import blackboard.platform.gradebook2.GradebookManager;
import javax.servlet.http.HttpSession;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.Serializable;

/**
 * Initializes and provides access to http request related objects
 * and Bb objects commonly used for accessing of Bb data
 * @author vic
 */
public class GCDDRequestScopeBean implements Serializable {
    private Id courseId;
    private BbPersistenceManager persistenceManager;
    private Context context;
    private User sessionUser;
    private CourseMembershipDbLoader courseMembershipDbLoader;
    private HttpSession session;
    private HttpServletRequest request;
    private HttpServletResponse response;
    private GradebookManager gradebookManager;
    private SettingsBean settings;
    
    public GCDDRequestScopeBean () {
        GCDDLog.logForward(LogService.Verbosity.INFORMATION, "GCDDRequestScopeBean(): Entered", this);
    }
    public void init(HttpSession session, HttpServletRequest request, 
                    HttpServletResponse response, SettingsBean settings) throws Exception {
        GCDDLog.logForward(LogService.Verbosity.INFORMATION, "init(): Entered", this);

	String course_id_param = request.getParameter("course_id");
	request.getSession().setAttribute("course_id", course_id_param);
	GCDDLog.logForward(LogService.Verbosity.INFORMATION, "init(): request.getParameter(\"course_id\"): " + course_id_param, this);

	this.persistenceManager = PersistenceServiceFactory.getInstance().getDbPersistenceManager();
        this.courseId = this.persistenceManager.generateId(Course.DATA_TYPE, course_id_param);
	//obtaing of context through bbData:context tag caused IllegalStateException
	//upon response.sendRedirect(formURL) after saving of lineitems.
        this.context = ContextManagerFactory.getInstance().getContext();
        String user_name = null;
        this.sessionUser = context.getUser();
        if (this.sessionUser == null)
                throw new GCDDException("Failed to obtain User object from Context.");
        user_name = this.sessionUser.getUserName();
        GCDDLog.logForward(LogService.Verbosity.INFORMATION, "init(): sessionUser.getUserName(): " + user_name, this);

        this.courseMembershipDbLoader = CourseMembershipDbLoader.Default.getInstance();
        this.session = session;
        this.request = request;
        this.response = response;
        this.gradebookManager = GradebookManagerFactory.getInstance();
        //commented out is temporary code for debugging of ToDo logic
        //this.gradebookManager = (GradebookManager)TransactionInterfaceFactory.getInstance(GradebookManager.class, new GradebookManagerFacadeIDLA(true));
        this.settings = settings;
    }


    public Id getCourseId() {
        return courseId;
    }

    public BbPersistenceManager getPersistenceManager() {
        return persistenceManager;
    }

    public Context getContext() {
        return context;
    }

    public User getSessionUser() {
        return sessionUser;
    }

    public CourseMembershipDbLoader getCourseMembershipDbLoader() {
        return courseMembershipDbLoader;
    }

    public HttpSession getSession() {
        return session;
    }

    public HttpServletRequest getRequest() {
        return request;
    }

    public HttpServletResponse getResponse() {
        return response;
    }

    public GradebookManager getGradebookManager() {
        return gradebookManager;
    }

    public SettingsBean getSettings() {
        return settings;
    }

    public String getIndividualDueDatesURL() {
        return "gc_duedates.jsp?course_id=" + getCourseId().toExternalString();
    }

}
