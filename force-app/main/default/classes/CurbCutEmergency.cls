/**
 * CurbCutEmergency — the narrow exception, recorded as one.
 *
 * Curb Cut's central promise is that nobody is ever routed to a telephone.
 * That promise has to survive the situation nobody planned for: a family member
 * ringing in frightened about someone, a safeguarding concern, something moving
 * faster than a message thread.
 *
 * The design keeps the promise intact while making the exception possible:
 *
 * - It CANNOT call the person. Not by policy, by construction: there is no
 *   phone or email field anywhere in this schema and never has been. A number
 *   only exists here if somebody volunteered one during this escalation.
 * - It refuses outright when the person has recorded that they cannot take a
 *   call. That flag is not advisory; for some people a phone call is a door
 *   that does not open, and an emergency does not change their hearing.
 * - A written reason is required before anything happens, and the validation
 *   rule enforces a real sentence rather than a keystroke.
 * - It records who raised it, on whose account, and whether the person even
 *   knows, because acting on somebody else's word about a disabled person is
 *   exactly how their autonomy usually gets taken.
 * - Access is a separate permission set. Granting it is a decision.
 */
public with sharing class CurbCutEmergency {

    public class BlockedException extends Exception {}

    public class Context {
        @AuraEnabled public Boolean neverCall     { get; set; }
        @AuraEnabled public String  theirWords    { get; set; }
        @AuraEnabled public String  reachBy       { get; set; }
        @AuraEnabled public Boolean alreadyOpen   { get; set; }
        @AuraEnabled public String  openEscalation{ get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static Context context(Id handoffId) {
        Human_Handoff__c h = [
            SELECT Reachable_By__c, Barrier_Report__c,
                   Barrier_Report__r.Functional_Description__c,
                   Barrier_Report__r.Access_Profile__r.Never_Call__c
            FROM Human_Handoff__c WHERE Id = :handoffId
            WITH SECURITY_ENFORCED LIMIT 1];

        Context c = new Context();
        c.reachBy = h.Reachable_By__c;
        c.neverCall = h.Barrier_Report__r != null
            && h.Barrier_Report__r.Access_Profile__r != null
            && h.Barrier_Report__r.Access_Profile__r.Never_Call__c == true;
        c.theirWords = h.Barrier_Report__r == null
            ? null : h.Barrier_Report__r.Functional_Description__c;

        List<Emergency_Escalation__c> open = [
            SELECT Name FROM Emergency_Escalation__c
            WHERE Human_Handoff__c = :handoffId AND Closed_At__c = null
            WITH SECURITY_ENFORCED LIMIT 1];
        c.alreadyOpen = !open.isEmpty();
        c.openEscalation = open.isEmpty() ? null : open[0].Name;
        return c;
    }

    /**
     * Raises the escalation. Returns the record so the component can show the
     * number to dial only after the reason is on file, never before.
     */
    @AuraEnabled
    public static Emergency_Escalation__c raise(Id handoffId, String reason, String squad,
                                                String raisedByWhom, String personKnows,
                                                String callbackNumber) {
        if (String.isBlank(reason) || reason.trim().length() < 15) {
            throw new BlockedException('Say why, in a sentence someone reviewing this in six months '
                + 'could understand. This is the one thing the system promises not to do, so '
                + 'the exception is written down before it is made.');
        }

        Human_Handoff__c h = [
            SELECT Barrier_Report__c, Barrier_Report__r.Access_Profile__r.Never_Call__c
            FROM Human_Handoff__c WHERE Id = :handoffId WITH SECURITY_ENFORCED LIMIT 1];

        Boolean neverCall = h.Barrier_Report__r != null
            && h.Barrier_Report__r.Access_Profile__r != null
            && h.Barrier_Report__r.Access_Profile__r.Never_Call__c == true;

        // Escalating to a colleague is always allowed. Ringing the person is not,
        // and the component is told which of the two this is.
        Emergency_Escalation__c e = new Emergency_Escalation__c(
            Human_Handoff__c      = handoffId,
            Barrier_Report__c     = h.Barrier_Report__c,
            Reason__c             = reason.trim(),
            Squad__c              = String.isBlank(squad) ? 'Safeguarding lead' : squad,
            Caller_Relationship__c= String.isBlank(raisedByWhom) ? 'Someone else' : raisedByWhom,
            Person_Knows__c       = String.isBlank(personKnows) ? 'Unknown' : personKnows,
            Callback_Number__c    = String.isBlank(callbackNumber) ? null : callbackNumber.trim(),
            Raised_At__c          = System.now(),
            Raised_By_Name__c     = UserInfo.getName());
        insert e;

        // A call is a contact. It belongs in the same ledger as every other one.
        CurbCutLog.record('Voice', 'Outbound', 'Escalated', null,
            'emergency escalation ' + e.Id + ' raised to ' + e.Squad__c
            + (neverCall ? ' (person cannot take calls; squad contact only)' : ''),
            h.Barrier_Report__c);

        return [SELECT Id, Name, Squad__c, Raised_At__c, Raised_By_Name__c, Callback_Number__c
                FROM Emergency_Escalation__c WHERE Id = :e.Id];
    }

    @AuraEnabled
    public static void close(Id escalationId, String outcome) {
        update new Emergency_Escalation__c(
            Id = escalationId,
            Closed_At__c = System.now(),
            Outcome__c = outcome,
            // The number was borrowed for an emergency, not collected. It goes
            // when the emergency does.
            Callback_Number__c = null);
    }
}
