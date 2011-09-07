package idla.gc_duedates;

import blackboard.platform.gradebook2.GradableItem;
import blackboard.platform.log.LogService;
import blackboard.db.DbUtil;
import javax.servlet.http.HttpServletRequest;
import java.io.Serializable;
import java.util.Calendar;
import java.util.List;
import java.util.Comparator;


/**
 * Inside LineitemHelper are declared ancestors of LineItemField
 * - LineItemIsAvailableField and LineItemDueDateField classes,
 * which are closely integrated and accessing fields of its container - LineitemHelper.
 * LineitemHelper is container of GradableItem providing methods for
 * setting of GradableItem from http request parameters
 * and detection of necessity in data saving.
 * Lineitem part of class name is obsolete, currently GradableItem is used for
 * accessing of Bb data.
 * @author vic
 */
public class LineitemHelper implements Serializable {
	public static final String liDueDateParamNameBase = "liDueDateParam";
	public static final String liIdParamNameBase = "liIdParam_";
	public static final String liHasDueDateParamNameBase = "liHasDueDateParam_";
	public static final String liIsAvailableParamNameBase =  "liIsAvailableParam_";
	public static final String liNameParamNameBase =  "liNameParam_";


        GradableItem liPrev;
        //!! -> private
        public GradableItem lineitem;

        Calendar calPrev;
        Calendar calendar;
        double fPointsPossible;
        double fMinutesPerPoint;
        long lMinutesCount;

        //!! move strRowStatus, DueDateOrder, isDueDateConstructed, paramIndex, fieldsList to private scope,
        // probably along with moving of data saving processing inside LineitemHelper
        // (currently performed in jsp files)
        public String strRowStatus;
        public int DueDateOrder; //used just for indexing, contains initial DueDateOrder, can become incorrect after save, but it should not influence behavior
        public boolean isDueDateConstructed; //quick flagging solution to avoid 2 datepicker controls to be created for one of the rows (first row is passed twice by InventoryList
        public int paramIndex;
        public List<LineItemField> fieldsList;

        public LineitemHelper(GradableItem liPrev_, GradableItem lineitem_) {
                strRowStatus = "";
                isDueDateConstructed = false;
                liPrev = liPrev_;
                lineitem = lineitem_;
                assert (lineitem_ != null);
                refresh();
        }

        public boolean needsSave() {
                for (LineItemField lif_temp: fieldsList) {
                        if (lif_temp.isSet) return true;
                }
                return false;
        }

        public void refresh() {
                calPrev = null;
                calendar = null;
                fPointsPossible = lineitem.getPoints();
                calendar = lineitem.getDueDate();
                if (liPrev == null) {
                        fMinutesPerPoint = 0;
                } else {
                        calPrev = liPrev.getDueDate();
                        if (calPrev == null) {
                                fMinutesPerPoint = 0;
                        } else if (calendar != null) {
                                lMinutesCount = (long) ((calendar.getTimeInMillis() - calPrev.getTimeInMillis()) / (1000 * 60));
                                fMinutesPerPoint = lMinutesCount/fPointsPossible;
                        }
                }
                if (calendar == null) fMinutesPerPoint = -1;
        }

        public String toString() {
                if (calendar == null || liPrev == null || calPrev == null) return "N/A / " + fPointsPossible + " = N/A";
                else return lMinutesCount + " / " + fPointsPossible + " = " + fMinutesPerPoint;
        }

        /**
         * LineItemField is class for more centralized error handling of GradableItem
         * fields setting and persisting add easier capabilities for adding of more editable fields
         */
	public class  LineItemField {
		protected String value;
                protected GCDDRequestScopeBean requestScope;
		String paramName;
                //flag indicatings that GradableItem has to be saved
		boolean isSet;
		public LineItemField (String paramName_, GCDDRequestScopeBean requestScope) {
			paramName = paramName_;
                        this.requestScope = requestScope;
			value = requestScope.getRequest().getParameter(paramName);
			GCDDLog.logForward(LogService.Verbosity.INFORMATION, "LineItemField.paramName: " + paramName + ", value: " + value, this);
			if (value == null) value = "";
		}
                //!! move checkAndSet to private scope during rework of data saving processing
		public void checkAndSet() throws Exception {
			isSet = false;
			checkAndSetInternal();
		}
                /**
                 * Ancestors of LineItemField override this function with code
                 * deciding whether particular field value is changed
                 * (differs from actually stored in DB) by user and
                 * in such case flagging that whole Bb object has to be saved
                 */
		void checkAndSetInternal() throws Exception {}
	} //private class  LineItemField {

