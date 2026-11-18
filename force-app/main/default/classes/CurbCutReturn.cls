/**
 * CurbCutReturn — the way back to the same person.
 *
 * Somebody on the web asks for a person. They are anonymous, so there is no
 * address to answer, and the page tells them the truth: keep this code, send it
 * here, or by text, or by email, and you land straight back with the same
 * person. We kept a hash of the code on the handoff and nothing ever looked a
 * handoff up by it. A person who came back with their code was read as
 * somebody describing a new barrier, the code went into the library as if it
 * were a need, and they started again from nothing, at exactly the moment they
 * had been told they would not have to.
 *
 * So every door asks this first, before the words are read as a need. It is
 * one class so that the web, text, Slack and email cannot come to disagree
 * about what a code is or what happens when one arrives.
 *
 * What it does with a code that leads somewhere:
 *   - writes Returned_At__c, so the record says they came back and when;
 *   - moves Reachable_By__c to the door they came back through, where one
 *     fits, so the handler answers where they are now;
 *   - names the same handler back to them, and nothing else.
 *
 * What it never does:
 *   - keep anything they wrote. The code is the only part of the message used,
 *     and it is used to make a hash and then dropped. Nothing they said is
 *     stored here, redacted or otherwise.
 *   - keep who they are. It takes no handle at all. The door's own ledger row
 *     is the only place a hashed handle goes, exactly as for any other message.
 *   - tell them anything about the request. The code is a bearer secret: anyone
 *     holding it gets the handler's name and the fact that it is still open,
 *     and not one word of what was asked. The code itself is never said back.
 *   - change what a control word means. OFF and WHO take a claim code, STOP and
 *     HELP belong to the carrier, NOMINATE takes a workplace. A return code
 *     sent with any of them is answered by that word, as it was before.
 *     HUMAN is the one exception, and only because it is the same request:
 *     somebody who sends HUMAN with their code is asking for their person, and
 *     a second handoff with a second stranger would break the promise the
 *     first one made. If the code leads nowhere, HUMAN works exactly as it did.
 */
