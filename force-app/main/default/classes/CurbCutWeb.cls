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
    }

    /** Step 1. Log what is hard, anonymously, and look up grounded options. */
    @RemoteAction
    global static Reply consult(String need) {
        Reply r = new Reply();
        r.created = false;

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
}
