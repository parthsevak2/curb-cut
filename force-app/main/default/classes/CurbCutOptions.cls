/**
 * CurbCutOptions
 *
 * Grounded retrieval for the Curb Cut agent.
 *
 * The agent must not answer "what could I ask for?" from model knowledge. For this
 * population a fabricated accommodation or a fabricated cost is not a harmless error --
 * someone acts on an entitlement that does not exist. Every option the agent names
 * comes from Accommodation_Option__c, and every row carries a source URL.
 *
 * When nothing matches, this returns empty. The agent is instructed to say so rather
 * than improvise. An honest "I don't know" is the feature.
 */
public with sharing class CurbCutOptions {

    private static final Set<String> STOPWORDS = new Set<String>{
        'the','a','an','and','or','but','i','im','my','me','to','for','of','in','on',
        'at','it','is','am','are','was','were','be','been','with','that','this','have',
        'has','had','do','does','did','can','cant','cannot','not','no','when','what',
        'very','really','just','so','too','get','got','because','they','them'
    };

    public class Request {
        @InvocableVariable(required=true label='Functional need in the person\'s own words')
        public String need;

        @InvocableVariable(label='Maximum options to return')
        public Integer limitSize;
    }

    public class Result {
        @InvocableVariable(label='Formatted options, empty when nothing matched')
        public String options;

        @InvocableVariable(label='Number of options matched')
        public Integer matchCount;

        @InvocableVariable(label='True when nothing matched and the agent must say so')
        public Boolean noMatch;
    }

    @InvocableMethod(
        label='Find accommodation options'
        description='Retrieves grounded accommodation options. Returns empty rather than guessing.'
    )
    public static List<Result> find(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            results.add(findOne(req));
        }
        return results;
    }

    private static Result findOne(Request req) {
        Result res = new Result();
        res.matchCount = 0;
        res.noMatch = true;
        res.options = '';

        List<String> keywords = extractKeywords(req.need);
        if (keywords.isEmpty()) {
            return res;
        }

        Integer cap = (req.limitSize != null && req.limitSize > 0) ? req.limitSize : 4;

        // The library is public reference data with a source URL on every row and
        // nothing about any person in it. The site guest user owns none of those
        // records, so record sharing would hand them an empty library and the
        // agent would honestly report that it knows nothing. Read it without
        // sharing, deliberately and only here.
        List<Accommodation_Option__c> all = new LibraryReader().all();

        List<ScoredOption> scored = new List<ScoredOption>();
        for (Accommodation_Option__c opt : all) {
            // Whole words only. Substring matching once offered visual fire alarms
            // to someone who said they could not type for long, because 'long' is
            // inside 'alongside'. An irrelevant suggestion is not a harmless miss:
            // it tells someone already having a hard week that they were not heard.
            Set<String> words = new Set<String>(tokenize(
                (opt.Option__c == null ? '' : opt.Option__c) + ' ' +
                (opt.Plain_Language_Summary__c == null ? '' : opt.Plain_Language_Summary__c)
            ));

            Integer score = 0;
            for (String kw : keywords) {
                if (words.contains(kw)) {
                    score++;
                }
            }
            if (score > 0) {
                scored.add(new ScoredOption(opt, score));
            }
        }

        if (scored.isEmpty()) {
            return res;
        }

        scored.sort();

        List<String> lines = new List<String>();
        Integer taken = 0;
        for (ScoredOption so : scored) {
            if (taken >= cap) { break; }
            lines.add(format(so.option));
            taken++;
        }

        res.options = String.join(lines, '\n\n');
        res.matchCount = taken;
        res.noMatch = false;
        return res;
    }

    /**
     * Cost is stated plainly and only when known. Precedent count is stated only when
     * real data exists -- a zero means we have no precedent data, not zero precedent,
     * and the agent must not present it as either.
     */
    private static String format(Accommodation_Option__c opt) {
        String line = '- ' + opt.Option__c;
        if (String.isNotBlank(opt.Plain_Language_Summary__c)) {
            line += '\n  ' + opt.Plain_Language_Summary__c;
        }
        if (opt.Zero_Cost__c == true) {
            line += '\n  Usually costs nothing.';
        } else if (opt.Typical_Cost__c != null && opt.Typical_Cost__c > 0) {
            line += '\n  Usually about $' + String.valueOf(opt.Typical_Cost__c.setScale(0)) + '.';
        }
        if (opt.Precedent_Count__c != null && opt.Precedent_Count__c > 0) {
            line += '\n  Approved ' + String.valueOf(opt.Precedent_Count__c.intValue())
                 + ' times here before.';
        }
        return line;
    }

    /** Words of three characters or more, lowercased, punctuation stripped. */
    private static List<String> tokenize(String text) {
        List<String> out = new List<String>();
        if (String.isBlank(text)) { return out; }
        for (String raw : text.toLowerCase().split('[^a-z0-9]+')) {
            String w = raw.trim();
            if (w.length() >= 3) { out.add(w); }
        }
        return out;
    }

    private static List<String> extractKeywords(String need) {
        List<String> out = new List<String>();
        for (String w : tokenize(need)) {
            if (STOPWORDS.contains(w)) { continue; }
            if (!out.contains(w)) { out.add(w); }
        }
        return out;
    }

    /**
     * Reads the public accommodation library.
     *
     * `without sharing` is a deliberate, narrow exception: this class touches
     * exactly one object, that object holds no information about any person,
     * and every row carries a public source URL. Field-level security still
     * applies through WITH SECURITY_ENFORCED, so a caller with no field access
     * still gets nothing.
     */
    private without sharing class LibraryReader {
        private List<Accommodation_Option__c> all() {
            return [
                SELECT Option__c, Plain_Language_Summary__c, Typical_Cost__c,
                       Zero_Cost__c, Precedent_Count__c, Source_URL__c
                FROM Accommodation_Option__c
                WITH SECURITY_ENFORCED
                LIMIT 500
            ];
        }
    }

    private class ScoredOption implements Comparable {
        public Accommodation_Option__c option;
        public Integer score;

        public ScoredOption(Accommodation_Option__c option, Integer score) {
            this.option = option;
            this.score = score;
        }

        public Integer compareTo(Object other) {
            ScoredOption o = (ScoredOption) other;
            if (this.score == o.score) { return 0; }
            return this.score > o.score ? -1 : 1;   // highest score first
        }
    }
}
