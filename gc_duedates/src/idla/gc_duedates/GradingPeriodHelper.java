package idla.gc_duedates;

import blackboard.platform.log.LogService;
import blackboard.persist.Id;
import blackboard.persist.KeyNotFoundException;
import blackboard.platform.gradebook2.GradingPeriod;
import blackboard.platform.gradebook2.GradableItem;
import java.util.List;
import java.util.ArrayList;

/**
 * Uses LineitemHelperHashBean for accessing of gradebook columns included in
 * grading period, basically just a code for filtration of these columns by grading
 * period instead of by course.
 * @author vic
 */
public class GradingPeriodHelper {
    public static final String ID_PARAM_NAME_BASE = "gpIdParam_";
    public static final String TITLE_PARAM_NAME_BASE = "gpTitleParam_";
    public static final String DUEDATE_PARAM_NAME_BASE = "gpDueDateParam_";

    GradingPeriod gradingPeriod;
    private LineitemHelperHashBean lineitemHelperHash;
    private Id oldId;
    private String oldTitle;
    public String strRowStatus;

    //!!
    public int DueDateOrder;
        public boolean isDueDateConstructed; //quick flagging solution to avoid 2 datepicker controls to be created for one of the rows (first row is passed twice by InventoryList

    public GradingPeriodHelper(GradingPeriod gradingPeriod, GCDDRequestScopeBean requestScope)
        throws Exception {
        GCDDLog.logForward(LogService.Verbosity.INFORMATION, "Entered GradingPeriodHelper.GradingPeriodHelper()", this);
        this.isDueDateConstructed = false; //??
        GCDDLog.logForward(LogService.Verbosity.DEBUG, "gradingPeriod: " + gradingPeriod, this);
        this.gradingPeriod = gradingPeriod;
        GCDDLog.logForward(LogService.Verbosity.DEBUG, "requestScope.getGradebookManager(): " + requestScope.getGradebookManager(), this);
        List<GradableItem> li_all_list
            = requestScope.getGradebookManager().getGradebookItemsByGradingPeriod(gradingPeriod.getId(), 0);
        GCDDLog.logForward(LogService.Verbosity.DEBUG, "lineitemHelperHash = new LineitemHelperHashBean();", this);
        this.lineitemHelperHash = new LineitemHelperHashBean();
        GCDDLog.logForward(LogService.Verbosity.DEBUG, "this.lineitemHelperHash.cleanupCaclulatedColumnsAndFillHash(li_all_list);", this);
        this.lineitemHelperHash.cleanupCaclulatedColumnsAndFillHash(li_all_list);
        
    }

    //started coding of methods for checking of concurrent changes with "Old" getters and setters
    public Id getOldId() {
        return oldId;
    }

    public void setOldId(Id oldId) {
        this.oldId = oldId;
    }
    public String getOldTitle() {
        return oldTitle;
    }
    public void setOldTitle(String oldTitle) {
        this.oldTitle = oldTitle;
    }
    public LineitemHelperHashBean getLineitemHelperHash() {
        return lineitemHelperHash;
    }

    public static String getGradingPeriodTitle(GradableItem gradableItem, GCDDRequestScopeBean requestScope) {
        String gp_title = "";
        Id id = gradableItem.getGradingPeriodId();
        if (id != null) {
            try {
                GradingPeriod gp = requestScope.getGradebookManager().getGradingPeriod(id);
                gp_title = gp.getTitle();
            } catch (Exception e) {
                GCDDLog.logForward(LogService.Verbosity.WARNING, e, "GradingPeriodHelper.getGradingPeriodTitle(): ");
            }
        }
        return gp_title;
    }

}
