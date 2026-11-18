/**
 * The way back to the same person, on every door the promise names.
 *
 * The web hands an anonymous person a code and says: send it here, or by
 * text, or by email, and you land straight back with the same person. For as
 * long as that sentence has been on the page, nothing redeemed it. These tests
 * hold each door to it, and hold the code to what a bearer secret must be:
 * it opens one handoff, says one name back, and tells whoever is holding it
 * nothing else at all.
 */
@IsTest
private class CurbCutReturnTest {

    private static final String THEIR_WORDS = 'I keep missing things in meetings';

    @TestSetup
    static void library() {
        insert new Accommodation_Option__c(
            Option__c = 'Captions turned on in all meetings',
            Plain_Language_Summary__c = 'Live captions on by default in every meeting.',
            Zero_Cost__c = true, Source_URL__c = 'https://askjan.org/topics/costs.cfm');
    }

    /** A person asks on the web, with words on record, and is handed a code. */
    private static CurbCutWeb.Reply askedOnTheWeb() {
        CurbCutWeb.Reply consulted = CurbCutWeb.consult(THEIR_WORDS);
        CurbCutWeb.Reply asked = CurbCutWeb.human(THEIR_WORDS, consulted.barrierId);
        System.assert(asked.created, 'setup: the handoff must be created: ' + asked.message);
        System.assert(String.isNotBlank(asked.claimCode), 'setup: a code must be handed out');
        return asked;
    }

    private static Human_Handoff__c only() {
        return [SELECT Id, Returned_At__c, Reachable_By__c, Handler_Name__c,
                       Requested_At__c, Picked_Up_At__c, Barrier_Report__c
                  FROM Human_Handoff__c LIMIT 1];
    }

    private static void setKey() {
        insert new Curb_Cut_Secret__c(SetupOwnerId = UserInfo.getOrganizationId(),
            Key__c = EncodingUtil.base64Encode(Crypto.generateAesKey(256)));
    }

    /** The code is a bearer secret. Nothing of the request may come back with it. */
    private static void assertRevealsNothing(String said, String code, Human_Handoff__c h) {
        System.assert(!said.containsIgnoreCase(code), 'The code was said back: ' + said);
        System.assert(!said.contains(String.valueOf(h.Id)), 'The handoff id was handed back');
        if (h.Barrier_Report__c != null) {
            System.assert(!said.contains(String.valueOf(h.Barrier_Report__c)),
                'The barrier report id was handed back');
        }
        System.assert(!said.containsIgnoreCase('meetings'),
            'Their earlier words were handed to whoever holds the code: ' + said);
    }

    // ---- the web ----------------------------------------------------------

    @IsTest
    static void theWebTakesThemBackToTheSameHandler() {
        CurbCutWeb.Reply asked = askedOnTheWeb();
        update new Human_Handoff__c(Id = only().Id, Handler_Name__c = 'Priya');
        Integer reports = [SELECT COUNT() FROM Barrier_Report__c];

        Test.startTest();
        CurbCutWeb.Reply back = CurbCutWeb.consult(asked.claimCode);
        Test.stopTest();

        Human_Handoff__c h = only();
        System.assertEquals('RETURN', back.intent);
        System.assertNotEquals(null, h.Returned_At__c, 'The record must say they came back');
        System.assertEquals('Web chat', h.Reachable_By__c);
        System.assert(back.message.startsWith('Welcome back. Priya still has your request.'),
            'It must name the same handler: ' + back.message);
        System.assert(back.message.contains('no way to reach you'),
            'The page cannot carry a reply, so it must say where one can come: ' + back.message);
        System.assertEquals(1, [SELECT COUNT() FROM Human_Handoff__c], 'No second handoff');
        System.assertEquals(reports, [SELECT COUNT() FROM Barrier_Report__c],
            'A code is not a need and must not be written down as one');
        System.assertEquals(null, back.barrierId);
        System.assertEquals(null, back.claimCode);
        assertRevealsNothing(JSON.serialize(back), asked.claimCode, h);
    }

