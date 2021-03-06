package idla.gc_duedates;

import blackboard.platform.plugin.PlugIn;
import blackboard.platform.plugin.PlugInConfig;
import blackboard.platform.plugin.PlugInException;
import blackboard.platform.plugin.PlugInManager;
import blackboard.platform.plugin.PlugInManagerFactory;
import blackboard.platform.log.*;
import java.beans.*;
import java.io.Serializable;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Properties;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.text.SimpleDateFormat;


/**
 * Settings defined in administrative Settings screen of building block.
 * Provides methods for saving and loading of settings from properties file
 * located in c:\blackboard\content\vi\BB_bb60\plugins\IDLA-gradecenter_duedates\config\config.properties
 * @author vic
 */
public class SettingsBean implements Serializable {
    //need it here because GCDDLog accesses SettingsBean for value of "logSeverityOverride"
    //will be used only in constructractor for beta-tracking of SettingsBean instantinations
    //and error logging
    private static Log log = LogServiceFactory.getInstance().getDefaultLog();
    private Properties properties;

    /**
     * constructor loads settings from properties file
     *
    */
    public SettingsBean() {

        //logging is performed directly through Bb methods, because
        //GCDDLog relies on settings (creates them upon own initialization)
        //and invoking GCDDLog method would cause dead loop
        log.log("Entered SettingsBean.SettingsBean()", log.getVerbosityLevel());
        try {
            this.properties = loadProperties(getConfigFile());
        } catch (Exception e) {
            log.log("SettingsBean(): this.properties = loadProperties(getConfigFile());", e, log.getVerbosityLevel());
            try {
                PlugInManager pim = PlugInManagerFactory.getInstance();
                PlugIn plugin = pim.getPlugIn(GCDDConstants.VENDOR_ID, GCDDConstants.HANDLE);
                //!! default config values can be specified in this file (i.e. overriding those that are hardcoded
                //as default values in getProperty() calls, but it was not tested and default-config.properties file
                //by itself does not exists in project tree
                File file = new File(pim.getPlugInDir(plugin), "/webapp/WEB-INF/config/default-config.properties");
                this.properties = loadProperties(file);
            } catch (Exception e2) {
                log.log("SettingsBean(): this._properties = loadProperties(file);", e2, log.getVerbosityLevel());
                this.properties = new Properties();
            }
        }
    }


    public void saveSettings () throws Exception {
        GCDDLog.logForward(LogService.Verbosity.DEBUG, "entered SettingsBean.saveSettings() ", this);
        File file = getConfigFile();
        FileOutputStream fos = null;
        try {
            fos = new FileOutputStream(file);
            this.properties.store(fos, "Grade Center Due Dates Configuration File");
        }
        finally {
            if (fos != null) fos.close();
        }
    }

    private static File getConfigFile() throws PlugInException {
        PlugInConfig config = new PlugInConfig(GCDDConstants.VENDOR_ID, GCDDConstants.HANDLE);
        return new File(config.getConfigDirectory(), "config.properties");
    }

    private static Properties loadProperties(File configFile) throws IOException  {
        Properties result = new Properties();
        FileInputStream fis = null;
        try {
            fis = new FileInputStream(configFile);
            result.load(fis);
            return result;
        } finally  {
            if (fis != null) fis.close();
        }
    }

    /**
     * Reads default common due time defined in administrative settings
     * @return the commonDueTime
     */
    public java.util.Calendar getCommonDueTime() throws Exception {
        GCDDLog.logForward(LogService.Verbosity.DEBUG, "entered SettingsBean.getCommonDueTime() ", this);
        String str_time = this.properties.getProperty("CommonDueTime", "10:00 PM");
        str_time = GCDDUtil.fixTimeString(str_time);
        GCDDLog.logForward(LogService.Verbosity.DEBUG, "SettingsBean.getCommonDueTime(); str_time: " + str_time, this);
        String time_fmt = getTimeFormat();
        Calendar gc = GCDDUtil.dateStringToCalendar(str_time, time_fmt);
        return gc;
    }

    public void setCommonDueTime_time(String value) {
        GCDDLog.logForward(LogService.Verbosity.DEBUG, "entered SettingsBean.setCommonDueTime_time(), value: " + value, this);
        value = GCDDUtil.fixTimeString(value);
        this.properties.setProperty("CommonDueTime", value);
    }

    /**
     * These settings may be added as optional features of BB in future releases,
     * currently just return hardcoded false values.
     */

    public boolean isShowDueTime() {
        String val = this.properties.getProperty("ShowDueTime", "false");
        return "true".equals(val);
    }

    public void setShowDueTime(boolean value) {
        this.properties.setProperty("ShowDueTime", Boolean.toString(value));
    }

    public boolean isShowOrderColumn() {
        return false;
    }
    public boolean isShowHasDueDateColumn() {
        return false;
    }

    /**
     * Setting defining logging level of BB, independently of overall
     * logging level of Bb server
     */
    public String getLogSeverityOverride() {
        return this.properties.getProperty("LogSeverityOverride", "5");
    }
    public void setLogSeverityOverride(String value) {
        this.properties.setProperty("LogSeverityOverride", value);
    }

    public String getDateFormat() {
        return this.properties.getProperty("DateFormat", "MM/dd/yyyy");
    }

    public void setDateFormat(String value) {
        this.properties.setProperty("DateFormat", value);
    }
    
    public String getTimeFormat() {
        return this.properties.getProperty("TimeFormat", "K:mm a");
    }
    public void setTimeFormat(String value) {
        this.properties.setProperty("TimeFormat", value);
    }

    public int getMaxDueDateCount() {
        return Integer.parseInt(this.properties.getProperty("MaxDueDateCount", "500"));
    }
    public void setMaxDueDateCount(int value) {
        this.properties.setProperty("MaxDueDateCount", Integer.toString(value));
    }

    public int getMaxGradingPeriodCount() {
        return Integer.parseInt(this.properties.getProperty("MaxGradingPeriodCount", "100"));
    }
    public void setMaxGradingPeriodCount(int value) {
        this.properties.setProperty("MaxGradingPeriodCount", Integer.toString(value));
    }

}
