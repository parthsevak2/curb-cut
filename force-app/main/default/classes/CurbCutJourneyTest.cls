/**
 * End-to-end journeys, run as a user who holds ONLY the guest permission set.
 *
 * Every serious bug in this project has been a permission or sharing bug, and
 * every one of them passed the unit tests, because the unit tests run as an
 * administrator who can see everything. The library was invisible to the agent
 * for an afternoon. Requests lost their provenance link. Standing preferences
 * could be switched on and not off. None of that is visible from the inside.
 *
 * So these walk the whole journey as somebody who has been granted only what a
 * visitor is granted, and assert the outcome the visitor would actually get.
 */
@IsTest
private class CurbCutJourneyTest {


    /**
     * Assert that text does not OFFER a thing, rather than that it never says
     * the word. This distinction has now cost two tests. "You will not have to
     * call anyone" is the promise; a test banning the word "call" fails the
     * sentence that keeps it. Same for "I am not sharing a diagnosis". The
     * product names what it refuses, on purpose, so the assertion has to be
     * about the offer and not the vocabulary.
     */
    private static void assertDoesNotOffer(String text, List<String> offers, String what) {
        String t = text.toLowerCase();
        for (String phrase : offers) {
            System.assert(!t.contains(phrase),
                what + ' — found "' + phrase + '" in: ' + text);
        }
    }

