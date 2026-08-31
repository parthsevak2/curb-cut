/**
 * Tests for the spec-mandated behaviours that were missing: intake across all
 * four modalities, standing preferences with reasonless revocation, and the
 * manager cost brief.
 */
@IsTest
private class CurbCutSpecTest {

    @TestSetup
    static void seed() {
        insert new List<Accommodation_Option__c>{
            new Accommodation_Option__c(
                Option__c = 'Captions turned on in all meetings',
                Plain_Language_Summary__c = 'Live captions on by default.',
                Zero_Cost__c = true, Source_URL__c = 'https://askjan.org/topics/costs.cfm'),
            new Accommodation_Option__c(
                Option__c = 'Noise-cancelling headset',
                Plain_Language_Summary__c = 'Reduces background noise.',
                Typical_Cost__c = 250, Zero_Cost__c = false, Precedent_Count__c = 4,
                Source_URL__c = 'https://askjan.org/topics/costs.cfm')
        };
    }

    private static CurbCutIntake.Result intake(String what, String modality, String profileId) {
        CurbCutIntake.Request r = new CurbCutIntake.Request();
        r.functionalDescription = what; r.inboundModality = modality; r.accessProfileId = profileId;
        return CurbCutIntake.log(new List<CurbCutIntake.Request>{ r })[0];
    }

    // ---- intake -------------------------------------------------------------

    @IsTest
    static void intakeIsAnonymousByDefault() {
        Test.startTest();
        CurbCutIntake.Result res = intake('I miss things in meetings', 'Text', null);
        Test.stopTest();
        System.assertEquals(true, res.anonymous, 'Anonymous must be the default');
        Barrier_Report__c br = [SELECT Anonymous__c, Access_Profile__c, Inbound_Modality__c
                                FROM Barrier_Report__c LIMIT 1];
        System.assertEquals(true, br.Anonymous__c);
        System.assertEquals(null, br.Access_Profile__c, 'No profile link may be written');
    }

    @IsTest
    static void anonymousConsultWritesNoRequest() {
        // Spec adversarial case 5.
        intake('I miss things in meetings', 'Text', null);
        System.assertEquals(0, [SELECT COUNT() FROM Accommodation_Request__c],
            'An anonymous consult must never produce a request row');
    }

    @IsTest
    static void signedVideoFlagsInterpreterAndNeverDescribesIt() {
        CurbCutIntake.Result res = intake('video of me signing', 'Video', null);
        System.assertEquals(true, res.interpreterNeeded, 'Signed video needs a human');
        System.assert(res.message.contains('not a machine'));
        Barrier_Report__c br = [SELECT Interpreter_Needed__c, Inbound_Modality__c
                                FROM Barrier_Report__c LIMIT 1];
        System.assertEquals(true, br.Interpreter_Needed__c);
        System.assertEquals('Video', br.Inbound_Modality__c);
    }

    @IsTest
    static void everyModalityIsAcceptedAndUnknownFallsBackToText() {
        for (String m : new List<String>{ 'Text', 'Voice note', 'Video', 'Image' }) {
            System.assert(String.isNotBlank(intake('something hard', m, null).barrierReportId), m);
        }
        intake('something hard', 'Telepathy', null);
        Integer textRows = [SELECT COUNT() FROM Barrier_Report__c WHERE Inbound_Modality__c = 'Text'];
        System.assert(textRows >= 2, 'Unknown modality must fall back to Text, not fail');
    }

    @IsTest
    static void badProfileIdStaysAnonymousRatherThanFailing() {
        CurbCutIntake.Result res = intake('something hard', 'Text', 'not-an-id');
        System.assertEquals(true, res.anonymous, 'A bad id must not de-anonymise or throw');
    }

    // ---- standing preferences ----------------------------------------------

