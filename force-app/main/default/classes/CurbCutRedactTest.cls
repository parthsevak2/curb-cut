/**
 * The privacy policy said a volunteered condition "is not written to any
 * record". It was written to Functional_Description__c, whole, every time.
 * These tests are the difference between that sentence being a claim and being
 * a fact.
 *
 * The same sentence was also false for Statement__c on a standing preference,
 * which is the one text built to be shown to a manager. And the word list was
 * wrong in two directions at once: "hearing aids" lost the word "aids", while
 * "autistic" was taken out as if it were a diagnosis. The later tests here pin
 * both corrections.
 */
@IsTest
private class CurbCutRedactTest {

    private static String stored(String said) {
        CurbCutIntake.Request r = new CurbCutIntake.Request();
        r.functionalDescription = said;
        r.inboundModality = 'Text';
        CurbCutIntake.Result res = CurbCutIntake.log(
            new List<CurbCutIntake.Request>{ r })[0];
        return [SELECT Functional_Description__c FROM Barrier_Report__c
                 WHERE Id = :res.barrierReportId].Functional_Description__c;
    }

    /** Saves a standing preference through the invocable entry point. */
    private static CurbCutStanding.Result standing(String said) {
        CurbCutStanding.Request r = new CurbCutStanding.Request();
        r.operation = 'save';
        r.statement = said;
        return CurbCutStanding.run(new List<CurbCutStanding.Request>{ r })[0];
    }

    private static String statementStored(CurbCutStanding.Result res) {
        System.assert(res.ok, 'the preference must save: ' + res.message);
        return [SELECT Statement__c FROM Access_Preference__c
                 WHERE Id = :res.preferenceId].Statement__c;
    }

    @IsTest
    static void aVolunteeredConditionNeverReachesTheDatabase() {
        Map<String, String> cases = new Map<String, String>{
            'I have multiple sclerosis and some days I cannot type for long' => 'sclerosis',
            'I was diagnosed with ADHD and I lose track in long meetings'    => 'adhd',
            'My Crohn\'s disease means I need to be near a bathroom'         => 'crohn',
            'I have epilepsy so strobing screens are a problem'              => 'epilepsy',
            'bipolar disorder makes early starts hard for me'                => 'bipolar'
        };
        for (String said : cases.keySet()) {
            String kept = stored(said);
            System.assert(!kept.containsIgnoreCase(cases.get(said)),
                'the condition must not be stored: ' + kept);
            System.assert(kept.contains(CurbCutRedact.MARK),
                'the removal must be visible in the record: ' + kept);
        }
    }

    /** The half that matters has to survive, or the redaction has broken intake. */
    @IsTest
    static void whatIsHardSurvivesTheRedaction() {
        String kept = stored('I have multiple sclerosis and some days I cannot type for long');
        System.assert(kept.containsIgnoreCase('cannot type for long'),
            'the functional description is the part we work from: ' + kept);
    }

    /**
     * Deaf, blind and hard of hearing are how people describe themselves, and
     * the interpreter routing reads them. Stripping them would be an insult and
     * a regression at the same time.
     */
    @IsTest
    static void identityAndFunctionAreLeftAlone() {
        for (String said : new List<String>{
                'I am Deaf and I need an interpreter for team meetings',
                'I am blind and I use a screen reader',
                'I am hard of hearing and miss things in open plan',
                'I cannot type for long because my hands hurt',
                'I use a wheelchair and the meeting rooms are upstairs'}) {
            String kept = stored(said);
            System.assertEquals(said, kept,
                'this must be stored exactly as the person wrote it: ' + kept);
        }
    }

    @IsTest
    static void thePersonIsToldInTheSameReply() {
        Test.startTest();
        CurbCutWeb.Reply r = CurbCutWeb.consult(
            'I have multiple sclerosis and some days I cannot type for long');
        Test.stopTest();
        System.assert(r.message.containsIgnoreCase('took it out'),
            'the person must be told their condition was removed: ' + r.message);
        System.assert(!r.message.containsIgnoreCase('sclerosis'),
            'and the reply must not repeat it back: ' + r.message);
    }

    /**
     * The agent rewrites what an action returns rather than relaying it, so no
     * amount of prompt or payload work makes it say this every time - measured
     * at roughly half of six runs. The channels that compose their reply in Apex
     * do not have that problem, and this pins them so they never regress to
     * depending on a model's memory.
     */
    @IsTest
    static void everyApexComposedChannelSaysItEveryTime() {
        for (String channel : new List<String>{ 'Web', 'SMS', 'Slack', 'Email' }) {
            CurbCutChannelApi.Answer a = CurbCutChannelApi.handle(
                channel, 'I have multiple sclerosis and some days I cannot type for long',
                'h-' + channel, null);
            String said = (a.message == null ? '' : a.message)
                        + ' ' + (a.options == null ? '' : a.options);
            System.assert(said.containsIgnoreCase('took it out'),
                channel + ' must say the condition was removed: ' + said);
            System.assert(!said.containsIgnoreCase('sclerosis'),
                channel + ' must not echo the condition back: ' + said);
        }
    }

