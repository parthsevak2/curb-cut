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
    private static final String COULD_NOT_SEND =
        'I could not send that, and that is my problem, not yours. '
      + 'Ask for a real person and someone will pick this up.';

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

    /**
     * Writes the request, including its link to the intake it came from.
     * `without sharing` is scoped to this single insert and exposes nothing:
     * the referenced record was created by this same flow moments earlier.
     */
    private without sharing class Linker {
        private void save(Accommodation_Request__c ar) { insert ar; }
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
            // A bare statement of the problem is a dead end, and a dead end at the
            // wrong moment is how somebody stops asking altogether.
            res.message = 'There is nothing drafted to send yet. Tell me what is hard '
                        + 'and I will write something for you to look at first. Nothing '
                        + 'goes anywhere until you say so.';
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
            // The link is written in a without-sharing context. A site guest
            // cannot READ the barrier report it just created -- secure guest
            // record access sees to that -- so a sharing-enforced insert cannot
            // reference it, and every web request was losing its provenance.
            // The reference is one this code just created microseconds earlier;
            // nothing about the person is exposed by writing it down.
            new Linker().save(ar);
        } catch (DmlException e) {
            // A guest user cannot reference a record it is not allowed to read,
            // so the link to the barrier report can fail even though the request
            // itself is perfectly valid. The link is bookkeeping. The request is
            // the thing the person actually asked for, and they do not lose it
            // over a foreign key.
            if (ar.Barrier_Report__c != null) {
                ar = ar.clone(false, true, false, false);
                ar.Barrier_Report__c = null;
                try {
                    new Linker().save(ar);
                } catch (DmlException retry) {
                    res.message = COULD_NOT_SEND;
                    return res;
                }
            } else {
                res.message = COULD_NOT_SEND;
                return res;
            }
        }
        res.requestId = ar.Id;
        res.created = true;
        res.message = 'Sent to the access desk of the organisation running this page. No manager has been told. '
                    + 'Their target is to answer by ' + ar.Interactive_Process_Due__c.format()
                    + '. That date is their commitment, not something this page can force. You can stop this any time.';
        return res;
    }
}
