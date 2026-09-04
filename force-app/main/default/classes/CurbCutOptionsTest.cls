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
                Zero_Cost__c = true, Source_URL__c = 'https://askjan.org/topics/costs.cfm'),
            // Costs money, but no figure is published. The library must say
            // nothing about the price rather than imply one.
            new Accommodation_Option__c(
                Option__c = 'ASL interpreter booked in advance',
                Plain_Language_Summary__c = 'A human interpreter arranged ahead of the meeting.',
                Zero_Cost__c = false, Typical_Cost__c = null,
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

    /**
     * The sentence this entire system was designed around. The library says
     * 'typing'; a person says 'I cannot type for long'. Whole-word matching
     * made that return nothing, and nothing is the cruellest answer here.
     */
    @IsTest
    static void theCanonicalSentenceFindsSomething() {
        Test.startTest();
        CurbCutOptions.Result res = run('I cannot type for long');
        Test.stopTest();
        System.assertEquals(false, res.noMatch,
            'The canonical example sentence returned nothing at all');
        System.assert(res.options.contains('keyboard'),
            'Expected the keyboard option, got: ' + res.options);
    }

    /**
     * Stemming must not undo the fix it was built on top of. 'long' inside
     * 'alongside' is how someone who could not type was once offered a fire alarm.
     */
    @IsTest
    static void stemmingDoesNotResurrectSubstringMatching() {
        CurbCutOptions.Result res = run('alongside');
        System.assertEquals(true, res.noMatch,
            'A word that merely contains another word must not match: ' + res.options);
    }

    /** Singular and plural of the same need must reach the same place. */
    @IsTest
    static void singularAndPluralAgree() {
        CurbCutOptions.Result one  = run('I miss things in the meeting');
        CurbCutOptions.Result many = run('I miss things in meetings');
        System.assertEquals(false, one.noMatch, 'singular found nothing');
        System.assertEquals(one.options, many.options,
            'singular and plural gave different answers');
    }

    /**
     * An option with no published price must produce no price. A placeholder
     * zero in the library once made another surface answer "typically about
     * $0, once" for a booked ASL interpreter. Somebody could repeat that to
     * their employer and lose both the argument and their footing, on a number
     * we made up. Saying nothing is the correct answer to a fact we lack.
     */
    @IsTest
    static void neverStatesAPriceItDoesNotHave() {
        Test.startTest();
        CurbCutOptions.Result res = run('I need an interpreter booked for meetings');
        Test.stopTest();
        System.assertEquals(false, res.noMatch, 'Should have matched the interpreter');
        System.assert(res.options.contains('interpreter'),
            'Expected the interpreter option, got: ' + res.options);
        // Scope the assertion to the interpreter's own block. Other options in
        // the same answer are legitimately free and do say so.
        Integer start = res.options.indexOf('ASL interpreter');
        Integer next  = res.options.indexOf('\n\n', start);
        String block  = next > start ? res.options.substring(start, next)
                                     : res.options.substring(start);
        System.assert(!block.contains('$'),
            'Stated a price for an option that has none: ' + block);
        System.assert(!block.contains('costs nothing'),
            'Claimed an unpriced option is free: ' + block);
    }

    /**
     * The failure this ranker exists to prevent.
     *
     * "I get migraines from the office lighting" returned "special chair or back
     * support", because the word 'office' appears in that summary and a single
     * brush was enough to qualify. There was no lighting row in the library at
     * all, so the honest answer was that we did not know. A confident wrong
     * suggestion costs somebody their one ask.
     */
    @IsTest
    static void aCoincidentalWordIsNotAMatch() {
        // The rule is about how much a word DISTINGUISHES, so the test has to
        // make the word common. Seven rows sharing 'workplace' makes it noise,
        // exactly as 'office' is noise in the real 28-row library.
        List<Accommodation_Option__c> common = new List<Accommodation_Option__c>();
        for (Integer i = 0; i < 7; i++) {
            common.add(new Accommodation_Option__c(
                Option__c = 'Filler option ' + i,
                Plain_Language_Summary__c = 'Something available in the workplace for staff.',
                Zero_Cost__c = true, Source_URL__c = 'https://askjan.org/topics/costs.cfm'));
        }
        insert common;

        CurbCutOptions.Request r = new CurbCutOptions.Request();
        r.need = 'workplace';
        r.limitSize = 4;
        CurbCutOptions.Result res = CurbCutOptions.find(
            new List<CurbCutOptions.Request>{ r })[0];
        System.assert(res.noMatch,
            'a word appearing across most of the library carries no signal and '
            + 'must not qualify as a match: ' + res.options);
    }

    /**
     * And the other half of it: raising the bar must not throw away the
     * sentence this project is built around. A flat score threshold did exactly
     * that, because "typing" lives in a summary rather than a name.
     */
    @IsTest
    static void theCanonicalSentenceStillMatches() {
        CurbCutOptions.Request r = new CurbCutOptions.Request();
        r.need = 'I cannot type for long';
        r.limitSize = 4;
        CurbCutOptions.Result res = CurbCutOptions.find(
            new List<CurbCutOptions.Request>{ r })[0];
        System.assert(!res.noMatch, 'the canonical sentence must return options');
        System.assert(res.options.containsIgnoreCase('keyboard'),
            'a keyboard is the point of that sentence: ' + res.options);
    }
}