    private static User restricted() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
        User u = new User(
            FirstName = 'Curb', LastName = 'Visitor',
            Alias = 'ccvis', Email = 'curbcut.visitor@example.invalid',
            Username = 'curbcut.visitor.' + DateTime.now().getTime() + '@example.invalid',
            ProfileId = p.Id, TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US');
        insert u;
        PermissionSet ps = [SELECT Id FROM PermissionSet
                            WHERE Name = 'Curb_Cut_Guest' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
        return u;
    }

    @TestSetup
    static void library() {
        insert new List<Accommodation_Option__c>{
            new Accommodation_Option__c(
                Option__c = 'Alternative or ergonomic keyboard',
                Plain_Language_Summary__c = 'A keyboard shaped to make typing easier or less painful.',
                Zero_Cost__c = true, Source_URL__c = 'https://askjan.org/topics/costs.cfm'),
            new Accommodation_Option__c(
                Option__c = 'Quiet space to work',
                Plain_Language_Summary__c = 'Somewhere with less noise to do focused work.',
                Zero_Cost__c = true, Source_URL__c = 'https://askjan.org/topics/costs.cfm')
        };
    }

    /**
     * The whole reason the web front door exists: no phone, no account, no name.
     * Ask, get grounded options, approve, and have the request actually exist
     * with the link back to what was said.
     */
    @IsTest
    static void aVisitorCanGoFromStuckToRequestWithoutAnAccount() {
        User u = restricted();
        System.runAs(u) {
            Test.startTest();
            CurbCutWeb.Reply consulted = CurbCutWeb.consult('I cannot type for long');
            System.assertEquals(false, consulted.noMatch,
                'The library was invisible to a visitor. That has happened before.');
            System.assert(consulted.options.contains('keyboard'),
                'Grounded options must reach a visitor: ' + consulted.options);
            System.assertNotEquals(null, consulted.barrierId,
                'What they said must be recorded so the request can point back at it');

            CurbCutWeb.Reply drafted = CurbCutWeb.draft('I cannot type for long', null);
            System.assert(String.isNotBlank(drafted.draft), 'Nothing was drafted');
            // It must REFUSE to disclose, which means it does say the word.
            assertDoesNotOffer(drafted.draft,
                new List<String>{'my diagnosis', 'i have been diagnosed', 'my condition is',
                                 'diagnosed with', 'i suffer from'},
                'The draft disclosed a condition');
            System.assert(drafted.draft.containsIgnoreCase('not sharing a diagnosis'),
                'The draft must say plainly that no diagnosis is being shared: ' + drafted.draft);

            CurbCutWeb.Reply sent = CurbCutWeb.send(drafted.draft, true, consulted.barrierId);
            Test.stopTest();
            System.assertEquals(true, sent.created, 'The request was not created: ' + sent.message);
        }

        Accommodation_Request__c ar = [
            SELECT Person_Approved__c, Barrier_Report__c, Interactive_Process_Due__c
            FROM Accommodation_Request__c ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals(true, ar.Person_Approved__c);
        System.assertNotEquals(null, ar.Barrier_Report__c,
            'Provenance was lost. Every web request lost it once already.');
        System.assertNotEquals(null, ar.Interactive_Process_Due__c,
            'A request with no clock is a request nobody has to answer');
    }

    /** A hedge is not a yes, and the refusal must survive the permission model. */
    @IsTest
    static void aVisitorCannotAccidentallySendWithoutSayingYes() {
        User u = restricted();
        System.runAs(u) {
            Test.startTest();
            CurbCutWeb.Reply r = CurbCutWeb.send('please give me a keyboard', false, null);
            Test.stopTest();
            System.assertEquals(false, r.created, 'Sent without approval');
            System.assert(r.message.containsIgnoreCase('not said yes'),
                'The refusal must explain itself: ' + r.message);
        }
        System.assertEquals(0, [SELECT COUNT() FROM Accommodation_Request__c]);
    }

    /**
     * Principle 4 from a browser. The asymmetry to guard against is being able
     * to switch a disclosure ON and not OFF.
     */
    @IsTest
    static void aVisitorCanSwitchAPreferenceOnAndAlsoOffAgain() {
        User u = restricted();
        Id prefId;
        System.runAs(u) {
            Test.startTest();
            CurbCutWeb.Reply saved = CurbCutWeb.saveStanding(
                'Please face me when you speak.', 'Meetings', 'Meeting hosts', true);
            System.assertEquals(true, saved.created, 'Could not save: ' + saved.message);
            System.assert(saved.message.contains('OFF'),
                'A visitor must be told the way off, and it is OFF, never STOP');
            System.assert(!saved.message.contains('STOP'),
                'STOP is the carrier keyword and would cost them the service');
            prefId = saved.preferenceId;

            CurbCutWeb.Reply who = CurbCutWeb.whoSaw(prefId);
            System.assertEquals(0, who.shownCount, 'Nobody has been shown it yet');

            CurbCutWeb.Reply off = CurbCutWeb.revokeStanding(prefId);
            Test.stopTest();
            System.assertEquals(true, off.created, 'Could not turn it off: ' + off.message);
        }
        Access_Preference__c p = [SELECT Revoked_On__c FROM Access_Preference__c
                                  WHERE Id = :prefId];
        System.assertNotEquals(null, p.Revoked_On__c,
            'Switching a disclosure on but not off is the worst possible asymmetry');
    }

    /** Signed video, from a visitor, must summon a person and keep its flag. */
    @IsTest
    static void aVisitorSendingSignedVideoGetsAPersonAndKeepsTheirInterpreter() {
        User u = restricted();
        System.runAs(u) {
            Test.startTest();
            CurbCutMedia.Result v = CurbCutMedia.send(
                null, 'signed.mp4', EncodingUtil.base64Encode(Blob.valueOf('v')), 'Video');
            System.assertEquals(true, v.accepted, 'Video refused: ' + v.message);
            System.assertEquals(true, v.interpreter);
            CurbCutMedia.Result photo = CurbCutMedia.send(
                v.barrierId, 'desk.jpg', EncodingUtil.base64Encode(Blob.valueOf('p')), 'Image');
            Test.stopTest();
            System.assertEquals(true, photo.accepted);

            Barrier_Report__c br = [SELECT Interpreter_Needed__c FROM Barrier_Report__c
                                    WHERE Id = :v.barrierId];
            System.assertEquals(true, br.Interpreter_Needed__c,
                'A later photo stripped their interpreter');
        }
        System.assertEquals(1, [SELECT COUNT() FROM Human_Handoff__c],
            'Signed video must raise a person the moment it lands');
    }

    /** Asking for a person must work at any point, including as the first act. */
    @IsTest
    static void aVisitorCanAskForAPersonWithoutExplainingWhy() {
        User u = restricted();
        System.runAs(u) {
            Test.startTest();
            CurbCutWeb.Reply r = CurbCutWeb.human('', null);
            Test.stopTest();
            assertDoesNotOffer(r.message,
                new List<String>{'give us a call', 'call us', 'phone us', 'give me a call',
                                 'ring us', 'call this number', 'call the'},
                'Somebody was routed to a telephone');
            System.assert(r.message.containsIgnoreCase('will not have to call'),
                'The promise not to make them phone anyone must be stated: ' + r.message);
        }
        Human_Handoff__c h = [SELECT Reachable_By__c FROM Human_Handoff__c LIMIT 1];
        System.assertNotEquals('Phone', h.Reachable_By__c);
    }

    /** Every step a visitor takes must be answerable later with "did we reach them". */
    @IsTest
    static void everythingAVisitorDoesLandsInTheLedger() {
        User u = restricted();
        System.runAs(u) {
            Test.startTest();
            CurbCutWeb.consult('the open office is unbearable');
            Test.stopTest();
        }
        System.assert([SELECT COUNT() FROM Message_Log__c WHERE Channel__c = 'Web'] > 0,
            'The web channel was missing from the ledger once already');
    }
}
