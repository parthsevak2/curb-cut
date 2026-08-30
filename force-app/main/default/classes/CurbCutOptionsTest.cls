/**
 * The no-match test is the important one. Everything else is plumbing.
 */
@IsTest
private class CurbCutOptionsTest {

    @TestSetup
    static void seed() {
        insert new List<Accommodation_Option__c>{
            new Accommodation_Option__c(
                Option__c = 'Captions turned on in all meetings',
                Plain_Language_Summary__c = 'Live captions on by default in every meeting.',
                Zero_Cost__c = true, Source_URL__c = 'https://askjan.org/topics/costs.cfm'),
            new Accommodation_Option__c(
                Option__c = 'Noise-cancelling headset',
                Plain_Language_Summary__c = 'Headset to reduce background noise.',
                Typical_Cost__c = 250, Zero_Cost__c = false,
                Source_URL__c = 'https://askjan.org/topics/costs.cfm')
        };
    }

    private static CurbCutOptions.Result run(String need) {
        CurbCutOptions.Request r = new CurbCutOptions.Request();
        r.need = need;
        return CurbCutOptions.find(new List<CurbCutOptions.Request>{ r })[0];
    }

    @IsTest
    static void matchesOnFunctionalLanguage() {
        Test.startTest();
        CurbCutOptions.Result res = run('I miss things in meetings, I need captions');
        Test.stopTest();
        System.assertEquals(false, res.noMatch, 'Should have matched captions');
        System.assert(res.matchCount > 0, 'Expected at least one match');
        System.assert(res.options.contains('Captions'), 'Expected the captions option');
    }

    @IsTest
    static void statesZeroCostPlainly() {
        CurbCutOptions.Result res = run('captions meetings');
        System.assert(res.options.contains('costs nothing'), 'Zero-cost should be stated plainly');
    }

    @IsTest
    static void neverInventsPrecedentWhenDataIsAbsent() {
        CurbCutOptions.Result res = run('captions meetings');
        System.assert(!res.options.contains('times here before'),
            'Precedent count is absent, so it must not be stated at all');
    }

    @IsTest
    static void returnsEmptyRatherThanGuessing() {
        Test.startTest();
        CurbCutOptions.Result res = run('quantum sledgehammer procurement');
        Test.stopTest();
        System.assertEquals(true, res.noMatch, 'Unknown need must return noMatch');
        System.assertEquals(0, res.matchCount);
        System.assertEquals('', res.options, 'Must return nothing rather than improvise');
    }

    @IsTest
    static void blankInputIsSafe() {
        CurbCutOptions.Result res = run('   ');
        System.assertEquals(true, res.noMatch);
    }
}
