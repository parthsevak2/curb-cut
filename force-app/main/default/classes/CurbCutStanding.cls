/**
 * CurbCutStanding
 *
 * Principle 4: you should have to ask once, not forever.
 *
 * Revocation is the part that matters. It is instant, it needs no reason, and
 * this class does not accept a reason parameter -- there is nowhere to put one,
 * so nobody can be asked for one later.
 */
public with sharing class CurbCutStanding {

    public class Request {
        @InvocableVariable(required=true label='save or revoke')
        public String operation;

        @InvocableVariable(label='The preference in the person\'s exact words')
        public String statement;

        @InvocableVariable(label='Always, Meetings, This team or This manager')
        public String scope;

        @InvocableVariable(label='Manager only, Meeting hosts or My team')
        public String sharedWith;

        @InvocableVariable(label='Apply ahead of time without being asked')
        public Boolean autoApply;

        @InvocableVariable(label='Preference to revoke')
        public String preferenceId;
    }

    public class Result {
        @InvocableVariable(label='Id of the preference')
        public String preferenceId;

        @InvocableVariable(label='True when the operation succeeded')
        public Boolean ok;

        @InvocableVariable(label='Who will be shown this preference')
        public String sharedWith;

        @InvocableVariable(label='What to tell the person')
        public String message;
    }

    @InvocableMethod(
        label='Save or revoke a standing preference'
        description='Revocation is immediate and requires no reason.'
    )
    public static List<Result> run(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            results.add('revoke'.equalsIgnoreCase(req.operation) ? revoke(req) : save(req));
        }
        return results;
    }


    /**
     * The site guest user can create a preference but cannot edit one, and
     * secure guest record access means it cannot read back the row it just
     * wrote. Both are correct defaults and both would make revocation from the
     * web impossible, which would leave a person able to switch a disclosure ON
     * and not OFF. That is the worst possible asymmetry for this particular
     * feature, so the write runs without sharing -- narrowly, on one object,
     * by id, with no reason recorded and nothing read back.
     */
    private without sharing class Pen {
        private void save(Access_Preference__c p) { insert p; }
        private void revoke(Id prefId) {
            update new Access_Preference__c(Id = prefId, Revoked_On__c = System.now());
        }
    }

    private static Result save(Request req) {
        Result res = new Result();
        res.ok = false; res.preferenceId = '';

        if (String.isBlank(req.statement)) {
            res.message = 'There is nothing to save yet.';
            return res;
        }

        Access_Preference__c p = new Access_Preference__c(
            Statement__c   = req.statement,
            Scope__c       = String.isNotBlank(req.scope) ? req.scope : 'Always',
            Shared_With__c = String.isNotBlank(req.sharedWith) ? req.sharedWith : 'Manager only',
            Auto_Apply__c  = req.autoApply == true
        );
        try {
            new Pen().save(p);
            res.preferenceId = p.Id;
            res.ok = true;
            res.sharedWith = p.Shared_With__c;
            // Never STOP. STOP belongs to the carrier: it unsubscribes the person
            // from the number entirely, and is intercepted before it ever reaches
            // us. Someone told to reply STOP to turn off one preference would lose
            // the whole service and keep the preference, which is the exact
            // opposite of what they asked for. OFF is ours; STOP is not.
            res.message = 'Saved. ' + p.Shared_With__c + ' will see it. '
                        + 'Reply WHO any time to see everyone who has been shown it. '
                        + 'Reply OFF any time to turn it off. I will not ask why.';
        } catch (DmlException e) {
            res.message = 'I could not save that.';
        }
        return res;
    }

    private static Result revoke(Request req) {
        Result res = new Result();
        res.ok = false;
        res.preferenceId = String.isNotBlank(req.preferenceId) ? req.preferenceId : '';

        if (String.isBlank(req.preferenceId)) {
            res.message = 'Tell me which one to turn off and I will do it.';
            return res;
        }
        try {
            new Pen().revoke(Id.valueOf(req.preferenceId));
            res.ok = true;
            // No reason is captured. There is nowhere to put one.
            res.message = 'Turned off. It will not be shown to anyone again.';
        } catch (Exception e) {
            res.message = 'I could not turn that off. Reply HUMAN and a person will.';
        }
        return res;
    }
}
