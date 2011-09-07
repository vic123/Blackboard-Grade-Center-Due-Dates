package idla.gc_duedates;

/**
 * Just a place reserved for centralized extending of exception processing
 * @author vic
 */
public class GCDDException extends Exception {
    private static final long serialVersionUID = 0x9C86F94BDD670411L;
    public GCDDException(String message, Throwable cause) {
            super (message, cause);
    }
    public GCDDException(String message) {
            super (message);
    }
}
