/**
 * Every failure path, checked for how it treats the person who hit it.
 *
 * This is not a style test. The people using this are, disproportionately,
 * people for whom the last several systems they touched blamed them for the
 * system's own problems: your session has expired, invalid input, you must
 * complete all required fields. A dead end at the wrong moment is the thing
 * that makes somebody stop asking for what they need, and stopping is the
 * outcome this entire project exists to prevent.
 *
 * So the build fails if an error message blames the reader, or leaves them
 * without somewhere to go next.
 */
@IsTest
private class CurbCutKindnessTest {

    // Words that put the fault on the reader, or that read as machine noise.
    private static final List<String> BLAMING = new List<String>{
        'invalid', 'illegal', 'incorrect', 'you failed', 'you must', 'you should have',
        'not allowed', 'forbidden', 'denied', 'bad request', 'malformed', 'unexpected'
    };

    // At least one of these must appear: a way forward, or an offer of a person.
    private static final List<String> A_WAY_FORWARD = new List<String>{
        'try again', 'tell me', 'in words', 'a person', 'ask for', 'start again',
        'you can', 'i will', 'whenever', 'instead', 'and i will', 'will work',
        'say it again', 'come back'
    };

    private static void assertKind(String label, String message) {
        System.assert(String.isNotBlank(message),
            label + ' failed silently. Silence is the worst answer this system can give.');
        String m = message.toLowerCase();
        for (String bad : BLAMING) {
            System.assert(!m.contains(bad),
                label + ' blames the reader with "' + bad + '": ' + message);
        }
        Boolean offersSomething = false;
        for (String good : A_WAY_FORWARD) {
            if (m.contains(good)) { offersSomething = true; break; }
        }
        System.assert(offersSomething,
            label + ' is a dead end. It says what went wrong and offers nothing: ' + message);
    }

    /** Sentences people can hold on to when they are already having a hard day. */
    private static void assertReadable(String label, String message) {
        List<String> sentences = message.replace('\n', ' ').split('[.!?]');
        Integer words = 0, counted = 0;
        for (String s : sentences) {
            String t = s.trim();
            if (t.length() < 3) { continue; }
            words += t.split('\\s+').size();
            counted++;
        }
        if (counted == 0) { return; }
        Decimal avg = Decimal.valueOf(words) / counted;
        System.assert(avg <= 26,
            label + ' averages ' + avg.setScale(1) + ' words per sentence, which is a '
            + 'lot to parse when you are struggling: ' + message);
    }

    @IsTest
    static void theWebFrontDoorFailsKindly() {
        Test.startTest();
        assertKind('consult with nothing typed', CurbCutWeb.consult('').message);
        assertKind('send without approval', CurbCutWeb.send('a draft', false, null).message);
        assertKind('send with nothing drafted', CurbCutWeb.send('', true, null).message);
        assertKind('save a preference with no words', CurbCutWeb.saveStanding('', null, null, true).message);
        assertKind('turn off nothing', CurbCutWeb.revokeStanding('').message);
        assertKind('ask who saw nothing', CurbCutWeb.whoSaw('').message);
        Test.stopTest();
    }

    @IsTest
    static void mediaFailsKindly() {
        Test.startTest();
        assertKind('an empty upload',
            CurbCutMedia.send(null, 'x.jpg', '', 'Image').message);
        assertKind('a file we cannot place',
            CurbCutMedia.send(null, 'notes.txt',
                EncodingUtil.base64Encode(Blob.valueOf('x')), 'Document').message);
        Test.stopTest();
    }

    @IsTest
    static void theLibraryFailsKindlyWhenItKnowsNothing() {
        CurbCutOptions.Request r = new CurbCutOptions.Request();
        r.need = 'quantum sledgehammer procurement';
        Test.startTest();
        CurbCutOptions.Result res = CurbCutOptions.find(new List<CurbCutOptions.Request>{ r })[0];
        Test.stopTest();
        System.assertEquals(true, res.noMatch);
        // The agent supplies the sentence here, but the empty result must never
        // be dressed up as an answer.
        System.assertEquals('', res.options,
            'An empty library result must stay empty rather than improvising');
    }

    /** The refusals people are most likely to meet, read as a person would. */
    @IsTest
    static void theRefusalsAreReadable() {
        Test.startTest();
        assertReadable('send without approval', CurbCutWeb.send('a draft', false, null).message);
        assertReadable('consult with nothing typed', CurbCutWeb.consult('').message);
        assertReadable('a file we cannot place',
            CurbCutMedia.send(null, 'notes.txt',
                EncodingUtil.base64Encode(Blob.valueOf('x')), 'Document').message);
        Test.stopTest();
    }

    /**
     * A bad reference must never cost somebody their request. This path has
     * already broken once: every web request was silently losing its link back
     * to what the person said.
     */
    @IsTest
    static void aBrokenReferenceDoesNotCostThemTheRequest() {
        Test.startTest();
        CurbCutWeb.Reply r = CurbCutWeb.send('I am asking for a change to how I work.',
                                             true, 'not-an-id');
        Test.stopTest();
        System.assertEquals(true, r.created,
            'A bad id must not lose the request: ' + r.message);
        assertKind('send with a broken reference', r.message);
    }
}
