/**
 * The words a person reaches for when the system has already failed them.
 *
 * Every assertion here maps to something that was broken in production copy:
 * HUMAN returned an ASL interpreter card, PERSON returned "face the person when
 * speaking", OFF returned "I do not have good information on that" while the
 * disclosure it was meant to withdraw stayed switched on.
 */
@IsTest
private class CurbCutKeywordTest {

    @IsTest
    static void everyAdvertisedControlWordRoutes() {
        Map<String, String> expect = new Map<String, String>{
            'HUMAN' => 'HUMAN', 'human' => 'HUMAN', 'Person' => 'HUMAN',
            'someone' => 'HUMAN', 'a real person' => 'HUMAN',
            'talk to someone' => 'HUMAN', 'I need a human' => 'HUMAN',
            'WHO' => 'WHO', 'who saw it' => 'WHO',
            'OFF' => 'OFF', 'turn it off' => 'OFF', 'stop sharing' => 'OFF',
            'HELP' => 'HELP', 'curb cut' => 'HELP',
            'STOP' => 'STOP', 'unsubscribe' => 'STOP', 'START' => 'START'
        };
        for (String said : expect.keySet()) {
            CurbCutKeyword.Match m = CurbCutKeyword.route(said);
            System.assertEquals(expect.get(said), m.intent,
                '"' + said + '" must route to ' + expect.get(said));
        }
    }

    /**
     * The failure that matters most in the other direction. If a control word
     * swallowed a real sentence, somebody describing a barrier would get a menu.
     */
    @IsTest
    static void realNeedsAreNeverMistakenForCommands() {
        for (String need : new List<String>{
                'I cannot type for long',
                'I need help typing for long periods',
                'Someone needs to take notes for me in meetings',
                'I want to stop working in an open plan office',
                'Who I report to keeps changing my hours',
                'my hearing aid whistles when I turn my head off to one side',
                'I need help reading long documents on screen'}) {
            CurbCutKeyword.Match m = CurbCutKeyword.route(need);
            System.assertEquals('NONE', m.intent,
                'a described need must never be read as a command: ' + need);
        }
    }

    @IsTest
    static void yesIsNotAControlWord() {
        // YES approves a draft. If the router claimed it, a person agreeing to
        // send their request would instead be resubscribed to text messages.
        System.assertEquals('NONE', CurbCutKeyword.route('yes').intent,
            'YES belongs to the draft exchange, not to the router');
    }

    @IsTest
    static void codeTravelsWithTheWord() {
        CurbCutKeyword.Match m = CurbCutKeyword.route('off 4KQ7MT');
        System.assertEquals('OFF', m.intent, 'OFF with a code is still OFF');
        System.assertEquals('4KQ7MT', m.code, 'the code must come back');
    }

    @IsTest
    static void codesAvoidCharactersPeopleMisread() {
        for (Integer i = 0; i < 40; i++) {
            String c = CurbCutKeyword.newCode();
            System.assertEquals(6, c.length(), 'codes are six characters');
            for (String bad : new List<String>{ 'O', '0', 'I', '1', 'S', '5' }) {
                System.assert(!c.contains(bad),
                    'a code must not contain ' + bad + ', which is misread: ' + c);
            }
        }
    }

    /** Withdrawal has to work from a channel where we hold no identity at all. */
    @IsTest
    static void offByCodeActuallyRevokes() {
        CurbCutWeb.Reply saved = CurbCutWeb.saveStanding(
            'I need captions on every call', 'Always', 'Manager only', true);
        System.assert(saved.created, 'setup: the preference must save');
        System.assertNotEquals(null, saved.claimCode, 'the person must be given a code');

        Test.startTest();
        CurbCutStanding.Result off =
            CurbCutStanding.byCode('revoke', saved.claimCode);
        Test.stopTest();

        System.assert(off.ok, 'OFF with a valid code must turn the sharing off');
        Access_Preference__c p = [SELECT Revoked_On__c FROM Access_Preference__c
                                   WHERE Id = :saved.preferenceId];
        System.assertNotEquals(null, p.Revoked_On__c,
            'the record itself must be revoked, not just the message');
    }

    /**
     * A wrong code and an already-revoked code get the same answer. Anything
     * else turns this into a way to test whether somebody else's code is live.
     */
    @IsTest
    static void aWrongCodeIsNotAnOracle() {
        CurbCutWeb.Reply saved = CurbCutWeb.saveStanding(
            'I work from home on Mondays', 'Always', 'Manager only', false);
        CurbCutStanding.byCode('revoke', saved.claimCode);

        String spent = CurbCutStanding.byCode('revoke', saved.claimCode).message;
        String wrong = CurbCutStanding.byCode('revoke', 'ZZZZZZ').message;
        System.assertEquals(wrong, spent,
            'a spent code and a wrong code must be indistinguishable');
    }

    @IsTest
    static void everyChannelSaysTheSameThing() {
        // The whole reason the router exists: one person, two channels, one
        // account of what just happened.
        CurbCutChannelApi.Answer sms =
            CurbCutChannelApi.handle('SMS', 'human', 'hash-a', null);
        CurbCutChannelApi.Answer slack =
            CurbCutChannelApi.handle('Slack', 'a real person', 'hash-b', null);
        System.assertEquals('HUMAN', sms.intent, 'SMS must route HUMAN');
        System.assertEquals('HUMAN', slack.intent, 'Slack must route HUMAN');
        System.assert(sms.handedOff, 'HUMAN must create a real handoff, not a promise');
        System.assert(slack.handedOff, 'HUMAN must create a real handoff on Slack too');
    }

    /** A handoff nobody can act on is not an escape hatch. */
    @IsTest
    static void handoffRepliesWhereThePersonWrote() {
        CurbCutChannelApi.handle('Email', 'human', 'hash-c', null);
        Human_Handoff__c hh = [SELECT Reachable_By__c FROM Human_Handoff__c
                                ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals('Email', hh.Reachable_By__c,
            'somebody who wrote in by email cannot be reached by text; '
            + 'this system holds no phone number');
    }

    @IsTest
    static void nobodyIsEverRoutedToATelephone() {
        CurbCutCreateHandoff.Request r = new CurbCutCreateHandoff.Request();
        r.context = 'test';
        r.reachableBy = 'Phone call';
        CurbCutCreateHandoff.create(new List<CurbCutCreateHandoff.Request>{ r });
        Human_Handoff__c hh = [SELECT Reachable_By__c FROM Human_Handoff__c
                                ORDER BY CreatedDate DESC LIMIT 1];
        System.assertNotEquals('Phone call', hh.Reachable_By__c,
            'a telephone must be refused in code, not merely discouraged');
    }

    /** A need still gets grounded options, on every channel. */
    @IsTest
    static void aNeedStillGetsOptions() {
        CurbCutChannelApi.Answer a =
            CurbCutChannelApi.handle('Slack', 'I cannot type for long', 'hash-d', null);
        System.assertEquals('NONE', a.intent, 'a need is not a command');
        System.assertNotEquals(null, a.barrierId, 'the barrier must be logged');
    }
}