    @IsTest
    static void everyChannelRedactsBecauseTheyShareOneWritePath() {
        CurbCutChannelApi.Answer a = CurbCutChannelApi.handle(
            'Slack', 'I have epilepsy so strobing screens are a problem', 'h', null);
        System.assert(!a.message.containsIgnoreCase('epilepsy'),
            'no channel may echo a condition: ' + a.message);
        Barrier_Report__c br = [SELECT Functional_Description__c FROM Barrier_Report__c
                                 WHERE Id = :a.barrierId];
        System.assert(!br.Functional_Description__c.containsIgnoreCase('epilepsy'),
            'and no channel may store one: ' + br.Functional_Description__c);
    }

    /**
     * "aids" used to be on the condition list on its own, so "I wear hearing
     * aids" was stored as "I wear hearing [not recorded]". The one word the
     * person needed read was the one we removed. Equipment is not a diagnosis.
     */
    @IsTest
    static void equipmentIsNotACondition() {
        for (String said : new List<String>{
                'I wear hearing aids and miss things in open plan',
                'I need my mobility aids near my desk'}) {
            System.assert(!CurbCutRedact.names(said),
                'nothing here is a condition: ' + said);
            System.assertEquals(said, stored(said),
                'this must be stored exactly as the person wrote it');
        }
    }

    /**
     * Autistic, ADHD, dyslexic and the other neurodivergent words are identity
     * for many people and were being stripped as if they were a diagnosis. The
     * class publishes the list it will not touch; this walks every entry.
     */
    @IsTest
    static void neurodivergentWordsAreIdentityNotDiagnosis() {
        String said = 'I\'m autistic and the open office is unbearable';
        System.assertEquals(said, stored(said),
            'autistic is how this person describes themselves; it must stay');

        for (String word : CurbCutRedact.IDENTITY) {
            System.assert(!CurbCutRedact.names('I am ' + word + ' and I need notes in advance'),
                'an identity word must never count as a condition: ' + word);
        }
    }

    /**
     * A person who writes "diagnosed with" is quoting a clinic, whatever the
     * words after it are, and the word list cannot know every rare disease.
     * The clause comes out whole. The half after "and" is what is hard, and it
     * has to survive.
     */
    @IsTest
    static void aDiagnosisClauseIsTakenOutWhole() {
        String kept = stored('I was diagnosed with a rare neuromuscular disease last year');
        System.assertEquals('I was ' + CurbCutRedact.MARK, kept,
            'nothing after "diagnosed with" may be stored: ' + kept);

        kept = stored('I was diagnosed with ADHD and I lose track in long meetings');
        System.assert(!kept.containsIgnoreCase('adhd'),
            'inside a diagnosis clause even an identity word is a quote from a clinic: ' + kept);
        System.assert(kept.containsIgnoreCase('lose track in long meetings'),
            'the functional half must survive the clause: ' + kept);

        kept = stored('I take medication for my heart and get dizzy standing up');
        System.assert(!kept.containsIgnoreCase('heart'),
            'what the medication is for must not be stored: ' + kept);
        System.assert(kept.containsIgnoreCase('dizzy standing up'),
            'the functional half must survive the clause: ' + kept);
    }

    /**
     * Statement__c on a standing preference is the one text built to be shown
     * to a manager or a meeting host, and CurbCutStanding did not redact at
     * all. "I have epilepsy so no strobing slides" was stored whole and would
     * have travelled ahead of the person to every host who asked.
     */
    @IsTest
    static void aStandingPreferenceIsRedactedBeforeItIsSaved() {
        Test.startTest();
        CurbCutStanding.Result res = standing('I have epilepsy so no strobing slides');
        Test.stopTest();

        String kept = statementStored(res);
        System.assert(!kept.containsIgnoreCase('epilepsy'),
            'the condition must not be stored on the preference: ' + kept);
        System.assert(kept.contains(CurbCutRedact.MARK),
            'the removal must be visible in the record: ' + kept);
        System.assert(kept.containsIgnoreCase('no strobing slides'),
            'the part a host needs to read must survive: ' + kept);

        System.assertEquals(true, res.redacted, 'the result must say something was taken out');
        System.assert(res.message.containsIgnoreCase('took it out'),
            'the person must be told in the same reply: ' + res.message);
        System.assert(!res.message.containsIgnoreCase('epilepsy'),
            'and the reply must not repeat it back: ' + res.message);
        System.assert(res.message.contains('Saved.') && res.message.contains('OFF'),
            'the save message and the way to turn it off must still be there: ' + res.message);
        System.assertNotEquals(null, res.claimCode, 'the person must still get their code');
    }

    /** A preference with no condition in it is stored word for word, and nobody is told anything was removed. */
    @IsTest
    static void aCleanStandingPreferenceIsStoredWordForWord() {
        String said = 'I am Deaf, face me when you speak';
        CurbCutStanding.Result res = standing(said);
        System.assertEquals(said, statementStored(res),
            'the wording is the point; it must not be touched');
        System.assertEquals(false, res.redacted, 'nothing was taken out');
        System.assert(!res.message.containsIgnoreCase('took it out'),
            'no notice when nothing was removed: ' + res.message);
    }
}
