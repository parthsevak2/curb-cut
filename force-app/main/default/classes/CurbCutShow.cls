/**
 * CurbCutShow
 *
 * The one place a standing preference is shown to somebody else.
 *
 * A preference that travels ahead of a person is a disclosure they made about
 * themselves while they were not in the room. Until this class existed nothing
 * in the org could show one to anybody. "Travels ahead of you" meant save and
 * revoke, and WHO could only ever answer that nobody had seen it. The ledger
 * object was there. Nothing wrote to it.
 *
 * Three rules, in the order they run:
 *
 * 1. We show a preference only to the audience the person chose. The viewer
 *    tells us who they are reading as, and we record what they told us.
 * 2. We write the Disclosure_Event__c before we return a single word. If the
 *    write fails, nothing is shown. A showing we cannot record is a showing
 *    we do not make.
 * 3. The words come back exactly as the person typed them. We never tidy,
 *    shorten or summarise a statement here.
 *
 * With sharing, on purpose. Whoever reads this can read only the rows the org
 * already lets them read. We do not widen anything to make the brief fuller.
 */
public with sharing class CurbCutShow {

    /** The audiences a person can pick. Mirrors Access_Preference__c.Shared_With__c. */
    public static final Set<String> ROLES = new Set<String>{
        'Manager only', 'Meeting hosts', 'My team'
    };

    public class Shown {
        @AuraEnabled public String  preferenceId { get; set; }
        /** The person's own words, untouched. */
        @AuraEnabled public String  statement    { get; set; }
        @AuraEnabled public String  scope        { get; set; }
        /** When they saved it, as a date they would recognise. */
        @AuraEnabled public String  savedOn      { get; set; }
        /** The name we wrote to the ledger for this showing. */
        @AuraEnabled public String  shownTo      { get; set; }
    }

    /** Where a record leads back to: the person, and words for the ledger. */
    private class Origin {
        Id     profileId;
        String label;
    }

    /**
     * Show the active preferences behind a handoff or a request to the person
     * reading it, and record every one we showed.
     *
     * Not cacheable, because it writes. Reading it twice records it twice,
     * and that is correct: the person is entitled to know each time.
     */
    @AuraEnabled(cacheable=false)
    public static List<Shown> forRecord(Id recordId, String viewerRole) {
        if (recordId == null) {
            throw new AuraHandledException('We need a record to look behind.');
        }
        if (String.isBlank(viewerRole) || !ROLES.contains(viewerRole)) {
            throw new AuraHandledException(
                'Tell us who you are reading this as. We only show a preference '
                + 'to the audience the person chose.');
        }

        List<Shown> out = new List<Shown>();
        Origin origin = originOf(recordId);
        if (origin == null || origin.profileId == null) {
            // Anonymous, or nothing attached. That is a complete and normal way
            // to use this, and there is nothing to show.
            return out;
        }

        // Only what is switched on, only what the person asked to travel ahead
        // of them, and only for the audience they named. Scope is not narrowed
        // here; the person chose the audience and we honour that choice alone.
        List<Access_Preference__c> prefs = [
            SELECT Id, Statement__c, Scope__c, CreatedDate
              FROM Access_Preference__c
             WHERE Access_Profile__c = :origin.profileId
               AND Revoked_On__c = null
               AND Auto_Apply__c = true
               AND Shared_With__c = :viewerRole
              WITH SECURITY_ENFORCED
             ORDER BY CreatedDate ASC
             LIMIT 50];
        if (prefs.isEmpty()) {
            return out;
        }

        String viewer  = UserInfo.getName();
        Datetime at    = System.now();
        String context = (origin.label + ', read as ' + viewerRole).left(255);

        List<Disclosure_Event__c> ledger = new List<Disclosure_Event__c>();
        for (Access_Preference__c p : prefs) {
            ledger.add(new Disclosure_Event__c(
                Access_Preference__c = p.Id,
                Shown_To__c          = viewer,
                Shown_At__c          = at,
                Context__c           = context));
        }

        // The ledger first. If this fails, the person is shown nothing, because
        // the alternative is a disclosure they could never find out about.
        try {
            insert ledger;
        } catch (DmlException e) {
            throw new AuraHandledException(
                'We could not record that you saw this, so we have not shown it.');
        }

        for (Access_Preference__c p : prefs) {
            Shown s = new Shown();
            s.preferenceId = p.Id;
            s.statement    = p.Statement__c;
            s.scope        = p.Scope__c;
            s.savedOn      = p.CreatedDate == null ? '' : p.CreatedDate.format('d MMMM yyyy');
            s.shownTo      = viewer;
            out.add(s);
        }
        return out;
    }

    /**
     * From a handoff or a request, back through its barrier report, to the
     * profile the person chose to attach. Null when the record is neither, or
     * when the person chose to stay anonymous.
     */
    private static Origin originOf(Id recordId) {
        Schema.SObjectType t = recordId.getSObjectType();
        Origin o = new Origin();

        if (t == Human_Handoff__c.SObjectType) {
            List<Human_Handoff__c> rows = [
                SELECT Name, Barrier_Report__r.Access_Profile__c
                  FROM Human_Handoff__c
                 WHERE Id = :recordId
                  WITH SECURITY_ENFORCED
                 LIMIT 1];
            if (rows.isEmpty()) { return null; }
            o.label     = 'Handoff ' + rows[0].Name;
            o.profileId = rows[0].Barrier_Report__r == null
                        ? null : rows[0].Barrier_Report__r.Access_Profile__c;
            return o;
        }

        if (t == Accommodation_Request__c.SObjectType) {
            List<Accommodation_Request__c> rows = [
                SELECT Name, Barrier_Report__r.Access_Profile__c
                  FROM Accommodation_Request__c
                 WHERE Id = :recordId
                  WITH SECURITY_ENFORCED
                 LIMIT 1];
            if (rows.isEmpty()) { return null; }
            o.label     = 'Request ' + rows[0].Name;
            o.profileId = rows[0].Barrier_Report__r == null
                        ? null : rows[0].Barrier_Report__r.Access_Profile__c;
            return o;
        }

        return null;
    }
}
