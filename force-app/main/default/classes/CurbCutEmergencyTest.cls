/**
 * The exception has to stay an exception. These assert the friction is real.
 */
@IsTest
private class CurbCutEmergencyTest {

    private static Human_Handoff__c handoff(Boolean neverCall) {
        Access_Profile__c ap = new Access_Profile__c(
            Person_Handle__c = 'em-1', Active__c = true,
            Preferred_Modality__c = 'Text', Never_Call__c = neverCall);
        insert ap;
        Barrier_Report__c br = new Barrier_Report__c(
            Functional_Description__c = 'I cannot use the phone',
            Inbound_Modality__c = 'Text', Anonymous__c = false, Access_Profile__c = ap.Id);
        insert br;
        Human_Handoff__c h = new Human_Handoff__c(
            Barrier_Report__c = br.Id, Reachable_By__c = 'Text message',
            Requested_At__c = System.now().addHours(-2));
        insert h;
        return h;
    }

    @IsTest
    static void willNotRaiseWithoutARealReason() {
        Human_Handoff__c h = handoff(false);
        Test.startTest();
        for (String bad : new List<String>{ '', '   ', 'urgent', 'family called' }) {
            try {
                CurbCutEmergency.raise(h.Id, bad, 'Safeguarding lead',
                    'A family member', 'Unknown', null);
                System.assert(false, 'Raised with no real reason: "' + bad + '"');
            } catch (CurbCutEmergency.BlockedException e) {
                System.assert(e.getMessage().contains('Say why'), e.getMessage());
            }
        }
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM Emergency_Escalation__c],
            'Nothing may be recorded until a reason exists');
    }

    @IsTest
    static void recordsWhoRaisedItAndOnWhoseAccount() {
        Human_Handoff__c h = handoff(false);
        Test.startTest();
        Emergency_Escalation__c e = CurbCutEmergency.raise(h.Id,
            'A family member rang, worried they have not heard anything for two days.',
            'Safeguarding lead', 'A family member', 'No', '+1 555 0100');
        Test.stopTest();
        Emergency_Escalation__c saved = [
            SELECT Reason__c, Squad__c, Caller_Relationship__c, Person_Knows__c,
                   Raised_By_Name__c, Raised_At__c, Callback_Number__c, Barrier_Report__c
            FROM Emergency_Escalation__c WHERE Id = :e.Id];
        System.assertEquals('A family member', saved.Caller_Relationship__c);
        System.assertEquals('No', saved.Person_Knows__c,
            'Acting about someone who does not know must be recorded as such');
        System.assertNotEquals(null, saved.Raised_By_Name__c, 'A name must be on it');
        System.assertNotEquals(null, saved.Barrier_Report__c,
            'The escalation must stay tied to the person it concerns');
    }

    /** A call is a contact, and belongs in the same ledger as every other one. */
    @IsTest
    static void everyEscalationLandsInTheDeliveryLedger() {
        Human_Handoff__c h = handoff(false);
        Test.startTest();
        CurbCutEmergency.raise(h.Id,
            'Safeguarding concern raised by a colleague this afternoon.',
            'Safeguarding lead', 'A colleague or manager', 'Unknown', null);
        Test.stopTest();
        Message_Log__c m = [SELECT Channel__c, Direction__c, Status__c, Detail__c
                            FROM Message_Log__c LIMIT 1];
        System.assertEquals('Voice', m.Channel__c);
        System.assertEquals('Escalated', m.Status__c);
    }

    /** The flag is not advisory, and the record has to say so. */
    @IsTest
    static void aPersonWhoCannotTakeCallsIsFlaggedOnTheEscalationItself() {
        Human_Handoff__c h = handoff(true);
        Test.startTest();
        CurbCutEmergency.Context c = CurbCutEmergency.context(h.Id);
        CurbCutEmergency.raise(h.Id,
            'Family member called the office line asking us to check on them.',
            'Safeguarding lead', 'A family member', 'No', null);
        Test.stopTest();
        System.assertEquals(true, c.neverCall,
            'The component must be told this person cannot take a call');
        Message_Log__c m = [SELECT Detail__c FROM Message_Log__c LIMIT 1];
        System.assert(m.Detail__c.contains('cannot take calls'),
            'The ledger must record that the person could not be called: ' + m.Detail__c);
    }

    /** A number borrowed for an emergency is not a number collected. */
    @IsTest
    static void closingClearsTheCallbackNumber() {
        Human_Handoff__c h = handoff(false);
        Emergency_Escalation__c e = CurbCutEmergency.raise(h.Id,
            'Family member rang the main line and left a number to call back on.',
            'Safeguarding lead', 'A family member', 'Yes', '+1 555 0199');
        Test.startTest();
        CurbCutEmergency.close(e.Id, 'Spoke to the duty officer, no further action.');
        Test.stopTest();
        Emergency_Escalation__c after = [
            SELECT Callback_Number__c, Closed_At__c, Outcome__c
            FROM Emergency_Escalation__c WHERE Id = :e.Id];
        System.assertEquals(null, after.Callback_Number__c,
            'The number goes when the emergency does');
        System.assertNotEquals(null, after.Closed_At__c);
    }
}
