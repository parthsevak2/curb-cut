/**
 * The refusal tests are the important ones. A request that exists without the
 * person's yes is the failure this whole design is built to prevent.
 */
@IsTest
private class CurbCutActionsTest {

    private static CurbCutCreateRequest.Result createWith(Boolean approved, String draft) {
        CurbCutCreateRequest.Request r = new CurbCutCreateRequest.Request();
        r.approved = approved;
        r.draft = draft;
        return CurbCutCreateRequest.create(new List<CurbCutCreateRequest.Request>{ r })[0];
    }

    @IsTest
    static void refusesToCreateWithoutApproval() {
        Test.startTest();
        CurbCutCreateRequest.Result res = createWith(false, 'I need captions in meetings.');
        Test.stopTest();
        System.assertEquals(false, res.created, 'Must not create without approval');
        System.assertEquals('', res.requestId, 'No record may exist');
        System.assertEquals(0, [SELECT COUNT() FROM Accommodation_Request__c],
            'Nothing may be written without the person saying yes');
    }

    @IsTest
    static void refusesToCreateWhenApprovalIsNull() {
        CurbCutCreateRequest.Result res = createWith(null, 'I need captions in meetings.');
        System.assertEquals(false, res.created, 'Null is not a yes');
        System.assertEquals(0, [SELECT COUNT() FROM Accommodation_Request__c]);
    }

    @IsTest
    static void refusesToCreateWithNothingDrafted() {
        CurbCutCreateRequest.Result res = createWith(true, '   ');
        System.assertEquals(false, res.created, 'Approval of nothing is not a request');
        System.assertEquals(0, [SELECT COUNT() FROM Accommodation_Request__c]);
    }

    @IsTest
    static void createsOnExplicitApproval() {
        Test.startTest();
        CurbCutCreateRequest.Result res = createWith(true, 'I need captions in meetings.');
        Test.stopTest();
        System.assertEquals(true, res.created, 'Explicit yes must create the request');
        System.assert(String.isNotBlank(res.requestId), 'Expected an id back');

        Accommodation_Request__c ar = [
            SELECT Person_Approved__c, Manager_Response__c, Interactive_Process_Due__c
            FROM Accommodation_Request__c LIMIT 1];
        System.assertEquals(true, ar.Person_Approved__c, 'The person holds the pen');
        System.assertEquals('Pending', ar.Manager_Response__c);
        System.assertNotEquals(null, ar.Interactive_Process_Due__c,
            'The interactive process clock must start');
    }

    @IsTest
    static void badBarrierReportIdDoesNotCostThePersonTheirRequest() {
        CurbCutCreateRequest.Request r = new CurbCutCreateRequest.Request();
        r.approved = true;
        r.draft = 'I need written follow-up.';
        r.barrierReportId = 'not-an-id';
        CurbCutCreateRequest.Result res =
            CurbCutCreateRequest.create(new List<CurbCutCreateRequest.Request>{ r })[0];
        System.assertEquals(true, res.created, 'A bad id must not block the request');
    }

    @IsTest
    static void draftCarriesNoClinicalLanguageAndWritesNothing() {
        CurbCutDraftRequest.Request r = new CurbCutDraftRequest.Request();
        r.need = 'I miss things in meetings';
        r.chosenOption = 'Captions turned on in all meetings';
        Test.startTest();
        CurbCutDraftRequest.Result res =
            CurbCutDraftRequest.draft(new List<CurbCutDraftRequest.Request>{ r })[0];
        Test.stopTest();
        System.assert(res.draft.contains('I miss things in meetings'), 'Their words, kept');
        System.assert(res.draft.contains('Captions turned on in all meetings'));
        System.assert(res.draft.contains('not sharing a diagnosis'));
        System.assertEquals(0, [SELECT COUNT() FROM Accommodation_Request__c],
            'Drafting is not asking, and must write nothing');
    }

    @IsTest
    static void blankNeedDraftsNothing() {
        CurbCutDraftRequest.Request r = new CurbCutDraftRequest.Request();
        r.need = '  ';
        CurbCutDraftRequest.Result res =
            CurbCutDraftRequest.draft(new List<CurbCutDraftRequest.Request>{ r })[0];
        System.assertEquals('', res.draft);
    }

    @IsTest
    static void handoffIsAlwaysReachableByMessageNeverPhone() {
        CurbCutCreateHandoff.Request r = new CurbCutCreateHandoff.Request();
        r.context = 'I could not get anywhere with the form.';
        Test.startTest();
        CurbCutCreateHandoff.Result res =
            CurbCutCreateHandoff.create(new List<CurbCutCreateHandoff.Request>{ r })[0];
        Test.stopTest();
        System.assertEquals(true, res.created);
        System.assert(String.isNotBlank(res.handlerName), 'The person must be given a name');

        Human_Handoff__c hh = [SELECT Reachable_By__c, Requested_At__c, Handler_Name__c
                               FROM Human_Handoff__c LIMIT 1];
        System.assertEquals('Text message', hh.Reachable_By__c,
            'Nobody gets routed to a phone call');
        System.assertNotEquals(null, hh.Requested_At__c);
    }
}
