/**
 * CurbCutConsole — what the person on duty needs, in one call each.
 *
 * The console was standard list views on standard layouts. Everything a human
 * needed in order to act well was one or two clicks away from where they were
 * looking, and the thing that matters most on a handoff -- the words the person
 * already typed once -- was behind a lookup.
 *
 * These methods exist so a component can put the answer on the screen instead
 * of the route to the answer.
 */
public with sharing class CurbCutConsole {

    public class Triage {
        @AuraEnabled public Integer waiting             { get; set; }
        @AuraEnabled public Integer longestWaitHours    { get; set; }
        @AuraEnabled public Integer undecided           { get; set; }
        @AuraEnabled public Integer overdue             { get; set; }
        @AuraEnabled public Integer interpreters        { get; set; }
        @AuraEnabled public Integer unreached           { get; set; }
    }

    /** Everything the On Duty page shows, in one round trip. */
    @AuraEnabled(cacheable=true)
    public static Triage triage() {
        Triage t = new Triage();

        List<Human_Handoff__c> waiting = [
            SELECT Requested_At__c FROM Human_Handoff__c
            WHERE Picked_Up_At__c = null
            WITH SECURITY_ENFORCED
            ORDER BY Requested_At__c ASC
        ];
        t.waiting = waiting.size();
        t.longestWaitHours = 0;
        if (!waiting.isEmpty() && waiting[0].Requested_At__c != null) {
            Long ms = System.now().getTime() - waiting[0].Requested_At__c.getTime();
            t.longestWaitHours = (Integer) (ms / (1000 * 60 * 60));
        }

        t.undecided = [
            SELECT COUNT() FROM Accommodation_Request__c
            WHERE Manager_Response__c = 'Pending' WITH SECURITY_ENFORCED];
        t.overdue = [
            SELECT COUNT() FROM Accommodation_Request__c
            WHERE Manager_Response__c = 'Pending'
              AND Interactive_Process_Due__c < :Date.today() WITH SECURITY_ENFORCED];
        t.interpreters = [
            SELECT COUNT() FROM Barrier_Report__c
            WHERE Interpreter_Needed__c = true WITH SECURITY_ENFORCED];
        // Anything that is not Accepted is a person who asked and heard nothing.
        t.unreached = [
            SELECT COUNT() FROM Message_Log__c
            WHERE Direction__c = 'Outbound' AND Status__c != 'Accepted'
            WITH SECURITY_ENFORCED];
        return t;
    }

    public class Brief {
        @AuraEnabled public String  theirWords      { get; set; }
        @AuraEnabled public String  reachBy         { get; set; }
        @AuraEnabled public String  modality        { get; set; }
        @AuraEnabled public Boolean interpreter     { get; set; }
        @AuraEnabled public Boolean neverCall       { get; set; }
        @AuraEnabled public Integer waitedHours     { get; set; }
        @AuraEnabled public String  handler         { get; set; }
        @AuraEnabled public Boolean pickedUp        { get; set; }
        @AuraEnabled public String  barrierId       { get; set; }
    }

    /**
     * The handoff, plus the thing behind the lookup that nobody clicks.
     *
     * What the person asked to be known ahead of them is deliberately not in
     * here. Showing a standing preference is a disclosure, and every showing
     * must be written to Disclosure_Event__c before a word is returned. This
     * method is cacheable and cannot write, so the brief component asks
     * CurbCutShow.forRecord for that, only when the viewer presses the button.
     */
    @AuraEnabled(cacheable=true)
    public static Brief brief(Id handoffId) {
        Human_Handoff__c h = [
            SELECT Requested_At__c, Picked_Up_At__c, Handler_Name__c, Reachable_By__c,
                   Barrier_Report__c,
                   Barrier_Report__r.Functional_Description__c,
                   Barrier_Report__r.Inbound_Modality__c,
                   Barrier_Report__r.Interpreter_Needed__c,
                   Barrier_Report__r.Access_Profile__r.Never_Call__c
            FROM Human_Handoff__c WHERE Id = :handoffId
            WITH SECURITY_ENFORCED LIMIT 1];

        Brief b = new Brief();
        b.reachBy    = h.Reachable_By__c;
        b.handler    = h.Handler_Name__c;
        b.pickedUp   = h.Picked_Up_At__c != null;
        b.barrierId  = h.Barrier_Report__c;
        b.waitedHours = 0;
        if (h.Requested_At__c != null) {
            Long ms = (h.Picked_Up_At__c == null ? System.now() : h.Picked_Up_At__c).getTime()
                    - h.Requested_At__c.getTime();
            b.waitedHours = (Integer) (ms / (1000 * 60 * 60));
        }
        if (h.Barrier_Report__r != null) {
            b.theirWords  = h.Barrier_Report__r.Functional_Description__c;
            b.modality    = h.Barrier_Report__r.Inbound_Modality__c;
            b.interpreter = h.Barrier_Report__r.Interpreter_Needed__c == true;
            b.neverCall   = h.Barrier_Report__r.Access_Profile__r != null
                         && h.Barrier_Report__r.Access_Profile__r.Never_Call__c == true;
        }
        return b;
    }

    /**
     * Take it. One press, so the next shift can see it is not waiting on
     * nobody, which is the single most common way a queue like this fails.
     */
    @AuraEnabled
    public static void pickUp(Id handoffId, String handlerName) {
        update new Human_Handoff__c(
            Id = handoffId,
            Handler_Name__c = String.isBlank(handlerName) ? UserInfo.getName() : handlerName,
            Picked_Up_At__c = System.now());
    }

    public class Media {
        @AuraEnabled public String  id        { get; set; }
        @AuraEnabled public String  title     { get; set; }
        @AuraEnabled public String  url       { get; set; }
        @AuraEnabled public Boolean isVideo   { get; set; }
        @AuraEnabled public Boolean isImage   { get; set; }
        @AuraEnabled public String  arrivedAt { get; set; }
        @AuraEnabled public Integer sizeKb    { get; set; }
    }

    /**
     * What the person sent instead of typing.
     *
     * Deliberately returns the file and nothing else. No transcript, no caption,
     * no generated alt text. A photo of somebody's workstation is evidence they
     * chose to send; turning it into a machine's description of their body is
     * the disclosure this whole system refuses to make on their behalf.
     */
    @AuraEnabled(cacheable=true)
    public static List<Media> media(Id barrierId) {
        List<Media> out = new List<Media>();
        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink l : [
                SELECT ContentDocumentId FROM ContentDocumentLink
                WHERE LinkedEntityId = :barrierId]) {
            docIds.add(l.ContentDocumentId);
        }
        if (docIds.isEmpty()) { return out; }

        for (ContentVersion v : [
                SELECT Id, Title, FileExtension, ContentSize, CreatedDate
                FROM ContentVersion
                WHERE ContentDocumentId IN :docIds AND IsLatest = true
                ORDER BY CreatedDate DESC]) {
            String ext = v.FileExtension == null ? '' : v.FileExtension.toLowerCase();
            Media m = new Media();
            m.id = v.Id;
            m.title = v.Title;
            m.url = '/sfc/servlet.shepherd/version/download/' + v.Id;
            m.isVideo = new Set<String>{'mp4','mov','m4v','webm','avi','3gp'}.contains(ext);
            m.isImage = new Set<String>{'png','jpg','jpeg','gif','heic','webp','bmp'}.contains(ext);
            m.arrivedAt = v.CreatedDate.format('d MMMM yyyy, HH:mm');
            m.sizeKb = v.ContentSize == null ? 0 : (Integer) (v.ContentSize / 1024);
            out.add(m);
        }
        return out;
    }

    /**
     * Books the interpreter. The gap between Requested At and this is the entire
     * cost to the person, so it is one press rather than an edit page.
     */
    @AuraEnabled
    public static void bookInterpreter(Id handoffId, String interpreterName) {
        update new Human_Handoff__c(
            Id = handoffId,
            Interpreter_Name__c = String.isBlank(interpreterName)
                ? UserInfo.getName() : interpreterName,
            Interpreter_Booked_At__c = System.now());
    }
}