public with sharing class CurbCutReturn {

    private static final String FALLBACK_HANDLER = 'the access team';

    /** A long email can carry a lot of six letter words. Enough to find a code, no more. */
    private static final Integer MAX_CANDIDATES = 10;

    /**
     * Doors where an answer can come back the way the person came. Reachable
     * By is moved here, and the reply says they will be answered here.
     */
    private static final Map<String, String> ANSWERS_HERE = new Map<String, String>{
        'SMS'   => 'Text message',
        'Slack' => 'Slack',
        'Email' => 'Email'
    };

    /**
     * Doors where the return is recorded but nothing can be sent back: the web
     * page holds no address, and that is on purpose. Voice, MCP and anything
     * else arriving as External have no picklist value that would be true,
     * so Reachable By is left as it was rather than set to something false.
     */
    private static final Map<String, String> RECORDED_ONLY = new Map<String, String>{
        'Web' => 'Web chat'
    };

    /**
     * Said around a code by somebody plainly coming back with it, already
     * normalised the way CurbCutKeyword normalises: lower case, punctuation to
     * spaces. Longest first, so "my code is" is taken before "my code".
     */
    private static final List<String> LEADS = new List<String>{
        'here is my code', 'here s my code', 'it is me again', 'it s me again',
        'its me again', 'my code is', 'the code is', 'heres my code',
        'back again', 'i am back', 'it is me', 'it s me', 'me again',
        'returning', 'code is', 'my code', 'i m back', 'im back', 'its me',
        'resume', 'return', 'hello', 'code', 'back', 'hey', 'hi'
    };
    private static final List<String> TAILS = new List<String>{
        'thank you', 'thanks', 'please', 'thx', 'ty'
    };

    public class Result {
        /** True when the code led to a handoff and the return is now on it. */
        public Boolean found = false;
        /**
         * What to say. Null when the message was not a way back at all, and
         * the door carries on exactly as it would have.
         */
        public String  message;
        /** The person they were told they would land back with. Only when found. */
        public String  handlerName;
    }

    /**
     * Without sharing, narrowly, for the same reason as CurbCutStanding.Pen.
     * The guest user cannot read a handoff once it is written, and neither can
     * the integration user the relays sign in as, because sharing is Private.
     * Both would make the code a promise nobody could redeem. Scoped to one
     * lookup by hash, returning at most one row, reachable only by somebody
     * holding the code, and to one update of two fields on that row.
     */
    private without sharing class Desk {
        private Human_Handoff__c byHash(Set<String> hashes) {
            List<Human_Handoff__c> found = [
                SELECT Id, Handler_Name__c, Reachable_By__c
                  FROM Human_Handoff__c
                 WHERE Return_Code_Hash__c IN :hashes
                 ORDER BY Requested_At__c DESC
                 LIMIT 1];
            return found.isEmpty() ? null : found[0];
        }
        private void cameBack(Human_Handoff__c h) { update h; }
    }

    /**
     * Every door calls this before it treats a message as a new ask.
     *
     * channel is the door, in the ledger's words: Web, SMS, Slack, Email or
     * External. A message that is not a way back returns a Result with no
     * message, and the door goes on as if this had not been asked.
     */
    public static Result tryResume(String channel, String text) {
        Result res = new Result();
        if (String.isBlank(text)) { return res; }

        CurbCutKeyword.Match kw = CurbCutKeyword.route(text);
        Boolean askedForAPerson = kw.matched && kw.intent == 'HUMAN';
        if (kw.matched && !askedForAPerson) { return res; }
        if (askedForAPerson && String.isBlank(kw.code)) { return res; }

        String n = normal(text);
        // The first line that says anything is a code and nothing else, once
        // the hello and the thank you are taken off. One line, because below
        // it is where "Sent from my phone" lives. Spaces inside the code are
        // tolerated: read off a screen, or by a screen reader, a code often
        // arrives as "4KQ 7MT" or "4 K Q 7 M T".
        String line = '';
        for (String l : text.split('\r?\n')) {
            if (String.isNotBlank(trimmed(normal(l)))) { line = normal(l); break; }
        }
        String rest = trimmed(line);
        String joined = rest.replace(' ', '');
        Boolean onlyACode = CurbCutKeyword.isCode(joined);
        // Whether anything else came with it, anywhere in the message.
        Boolean nothingElse = CurbCutKeyword.isCode(trimmed(n).replace(' ', ''));

        List<String> codes = new List<String>();
        if (askedForAPerson) {
            codes.add(kw.code.toUpperCase());
        } else {
            if (onlyACode) { codes.add(joined.toUpperCase()); }
            // A sentence can carry a code too: "Hi, my code is 4KQ7MT. Has
            // anything happened?" is how an email comes back.
            for (String t : n.split(' ')) {
                if (codes.size() >= MAX_CANDIDATES) { break; }
                String c = t.toUpperCase();
                if (CurbCutKeyword.isCode(t) && !codes.contains(c)) { codes.add(c); }
            }
        }
        if (codes.isEmpty()) { return res; }

        Set<String> hashes = new Set<String>();
        for (String c : codes) { hashes.addAll(CurbCutCreateHandoff.returnCodeHashes(c)); }
        Human_Handoff__c h = new Desk().byHash(hashes);

        if (h == null) {
            // HUMAN with a code that leads nowhere is still a request for a
            // person, and gets one, exactly as before.
            if (askedForAPerson) { return res; }
            // Only somebody plainly sending a code is told it led nowhere: the
            // code alone, or after "my code is". A bare six letter word with no
            // digit in it could be a word ("travel", "health"), so that goes on
            // to be read as a need. Everything else that is not a code is
            // answered exactly as it was before this class existed.
            Boolean plainlyACode = onlyACode
                && (rest != line || joined.containsAny('2346789'));
            if (!plainlyACode) { return res; }
            // One answer for a code that was never ours, a code with a letter
            // wrong, and a code for a handoff that has gone: "right now" is
            // true of all three and tells nobody which. Answering a typo as a
            // need instead would write a near-miss of somebody's code into a
            // barrier report in readable form, one letter from the real one,
            // and tell a person who mistyped it that codes are not understood.
            res.message = 'That code does not lead to a request right now. '
                        + 'You can check each letter and try again. '
                        + 'If it is the code for something you asked me to remember, '
                        + 'send WHO or OFF with it. '
                        + 'Or send HUMAN and a real person will pick this up.';
            return res;
        }

        String who = String.isBlank(h.Handler_Name__c) ? FALLBACK_HANDLER : h.Handler_Name__c;
        Human_Handoff__c back = new Human_Handoff__c(Id = h.Id, Returned_At__c = System.now());
        String reach = ANSWERS_HERE.containsKey(channel)
            ? ANSWERS_HERE.get(channel) : RECORDED_ONLY.get(channel);
        if (reach != null) { back.Reachable_By__c = reach; }
        try {
            new Desk().cameBack(back);
        } catch (DmlException e) {
            // Found, and not able to say so on the record. Telling them the
            // handler knows would be the one lie this class exists to stop.
            res.message = 'I could not tell ' + who + ' you are back just now, and I am '
                        + 'not going to pretend I did. You can write to '
                        + System.Label.CurbCut_Support_Email + ' and somebody will pick it up.';
            return res;
        }

        res.found = true;
        res.handlerName = who;
        res.message = 'Welcome back. ' + who.left(1).toUpperCase() + who.substring(1)
                    + ' still has your request. I have told them you came back, so you '
                    + 'do not have to explain it again. '
                    // The rest of what they wrote is not kept, so say so, rather
                    // than let them think it was passed on.
                    + (nothingElse || askedForAPerson ? ''
                        : 'I only passed on that you came back. Tell them anything '
                          + 'new when they answer. ')
                    + (ANSWERS_HERE.containsKey(channel)
                        ? 'They will answer you here. You can send this code again whenever you like.'
                        : (channel == 'Web' ? 'This page has no way to reach you.'
                                            : 'I have no way to reach you from here.')
                          + (CurbCutDoors.textOpen()
                              ? ' You can text this code to ' + System.Label.CurbCut_SMS_Number
                                + ', or write to ' + System.Label.CurbCut_Support_Email
                                + ', to hear from them.'
                              : ' You can write to ' + System.Label.CurbCut_Support_Email
                                + ' with this code to hear from them.'));
        return res;
    }

    /** The same normalising CurbCutKeyword does: lower case, punctuation to spaces. */
    private static String normal(String s) {
        return s.toLowerCase().replaceAll('[^a-z0-9]+', ' ').trim();
    }

    /** The hello before a code and the thank you after it, taken off. */
    private static String trimmed(String n) {
        String s = n;
        for (Integer pass = 0; pass < 4; pass++) {
            String before = s;
            for (String lead : LEADS) {
                if (s == lead) { s = ''; break; }
                if (s.startsWith(lead + ' ')) { s = s.substring(lead.length() + 1); break; }
            }
            for (String tail : TAILS) {
                if (s.endsWith(' ' + tail)) { s = s.substring(0, s.length() - tail.length() - 1); break; }
            }
            if (s == before) { break; }
        }
        return s.trim();
    }
}
