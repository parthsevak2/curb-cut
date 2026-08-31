/**
 * The words a person can send to get out.
 *
 * Every channel told people they could reply HUMAN, WHO or OFF "any time".
 * Nothing routed them. HUMAN came back with an ASL interpreter card, PERSON
 * came back with "face the person when speaking", and OFF - the word that
 * withdraws a standing disclosure - came back with "I do not have good
 * information on that". Somebody trying to take back what an employer can see
 * was told the system did not understand, and the sharing stayed on.
 *
 * The escape hatch is the one part of this that cannot be approximate, because
 * everyone who reaches for it has already been failed once. So it lives here,
 * in one place, and every channel routes through it before anything else.
 *
 * Matching is whole-message only. A keyword buried in a sentence is not a
 * command - "I need help typing" is a need, not a request for the help menu -
 * so nothing here ever matches a substring.
 */
public with sharing class CurbCutKeyword {

    public class Match {
        @AuraEnabled public Boolean matched { get; set; }
        /** HUMAN, WHO, OFF, HELP, STOP, START, or NONE. */
        @AuraEnabled public String  intent  { get; set; }
        /** The claim code the person sent with it, if any. */
        @AuraEnabled public String  code    { get; set; }
        /** Channel-neutral wording. A channel may add to it, never contradict it. */
        @AuraEnabled public String  message { get; set; }
    }

    // Whole phrases, never substrings. Generous about how somebody might say it,
    // because a person reaching for the exit should not have to guess the word.
    private static final Map<String, Set<String>> PHRASES = new Map<String, Set<String>>{
        'HUMAN' => new Set<String>{
            'human', 'a human', 'real human', 'human please', 'humans',
            'person', 'a person', 'real person', 'real people', 'person please',
            'a real person', 'a real human', 'a real one', 'an actual person',
            'actual person', 'actual human', 'not a bot', 'not a robot',
            'someone', 'somebody', 'some one', 'agent', 'representative', 'rep',
            'talk to a human', 'talk to a person', 'talk to someone',
            'speak to a human', 'speak to a person', 'speak to someone',
            'talk to human', 'speak to human', 'get me a human',
            'i need a human', 'i need a person', 'i need someone',
            'i want a human', 'i want a person', 'i want someone',
            'let me talk to a person', 'let me talk to someone',
            'can i talk to a person', 'can i talk to someone'
        },
        'WHO' => new Set<String>{
            'who', 'who saw', 'who saw it', 'who has seen it', 'who has seen',
            'who sees it', 'who knows', 'who knows it', 'who was told',
            'who has it', 'who can see it', 'who can see'
        },
        'OFF' => new Set<String>{
            'off', 'turn it off', 'turn off', 'switch it off', 'switch off',
            'stop sharing', 'stop sharing it', 'unshare', 'un share',
            'withdraw', 'withdraw it', 'take it back', 'take that back'
        },
        'HELP' => new Set<String>{
            'help', 'info', 'information', 'what is this', 'what can you do',
            'what do you do', 'commands', 'menu',
            // The words printed on the poster. This is the first thing somebody
            // ever sends us, and it used to go to the library as if it were a
            // description of a barrier.
            'curb cut', 'curbcut', 'curb'
        },
        // Carrier-reserved. Mirrored from the relay so the two can never drift;
        // an invariant fails the build if they do.
        'STOP'  => new Set<String>{
            'stop', 'stopall', 'stop all', 'unsubscribe', 'cancel', 'end', 'quit'
        },
        // 'yes' is deliberately absent. On a channel with a draft open, YES
        // approves the draft. The relay may treat it as opt-in resumption
        // because it knows whether the person is currently stopped; here there
        // is no such context, and guessing wrong sends something.
        'START' => new Set<String>{ 'start', 'unstop' }
    };

    // Codes avoid characters people mistake for each other when reading them off
    // a screen with low vision, a cracked phone, or a screen reader: no O or 0,
    // no I or 1, no S or 5.
    private static final String CODE_ALPHABET = 'ABCDEFGHJKLMNPQRTUVWXYZ2346789';
    private static final Pattern CODE_IN_TEXT =
        Pattern.compile('(?i)\\b([abcdefghjklmnpqrtuvwxyz2346789]{6})\\b');

    /** A code the person keeps. We store only a hash, so we cannot look them up. */
    public static String newCode() {
        String s = '';
        for (Integer i = 0; i < 6; i++) {
            Integer at = Math.mod(Math.abs(Crypto.getRandomInteger()), CODE_ALPHABET.length());
            s += CODE_ALPHABET.substring(at, at + 1);
        }
        return s;
    }

    public static Match route(String text) {
        Match m = new Match();
        m.matched = false;
        m.intent  = 'NONE';
        if (String.isBlank(text)) { return m; }

        // Normalise: lower case, punctuation to spaces, collapse runs.
        String n = text.toLowerCase().replaceAll('[^a-z0-9]+', ' ').trim();
        n = n.replaceAll('\\s+', ' ');
        if (String.isBlank(n)) { return m; }

        // A code may travel with the word: "off 4KQ7MT".
        String stripped = n;
        Matcher cm = CODE_IN_TEXT.matcher(n);
        while (cm.find()) {
            String candidate = cm.group(1);
            // Only treat it as a code if it is not itself one of our words.
            if (!isPhrase(candidate)) {
                m.code = candidate.toUpperCase();
                stripped = n.replace(candidate, ' ').replaceAll('\\s+', ' ').trim();
                break;
            }
        }
        if (String.isBlank(stripped)) { stripped = n; }

        // Long messages are needs, not commands. Somebody describing what is hard
        // must never be answered with a menu.
        if (stripped.split(' ').size() > 6) { return m; }

        for (String intent : PHRASES.keySet()) {
            if (PHRASES.get(intent).contains(stripped)) {
                m.matched = true;
                m.intent  = intent;
                m.message = wording(intent);
                return m;
            }
        }
        return m;
    }

    private static Boolean isPhrase(String w) {
        for (String intent : PHRASES.keySet()) {
            if (PHRASES.get(intent).contains(w)) { return true; }
        }
        return false;
    }

    /**
     * Said the same way everywhere. A person who texts and then emails should
     * not get two different accounts of what just happened.
     */
    public static String wording(String intent) {
        if (intent == 'HUMAN') {
            return 'Yes. A real person will pick this up, and you will not have to '
                 + 'explain it again. They will reply here, on this same channel. '
                 + 'Nobody will ring you.';
        }
        if (intent == 'WHO') {
            return 'I can show you everyone who has been shown what you asked me to '
                 + 'remember. Send WHO and your six letter code, like WHO 4KQ7MT. '
                 + 'The code was in the message where you set it up.';
        }
        if (intent == 'OFF') {
            return 'I can turn that off. Send OFF and your six letter code, like '
                 + 'OFF 4KQ7MT. The code was in the message where you set it up. '
                 + 'I will not ask why.';
        }
        if (intent == 'HELP') {
            return 'Tell me what is hard at work, in your own words. I will tell you '
                 + 'what other people have asked for. You never have to say what '
                 + 'condition you have. Send HUMAN at any point for a real person.';
        }
        return null;
    }

    /** The words the relay owns, exposed so one list can be checked against it. */
    public static Set<String> phrasesFor(String intent) {
        return PHRASES.containsKey(intent) ? PHRASES.get(intent) : new Set<String>();
    }
}
