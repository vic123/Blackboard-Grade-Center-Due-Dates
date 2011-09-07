package idla.gc_duedates;

import blackboard.platform.gradebook2.GradableItem;
import blackboard.platform.log.LogService;
import blackboard.persist.Id;
import java.beans.*;
import java.io.Serializable;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.List;

/**
 * Lineitem is older class of Bb API containing gradebook columns data.
 * Currently this data is accessd through GradableItem.
 * @author vic
 */
public class LineitemHelperHashBean implements Serializable {
    //!! hashMap, liPhysicalList has to go into class' private scope
    //hashMap and liPhysicalList are logically linked through GradableItem.id
    //hashMap is used for mapping of data in submit request to the one actually extisting in database
    public HashMap<String, LineitemHelper> hashMap = new HashMap<String, LineitemHelper>();
    //liPhysicalList is used for generation of page interface (inventoryList of gradebook columns)
    //liPhysicalList will contain only regular gradebook columns, without total ones
    public ArrayList<GradableItem> liPhysicalList = new ArrayList<GradableItem>();

    public void loadLineitemsByCourseId (GCDDRequestScopeBean requestScope) throws Exception {
        GCDDLog.logForward(LogService.Verbosity.INFORMATION, "Entered LineitemHelperHashBean.loadLineitemsByCourseId()", this);
	List<GradableItem> li_all_list
                = requestScope.getGradebookManager().getGradebookItems(requestScope.getCourseId());
        cleanupCaclulatedColumnsAndFillHash(li_all_list);
    }
    public void cleanupCaclulatedColumnsAndFillHash (List<GradableItem> allLineitems) {
        GCDDLog.logForward(LogService.Verbosity.INFORMATION, "Entered LineitemHelperHashBean.cleanupCaclulatedColumnsAndFillHash()", this);
	GradableItem li_prev = null;
	GCDDLog.logForward(LogService.Verbosity.DEBUG, "for (GradableItem li_temp: allLineitems) {", this);
	for (GradableItem li_temp: allLineitems) {
            //exclude total gradebook columns
            if (!li_temp.isCalculated()) {
            //commented out is old way of calculated column detection with capabilities of Lineitem class
            //if  (!(li_temp.getType().equals("Weighted Total") || li_temp.getType().equals("Total") )
                    //old (Lineitem) API does not set type of lineitem correctly, instead of this it returns "hardcoded" names for "total" columns
            //        && !(li_temp.getType().equals("") && (li_temp.getName().equals("Weighted Total") || li_temp.getName().equals("Total") || li_temp.getName().equals("Running Weighted Total") || li_temp.getName().equals("Running Total")))
            //    ) {
                    GCDDLog.logForward(LogService.Verbosity.DEBUG, "LineitemHelper mpp = new LineitemHelper(li_prev, li_temp);", this);
                    //LineitemHelper is container of GradableItem providing methods for
                    //setting of GradableItem from http request parameters
                    //and detection of necessity in data saving
                    LineitemHelper mpp = new LineitemHelper(li_prev, li_temp);
                    mpp.DueDateOrder = liPhysicalList.size();
                    GCDDLog.logForward(LogService.Verbosity.DEBUG, "hashMap.put(li_temp.getId().toExternalString(), mpp);", this);
                    this.hashMap.put(li_temp.getId().toExternalString(), mpp);
                    liPhysicalList.add(li_temp);
            }
            GCDDLog.logForward(LogService.Verbosity.DEBUG, "li_prev = li_temp;", this);
            li_prev = li_temp;
        }
    }
}
