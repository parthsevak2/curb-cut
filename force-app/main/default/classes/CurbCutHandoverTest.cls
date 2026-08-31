/**
 * The refusal tests are the important ones. A handover that succeeds when it
 * should not is a disclosure the person did not make and cannot take back.
 */
@IsTest
private class CurbCutHandoverTest {

    private static Accommodation_Request__c make(Boolean approved, Boolean withWords) {
        Barrier_Report__c br = new Barrier_Report__c(
            Functional_Description__c = withWords ? 'I cannot type for long' : null,
            Inbound_Modality__c = 'Text',
            Anonymous__c = true);
        insert br;
        Accommodation_Request__c ar = new Accommodation_Request__c(
            Person_Approved__c = approved,
            // Deliberately left null when unapproved: the validation rule stops
            // the record existing at all, so this is the only unapproved state
            // the handover can ever actually meet.
            Approved_At__c = approved ? System.now() : null,
            Manager_Response__c = 'Pending',
            Interactive_Process_Due__c = Date.today().addDays(10),
            Barrier_Report__c = br.Id);
        insert ar;
        return ar;
    }

    /** An approved record whose approval timestamp is missing. */
    private static Accommodation_Request__c withoutApprovalTime() {
        Accommodation_Request__c ar = make(true, true);
        ar.Approved_At__c = null;
        update ar;
        return ar;
    }

    /**
     * Consent is enforced twice, and this test exists to prove the first layer
     * makes the second unreachable. The database will not let an unapproved
     * request exist at all, so there is no stored state from which an
     * unapproved payload could ever be built. The check inside the handover is
     * defence in depth against a future where somebody relaxes the rule.
     */
    @IsTest
    static void theDatabaseWillNotEvenHoldAnUnapprovedRequest() {
        Test.startTest();
        try {
            make(false, true);
            System.assert(false, 'An unapproved request was allowed to exist');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('approved it themselves'),
                'Blocked for the wrong reason: ' + e.getMessage());
        }
        Test.stopTest();
    }

    /**
     * The reachable half of the same guarantee: approval with no record of when
     * it was given is not evidence of consent, and will not be treated as any.
     */
    @IsTest
    static void refusesWhenConsentHasNoTimestamp() {
        Accommodation_Request__c ar = withoutApprovalTime();
        try {
            CurbCutHandover.payloadFor(ar.Id);
            System.assert(false, 'Built a payload from an undated approval');
        } catch (CurbCutHandover.RefusedException e) {
            System.assert(e.getMessage().contains('not approved'),
                'Wrong refusal: ' + e.getMessage());
        }
    }

    @IsTest
    static void refusesWhenThereAreNoWordsOfTheirs() {
        Accommodation_Request__c ar = make(true, false);
        try {
            CurbCutHandover.payloadFor(ar.Id);
            System.assert(false, 'Sent an employer an empty request');
        } catch (CurbCutHandover.RefusedException e) {
            System.assert(e.getMessage().contains('empty request'),
                'Wrong refusal: ' + e.getMessage());
        }
    }

    @IsTest
    static void carriesTheirWordsAndTheirConsent() {
        Accommodation_Request__c ar = make(true, true);
        Test.startTest();
        String json = CurbCutHandover.payloadFor(ar.Id);
        Test.stopTest();
        System.assert(json.contains('I cannot type for long'), 'Lost the person\'s words');
        System.assert(json.contains('"consent"'), 'No consent block');
        System.assert(json.contains('a hedge was not accepted'), 'Consent mechanism not stated');
        System.assert(json.contains('never_by_telephone'), 'Did not state the channel rule');
    }

    /**
     * The allow-list is the whole design. If a field is added to the schema and
     * this test still passes, the field did not leak, which is the point.
     */
    @IsTest
    static void tellsTheRecipientWhatCannotBeAsked() {
        Accommodation_Request__c ar = make(true, true);
        String json = CurbCutHandover.payloadFor(ar.Id);
        System.assert(json.contains('must_not_ask'), 'No instruction to the recipient');
        System.assert(json.contains('no such field exists in this system'),
            'Did not state that the medical fields are absent rather than withheld');
        System.assert(json.contains('incomplete submission'),
            'Did not warn against treating missing medical detail as incomplete');
    }

    /**
     * Nothing about the person beyond what they said and agreed to may appear.
     * The internal handle in particular must never cross the boundary.
     */
    @IsTest
    static void leaksNothingElseAboutThePerson() {
        Accommodation_Request__c ar = make(true, true);
        String json = CurbCutHandover.payloadFor(ar.Id).toLowerCase();
        for (String forbidden : new List<String>{
                'person_handle', 'recipient_hash', 'anonymous__c', 'ownerid', 'createdbyid'}) {
            System.assert(!json.contains(forbidden),
                'Payload carried ' + forbidden + ', which is nobody else\'s business');
        }
    }

    @IsTest
    static void invocableRefusesGracefullyRatherThanThrowing() {
        Accommodation_Request__c ar = withoutApprovalTime();
        Test.startTest();
        List<String> out = CurbCutHandover.build(new List<Id>{ ar.Id });
        Test.stopTest();
        System.assertEquals(1, out.size());
        System.assert(out[0].contains('"refused" : true'),
            'A flow caller should get a refusal it can read, not an exception: ' + out[0]);
    }
}
