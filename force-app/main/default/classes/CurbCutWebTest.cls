/**
 * The web channel can create records, so it gets the same scrutiny as SMS.
 * The refusal tests matter most.
 */
@IsTest
private class CurbCutWebTest {

    @TestSetup
    static void seed() {
        insert new List<Accommodation_Option__c>{
            new Accommodation_Option__c(
                Option__c = 'Captions turned on in all meetings',
                Plain_Language_Summary__c = 'Live captions on by default in every meeting.',
                Zero_Cost__c = true, Source_URL__c = 'https://askjan.org/topics/costs.cfm')
        };
    }

    @IsTest
    static void consultLogsABarrierReportAnonymously() {
        Test.startTest();
        CurbCutWeb.Reply r = CurbCutWeb.consult('I keep missing things in meetings');
        Test.stopTest();

        System.assertEquals(false, r.noMatch, 'Should have matched captions');
        System.assert(r.options.contains('Captions'), 'Expected the captions option');
        System.assert(String.isNotBlank(r.barrierId), 'The web channel must log intake');

        Barrier_Report__c br = [SELECT Anonymous__c, Access_Profile__c FROM Barrier_Report__c LIMIT 1];
        System.assertEquals(true, br.Anonymous__c, 'Web intake is anonymous by default');
        System.assertEquals(null, br.Access_Profile__c, 'No identity may be attached');
    }

    @IsTest
    static void consultSaysSoRatherThanGuessing() {
        CurbCutWeb.Reply r = CurbCutWeb.consult('quantum sledgehammer procurement');
        System.assertEquals(true, r.noMatch);
        System.assertEquals('', r.options, 'Must return nothing rather than improvise');
        System.assert(r.message.contains('rather tell you that than guess'));
    }

    @IsTest
    static void blankNeedIsSafe() {
        CurbCutWeb.Reply r = CurbCutWeb.consult('   ');
        System.assertEquals(true, r.noMatch);
        System.assertEquals(0, [SELECT COUNT() FROM Barrier_Report__c],
            'A blank message must not create a record');
    }

    @IsTest
    static void draftWritesNothingOutward() {
        Test.startTest();
        CurbCutWeb.Reply r = CurbCutWeb.draft('I miss things in meetings', 'Captions turned on in all meetings');
        Test.stopTest();
        System.assert(r.draft.contains('I miss things in meetings'));
        System.assertEquals(0, [SELECT COUNT() FROM Accommodation_Request__c],
            'Drafting is not asking, and must create nothing');
    }

    @IsTest
    static void sendRefusesWithoutApproval() {
        Test.startTest();
        CurbCutWeb.Reply r = CurbCutWeb.send('I would like captions.', false, null);
        Test.stopTest();
        System.assertEquals(false, r.created, 'Must not create without approval');
        System.assertEquals(0, [SELECT COUNT() FROM Accommodation_Request__c]);
    }

    @IsTest
    static void sendRefusesWhenApprovalIsNull() {
        CurbCutWeb.Reply r = CurbCutWeb.send('I would like captions.', null, null);
        System.assertEquals(false, r.created, 'Null is not approval');
        System.assertEquals(0, [SELECT COUNT() FROM Accommodation_Request__c]);
    }

    @IsTest
    static void sendCreatesExactlyOneOnApproval() {
        Test.startTest();
        CurbCutWeb.Reply r = CurbCutWeb.send('I would like captions.', true, null);
        Test.stopTest();
        System.assertEquals(true, r.created);
        System.assertEquals(1, [SELECT COUNT() FROM Accommodation_Request__c],
            'Exactly one request, never two');
        System.assertEquals(true,
            [SELECT Person_Approved__c FROM Accommodation_Request__c LIMIT 1].Person_Approved__c);
    }

    @IsTest
    static void humanHandoffIsReachableByMessage() {
        Test.startTest();
        CurbCutWeb.Reply r = CurbCutWeb.human('I could not get anywhere with this', null);
        Test.stopTest();
        System.assertEquals(true, r.created);
        System.assert(String.isNotBlank(r.handlerName), 'The person must be given a name');
        // Assert on OFFERING a call, not on the word. The correct message contains
        // "you will not have to call anyone" -- a promise, not a phone number.
        String m = r.message.toLowerCase();
        System.assert(!m.contains('call us') && !m.contains('call you')
                   && !m.contains('give us a call') && !m.contains('phone number'),
            'The web channel must never offer a phone route: ' + r.message);
        System.assert(m.contains('message'),
            'The handoff must say they will be reached by message: ' + r.message);
        System.assertEquals('Text message',
            [SELECT Reachable_By__c FROM Human_Handoff__c LIMIT 1].Reachable_By__c);
    }

    @IsTest
    static void wholeJourneyEndToEnd() {
        CurbCutWeb.Reply c = CurbCutWeb.consult('I keep missing things in meetings');
        CurbCutWeb.Reply d = CurbCutWeb.draft('I keep missing things in meetings', 'Captions turned on in all meetings');
        Test.startTest();
        CurbCutWeb.Reply s = CurbCutWeb.send(d.draft, true, c.barrierId);
        Test.stopTest();
        System.assertEquals(true, s.created);
        Accommodation_Request__c ar = [SELECT Barrier_Report__c FROM Accommodation_Request__c LIMIT 1];
        System.assertEquals(c.barrierId, ar.Barrier_Report__c,
            'The request must be linked to the intake it came from');
        System.assertNotEquals(null, ar.Barrier_Report__c,
            'Provenance must survive: every web request was losing this link');
    }
}
