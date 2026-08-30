/**
 * CurbCutCreateHandoff
 *
 * The escape hatch. Reachable_By__c is hard-coded to 'Text message' because
 * the whole point is that nobody is routed to a phone call. If that ever
 * needs to change, it should be an argument someone has to make out loud.
 */
public with sharing class CurbCutCreateHandoff {

    private static final String REACHABLE_BY = 'Text message';
    private static final String FALLBACK_HANDLER = 'the access team';

    public class Request {
        @InvocableVariable(label='What the person said was hard, for the human picking this up')
        public String context;

        @InvocableVariable(label='Barrier Report this handoff came from, if there is one')
        public String barrierReportId;
    }

    public class Result {
        @InvocableVariable(label='Name of the person picking this up')
        public String handlerName;

        @InvocableVariable(label='Id of the created handoff')
        public String handoffId;

        @InvocableVariable(label='True when a handoff was created')
        public Boolean created;
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

    private static Result createOne(Request req) {
        Result res = new Result();
        res.created = false;
        res.handoffId = '';
        res.handlerName = FALLBACK_HANDLER;

        Human_Handoff__c hh = new Human_Handoff__c(
            Requested_At__c = System.now(),
            Reachable_By__c = REACHABLE_BY,
            Handler_Name__c = FALLBACK_HANDLER
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
            res.created = true;
        } catch (DmlException e) {
            // Even a failed handoff must not leave the person with nothing.
            res.created = false;
        }
        return res;
    }
}