        public class  LineItemIsAvailableField extends LineItemField {
                public LineItemIsAvailableField(String paramName_, GCDDRequestScopeBean requestScope) {
                        super(paramName_, requestScope);
                }
                void checkAndSetInternal() throws Exception {
                        boolean is_avail = value.equals("on");
                        if (LineitemHelper.this.lineitem.isVisibleToStudents() != is_avail) {
                                GCDDLog.logForward(LogService.Verbosity.INFORMATION, "LineitemHelper.this.lineitem.setIsAvailable(is_avail);" + "is_avail: " + is_avail, this);
                                LineitemHelper.this.lineitem.setVisibleToStudents(is_avail);
                                isSet = true;
                        }
                }
        } //private class  LineItemIsAvailable extends LineItemField {

        public class  LineItemDueDateField extends LineItemField {
            LineItemField liHasDueDate;
            LineItemField isCommonDueTime;
            LineItemField commonDueTime;
            //-> private
            public LineItemDueDateField(String paramName_, GCDDRequestScopeBean requestScope) {
                    super(paramName_, requestScope);
                    liHasDueDate = new LineItemField(liHasDueDateParamNameBase + LineitemHelper.this.paramIndex, requestScope);
                    isCommonDueTime = new LineItemField("isCommonDueTimeParam", requestScope);
                    commonDueTime = new LineItemField("commonDueTimeParam_datetime", requestScope);
            }

            void checkAndSetInternal() throws Exception {
                    Calendar saved_due_date = LineitemHelper.this.lineitem.getDueDate();
                    GCDDLog.logForward(LogService.Verbosity.INFORMATION, "saved_due_date: " + saved_due_date, this);
                    Calendar due_date = DbUtil.stringToCalendar(value);
                    if (requestScope.getSettings().isShowHasDueDateColumn()) {
                        GCDDLog.logForward(LogService.Verbosity.INFORMATION, "liHasDueDate.value: " + liHasDueDate.value, this);
                        if (liHasDueDate.value.equals("on")) {
                            if (due_date == null) {
                                    throw new GCDDException("Due date is not set");
                            }
                            GCDDLog.logForward(LogService.Verbosity.DEBUG, "due_date: " + due_date, this);
                        } else if (saved_due_date != null) {
                            GCDDLog.logForward(LogService.Verbosity.INFORMATION, "LineitemHelper.this.lineitem.getOutcomeDefinition().setDueDate(null);", this);
                            LineitemHelper.this.lineitem.setDueDate(null);
                            isSet = true;
                            return;
                        }
                    }

                    if ( due_date == null) {
                        if ( saved_due_date == null) return;
                        else {
                            LineitemHelper.this.lineitem.setDueDate(null);
                            isSet = true;
                            return;
                        }
                    } else {
                        Calendar common_duetime = requestScope.getSettings().getCommonDueTime();
                        if (requestScope.getSettings().isShowCommonDueTime()) {
                                if (isCommonDueTime.value.equals("on")) {
                                    common_duetime = DbUtil.stringToCalendar(commonDueTime.value);
                                }
                        }

                        GCDDLog.logForward(LogService.Verbosity.DEBUG, "common_duetime: " + common_duetime.toString(), this);
                        due_date.set(Calendar.MILLISECOND, common_duetime.get(Calendar.MILLISECOND));
                        due_date.set(Calendar.SECOND, common_duetime.get(Calendar.SECOND));
                        due_date.set(Calendar.MINUTE, common_duetime.get(Calendar.MINUTE));
                        due_date.set(Calendar.HOUR_OF_DAY, common_duetime.get(Calendar.HOUR_OF_DAY));
                        GCDDLog.logForward(LogService.Verbosity.INFORMATION, "due_date: " + due_date, this);
                        if ( saved_due_date == null) {
                                GCDDLog.logForward(LogService.Verbosity.INFORMATION, "getOutcomeDefinition().getDueDate() == null -> LineitemHelper.this.lineitem.getOutcomeDefinition().setDueDate(due_date);", this);
                                LineitemHelper.this.lineitem.setDueDate(due_date);
                                isSet = true;
                        } else if (saved_due_date.compareTo(due_date) != 0) {
                                    GCDDLog.logForward(LogService.Verbosity.INFORMATION, "getOutcomeDefinition().getDueDate().compareTo(due_date) != 0 -> LineitemHelper.this.lineitem.getOutcomeDefinition().setDueDate(due_date);", this);
                                    LineitemHelper.this.lineitem.setDueDate(due_date);
                                    isSet = true;
                                }
                    }
            } //void checkAndSetInternal() {
        } //private class  LineItemDueDate extends LineItemField {

