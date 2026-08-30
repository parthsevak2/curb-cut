/**
 * CurbCutIntake
 *
 * Spec section 3: one inbound handler normalises every modality into a
 * Barrier_Report__c. No modality is privileged.
 *
 * Anonymous is the DEFAULT, not a setting the person has to find. While
 * anonymous, no Access_Profile__c link is written at all -- not a null lookup
 * on a linked row, no link. Principle 3: a person can get a real answer without
 * identifying themselves.
 *
 * Signed video sets Interpreter_Needed__c and nothing else. This class never
 * attempts to describe or summarise a signed video.
 */
public with sharing class CurbCutIntake {

    private static final Set<String> MODALITIES =
        new Set<String>{ 'Text', 'Voice note', 'Video', 'Image' };

    public class Request {
        @InvocableVariable(required=true label='What is hard, in the person\'s own words. Never why.')
        public String functionalDescription;

        @InvocableVariable(label='Text, Voice note, Video or Image. Defaults to Text.')
        public String inboundModality;

        @InvocableVariable(label='Access Profile to link, ONLY if the person identified themselves')
        public String accessProfileId;
    }

    public class Result {
        @InvocableVariable(label='Id of the barrier report')
        public String barrierReportId;

        @InvocableVariable(label='True when this report is anonymous')
        public Boolean anonymous;

        @InvocableVariable(label='True when a human interpreter is required')
        public Boolean interpreterNeeded;

        @InvocableVariable(label='What to tell the person')
        public String message;
    }

    @InvocableMethod(
        label='Log a barrier report'
        description='Normalises any modality into a Barrier_Report__c. Anonymous by default.'
    )
    public static List<Result> log(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            results.add(logOne(req));
        }
        return results;
    }

    private static Result logOne(Request req) {
        Result res = new Result();
        res.barrierReportId = '';
        res.anonymous = true;
        res.interpreterNeeded = false;

        if (String.isBlank(req.functionalDescription)) {
            res.message = 'There is nothing to log yet.';
            return res;
        }

        String modality = MODALITIES.contains(req.inboundModality)
            ? req.inboundModality : 'Text';
        Boolean signed = (modality == 'Video');

        Barrier_Report__c br = new Barrier_Report__c(
            Functional_Description__c = req.functionalDescription,
            Inbound_Modality__c       = modality,
            Interpreter_Needed__c     = signed,
            Anonymous__c              = true
        );

        // A profile link is written ONLY when the person supplied one. Absent
        // that, the report is anonymous and carries no link at all.
        if (String.isNotBlank(req.accessProfileId)) {
            try {
                br.Access_Profile__c = Id.valueOf(req.accessProfileId);
                br.Anonymous__c = false;
            } catch (Exception e) {
                br.Access_Profile__c = null;
                br.Anonymous__c = true;
            }
        }

        try {
            insert br;
            res.barrierReportId   = br.Id;
            res.anonymous         = br.Anonymous__c;
            res.interpreterNeeded = br.Interpreter_Needed__c;
            res.message = signed
                ? 'Got your video. A person will look at it, not a machine.'
                : 'Noted, in your words.';
        } catch (DmlException e) {
            res.message = 'I could not log that, and that is my problem, not yours.';
        }
        return res;
    }
}
