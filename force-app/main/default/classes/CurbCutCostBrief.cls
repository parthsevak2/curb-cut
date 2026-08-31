/**
 * CurbCutCostBrief
 *
 * Spec section 4, topic.decide: lead with cost reality, then precedent, then
 * the interactive-process clock.
 *
 * The JAN figures are stated as what they are -- an employer survey through
 * 2024, with its source -- and never as a fact about this employer. The
 * precedent count comes from the library or is omitted. A zero in
 * Precedent_Count__c means we have no precedent data, NOT zero precedent, and
 * this class will not present it as either.
 */
public with sharing class CurbCutCostBrief {

    // Named as well as linked. The Agent API redacts bare URLs in what it says,
    // so a manager was being shown "Source: URL_Redacted" - a grounded figure
    // that looked unsourced at the exact moment somebody was deciding with it.
    private static final String  JAN_SOURCE     =
        'the Job Accommodation Network employer survey through 2024, askjan.org/topics/costs.cfm';
    private static final Integer JAN_ZERO_COST_PCT = 61;
    private static final Integer JAN_MEDIAN_USD    = 300;
    private static final Integer INTERACTIVE_DAYS  = 10;

    public class Request {
        @InvocableVariable(required=true label='The accommodation being decided on')
        public String option;
    }

    public class Result {
        @InvocableVariable(label='The cost brief, in order: cost, precedent, clock')
        public String brief;

        @InvocableVariable(label='True when we hold real precedent data for this option')
        public Boolean hasPrecedent;

        @InvocableVariable(label='Source URL to cite')
        public String source;
    }

    @InvocableMethod(
        label='Build manager cost brief'
        description='Cost reality, then precedent, then the interactive-process clock. Cited.'
    )
    public static List<Result> build(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            results.add(buildOne(req));
        }
        return results;
    }

    private static Result buildOne(Request req) {
        Result res = new Result();
        res.hasPrecedent = false;
        res.source = JAN_SOURCE;

        List<String> lines = new List<String>();
        lines.add('Cost first.');
        lines.add('In the Job Accommodation Network employer survey through 2024, '
                + JAN_ZERO_COST_PCT + ' out of every 100 accommodations cost the employer '
                + 'nothing. For the rest, the median one-time cost was about $'
                + JAN_MEDIAN_USD + '. Source: ' + JAN_SOURCE);

        Accommodation_Option__c opt = lookup(req.option);
        if (opt != null) {
            if (opt.Zero_Cost__c == true) {
                lines.add('This one usually costs nothing.');
            } else if (opt.Typical_Cost__c != null && opt.Typical_Cost__c > 0) {
                lines.add('This one usually costs about $'
                        + String.valueOf(opt.Typical_Cost__c.setScale(0)) + '.');
            }
            if (opt.Precedent_Count__c != null && opt.Precedent_Count__c > 0) {
                res.hasPrecedent = true;
                lines.add('It has been approved ' + opt.Precedent_Count__c.intValue()
                        + ' times here before.');
            } else {
                // Adversarial case 10: say so rather than inventing a number.
                lines.add('We do not hold precedent data for this one. '
                        + 'That means we do not know, not that it has never been approved.');
            }
            if (String.isNotBlank(opt.Source_URL__c)) {
                res.source = opt.Source_URL__c;
            }
        } else {
            lines.add('This option is not in the grounded library, so there is no '
                    + 'cost or precedent figure to give you. I will not estimate one.');
        }

        lines.add('The interactive process should reach an answer within '
                + INTERACTIVE_DAYS + ' days of the request. A fair no is a legitimate '
                + 'outcome. Delay is not.');

        res.brief = String.join(lines, '\n\n');
        return res;
    }

    private static Accommodation_Option__c lookup(String option) {
        if (String.isBlank(option)) { return null; }
        String needle = '%' + String.escapeSingleQuotes(option.trim()) + '%';
        List<Accommodation_Option__c> found = [
            SELECT Option__c, Typical_Cost__c, Zero_Cost__c, Precedent_Count__c, Source_URL__c
            FROM Accommodation_Option__c
            WHERE Option__c LIKE :needle
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        return found.isEmpty() ? null : found[0];
    }
}