        public class  LineItemDueDateFieldForPeriod extends LineItemField {
                GCDDRequestScopeBean requestScope;
                public LineItemDueDateFieldForPeriod(String paramName_, GCDDRequestScopeBean requestScope) {
                        super(paramName_, requestScope);
                        this.requestScope = requestScope;
                }

                void checkAndSetInternal() throws Exception {
                        if ("".equals(value)) return;
                        Calendar saved_due_date = LineitemHelper.this.lineitem.getDueDate();
                        GCDDLog.logForward(LogService.Verbosity.DEBUG, "saved_due_date: " + saved_due_date, this);
                        GCDDLog.logForward(LogService.Verbosity.DEBUG, "value: " + value, this);
                        Calendar due_date = DbUtil.stringToCalendar(value);
                        GCDDLog.logForward(LogService.Verbosity.DEBUG, "due_date: " + due_date, this);
                        Calendar common_duetime = requestScope.getSettings().getCommonDueTime();
                        GCDDLog.logForward(LogService.Verbosity.DEBUG, "common_duetime: " + common_duetime.toString(), this);
                        due_date.set(Calendar.MILLISECOND, common_duetime.get(Calendar.MILLISECOND));
                        due_date.set(Calendar.SECOND, common_duetime.get(Calendar.SECOND));
                        due_date.set(Calendar.MINUTE, common_duetime.get(Calendar.MINUTE));
                        due_date.set(Calendar.HOUR_OF_DAY, common_duetime.get(Calendar.HOUR_OF_DAY));
                        GCDDLog.logForward(LogService.Verbosity.DEBUG, "due_date: " + due_date, this);
                        if ( saved_due_date == null) {
                            GCDDLog.logForward(LogService.Verbosity.DEBUG, "getOutcomeDefinition().getDueDate() == null -> LineitemHelper.this.lineitem.getOutcomeDefinition().setDueDate(due_date);", this);
                            LineitemHelper.this.lineitem.setDueDate(due_date);
                            isSet = true;
                        } else if (saved_due_date.compareTo(due_date) != 0) {
                            GCDDLog.logForward(LogService.Verbosity.DEBUG, "getOutcomeDefinition().getDueDate().compareTo(due_date) != 0 -> LineitemHelper.this.lineitem.getOutcomeDefinition().setDueDate(due_date);", this);
                            LineitemHelper.this.lineitem.setDueDate(due_date);
                            isSet = true;
                        }
                } //void checkAndSetInternal() {
        } //public class  LineItemDueDateFieldForPeriod

	public static class ComparatorSortByMinutesPerPoint implements Comparator<GradableItem> {
		public java.util.HashMap<String, LineitemHelper> lineitemHelperHash;
		public ComparatorSortByMinutesPerPoint (java.util.HashMap<String, LineitemHelper> lineitemHelperHash_) {
			lineitemHelperHash = lineitemHelperHash_;
		}
   		public int compare(GradableItem li1, GradableItem li2) {
	   		LineitemHelper minpp1 = lineitemHelperHash.get(li1.getId().toExternalString());
	   		LineitemHelper minpp2 = lineitemHelperHash.get(li2.getId().toExternalString() );
	        if (minpp1.liPrev == null) return -1;
	        if (minpp2.liPrev == null) return 1;
	        return Double.compare (minpp1.fMinutesPerPoint, minpp2.fMinutesPerPoint);
		}
   	}
}
