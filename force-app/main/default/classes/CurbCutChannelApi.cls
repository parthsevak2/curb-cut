/**
 * One door for every channel that is not the web page.
 *
 * SMS had its own keyword list in JavaScript. Email had different words again,
 * in Apex. The web had none at all. Three channels, three sets of rules, and
 * the person is the same person - somebody who texts on Monday and emails on
 * Thursday was talking to two services that disagreed about what the word OFF
 * meant, and one of them was wrong.
 *
 * So the routing lives in Apex, once, and every channel asks this. A new
 * channel gets the whole contract - the control words, the grounded library,
 * the refusal to send anything without a yes, the ledger - by calling one
 * endpoint, and cannot accidentally ship a channel that answers differently.
 *
 * This is authenticated. It is a server-to-server door for a relay we run, not
 * the anonymous public surface; that is the Visualforce site, which needs no
 * credential at all and never will.
 */
@RestResource(urlMapping='/curbcut/v1/message/*')
global with sharing class CurbCutChannelApi {

    global class Answer {
        global String  intent      { get; set; }
        global String  message     { get; set; }
        global String  options     { get; set; }
        global Boolean noMatch     { get; set; }
        global Boolean handedOff   { get; set; }
        global String  handlerName { get; set; }
        global String  barrierId   { get; set; }
        global String  claimCode   { get; set; }
    }

    /** Channels we will answer for, mapped to how a person is reached back. */
    private static final Map<String, String> REPLY_ON = new Map<String, String>{
        'SMS'      => 'Text message',
        'Slack'    => 'Slack',
        'Email'    => 'Email',
        'Web'      => 'Web chat',
        'External' => 'Text message'
    };

    @HttpPost
    global static Answer post() {
        RestRequest req = RestContext.request;
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(
            req.requestBody == null ? '{}' : req.requestBody.toString());

        String channel = str(body.get('channel'));
        String text    = str(body.get('text'));
        String who     = str(body.get('handle'));
        String barrier = str(body.get('barrierId'));

        if (!REPLY_ON.containsKey(channel)) { channel = 'External'; }
        return handle(channel, text, who, barrier);
    }

    private static String str(Object o) { return o == null ? null : String.valueOf(o); }

    /**
     * Public so an Apex caller can reach it without going out over HTTP to come
     * straight back in. The email handler and the tests use this directly.
     */
    public static Answer handle(String channel, String text, String handle, String barrierId) {
        Answer a = new Answer();
        a.intent = 'NONE';
        a.noMatch = false;
        a.handedOff = false;
        a.barrierId = barrierId;

        CurbCutLog.record(channel, 'Inbound', 'Accepted', handle, 'message received', barrierId);

        if (String.isBlank(text)) {
            a.message = 'Tell me what is hard at work, in your own words. You never '
                      + 'have to say what condition you have.';
            return a;
        }

        // Control words first, everywhere, identically.
        CurbCutKeyword.Match kw = CurbCutKeyword.route(text);
        if (kw.matched) {
            a.intent = kw.intent;
            if (kw.intent == 'HUMAN') {
                CurbCutCreateHandoff.Request hr = new CurbCutCreateHandoff.Request();
                hr.context = 'Asked for a person on ' + channel + '.';
                hr.barrierReportId = barrierId;
                hr.reachableBy = REPLY_ON.get(channel);
                CurbCutCreateHandoff.Result hres = CurbCutCreateHandoff.create(
                    new List<CurbCutCreateHandoff.Request>{ hr })[0];
                a.handedOff   = hres.created;
                a.handlerName = hres.handlerName;
                a.message = hres.created
                    ? hres.handlerName + ' is picking this up. They will reply here, on this '
                      + 'same channel. You will not have to explain it again, and nobody '
                      + 'will ring you.'
                    : 'I could not reach a person just now, and I am not going to pretend '
                      + 'I did. Write to parth.sevak2@gmail.com and somebody will pick it up.';
            } else if (kw.intent == 'WHO' || kw.intent == 'OFF') {
                if (String.isBlank(kw.code)) {
                    a.message = kw.message;
                } else {
                    CurbCutStanding.Result sr = CurbCutStanding.byCode(
                        kw.intent == 'WHO' ? 'who' : 'revoke', kw.code);
                    a.message = sr.message;
                }
            } else {
                a.message = kw.message;
            }
            CurbCutLog.record(channel, 'Outbound', 'Accepted', handle,
                              'keyword: ' + kw.intent.toLowerCase(), barrierId);
            return a;
        }

        // Not a control word, so it is a need. Log it anonymously and answer it
        // from the library, never from the model's own idea of an accommodation.
        CurbCutIntake.Request ir = new CurbCutIntake.Request();
        ir.functionalDescription = text;
        ir.inboundModality = 'Text';
        CurbCutIntake.Result intake = CurbCutIntake.log(
            new List<CurbCutIntake.Request>{ ir })[0];
        a.barrierId = intake.barrierReportId;

        CurbCutOptions.Request optReq = new CurbCutOptions.Request();
        optReq.need = text;
        optReq.limitSize = 4;
        CurbCutOptions.Result opts = CurbCutOptions.find(
            new List<CurbCutOptions.Request>{ optReq })[0];

        a.options = opts.options;
        a.noMatch = opts.noMatch;
        String took = intake.redacted == true ? CurbCutRedact.notice() + '\n\n' : '';
        a.message = took + (opts.noMatch
            ? 'I do not have good information on that one, and I would rather say so '
              + 'than guess. Send HUMAN and a real person will pick it up instead.'
            : 'Here is what other people have asked for in situations like yours. You '
              + 'can stop here. Knowing is allowed, and asking is optional.');

        CurbCutLog.record(channel, 'Outbound', 'Accepted', handle,
                          opts.noMatch ? 'no match' : 'options returned', a.barrierId);
        return a;
    }
}
