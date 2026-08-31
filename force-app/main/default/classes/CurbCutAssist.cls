/**
 * CurbCutAssist — the assistant for the person on duty.
 *
 * The public agent helps the person who needs an accommodation. Nobody was
 * helping the person answering, and that is where accommodations actually die:
 * not in refusal, in a well-meaning operator who does not know what to offer,
 * guesses, and offers something wrong or something that requires a phone call.
 *
 * Two deliberate design choices, both arguable, both argued:
 *
 * 1. It is GROUNDED AND DETERMINISTIC, exactly like CurbCutWeb. Suggestions
 *    come from the sourced library or they do not come. An operator repeating a
 *    fluent invention to a manager spends someone's one ask on a thing that does
 *    not exist. There is nothing here to hallucinate.
 *
 * 2. It applies the SAME refusals to staff as to everyone else. An operator who
 *    asks this what condition a person has is refused, in the same words a
 *    manager would get. The internal tool is where a privacy promise is usually
 *    quietly exempted, so this is the place to prove it is not.
 *
 * What makes it assistive rather than a search box: it reads the situation and
 * proposes the next actions, each of which it can then carry out.
 */
public with sharing class CurbCutAssist {

    // Written for how somebody actually types at four in the afternoon, not for
    // the schema. A test caught "how severe is it" sailing through because the
    // pattern only knew the word "severity". Note the word boundary on severe:
    // "several people talk at once" is a real sentence in real records here.
    private static final Pattern MEDICAL = Pattern.compile(
        '(?i).*(diagnos|\\bcondition|disabilit|medical|\\bsevere|\\bseverity|prognos'
      + '|illness|impairment|symptom|treatment|medication|what.s wrong|whats wrong'
      + '|how bad|why do they need|why does (he|she|they) need).*');

    public class Step {
        @AuraEnabled public String  id       { get; set; }
        @AuraEnabled public String  label    { get; set; }
        @AuraEnabled public String  why      { get; set; }
        @AuraEnabled public String  tone     { get; set; }   // urgent | live | calm
        @AuraEnabled public Boolean done     { get; set; }
    }

    public class Answer {
        @AuraEnabled public Boolean refused    { get; set; }
        @AuraEnabled public String  message    { get; set; }
        @AuraEnabled public String  body       { get; set; }
        @AuraEnabled public List<Step> steps   { get; set; }
        @AuraEnabled public String  channel    { get; set; }
        @AuraEnabled public Boolean plainLanguage { get; set; }
    }

    /** Context for one handoff: what to do next, in order, and why. */
    @AuraEnabled(cacheable=true)
    public static Answer nextSteps(Id handoffId) {
        Human_Handoff__c h = [
            SELECT Requested_At__c, Picked_Up_At__c, Handler_Name__c, Reachable_By__c,
                   Barrier_Report__c, Barrier_Report__r.Functional_Description__c,
                   Barrier_Report__r.Interpreter_Needed__c,
                   Barrier_Report__r.Inbound_Modality__c,
                   Barrier_Report__r.Access_Profile__r.Plain_Language_Mode__c
            FROM Human_Handoff__c WHERE Id = :handoffId
            WITH SECURITY_ENFORCED LIMIT 1];

        Answer a = new Answer();
        a.refused = false;
        a.steps = new List<Step>();
        a.channel = h.Reachable_By__c;
        a.plainLanguage = h.Barrier_Report__r != null
            && h.Barrier_Report__r.Access_Profile__r != null
            && h.Barrier_Report__r.Access_Profile__r.Plain_Language_Mode__c == true;

        Boolean taken = h.Picked_Up_At__c != null;
        Integer hours = h.Requested_At__c == null ? 0
            : (Integer) ((System.now().getTime() - h.Requested_At__c.getTime()) / 3600000);

        a.steps.add(step('take', taken ? 'Taken by ' + h.Handler_Name__c : 'Put your name on it',
            taken ? 'The next shift can see this is not waiting on nobody.'
                  : 'Nobody owns this yet. Claiming it is the difference between a queue and a pile.',
            taken ? 'calm' : (hours >= 12 ? 'urgent' : 'live'), taken));

        a.steps.add(step('hold', 'Send a holding message',
            hours >= 4
              ? 'They have been waiting ' + hours + ' hours in silence. Silence is the harm here, '
                + 'and a holding message costs you nothing.'
              : 'Tell them a person has it. Waiting is easier when you know someone is there.',
            hours >= 12 ? 'urgent' : 'live', false));

        if (h.Barrier_Report__r != null && h.Barrier_Report__r.Interpreter_Needed__c == true) {
            a.steps.add(step('interpreter', 'Book a human interpreter',
                'Signed video is never machine translated. Nothing else on this record can '
                + 'proceed until a person is booked, and the wait is the entire cost to them.',
                'urgent', false));
        }

        a.steps.add(step('offer', 'See what you could offer them',
            'Grounded in the sourced library, with what each option typically costs. '
            + 'If there is no good match it will say so rather than invent one.', 'live', false));

        a.steps.add(step('draft', 'Draft the reply',
            'In their channel, in their register. Never asks them to explain again, and '
            + 'never routes them to a telephone.', 'live', false));

        a.message = taken
            ? 'You have this one. Work down the list.'
            : 'Nobody has this yet. Start at the top.';
        return a;
    }

    private static Step step(String id, String label, String why, String tone, Boolean done) {
        Step s = new Step();
        s.id = id; s.label = label; s.why = why; s.tone = tone; s.done = done;
        return s;
    }

    /**
     * What could be offered, from the library, for the words already on record.
     * Uses exactly the lookup the public agent uses, so staff and the person
     * being helped can never be told two different things.
     */
    @AuraEnabled
    public static Answer offer(Id handoffId) {
        Human_Handoff__c h = [
            SELECT Barrier_Report__r.Functional_Description__c
            FROM Human_Handoff__c WHERE Id = :handoffId WITH SECURITY_ENFORCED LIMIT 1];

        Answer a = new Answer();
        a.refused = false;
        String need = h.Barrier_Report__r == null ? null
                    : h.Barrier_Report__r.Functional_Description__c;
        if (String.isBlank(need)) {
            a.message = 'There are no words of theirs on this record, so there is nothing to '
                      + 'match against. Ask them, once, in their own channel.';
            return a;
        }
        CurbCutOptions.Request req = new CurbCutOptions.Request();
        req.need = need;
        req.limitSize = 4;
        CurbCutOptions.Result res = CurbCutOptions.find(new List<CurbCutOptions.Request>{ req })[0];

        if (res.noMatch) {
            a.message = 'Nothing in the sourced library matches what they described. '
                      + 'Say that plainly rather than improvising: a confident wrong suggestion '
                      + 'costs them their one ask.';
            return a;
        }
        a.message = 'From the sourced library. Every line has a source you can show them.';
        a.body = res.options;
        return a;
    }

    /** A reply, in their channel and their register, that they can act on. */
    @AuraEnabled
    public static Answer draftReply(Id handoffId) {
        Human_Handoff__c h = [
            SELECT Reachable_By__c, Barrier_Report__r.Functional_Description__c,
                   Barrier_Report__r.Interpreter_Needed__c,
                   Barrier_Report__r.Access_Profile__r.Plain_Language_Mode__c
            FROM Human_Handoff__c WHERE Id = :handoffId WITH SECURITY_ENFORCED LIMIT 1];

        Boolean plain = h.Barrier_Report__r != null
            && h.Barrier_Report__r.Access_Profile__r != null
            && h.Barrier_Report__r.Access_Profile__r.Plain_Language_Mode__c == true;
        Boolean interp = h.Barrier_Report__r != null
            && h.Barrier_Report__r.Interpreter_Needed__c == true;

        Answer a = new Answer();
        a.refused = false;
        a.channel = h.Reachable_By__c;
        a.plainLanguage = plain;

        List<String> lines = new List<String>();
        lines.add(plain
            ? 'Hello. A person is looking at this now. You do not need to do anything.'
            : 'Hello - a real person has picked this up and is looking at it now. '
              + 'You do not need to do anything or explain it again.');
        if (interp) {
            lines.add(plain
                ? 'We are booking someone to interpret. We will not use a machine for this.'
                : 'We are arranging a human interpreter. Your video will not be machine '
                  + 'translated, and I will text you again as soon as it is booked.');
        }
        lines.add(plain
            ? 'I will write again here. You will not have to phone anyone.'
            : 'I will come back to you here, on this channel. You will not be asked to '
              + 'telephone anyone at any point.');

        a.message = 'Drafted for ' + (String.isBlank(h.Reachable_By__c)
            ? 'their channel' : h.Reachable_By__c.toLowerCase())
            + (plain ? ', in plain language because they asked for it.' : '.')
            + ' Nothing is sent until you send it.';
        a.body = String.join(lines, '\n\n');
        return a;
    }

    /**
     * Free-text help for the operator, with the same boundaries as everywhere else.
     * The refusal path is the one that matters: an internal tool is exactly where
     * a privacy promise gets quietly exempted, and this is where it does not.
     */
    @AuraEnabled
    public static Answer ask(Id handoffId, String question) {
        Answer a = new Answer();
        a.refused = false;

        if (String.isBlank(question)) {
            a.message = 'Ask whatever would help you answer this person well.';
            return a;
        }
        if (MEDICAL.matcher(question).matches()) {
            a.refused = true;
            a.message = 'No, and not because of a permission setting.\n\n'
                + 'There is no field for a diagnosis, condition, disability type, medical note, '
                + 'severity or prognosis anywhere in this system. Nobody holds that, including '
                + 'the person who built it, and the person you are helping was never asked. '
                + 'A manager who asks you gets the same answer, and you can tell them it came '
                + 'from the system rather than from you.\n\n'
                + 'What you can act on is what they said is hard, which is on the record, and '
                + 'what could help, which is in the library.';
            return a;
        }
        if (question.containsIgnoreCase('call') || question.containsIgnoreCase('phone')) {
            a.message = 'Not by telephone. For some of the people who reach this service a '
                + 'phone call is a door that does not open, and every workplace process they '
                + 'have already tried ended at "give us a call". Reply on the channel on the '
                + 'record. If you think this one genuinely needs a voice, ask them in writing '
                + 'first and let them choose.';
            return a;
        }
        if (question.containsIgnoreCase('cost') || question.containsIgnoreCase('expensive')
            || question.containsIgnoreCase('budget') || question.containsIgnoreCase('afford')) {
            CurbCutCostBrief.Result c =
                CurbCutCostBrief.build(new List<CurbCutCostBrief.Request>{
                    new CurbCutCostBrief.Request() })[0];
            a.message = 'The published evidence, with its denominator, so you can quote it safely.';
            a.body = c.brief;
            return a;
        }
        a.message = 'This assistant is deliberately grounded and narrow: it answers from the '
            + 'sourced library and this record, and will not improvise about a person. '
            + 'Use the steps above for what to do next, or ask about cost, channel, or what '
            + 'could be offered.';
        return a;
    }

    /**
     * Records that a holding message went out. Deliberately a separate,
     * explicit act rather than something drafting implies: the ledger must mean
     * "we tried to reach this person", and a row written when nobody actually
     * sent anything makes the one honest record in the system into a lie.
     */
    @AuraEnabled
    public static void logSent(Id handoffId, String channel, String detail) {
        Human_Handoff__c h = [
            SELECT Barrier_Report__c FROM Human_Handoff__c
            WHERE Id = :handoffId WITH SECURITY_ENFORCED LIMIT 1];
        String ch = 'Web';
        if (String.isNotBlank(channel)) {
            String c = channel.toLowerCase();
            if (c.contains('text') || c.contains('message')) { ch = 'SMS'; }
            else if (c.contains('video')) { ch = 'SMS'; }
            else if (c.contains('mail'))  { ch = 'Email'; }
        }
        CurbCutLog.record(ch, 'Outbound', 'Accepted', null,
            String.isBlank(detail) ? 'holding message sent by an operator' : detail,
            h.Barrier_Report__c);
    }
}