    /** The person button sends whatever is in the box. With their code in it, that is their person. */
    @IsTest
    static void thePersonButtonWithACodeIsTheSamePersonNotANewOne() {
        CurbCutWeb.Reply asked = askedOnTheWeb();
        Test.startTest();
        CurbCutWeb.Reply again = CurbCutWeb.human('my code is ' + asked.claimCode, null);
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM Human_Handoff__c],
            'A second stranger would break the promise the first handoff made');
        System.assertNotEquals(null, only().Returned_At__c);
        System.assert(String.isBlank(again.claimCode), 'No new code is handed out');
    }

    /** Somebody who cannot see the handoff, which is every visitor, must still be able to come back. */
    @IsTest
    static void aVisitorWhoCannotReadTheHandoffCanStillComeBack() {
        CurbCutWeb.Reply asked = askedOnTheWeb();
        User u;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
            u = new User(
                FirstName = 'Curb', LastName = 'Visitor',
                Alias = 'ccback', Email = 'curbcut.back@example.invalid',
                Username = 'curbcut.back.' + DateTime.now().getTime() + '@example.invalid',
                ProfileId = p.Id, TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US');
            insert u;
            insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId =
                [SELECT Id FROM PermissionSet WHERE Name = 'Curb_Cut_Guest' LIMIT 1].Id);
        }
        CurbCutWeb.Reply back;
        Test.startTest();
        System.runAs(u) {
            back = CurbCutWeb.consult(asked.claimCode);
        }
        Test.stopTest();
        System.assertEquals('RETURN', back.intent, back.message);
        System.assert(back.message.startsWith('Welcome back.'), back.message);
        System.assertNotEquals(null, only().Returned_At__c);
    }

    // ---- text, Slack and the relays ---------------------------------------

    @IsTest
    static void aTextWithTheCodeLandsWithTheSameHandler() {
        CurbCutWeb.Reply asked = askedOnTheWeb();
        Test.startTest();
        CurbCutChannelApi.Answer a = CurbCutChannelApi.handle('SMS', asked.claimCode, 'relay-hash-1', null);
        Test.stopTest();
        Human_Handoff__c h = only();
        System.assertEquals('RETURN', a.intent);
        System.assertEquals('Text message', h.Reachable_By__c,
            'The handler must answer where they are now');
        System.assertNotEquals(null, h.Returned_At__c);
        System.assertEquals('the access team', a.handlerName);
        System.assert(a.message.startsWith('Welcome back. The access team still has your request.'),
            a.message);
        System.assert(a.message.contains('They will answer you here.'), a.message);
        System.assertEquals(null, a.barrierId, 'The earlier report is not handed back');
        assertRevealsNothing(JSON.serialize(a), asked.claimCode, h);
        // The ledger holds the fact, by hash, and not the code.
        for (Message_Log__c m : [SELECT Detail__c, Recipient_Hash__c FROM Message_Log__c
                                  WHERE Channel__c = 'SMS']) {
            System.assert(m.Recipient_Hash__c == null || !m.Recipient_Hash__c.contains('relay-hash'),
                'Never the handle itself');
            System.assert(m.Detail__c == null || !m.Detail__c.containsIgnoreCase(asked.claimCode),
                'Never the code');
        }
        Integer returned = 0;
        for (Message_Log__c m : [SELECT Detail__c FROM Message_Log__c WHERE Channel__c = 'SMS']) {
            if (m.Detail__c == 'returned to a handoff') { returned++; }
        }
        System.assertEquals(1, returned, 'The ledger says they came back, once');
    }

    @IsTest
    static void slackAndHumanWithACodeAreTheSamePersonToo() {
        CurbCutWeb.Reply asked = askedOnTheWeb();
        Test.startTest();
        CurbCutChannelApi.Answer a = CurbCutChannelApi.handle('Slack', 'human ' + asked.claimCode,
                                                             'slack-hash-1', null);
        Test.stopTest();
        System.assertEquals('RETURN', a.intent, 'HUMAN with their code is their person: ' + a.message);
        System.assertEquals(false, a.handedOff, 'No new handoff was made');
        System.assertEquals(1, [SELECT COUNT() FROM Human_Handoff__c]);
        System.assertEquals('Slack', only().Reachable_By__c);
    }

    /** A voice or MCP door holds no number, so nothing false is written and nothing false is said. */
    @IsTest
    static void aDoorThatCannotReplySaysWhereTheAnswerWillCome() {
        CurbCutWeb.Reply asked = askedOnTheWeb();
        Test.startTest();
        CurbCutChannelApi.Answer a = CurbCutChannelApi.handle('External', asked.claimCode, null, null, 'Voice');
        Test.stopTest();
        Human_Handoff__c h = only();
        System.assertNotEquals(null, h.Returned_At__c);
        System.assertEquals('Web chat', h.Reachable_By__c,
            'A voice call has no true picklist value, so the old one stays');
        System.assert(!a.message.contains('answer you here'), a.message);
        System.assert(a.message.contains(System.Label.CurbCut_Support_Email), a.message);
    }

    // ---- email --------------------------------------------------------------

    @IsTest
    static void anEmailWithTheCodeInASentenceLandsWithTheSameHandler() {
        CurbCutWeb.Reply asked = askedOnTheWeb();
        Integer reports = [SELECT COUNT() FROM Barrier_Report__c];
        Messaging.InboundEmail e = new Messaging.InboundEmail();
        e.subject = 'my request';
        e.plainTextBody = 'Hi,\n\nMy code is ' + asked.claimCode.toLowerCase()
                        + '. Has anything happened yet?\n\nSent from my phone';
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        env.fromAddress = 'someone@example.com';

        Test.startTest();
        Messaging.InboundEmailResult r = new CurbCutEmail().handleInboundEmail(e, env);
        Test.stopTest();

        Human_Handoff__c h = only();
        System.assertEquals(true, r.success);
        System.assertNotEquals(null, h.Returned_At__c);
        System.assertEquals('Email', h.Reachable_By__c);
        System.assertEquals(reports, [SELECT COUNT() FROM Barrier_Report__c],
            'What they wrote around the code is not kept');
        String said = CurbCutEmail.lastReply;
        System.assert(said.contains('The access team still has your request'), said);
        System.assert(said.contains('I only passed on that you came back'),
            'They wrote more than the code, so they are told it was not passed on: ' + said);
        assertRevealsNothing(said, asked.claimCode, h);
        for (Message_Log__c m : [SELECT Recipient_Hash__c FROM Message_Log__c WHERE Channel__c = 'Email']) {
            System.assert(m.Recipient_Hash__c == null || !m.Recipient_Hash__c.contains('@'),
                'Never the address itself');
        }
    }

    // ---- either side of the key, and however it is typed ---------------------

    @IsTest
    static void codesFromBeforeAndAfterTheKeyBothLeadBack() {
        CurbCutWeb.Reply before = CurbCutWeb.human('', null);
        setKey();
        CurbCutWeb.Reply after = CurbCutWeb.human('', null);
        Test.startTest();
        CurbCutChannelApi.Answer oldOne = CurbCutChannelApi.handle('SMS', before.claimCode, 'h-1', null);
        CurbCutChannelApi.Answer newOne = CurbCutChannelApi.handle('Email', after.claimCode, 'h-2', null);
        Test.stopTest();
        System.assertEquals('RETURN', oldOne.intent, 'A code from before the key: ' + oldOne.message);
        System.assertEquals('RETURN', newOne.intent, 'A code from after the key: ' + newOne.message);
        System.assert(oldOne.message.startsWith('Welcome back.'), oldOne.message);
        System.assert(newOne.message.startsWith('Welcome back.'), newOne.message);
        Map<String, Integer> byChannel = new Map<String, Integer>();
        for (Human_Handoff__c h : [SELECT Reachable_By__c FROM Human_Handoff__c
                                    WHERE Returned_At__c != null]) {
            byChannel.put(h.Reachable_By__c, 1);
        }
        System.assertEquals(new Set<String>{ 'Text message', 'Email' }, byChannel.keySet(),
            'Each code leads to its own handoff');
    }

    @IsTest
    static void lowerCaseAndSpacedCodesStillLeadBack() {
        CurbCutWeb.Reply asked = askedOnTheWeb();
        String c = asked.claimCode;
        List<String> ways = new List<String>{
            '  ' + c.toLowerCase() + '  ',
            c.left(3) + ' ' + c.right(3),
            String.join(c.toLowerCase().split(''), ' '),
            'Hi, it\'s me again. My code is ' + c.left(3).toLowerCase() + '-' + c.right(3) + '. Thanks'
        };
        Test.startTest();
        for (String w : ways) {
            CurbCutWeb.Reply back = CurbCutWeb.consult(w);
            System.assertEquals('RETURN', back.intent, 'Not recognised: "' + w + '": ' + back.message);
            System.assert(back.message.startsWith('Welcome back.'), w + ': ' + back.message);
            System.assert(!back.message.contains('only passed on'),
                'Nothing but a greeting came with it: ' + back.message);
        }
        Test.stopTest();
    }

    // ---- a code that leads nowhere ------------------------------------------

    @IsTest
    static void anUnknownCodeResumesNothingAndRevealsNothing() {
        CurbCutWeb.Reply asked = askedOnTheWeb();
        // One letter off the real one, and one that was never ours.
        String c = asked.claimCode;
        String nearMiss = c.left(5) + (c.right(1) == '7' ? '8' : '7');
        Integer reports = [SELECT COUNT() FROM Barrier_Report__c];

        Test.startTest();
        CurbCutWeb.Reply near = CurbCutWeb.consult(nearMiss);
        CurbCutWeb.Reply never = CurbCutWeb.consult('ZZZ7ZZ');
        CurbCutChannelApi.Answer bySms = CurbCutChannelApi.handle('SMS', 'my code is zzz7zz', 'h-9', null);
        Test.stopTest();

        System.assertEquals(null, only().Returned_At__c, 'Nothing may be resumed');
        System.assertEquals('Web chat', only().Reachable_By__c, 'Nothing may be moved');
        System.assertEquals(near.message, never.message,
            'A near miss and a stranger\'s guess must get the same answer');
        System.assertEquals(near.message, bySms.message, 'And the same answer on every door');
        System.assert(String.isBlank(near.handlerName), 'No handler is named for a wrong code');
        System.assert(!near.message.containsIgnoreCase('access team'), near.message);
        System.assertEquals(reports, [SELECT COUNT() FROM Barrier_Report__c],
            'A mistyped code must not be written into a barrier report');
        System.assertEquals(1, [SELECT COUNT() FROM Human_Handoff__c]);
    }

    /** A word that happens to look like a code is still somebody's need. */
    @IsTest
    static void aNeedThatContainsACodeShapedWordIsStillANeed() {
        CurbCutWeb.Reply asked = askedOnTheWeb();
        Test.startTest();
        CurbCutChannelApi.Answer sentence = CurbCutChannelApi.handle('Slack',
            'I need a change to how much I travel for work', 'h-3', null);
        CurbCutChannelApi.Answer word = CurbCutChannelApi.handle('Slack', 'travel', 'h-4', null);
        Test.stopTest();
        System.assertEquals('NONE', sentence.intent, sentence.message);
        System.assertNotEquals(null, sentence.barrierId, 'The need must still be logged');
        System.assertEquals('NONE', word.intent, 'A bare word is not a code: ' + word.message);
        System.assertEquals(null, only().Returned_At__c);
    }

    // ---- the control words keep their meaning ---------------------------------

    @IsTest
    static void offWithAClaimCodeStillTurnsAPreferenceOff() {
        CurbCutWeb.Reply saved = CurbCutWeb.saveStanding(
            'I need captions on every call', 'Always', 'Manager only', false);
        CurbCutWeb.Reply asked = askedOnTheWeb();
        Test.startTest();
        // A claim code sent as a code is not a way back, and must not open a handoff.
        CurbCutChannelApi.Answer bare = CurbCutChannelApi.handle('SMS', 'my code is ' + saved.claimCode, 'h-5', null);
        // A return code with OFF is answered as OFF, as it always was.
        CurbCutChannelApi.Answer offReturn = CurbCutChannelApi.handle('SMS', 'OFF ' + asked.claimCode, 'h-5', null);
        CurbCutChannelApi.Answer off = CurbCutChannelApi.handle('SMS', 'OFF ' + saved.claimCode, 'h-5', null);
        Test.stopTest();
        System.assertNotEquals('RETURN', off.intent);
        System.assertEquals('OFF', off.intent);
        System.assertNotEquals(null,
            [SELECT Revoked_On__c FROM Access_Preference__c LIMIT 1].Revoked_On__c,
            'OFF with a claim code must still revoke');
        System.assertEquals('OFF', offReturn.intent);
        System.assertEquals('RETURN', bare.intent, 'A code is answered as a code: ' + bare.message);
        System.assert(bare.message.contains('WHO or OFF'),
            'Somebody holding a claim code is told what to send with it: ' + bare.message);
        System.assertEquals(null, only().Returned_At__c,
            'Neither a claim code nor OFF may resume a handoff');
    }

    @IsTest
    static void stopHelpAndHumanKeepTheirMeaning() {
        CurbCutWeb.Reply asked = askedOnTheWeb();
        Test.startTest();
        CurbCutChannelApi.Answer stop = CurbCutChannelApi.handle('SMS', 'STOP ' + asked.claimCode, 'h-6', null);
        CurbCutChannelApi.Answer help = CurbCutChannelApi.handle('SMS', 'help', 'h-6', null);
        CurbCutChannelApi.Answer human = CurbCutChannelApi.handle('SMS', 'human ZZZ7ZZ', 'h-6', null);
        Test.stopTest();
        System.assertEquals('STOP', stop.intent, 'STOP is the carrier\'s, code or not');
        System.assertEquals('HELP', help.intent);
        System.assertEquals('HUMAN', human.intent,
            'HUMAN with a code that leads nowhere still gets a person');
        System.assert(human.handedOff);
        System.assertEquals(2, [SELECT COUNT() FROM Human_Handoff__c]);
        System.assertEquals(0, [SELECT COUNT() FROM Human_Handoff__c WHERE Returned_At__c != null]);
    }

    // ---- what the person on duty sees -----------------------------------------

    @IsTest
    static void theHandlerSeesThemFirstAndTheQueueKeepsTheirPlace() {
        CurbCutWeb.Reply asked = askedOnTheWeb();
        Datetime first = only().Requested_At__c;
        Test.startTest();
        CurbCutChannelApi.handle('SMS', asked.claimCode, 'h-7', null);
        Test.stopTest();

        CurbCutAssist.Answer plan = CurbCutAssist.nextSteps(only().Id);
        System.assertEquals('back', plan.steps[0].id, 'Coming back goes above everything else');
        System.assertEquals('urgent', plan.steps[0].tone);
        System.assert(plan.steps[0].why.contains('do not ask them to explain it again'),
            plan.steps[0].why);

        // Not picked up yet, so still waiting, with the time they first asked:
        // oldest first means coming back never sends anyone to the back.
        System.assertEquals(first, only().Requested_At__c);
        System.assertEquals(1, CurbCutConsole.triage().waiting);
    }

    @IsTest
    static void aHandoffAlreadyTakenStaysWithWhoeverTookIt() {
        CurbCutWeb.Reply asked = askedOnTheWeb();
        CurbCutConsole.pickUp(only().Id, 'Sam');
        Datetime taken = only().Picked_Up_At__c;
        Test.startTest();
        CurbCutChannelApi.Answer a = CurbCutChannelApi.handle('SMS', asked.claimCode, 'h-8', null);
        Test.stopTest();
        Human_Handoff__c h = only();
        System.assertEquals('Sam', h.Handler_Name__c, 'The same person, not whoever is next');
        System.assertEquals(taken, h.Picked_Up_At__c, 'When it was taken is not rewritten');
        System.assert(a.message.startsWith('Welcome back. Sam still has your request.'), a.message);
    }
}
