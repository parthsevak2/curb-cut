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

        @InvocableVariable(label='True when a named condition was taken out before saving')
        public Boolean redacted;

        /**
         * Shown once, at save, and never again. We keep only a hash, so this is
         * the person's copy and the only readable one. It is what lets somebody
         * turn this off from a text message on a channel where, by design, we
         * have no idea who they are.
         */
        @InvocableVariable(label='The code the person keeps')
        public String claimCode;
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
        /**
         * Reading by code has the same problem as revoking by id: the guest user
         * cannot see the row. Scoped to one field lookup, returning at most one
         * record, and only ever reachable by somebody holding the code.
         */
        private List<Access_Preference__c> byHash(String hash) {
            return [SELECT Id, Statement__c, Shared_With__c, Scope__c, Revoked_On__c
                      FROM Access_Preference__c
                     WHERE Claim_Code_Hash__c = :hash
                     LIMIT 1];
        }
    }

    private static Result save(Request req) {
        Result res = new Result();
        res.ok = false; res.preferenceId = ''; res.redacted = false;

        if (String.isBlank(req.statement)) {
            res.message = 'There is nothing to save yet.';
            return res;
        }

        // The condition comes out here, before the insert, the same way it does
        // in CurbCutIntake. Statement__c is the one text built to be shown to a
        // manager or a meeting host, so "I have epilepsy, no strobing slides"
        // stored whole would travel further than anything else we hold. We keep
        // "no strobing slides". That is the part they need to read.
        String statement = req.statement;
        res.redacted = false;
        if (CurbCutRedact.names(statement)) {
            statement = CurbCutRedact.clean(statement);
            res.redacted = true;
        }

        Access_Preference__c p = new Access_Preference__c(
            Statement__c   = statement,
            Scope__c       = String.isNotBlank(req.scope) ? req.scope : 'Always',
            Shared_With__c = String.isNotBlank(req.sharedWith) ? req.sharedWith : 'Manager only',
            Auto_Apply__c  = req.autoApply == true
        );
        String code = CurbCutKeyword.newCode();
        p.Claim_Code_Hash__c = hash(code);
        try {
            new Pen().save(p);
            res.preferenceId = p.Id;
            res.ok = true;
            res.sharedWith = p.Shared_With__c;
            res.claimCode = code;
            // Never STOP. STOP belongs to the carrier: it unsubscribes the person
            // from the number entirely, and is intercepted before it ever reaches
            // us. Someone told to reply STOP to turn off one preference would lose
            // the whole service and keep the preference, which is the exact
            // opposite of what they asked for. OFF is ours; STOP is not.
            //
            // When something was taken out, the notice goes first, in the same
            // reply, so the person is told before they read back what was kept.
            res.message = (res.redacted ? CurbCutRedact.notice() + '\n\n' : '')
                        + 'Saved. ' + p.Shared_With__c + ' will see it.\n\n'
                        + 'Your code is ' + code + '. Keep it somewhere you can find it.\n\n'
                        + 'Send WHO ' + code + ' to see everyone who has been shown this. '
                        + 'Send OFF ' + code + ' to turn it off. I will not ask why. '
                        + 'Both work from here, by text, or by email.\n\n'
                        + 'I am showing you this code because I cannot look you up. '
                        + 'I do not know who you are, and I would rather keep it that way.';
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
            res.message = 'I could not turn that off. Send HUMAN and a person will.';
        }
        return res;
    }

    private static final String CODE_SALT = 'curb-cut-claim-salt-v1';

    private static String hash(String code) {
        return EncodingUtil.convertToHex(Crypto.generateDigest(
            'SHA-256', Blob.valueOf(CODE_SALT + code.toUpperCase()))).substring(0, 64);
    }

    /**
     * WHO and OFF, from any channel, for somebody holding the code.
     *
     * A wrong code is answered the same way as a code for a preference that was
     * already turned off: no confirmation either way. Telling somebody "that
     * code is not one of ours" would turn this into an oracle for guessing at
     * other people's codes.
     */
    public static Result byCode(String operation, String code) {
        Result res = new Result();
        res.ok = false;
        res.preferenceId = '';

        if (String.isBlank(code)) {
            res.message = 'Send the word and your six letter code together, like '
                        + 'OFF 4KQ7MT. It was in the message where you set this up. '
                        + 'If you do not have it, send HUMAN and a person will sort it out.';
            return res;
        }

        List<Access_Preference__c> found = new Pen().byHash(hash(code));
        if (found.isEmpty() || found[0].Revoked_On__c != null) {
            res.message = 'That code is not switched on for anything right now. '
                        + 'If you think it should be, send HUMAN and a person will '
                        + 'look into it with you.';
            return res;
        }

        Access_Preference__c p = found[0];
        res.preferenceId = p.Id;
        res.sharedWith   = p.Shared_With__c;

        if ('who'.equalsIgnoreCase(operation)) {
            List<Disclosure_Event__c> seen = [
                SELECT Shown_To__c, Shown_At__c, Context__c
                  FROM Disclosure_Event__c
                 WHERE Access_Preference__c = :p.Id
                 ORDER BY Shown_At__c DESC
                 LIMIT 50];
            res.ok = true;
            if (seen.isEmpty()) {
                res.message = 'Nobody has been shown it yet. It is set to go to '
                            + p.Shared_With__c + '. Send OFF ' + code.toUpperCase()
                            + ' to turn it off.';
                return res;
            }
            String s = 'Shown to:\n';
            for (Disclosure_Event__c d : seen) {
                s += '- ' + (String.isBlank(d.Shown_To__c) ? 'someone unnamed' : d.Shown_To__c)
                   + (d.Shown_At__c == null ? '' : ', ' + d.Shown_At__c.format('d MMMM yyyy'))
                   + '\n';
            }
            res.message = s + '\nSend OFF ' + code.toUpperCase() + ' to turn it off.';
            return res;
        }

        Request r = new Request();
        r.operation = 'revoke';
        r.preferenceId = p.Id;
        Result done = revoke(r);
        done.preferenceId = p.Id;
        return done;
    }
}
