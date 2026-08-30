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
                Source_URL__c = 'https://askjan.org/topics/costs.cfm'),
            // Its summary mentions an office and a follow-up 'after'. Both are
            // traps that this class has fallen into, so the trap stays in the
            // fixture rather than in production.
            new Accommodation_Option__c(
                Option__c = 'Special chair or back support',
                Plain_Language_Summary__c = 'A chair chosen for you rather than the standard office one, after an assessment.',
                Zero_Cost__c = true, Source_URL__c = 'https://askjan.org/topics/costs.cfm'),
            new Accommodation_Option__c(
                Option__c = 'Alternative or ergonomic keyboard',
                Plain_Language_Summary__c = 'A keyboard shaped to make typing easier or less painful.',
                Zero_Cost__c = true, Source_URL__c = 'https://askjan.org/topics/costs.cfm')
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
    static void doesNotMatchAWordInsideAnotherWord() {
        // 'long' lives inside 'alongside'. Substring matching once recommended
        // visual fire alarms to someone who said they could not type for long.
        insert new Accommodation_Option__c(
            Option__c = 'Visual fire and safety alerts',
            Plain_Language_Summary__c = 'Strobe or vibrating alerts alongside audio alarms.',
            Zero_Cost__c = false, Source_URL__c = 'https://askjan.org/topics/costs.cfm');

        Test.startTest();
        CurbCutOptions.Result res = run('I cannot type for long');
        Test.stopTest();

        System.assert(!res.options.contains('Visual fire'),
            'alongside must not match the keyword long: ' + res.options);
    }

    @IsTest
    static void blankInputIsSafe() {
        CurbCutOptions.Result res = run('   ');
        System.assertEquals(true, res.noMatch);
    }

    /**
     * 'Typing hurts after a while' used to return 'Written follow-up after verbal
     * instructions' as its first result, matched on the word 'after'. Someone whose
     * hands hurt was offered note-taking. Function words must not score.
     */
    @IsTest
    static void functionWordsDoNotMatch() {
        Test.startTest();
        CurbCutOptions.Result res = run('Typing hurts after a while');
        Test.stopTest();
        System.assertEquals(false, res.noMatch, 'Should still match on "typing"');
        System.assert(res.options.contains('keyboard'),
            'Expected the keyboard option, got: ' + res.options);
        System.assert(!res.options.contains('chair'),
            'The chair matched only on the function word "after": ' + res.options);
    }

    /**
     * The name of an accommodation is what it is about. The summary is explanation
     * around it. A chair whose summary happens to mention an office must not
     * outrank a headset that is actually named for noise.
     */
    @IsTest
    static void theNameOutranksTheExplanation() {
        Test.startTest();
        CurbCutOptions.Result res = run('The noise in the office is too much');
        Test.stopTest();
        System.assertEquals(false, res.noMatch, 'Should have matched on "noise"');
        Integer headset = res.options.indexOf('Noise-cancelling headset');
        Integer chair   = res.options.indexOf('Special chair');
        System.assert(headset >= 0, 'Expected the headset, got: ' + res.options);
        System.assert(chair < 0 || headset < chair,
            'A summary hit on "office" outranked a name hit on "noise": ' + res.options);
    }

    /**
     * The same question asked twice must give the same answer in the same order.
     * A system that reshuffles its advice reads as one that is unsure of it.
     */
    @IsTest
    static void theOrderIsStable() {
        CurbCutOptions.Result first  = run('noise office typing');
        CurbCutOptions.Result second = run('noise office typing');
        System.assertEquals(first.options, second.options,
            'Identical input must produce identical output');
    }

    /**
     * Every starting point offered on the ask page must actually return something.
     * Handing someone a suggested phrase that then returns nothing is worse than
     * offering no phrase at all.
     */
    @IsTest
    static void everyOfferedStarterMatchesSomething() {
        List<String> starters = new List<String>{
            'I keep missing things in meetings',
            'Typing hurts after a while',
            'The noise in the office is too much',
            'My back hurts by the afternoon'
        };
        Test.startTest();
        for (String phrase : starters) {
            CurbCutOptions.Result res = run(phrase);
            System.assertEquals(false, res.noMatch,
                'A starter offered on the ask page returned nothing: ' + phrase);
        }
        Test.stopTest();
    }
}
