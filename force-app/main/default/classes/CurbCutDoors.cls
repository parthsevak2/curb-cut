/**
 * CurbCutDoors - which doors this deployment actually has.
 *
 * Every reply used to say "here, by text, or by email" whether or not the
 * deployment had a text number or an inbound address. On the showcase that
 * pointed people at a hackathon number nobody answered any more; on a fresh
 * install it would have pointed them at a placeholder. A door is only named
 * once its label holds a real value, the same rule the public pages follow.
 */
public with sharing class CurbCutDoors {

    /** The text-number placeholder the repository ships. */
    public static final String NO_NUMBER = '+10000000000';

    @TestVisible private static String linkOverride;
    @TestVisible private static String inboundOverride;

    private static String link() {
        return linkOverride != null ? linkOverride : System.Label.CurbCut_SMS_Number_Link;
    }

    private static String inbound() {
        return inboundOverride != null ? inboundOverride : System.Label.CurbCut_Inbound_Email;
    }

    /** True once the deployment has connected a number of its own. */
    public static Boolean textOpen() {
        String l = link();
        return String.isNotBlank(l) && l.trim() != NO_NUMBER;
    }

    /** True once Salesforce has made the inbound address and it is in the label. */
    public static Boolean emailOpen() {
        String e = inbound();
        return String.isNotBlank(e) && !e.containsIgnoreCase('example.com');
    }

    /**
     * "here, or by text, or by email", naming only the doors that exist, for
     * sentences like "Send it here, or by text, or by email."
     */
    public static String orElsewhere() {
        return 'here'
             + (textOpen()  ? ', or by text'  : '')
             + (emailOpen() ? ', or by email' : '');
    }
}