    private static CurbCutStanding.Result standing(String op, String stmt, String prefId) {
        CurbCutStanding.Request r = new CurbCutStanding.Request();
        r.operation = op; r.statement = stmt; r.preferenceId = prefId;
        return CurbCutStanding.run(new List<CurbCutStanding.Request>{ r })[0];
    }

    @IsTest
    static void savingAPreferenceStatesWhoWillSeeIt() {
        Test.startTest();
        CurbCutStanding.Result res = standing('save', 'Face me when you speak.', null);
        Test.stopTest();
        System.assertEquals(true, res.ok);
        System.assert(res.message.contains('will see it'), 'Disclosure must be stated up front');
        // OFF, never STOP. This assertion used to require the opposite and so
        // held the bug in place: STOP is a carrier keyword that unsubscribes the
        // person from the number entirely and never reaches our code, so anyone
        // following that instruction would lose the service and keep the
        // preference they were trying to turn off.
        System.assert(res.message.contains('OFF'), 'The way to turn it off must be stated');
        System.assert(!res.message.contains('STOP'),
            'Must not tell anyone to reply STOP; the carrier intercepts it: ' + res.message);
        System.assertEquals('Manager only',
            [SELECT Shared_With__c FROM Access_Preference__c LIMIT 1].Shared_With__c);
    }

    @IsTest
    static void revocationIsImmediateAndAsksNoReason() {
        // Spec adversarial case 6.
        CurbCutStanding.Result saved = standing('save', 'Text me, never call.', null);
        Test.startTest();
        CurbCutStanding.Result rev = standing('revoke', null, saved.preferenceId);
        Test.stopTest();
        System.assertEquals(true, rev.ok, 'Revocation must succeed immediately');
        System.assertNotEquals(null,
            [SELECT Revoked_On__c FROM Access_Preference__c WHERE Id = :saved.preferenceId].Revoked_On__c,
            'Revoked_On__c must be stamped');
        String m = rev.message.toLowerCase();
        System.assert(!m.contains('why') && !m.contains('reason'),
            'Revocation must not ask for a reason: ' + rev.message);
    }

    // ---- manager cost brief -------------------------------------------------

    private static CurbCutCostBrief.Result brief(String option) {
        CurbCutCostBrief.Request r = new CurbCutCostBrief.Request();
        r.option = option;
        return CurbCutCostBrief.build(new List<CurbCutCostBrief.Request>{ r })[0];
    }

    @IsTest
    static void briefLeadsWithCostAndCitesTheSource() {
        Test.startTest();
        CurbCutCostBrief.Result res = brief('Captions');
        Test.stopTest();
        System.assert(res.brief.startsWith('Cost first.'), 'Cost must lead');
        System.assert(res.brief.contains('61'), 'Zero-cost share must be stated');
        System.assert(res.brief.contains('300'), 'Median figure must be stated');
        System.assert(res.brief.contains('askjan.org'), 'The figure must be cited');
        System.assert(res.brief.contains('10 days'), 'The interactive clock must be stated');
    }

    @IsTest
    static void briefSaysSoWhenThereIsNoPrecedentData() {
        // Spec adversarial case 10.
        CurbCutCostBrief.Result res = brief('Captions');
        System.assertEquals(false, res.hasPrecedent);
        System.assert(res.brief.contains('do not hold precedent data'),
            'Absent precedent must be stated, not invented');
        System.assert(!res.brief.contains('approved 0 times'),
            'A zero must never be presented as a precedent count');
    }

    @IsTest
    static void briefStatesRealPrecedentWhenItExists() {
        CurbCutCostBrief.Result res = brief('Noise-cancelling');
        System.assertEquals(true, res.hasPrecedent);
        System.assert(res.brief.contains('approved 4 times here before'));
    }

    @IsTest
    static void unknownOptionRefusesToEstimate() {
        CurbCutCostBrief.Result res = brief('Company car');
        System.assert(res.brief.contains('not in the grounded library'));
        System.assert(res.brief.contains('will not estimate'));
    }
}
