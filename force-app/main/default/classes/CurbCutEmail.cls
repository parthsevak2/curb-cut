/**
 * CurbCutEmail — the email front door.
 *
 * Email reaches people the other channels miss. Someone with no mobile plan but
 * a library account. Someone whose phone is shared with the person they are
 * trying to get away from. Someone who needs to compose slowly, re-read, and
 * come back tomorrow — which a chat window punishes and an inbox does not.
 *
 * Same grounded library, same refusal to guess. Nothing is ever sent onward
 * from an email: an email cannot carry the explicit, in-the-moment approval a
 * request requires, so this channel consults and hands off, and says so.
 */
global with sharing class CurbCutEmail implements Messaging.InboundEmailHandler {

    /**
     * Apex suppresses real sending in tests and reports success, which would
     * leave the escalation path -- the one that matters when the org's daily
     * email cap is exhausted -- permanently unexercised. This seam lets a test
     * force the failure it cannot otherwise produce.
     */
    @TestVisible private static Boolean forceReplyFailure = false;

    global Messaging.InboundEmailResult handleInboundEmail(
            Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        result.success = true;   // never bounce; a bounce is a door closing

        String body = pickBody(email);
        if (String.isBlank(body)) {
            reply(email, envelope, greeting(), null);
            return result;
        }

        // Control words before anything else. This channel used to tell people
        // to "reply with the word PERSON" and then feed PERSON to the library,
        // which answered with "face the person when speaking". The one route out
        // was the one route that did not work.
        CurbCutKeyword.Match kw = CurbCutKeyword.route(body);
        if (kw.matched) {
            reply(email, envelope, forKeyword(kw), null);
            return result;
        }

        // Log the intake anonymously. The sender address is never stored.
        CurbCutIntake.Request ir = new CurbCutIntake.Request();
        ir.functionalDescription = body;
        ir.inboundModality = hasImage(email) ? 'Image' : 'Text';
        CurbCutIntake.Result intake =
            CurbCutIntake.log(new List<CurbCutIntake.Request>{ ir })[0];

        CurbCutOptions.Request optReq = new CurbCutOptions.Request();
        optReq.need = body;
        optReq.limitSize = 4;
        CurbCutOptions.Result opts =
            CurbCutOptions.find(new List<CurbCutOptions.Request>{ optReq })[0];

        reply(email, envelope, compose(opts, intake), intake.barrierReportId);
        return result;
    }

    private String pickBody(Messaging.InboundEmail email) {
        String b = String.isNotBlank(email.plainTextBody)
            ? email.plainTextBody
            : (email.htmlBody == null ? '' : email.htmlBody.stripHtmlTags());
        if (String.isBlank(b)) { return ''; }
        // Trim quoted history so a long reply chain is not read as the need.
        for (String marker : new List<String>{ '\nOn ', '\n>', '-----Original', 'From:' }) {
            Integer i = b.indexOf(marker);
            if (i > 40) { b = b.substring(0, i); }
        }
        return b.trim().left(4000);
    }

    private Boolean hasImage(Messaging.InboundEmail email) {
        if (email.binaryAttachments == null) { return false; }
        for (Messaging.InboundEmail.BinaryAttachment a : email.binaryAttachments) {
            String n = (a.fileName == null ? '' : a.fileName).toLowerCase();
            if (n.endsWith('.jpg') || n.endsWith('.jpeg') || n.endsWith('.png')
             || n.endsWith('.gif') || n.endsWith('.heic') || n.endsWith('.webp')) {
                return true;
            }
        }
        return false;
    }

    /**
     * Control words, answered the same way they are answered everywhere else.
     * HUMAN books a real person here rather than only promising one.
     */
    private String forKeyword(CurbCutKeyword.Match kw) {
        if (kw.intent == 'HUMAN') {
            CurbCutCreateHandoff.Request hr = new CurbCutCreateHandoff.Request();
            hr.context = 'Asked for a person by email.';
            hr.reachableBy = 'Email';
            CurbCutCreateHandoff.Result hres =
                CurbCutCreateHandoff.create(new List<CurbCutCreateHandoff.Request>{ hr })[0];
            return 'Yes.\n\n'
                 + (hres.created
                     ? hres.handlerName + ' will pick this up and reply to this email. '
                     : 'A real person will pick this up and reply to this email. ')
                 + 'You will not have to explain it again, and nobody will ring you.\n\n'
                 + signature();
        }
        if (kw.intent == 'WHO' || kw.intent == 'OFF') {
            if (String.isBlank(kw.code)) {
                return kw.message + '\n\n' + signature();
            }
            CurbCutStanding.Result sr =
                CurbCutStanding.byCode(kw.intent == 'WHO' ? 'who' : 'revoke', kw.code);
            return sr.message + '\n\n' + signature();
        }
        if (kw.intent == 'STOP') {
            return 'Done. I will not write to you again unless you write first.\n\n'
                 + 'Nothing about you was being kept anyway. There is no list to come off.\n\n'
                 + signature();
        }
        return kw.message + '\n\n' + signature();
    }

    private String greeting() {
        return 'Hi.\n\n'
             + 'I can help you work out what might make work easier, and help you ask for it.\n\n'
             + 'You do not have to tell me your name. You do not have to tell me what condition '
             + 'you have. I will never ask.\n\n'
             + 'Just reply and tell me what is hard right now, in your own words.\n\n'
             + 'Reply HUMAN at any point and a real person takes over instead.\n\n'
             + signature();
    }

    private String compose(CurbCutOptions.Result opts, CurbCutIntake.Result intake) {
        String s = 'Thank you for writing.\n\n';
        if (opts.noMatch) {
            s += 'I do not have good information on that one, and I would rather tell you '
               + 'that than guess.\n\n'
               + 'A real person can help. Reply with the word HUMAN and someone will pick '
               + 'this up by email. You will not have to explain it again.\n\n';
        } else {
            s += 'Here is what other people have asked for in situations like yours.\n\n'
               + opts.options + '\n\n'
               + 'You can stop here. Knowing is allowed, and asking is optional.\n\n'
               + 'If you would like help actually asking for one of these, the quickest way '
               + 'is to open this page, where you can read the request and press send yourself:\n'
               + SITE + '/ask\n\n'
               + 'I do not send anything on your behalf from email. Agreeing to something in '
               + 'writing, days later, is not the same as choosing it in the moment, so the '
               + 'send button stays where you can see exactly what it will do.\n\n';
        }
        s += 'Nothing about a diagnosis or condition was recorded. There is nowhere in this '
           + 'system to put one.\n\n';
        return s + signature();
    }

    private static final String SITE =
        'https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut';

    private String signature() {
        return '— Curb Cut\n'
             + SITE + '\n'
             + 'Text +1 276 495 9311, or reply to this email. Whichever is easier.';
    }

    /**
     * Reply, and escalate to a person if the reply cannot be delivered.
     *
     * The org has a hard daily cap on outbound email. Once it is exhausted, or
     * if delivery fails for any other reason, a person who wrote in gets nothing
     * back and never learns why. Silence is the failure mode this whole project
     * exists to remove, so a failed reply becomes a human handoff rather than a
     * log line nobody reads.
     */
    private void reply(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope,
                       String bodyText, String barrierId) {
        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
        msg.setToAddresses(new List<String>{ envelope.fromAddress });
        msg.setSubject('Re: ' + (String.isBlank(email.subject) ? 'what could make work easier' : email.subject));
        msg.setPlainTextBody(bodyText);

        CurbCutLog.record('Email', 'Inbound', 'Accepted', envelope.fromAddress, null, barrierId);

        Boolean delivered = false;
        String detail = null;
        try {
            if (forceReplyFailure) { throw new EmailException('forced for test'); }
            List<Messaging.SendEmailResult> res =
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ msg }, false);
            delivered = !res.isEmpty() && res[0].isSuccess();
            if (!delivered && !res.isEmpty()) {
                List<String> errs = new List<String>();
                for (Messaging.SendEmailError err : res[0].getErrors()) {
                    errs.add(err.getStatusCode() + ': ' + err.getMessage());
                }
                detail = String.join(errs, ' | ');
                System.debug(LoggingLevel.ERROR, 'reply rejected: ' + detail);
            }
        } catch (Exception e) {
            detail = e.getTypeName() + ': ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, 'reply failed: ' + detail);
        }

        CurbCutLog.record('Email', 'Outbound',
            delivered ? 'Accepted' : 'Rejected',
            envelope.fromAddress, detail, barrierId);

        if (!delivered) {
            escalate(barrierId);
            CurbCutLog.record('Email', 'Outbound', 'Escalated',
                envelope.fromAddress, 'Reply undeliverable; handed to a person.', barrierId);
        }
    }

    private class EmailException extends Exception {}

    /** Nobody is left with silence. */
    private void escalate(String barrierId) {
        try {
            CurbCutCreateHandoff.Request hr = new CurbCutCreateHandoff.Request();
            hr.context = 'Wrote in by email. The automated reply could not be delivered.';
            hr.barrierReportId = barrierId;
            CurbCutCreateHandoff.create(new List<CurbCutCreateHandoff.Request>{ hr });
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'escalation failed: ' + e.getMessage());
        }
    }
}
