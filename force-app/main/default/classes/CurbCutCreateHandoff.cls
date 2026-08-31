/**
 * CurbCutCreateHandoff
 *
 * The escape hatch.
 *
 * Reachable_By__c used to be hard-coded to 'Text message' to enforce the rule
 * that nobody is ever routed to a phone call. It enforced something narrower
 * than that and worse: somebody who wrote in by email got a handoff telling the
 * operator to text them, and this system holds no phone number to text. The
 * escape hatch was created and was not actionable.
 *
 * The rule was never "always text". It is "never a telephone". So the channel
 * is now an argument, and the telephone is refused here, in code, rather than
 * prevented by accident.
 */
public with sharing class CurbCutCreateHandoff {

    private static final String REACHABLE_BY = 'Text message';
    private static final String FALLBACK_HANDLER = 'the access team';

    /** Reply where they wrote from. Anything not here falls back to text. */
    private static final Set<String> ALLOWED = new Set<String>{
        'Text message', 'Email', 'Web chat', 'Slack', 'Video', 'In person'
    };

    /**
     * A phone call is a door that does not open for some of the people this
     * serves. Refused here so that no future caller can quietly route somebody
     * to one by passing a string.
     */
    private static final Set<String> NEVER = new Set<String>{
        'phone', 'call', 'telephone', 'voice', 'ring', 'dial'
    };

    public class Request {
        @InvocableVariable(label='What the person said was hard, for the human picking this up')
        public String context;

        @InvocableVariable(label='Barrier Report this handoff came from, if there is one')
        public String barrierReportId;

        @InvocableVariable(label='Where to reply to them. Never a telephone.')
        public String reachableBy;
    }

    public class Result {
        @InvocableVariable(label='Name of the person picking this up')
        public String handlerName;

        @InvocableVariable(label='Id of the created handoff')
        public String handoffId;

        @InvocableVariable(label='True when a handoff was created')
        public Boolean created;

        /**
         * Shown once. On the web the person is anonymous and there is no address
         * to reply to, so this is the only thing connecting them to the handler
         * they were just promised. We keep a hash and they keep this.
         */
        @InvocableVariable(label='The code the person keeps to come back')
        public String returnCode;
    }

    @InvocableMethod(
        label='Create human handoff'
        description='Hands off to a named human, reachable by message, never by phone.'
    )
    public static List<Result> create(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            results.add(createOne(req));
        }
        return results;
    }

    /**
     * Falls back to text rather than throwing. A handoff that refuses to be
     * created because an argument was wrong leaves a person with nothing, and
     * that is a worse outcome than a handler having to ask where to reply.
     */
    private static String channelFor(String asked) {
        if (String.isBlank(asked)) { return REACHABLE_BY; }
        String a = asked.trim();
        for (String bad : NEVER) {
            if (a.containsIgnoreCase(bad)) { return REACHABLE_BY; }
        }
        for (String ok : ALLOWED) {
            if (ok.equalsIgnoreCase(a)) { return ok; }
        }
        return REACHABLE_BY;
    }

    private static final String CODE_SALT = 'curb-cut-return-salt-v1';

    private static String hashCode(String code) {
        return EncodingUtil.convertToHex(Crypto.generateDigest(
            'SHA-256', Blob.valueOf(CODE_SALT + code.toUpperCase()))).substring(0, 64);
    }

    private static Result createOne(Request req) {
        Result res = new Result();
        res.created = false;
        res.handoffId = '';
        res.handlerName = FALLBACK_HANDLER;

        String code = CurbCutKeyword.newCode();
        Human_Handoff__c hh = new Human_Handoff__c(
            Requested_At__c     = System.now(),
            Reachable_By__c     = channelFor(req.reachableBy),
            Handler_Name__c     = FALLBACK_HANDLER,
            Return_Code_Hash__c = hashCode(code)
        );

        if (String.isNotBlank(req.barrierReportId)) {
            try {
                hh.Barrier_Report__c = Id.valueOf(req.barrierReportId);
            } catch (Exception e) {
                hh.Barrier_Report__c = null;
            }
        }

        try {
            insert hh;
            res.handoffId = hh.Id;
            res.handlerName = hh.Handler_Name__c;
            res.returnCode = code;
            res.created = true;
        } catch (DmlException e) {
            // Even a failed handoff must not leave the person with nothing.
            res.created = false;
        }
        return res;
    }
}
