/**
 * CurbCutWeb — the web front door.
 *
 * Not everyone has a phone. Not everyone has a phone plan, or a phone they can
 * use privately, or a phone at all. A library computer, a shared desktop, a
 * screen reader on a laptop: these must be front doors too, or the whole
 * argument about removing barriers is only true for people who already have one.
 *
 * This runs as the site guest user. It is deliberately DETERMINISTIC: it calls
 * exactly the same Apex actions the agent calls, in the same order, against the
 * same grounded library -- with no model in the loop. For the highest-stakes
 * step, creating a request, that means there is nothing to hallucinate. The
 * approval gate is code, not judgement.
 *
 * Every method is @RemoteAction so the page can call it without a credential
 * ever reaching the browser.
 */
global with sharing class CurbCutWeb {

    global class Reply {
        global String  message      { get; set; }
        global String  options      { get; set; }
        global Boolean noMatch      { get; set; }
        global String  draft        { get; set; }
        global String  barrierId    { get; set; }
        global String  requestId    { get; set; }
        global String  handlerName  { get; set; }
        global Boolean created      { get; set; }
        global String  preferenceId { get; set; }
        global String  sharedWith   { get; set; }
        global String  shownTo      { get; set; }
        global Integer shownCount   { get; set; }
    }

    /**
     * Every web action writes to the delivery ledger. Email, SMS and voice all
     * did; the web did not, so the one channel anybody can use today was the
     * one missing from the answer to "did we reach this person". Web has no
     * address to hash, and passing null is the honest record of that: the
     * conversation is anonymous and there is nothing to identify.
     */
    private static void ledger(String direction, String status, String detail, String barrierId) {
        CurbCutLog.record('Web', direction, status, null, detail, barrierId);
    }

    /**
     * Reads back the disclosure trail for one preference.
     *
     * Without sharing, deliberately and narrowly: the guest user cannot read a
     * Disclosure_Event__c at all, and this is the one question a person is
     * unconditionally entitled to an answer to -- who has been shown the thing
     * I said about myself. The caller must already hold the preference id,
     * which is handed to them and to nobody else. One object, one lookup, no
     * other person's rows reachable, because a preference belongs to one person.
     */
    private without sharing class Trail {
        private List<Disclosure_Event__c> forPreference(Id prefId) {
            return [
                SELECT Shown_To__c, Shown_At__c, Context__c
                FROM Disclosure_Event__c
                WHERE Access_Preference__c = :prefId
                ORDER BY Shown_At__c DESC
                LIMIT 200
            ];
        }
    }

    /** Step 1. Log what is hard, anonymously, and look up grounded options. */
    @RemoteAction
    global static Reply consult(String need) {
        Reply r = new Reply();
        r.created = false;
        ledger('Inbound', 'Accepted', 'consult', null);

        if (String.isBlank(need)) {
            r.message = 'Tell me what is hard right now, in your own words.';
            r.noMatch = true;
            return r;
        }

        // The web channel writes a barrier report every time. Anonymous by
        // default: no identity is attached, and there is nothing to attach.
        CurbCutIntake.Request ir = new CurbCutIntake.Request();
        ir.functionalDescription = need;
        ir.inboundModality = 'Text';
        CurbCutIntake.Result intake = CurbCutIntake.log(
            new List<CurbCutIntake.Request>{ ir })[0];
        r.barrierId = intake.barrierReportId;

        CurbCutOptions.Request optReq = new CurbCutOptions.Request();
        optReq.need = need;
        optReq.limitSize = 4;
        CurbCutOptions.Result opts = CurbCutOptions.find(
            new List<CurbCutOptions.Request>{ optReq })[0];

        r.options = opts.options;
        r.noMatch = opts.noMatch;
        r.message = opts.noMatch
            ? 'I do not have good information on that one, and I would rather tell you that than guess. You can ask for a real person instead.'
            : 'Here is what other people have asked for in situations like yours. You can stop here. Knowing is allowed; asking is optional.';
        return r;
    }

    /** Step 2. Draft the request, in their words. Writes nothing outward. */
    @RemoteAction
    global static Reply draft(String need, String chosenOption) {
        ledger('Inbound', 'Accepted', 'draft', null);
        Reply r = new Reply();
        r.created = false;

        CurbCutDraftRequest.Request dr = new CurbCutDraftRequest.Request();
        dr.need = need;
        dr.chosenOption = chosenOption;
        r.draft = CurbCutDraftRequest.draft(
            new List<CurbCutDraftRequest.Request>{ dr })[0].draft;

        r.message = String.isBlank(r.draft)
            ? 'There is nothing to draft yet.'
            : 'Read this over. Nothing is sent until you choose to send it.';
        return r;
    }

    /**
     * Step 3. Send it.
     *
     * `approved` is passed straight through and the Apex refuses anything that
     * is not literally true, and the validation rule refuses the insert
     * independently. On the web there is no hedge to misread -- a person either
     * pressed the button or did not. That is the point of putting the highest
     * stakes step on a deterministic channel.
     */
    @RemoteAction
    global static Reply send(String draftText, Boolean approved, String barrierId) {
        ledger('Inbound', 'Accepted', 'send requested', barrierId);
        CurbCutCreateRequest.Request cr = new CurbCutCreateRequest.Request();
        cr.draft = draftText;
        cr.approved = approved;
        cr.barrierReportId = barrierId;
        CurbCutCreateRequest.Result res = CurbCutCreateRequest.create(
            new List<CurbCutCreateRequest.Request>{ cr })[0];

        Reply r = new Reply();
        r.requestId = res.requestId;
        r.created   = res.created;
        r.message   = res.message;
        return r;
    }

    /** Any point. A real person, reachable by message, never by phone. */
    @RemoteAction
    global static Reply human(String context, String barrierId) {
        ledger('Inbound', 'Accepted', 'asked for a person', barrierId);
        CurbCutCreateHandoff.Request hr = new CurbCutCreateHandoff.Request();
        hr.context = context;
        hr.barrierReportId = barrierId;
        CurbCutCreateHandoff.Result res = CurbCutCreateHandoff.create(
            new List<CurbCutCreateHandoff.Request>{ hr })[0];

        Reply r = new Reply();
        r.handlerName = res.handlerName;
        r.created     = res.created;
        r.message     = res.created
            ? 'A person is picking this up. They will reply by message. You will not have to call anyone, and you will not have to explain any of this again.'
            : 'I could not reach a person just now. Please email parth.sevak2@gmail.com and someone will pick it up.';
        return r;
    }

    /**
     * Principle 4, finally reachable without a phone.
     *
     * CurbCutStanding has existed and been tested since the first week, wired
     * to the agent, and so usable only by voice or text. The web front door
     * does not go through the agent, so the promise this project is named for
     * -- explain once, and never explain it again to the next manager -- could
     * not be used by anyone arriving in a browser. Zero preferences existed.
     */
    @RemoteAction
    global static Reply saveStanding(String statement, String scope,
                                     String sharedWith, Boolean autoApply) {
        Reply r = new Reply();
        r.created = false;
        ledger('Inbound', 'Accepted', 'standing: save', null);

        if (String.isBlank(statement)) {
            r.message = 'Tell me what you would like remembered, in your own words.';
            return r;
        }

        CurbCutStanding.Request req = new CurbCutStanding.Request();
        req.operation  = 'save';
        req.statement  = statement;
        req.scope      = scope;
        req.sharedWith = sharedWith;
        req.autoApply  = autoApply == true;

        CurbCutStanding.Result res =
            CurbCutStanding.run(new List<CurbCutStanding.Request>{ req })[0];

        r.created      = res.ok;
        r.preferenceId = res.preferenceId;
        r.sharedWith   = res.sharedWith;
        r.message      = res.message;
        ledger('Outbound', res.ok ? 'Accepted' : 'Rejected',
               res.ok ? 'standing: saved' : 'standing: save failed', null);
        return r;
    }

    /** Immediate, and no reason is asked for, because there is nowhere to put one. */
    @RemoteAction
    global static Reply revokeStanding(String preferenceId) {
        Reply r = new Reply();
        r.created = false;
        ledger('Inbound', 'Accepted', 'standing: revoke', null);

        if (String.isBlank(preferenceId)) {
            r.message = 'Tell me which one to turn off and I will do it.';
            return r;
        }

        CurbCutStanding.Request req = new CurbCutStanding.Request();
        req.operation    = 'revoke';
        req.preferenceId = preferenceId;

        CurbCutStanding.Result res =
            CurbCutStanding.run(new List<CurbCutStanding.Request>{ req })[0];

        r.created      = res.ok;
        r.preferenceId = preferenceId;
        r.message      = res.message;
        ledger('Outbound', res.ok ? 'Accepted' : 'Rejected', 'standing: revoked', null);
        return r;
    }

    /**
     * WHO. A preference that travels ahead of someone is a disclosure made in
     * their absence, and they are entitled to the list without asking a person
     * for it.
     */
    @RemoteAction
    global static Reply whoSaw(String preferenceId) {
        Reply r = new Reply();
        r.created = false;
        r.shownCount = 0;
        ledger('Inbound', 'Accepted', 'standing: who', null);

        if (String.isBlank(preferenceId)) {
            r.message = 'I do not have a preference to look up.';
            return r;
        }

        List<Disclosure_Event__c> seen;
        try {
            seen = new Trail().forPreference(Id.valueOf(preferenceId));
        } catch (Exception e) {
            r.message = 'I could not look that up. Ask for a person and one will.';
            return r;
        }

        r.shownCount = seen.size();
        if (seen.isEmpty()) {
            r.message = 'Nobody has been shown it yet. If that changes, it will be listed here.';
            r.shownTo = '';
            return r;
        }

        List<String> lines = new List<String>();
        for (Disclosure_Event__c d : seen) {
            lines.add('- ' + (String.isBlank(d.Shown_To__c) ? 'someone unnamed' : d.Shown_To__c)
                    + (d.Shown_At__c == null ? '' : ' on ' + d.Shown_At__c.format('d MMMM yyyy'))
                    + (String.isBlank(d.Context__c) ? '' : ' (' + d.Context__c + ')'));
        }
        r.shownTo = String.join(lines, '\n');
        r.message = seen.size() == 1
            ? 'One person has been shown it.'
            : String.valueOf(seen.size()) + ' people have been shown it.';
        return r;
    }
}
