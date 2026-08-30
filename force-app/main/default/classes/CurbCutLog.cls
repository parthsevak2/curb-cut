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

    private static final String SALT =
        'curb-cut-log-salt-v1';   // rotating this orphans old hashes, by design

    /** Hashes the recipient so a log is never a contact list. */
    public static String handleFor(String raw) {
        if (String.isBlank(raw)) { return null; }
        return EncodingUtil.convertToHex(
            Crypto.generateDigest('SHA-256', Blob.valueOf(SALT + raw))).substring(0, 32);
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
