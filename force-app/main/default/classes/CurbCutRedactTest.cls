/**
 * The privacy policy said a volunteered condition "is not written to any
 * record". It was written to Functional_Description__c, whole, every time.
 * These tests are the difference between that sentence being a claim and being
 * a fact.
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
}
