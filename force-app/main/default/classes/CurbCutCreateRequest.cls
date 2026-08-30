/**
 * CurbCutCreateRequest
 *
 * The only path that writes an Accommodation_Request__c.
 *
 * Person_Approved__c is not a convenience flag. The Requires_Person_Approval
 * validation rule blocks the insert without it, and this class refuses to set
 * it unless the caller passed explicit approval through. Two locks, because
 * an agent optimising for a completed task will find one.
 */
public with sharing class CurbCutCreateRequest {

    private static final Integer INTERACTIVE_PROCESS_DAYS = 10;

    public class Request {
        @InvocableVariable(required=true label='The draft the person read')
        public String draft;

        @InvocableVariable(required=true label='True only if the person said yes in this conversation')
        public Boolean approved;

        @InvocableVariable(label='Barrier Report this request came from, if there is one')
        public String barrierReportId;
    }

    public class Result {
        @InvocableVariable(label='Id of the created request, blank when nothing was created')
        public String requestId;

        @InvocableVariable(label='True when a request was created')
        public Boolean created;

        @InvocableVariable(label='What to tell the person')
        public String message;
    }

    @InvocableMethod(
        label='Create accommodation request'
        description='Creates a request ONLY on explicit approval from the person.'
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
        res.requestId = '';

        if (req.approved != true) {
            res.message = 'Nothing was sent. You have not said yes yet, and I will not send it until you do.';
            return res;
        }
        if (String.isBlank(req.draft)) {
            res.message = 'There is nothing drafted to send yet.';
            return res;
        }

        Accommodation_Request__c ar = new Accommodation_Request__c(
            Person_Approved__c        = true,
            Approved_At__c            = System.now(),
            Manager_Response__c       = 'Pending',
            Interactive_Process_Due__c = Date.today().addDays(INTERACTIVE_PROCESS_DAYS)
        );

        if (String.isNotBlank(req.barrierReportId)) {
            try {
                ar.Barrier_Report__c = Id.valueOf(req.barrierReportId);
            } catch (Exception e) {
                // A bad id must not cost the person their request.
                ar.Barrier_Report__c = null;
            }
        }

        try {
            insert ar;
            res.requestId = ar.Id;
            res.created = true;
            res.message = 'Sent. You will hear back by ' + ar.Interactive_Process_Due__c.format()
                        + ' at the latest. You can stop this any time.';
        } catch (DmlException e) {
            res.message = 'I could not send that, and that is my problem, not yours. '
                        + 'Reply HUMAN and a real person will pick this up.';
        }
        return res;
    }
}
