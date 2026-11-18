/**
 * CurbCutLog — the delivery ledger.
 *
 * The email channel failed and nobody could tell, because nothing recorded the
 * attempt. Salesforce reported "success" while the message never arrived, and
 * the gap between those two facts is exactly where a person disappears.
 *
 * This records THAT we tried to reach someone and what happened. It never
 * records what they said, and never their raw address or number. The same rule
 * as everywhere else in this system: the fact of the contact is operational,
 * the content of it is theirs.
 */
public with sharing class CurbCutLog {

    /**
     * Hashes the recipient so a log is never a contact list. Keyed by this
     * org's own secret through CurbCutKeys; the salt that used to sit here was
     * in a public repository, which made it a label rather than a secret.
     */
    public static String handleFor(String raw) {
        if (String.isBlank(raw)) { return null; }
        return CurbCutKeys.digest(CurbCutKeys.Purpose.LOG_HANDLE, raw);
    }

    /**
     * Every handle this recipient's rows might carry: rows written before the
     * org had a key hold the old form, rows written after hold the new one.
     * Anything that ever looks a person's rows up by handle - to ask whether
     * they have had the disclosure, or to count what they were sent - must
     * match IN this set, or the history splits in two the day the key is set.
     */
    public static Set<String> handlesFor(String raw) {
        if (String.isBlank(raw)) { return new Set<String>(); }
        return CurbCutKeys.candidates(CurbCutKeys.Purpose.LOG_HANDLE, raw);
    }

    public static void record(String channel, String direction, String status,
                              String recipient, String detail, String barrierId) {
        try {
            Message_Log__c log = new Message_Log__c(
                Channel__c          = channel,
                Direction__c        = direction,
                Status__c           = status,
                Recipient_Hash__c   = handleFor(recipient),
                Detail__c           = detail == null ? null : detail.left(30000),
                Attempted_At__c     = System.now(),
                Daily_Quota_Used__c = Limits.getEmailInvocations(),
                Daily_Quota_Limit__c = Limits.getLimitEmailInvocations()
            );
            if (String.isNotBlank(barrierId)) {
                try { log.Barrier_Report__c = Id.valueOf(barrierId); }
                catch (Exception ignored) { log.Barrier_Report__c = null; }
            }
            insert log;
        } catch (Exception e) {
            // Logging must never be the thing that breaks a conversation.
            System.debug(LoggingLevel.ERROR, 'log failed: ' + e.getMessage());
        }
    }
}
