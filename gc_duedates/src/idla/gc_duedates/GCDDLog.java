package idla.gc_duedates;

import blackboard.platform.log.*;
import blackboard.platform.BbServiceManager;
import javax.annotation.Resource;
import javax.xml.ws.WebServiceContext;
import javax.servlet.ServletContext;
import javax.xml.ws.handler.MessageContext;
import java.lang.Thread;


/**
 * Static log forwarding functions - introduced for easier production of log messages
 * without necessity of modifying of server log settings.
 * Reworked from gc_duedates.jsp,  copy/pasted/adopted from BbWebservices\src\java\bbwscommon\BbWsLog.java
 * @author vic
 */
public class GCDDLog {

	static Log log = LogServiceFactory.getInstance().getDefaultLog();
        static int logSeverityOverride = -1;
        
        public static LogService.Verbosity getOverridenSeverity (LogService.Verbosity verbosity) {
            if (logSeverityOverride == -1) {
                log.log(GCDDConstants.LOG_PREFIX + " | "
                        + getCurrentThreadName() + " | " 
                        + "Logging initialization. SettingsBean sets = new SettingsBean();...", log.getVerbosityLevel());
                SettingsBean sets = new SettingsBean();
                String value = sets.getLogSeverityOverride();
                log.log(GCDDConstants.LOG_PREFIX + " | "
                        + getCurrentThreadName() + " | "
                        + "sets.getLogSeverityOverride(): " + value, log.getVerbosityLevel());
                try {
                    logSeverityOverride = Integer.decode(value);
                } catch (java.lang.NumberFormatException e) {
                    logSeverityOverride = 5;
                    log.log(GCDDConstants.LOG_PREFIX + " | "
                            + getCurrentThreadName() + " | "
                            + "Invalid value of logSeverityOverride: " + value, log.getVerbosityLevel());
                }
            }
            
            if (log.getVerbosityLevel().getLevelAsInt() < verbosity.getLevelAsInt()
                    && verbosity.getLevelAsInt() <= logSeverityOverride) {
                return log.getVerbosityLevel();
            } else {
                return verbosity;
            }
        }

        public static String getCurrentThreadName () {
            return Thread.currentThread().getName();
        }

	//log forwarding functions - intoroduced for easier production of log messages
	//without necessity of modifying of server log settings
	public static void logForward(LogService.Verbosity verbosity, String message) {
		message = GCDDConstants.LOG_PREFIX + " | "
                        + getCurrentThreadName() + " | "
                        + verbosity.toExternalString().substring(0,3) + " | " + message;
                verbosity = getOverridenSeverity(verbosity);
		log.log(message, verbosity);
	}
	public static void logForward(LogService.Verbosity verbosity, String message, Object obj) {
		message = GCDDConstants.LOG_PREFIX + " | " 
                        + getCurrentThreadName() + " | "
                        + verbosity.toExternalString().substring(0,3) + " | " + String.valueOf(obj) + " | " + message;
		log.log(message, getOverridenSeverity(verbosity));
	}
        
	public static void logForward(LogService.Verbosity verbosity, java.lang.Throwable error, String message) {
		message = GCDDConstants.LOG_PREFIX + " | " 
                        + getCurrentThreadName() + " | "
                        + verbosity.toExternalString().substring(0,3) + " | " + message;
		log.log(message, error, getOverridenSeverity(verbosity));
	}
	public static void logForward(LogService.Verbosity verbosity, java.lang.Throwable error, String message, Object obj) {
		message = GCDDConstants.LOG_PREFIX + " | " 
                        + getCurrentThreadName() + " | "
                        + verbosity.toExternalString().substring(0,3) + " | " + String.valueOf(obj) + " | " + message;
		log.log(message, error, getOverridenSeverity(verbosity));
	}
        
}
