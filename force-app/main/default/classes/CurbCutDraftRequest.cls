/**
 * CurbCutDraftRequest
 *
 * Turns what the person said is hard into request text they can read back.
 * Deliberately does no DML. Drafting is not asking, and the person has not
 * agreed to anything yet at this point in the conversation.
 *
 * The draft carries no condition, no diagnosis and no clinical language,
 * because the system never held any to begin with.
 */
public with sharing class CurbCutDraftRequest {

    public class Request {
        @InvocableVariable(required=true label='Functional need in the person\'s own words')
        public String need;

        @InvocableVariable(label='Option the person picked, if they picked one')
        public String chosenOption;
    }

    public class Result {
        @InvocableVariable(label='The drafted request, for the person to read and approve')
        public String draft;
    }

    @InvocableMethod(
        label='Draft accommodation request'
        description='Drafts request text in the person\'s own words. Writes nothing.'
    )
    public static List<Result> draft(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            res.draft = build(req);
            results.add(res);
        }
        return results;
    }

    private static String build(Request req) {
        if (String.isBlank(req.need)) {
            return '';
        }
        String body = 'I am asking for a change to how I work.\n\n'
                    + 'What is hard right now: ' + CurbCutRedact.clean(req.need.trim());

        if (String.isNotBlank(req.chosenOption)) {
            body += '\n\nWhat would help: ' + CurbCutRedact.clean(req.chosenOption.trim());
        }

        body += '\n\nI am not sharing a diagnosis, and I am not required to. '
             +  'This is about what I need to do my job.';
        return body;
    }
}
