package idla.gc_duedates;

import blackboard.platform.log.LogService;
import blackboard.platform.gradebook2.GradingPeriod;
import java.beans.*;
import java.io.Serializable;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.List;
/**
 * Made with use of LineitemHelperHashBean as prototype
 * @author vic
 */
public class GradingPeriodHelperHashBean implements Serializable {


    public GradingPeriodHelperHashBean() {
    }
    //!! move hashMap and gpPhysicalList to private scope
    public HashMap<String, GradingPeriodHelper> hashMap
            = new HashMap<String, GradingPeriodHelper>();
    public List<GradingPeriod> gpPhysicalList = new ArrayList<GradingPeriod>();

    public void loadGradingPeriodsByCourseId (GCDDRequestScopeBean requestScope) throws Exception {
        GCDDLog.logForward(LogService.Verbosity.INFORMATION, "Entered Bean.loadGradingPeriodsByCourseId()", this);
	List<GradingPeriod> gp_list
                = requestScope.getGradebookManager().getGradingPeriods(requestScope.getCourseId());

	GCDDLog.logForward(LogService.Verbosity.DEBUG, "for (GradingPeriod gp_temp: gp_list) {", this);
	for (GradingPeriod gp_temp: gp_list) {
            GCDDLog.logForward(LogService.Verbosity.DEBUG, "gp_temp: " + gp_temp, this);
            GradingPeriodHelper gph = new GradingPeriodHelper(gp_temp, requestScope);
            gph.DueDateOrder = gpPhysicalList.size();
            hashMap.put(gp_temp.getId().toExternalString(), gph);
            gpPhysicalList.add(gp_temp);
        }
    }

}
