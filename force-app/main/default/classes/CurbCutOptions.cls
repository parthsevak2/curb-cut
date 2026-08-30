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

    // Function words carry no meaning here, and a match on one is worse than no
    // match at all: 'Typing hurts after a while' once returned 'Written follow-up
    // after verbal instructions' as its top result, on the strength of 'after'.
    // An irrelevant suggestion tells someone already having a hard week that they
    // were not heard. Anything appearing incidentally in library prose belongs here.
    private static final Set<String> STOPWORDS = new Set<String>{
        'the','a','an','and','or','but','i','im','my','me','to','for','of','in','on',
        'at','it','is','am','are','was','were','be','been','with','that','this','have',
        'has','had','do','does','did','can','cant','cannot','not','no','when','what',
        'very','really','just','so','too','get','got','because','they','them',
        // connectives and quantifiers that turn up in the library's own summaries
        'after','before','while','during','than','then','rather','into','from','out',
        'own','one','some','all','any','each','more','less','most','much','also',
        'still','about','over','under','without','you','your','their','there','here',
        // filler that appears in almost every sentence a person types
        'keep','keeps','keeping','need','needs','needed','make','makes','made',
        'thing','things','right','now','way','ways','use','uses','using','used',
        'like','lot','bit','day','days','time','times',
        // 'work' is in half the library and in almost every phrase a person types,
        // so it separates nothing
        'work','works','working','job'
    };

    private static final Integer TITLE_WEIGHT = 3;
    private static final Integer BODY_WEIGHT = 1;

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
            //
            // The name of the accommodation is what it is about; the summary is
            // explanation around it. So a hit on the name counts for more. Without
            // this, 'the noise in the office' ranked a chair above a quiet room,
            // because the chair's summary happens to mention an office.
            Set<String> titleWords = stemAll(tokenize(
                opt.Option__c == null ? '' : opt.Option__c
            ));
            Set<String> bodyWords = stemAll(tokenize(
                opt.Plain_Language_Summary__c == null ? '' : opt.Plain_Language_Summary__c
            ));

            Integer score = 0;
            for (String kw : keywords) {
                if (titleWords.contains(kw)) { score += TITLE_WEIGHT; }
                else if (bodyWords.contains(kw)) { score += BODY_WEIGHT; }
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
    /**
     * A deliberately small stemmer, so that 'type' finds 'typing'.
     *
     * Whole-word matching fixed a bug where 'long' matched 'alongside', and
     * introduced a quieter one: the library says 'typing' and the canonical
     * sentence this whole system was designed around is 'I cannot type for
     * long'. That returned nothing at all over SMS. Being told 'I do not have
     * good information on that' when you have just described the single most
     * common accommodation need is worse than a wrong suggestion, because it
     * reads as: you are unusual, and there is nothing for you.
     *
     * Both sides are stemmed with the same rules, so matching stays symmetric
     * and 'alongside' still never becomes 'long'.
     */
    private static String stem(String w) {
        if (w == null || w.length() < 4) { return w; }
        // plural first, so 'meetings' can reach 'meet' via 'meeting'
        if (w.endsWith('ses') || w.endsWith('xes') || w.endsWith('zes')) { w = w.substring(0, w.length() - 2); }
        else if (w.endsWith('s') && !w.endsWith('ss')) { w = w.substring(0, w.length() - 1); }
        if (w.length() >= 5 && w.endsWith('ing')) { w = w.substring(0, w.length() - 3); }
        else if (w.length() >= 4 && w.endsWith('ed')) { w = w.substring(0, w.length() - 2); }
        // 'type' and 'typing' both land on 'typ'
        if (w.length() >= 4 && w.endsWith('e')) { w = w.substring(0, w.length() - 1); }
        return w;
    }

    /** Stems a whole list, dropping anything that collapses to nothing useful. */
    private static Set<String> stemAll(List<String> words) {
        Set<String> out = new Set<String>();
        for (String w : words) {
            String st = stem(w);
            if (String.isNotBlank(st) && st.length() >= 3) { out.add(st); }
        }
        return out;
    }

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
        // Stopwords are matched on the word as typed; stemming happens after,
        // so 'needs' is dropped as filler rather than stemmed into a keyword.
        List<String> kept = new List<String>();
        for (String w : tokenize(need)) {
            if (STOPWORDS.contains(w)) { continue; }
            kept.add(w);
        }
        List<String> out = new List<String>();
        for (String st : stemAll(kept)) { out.add(st); }
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
            if (this.score != o.score) {
                return this.score > o.score ? -1 : 1;   // highest score first
            }
            // Ties are broken by how many workplaces have already done it, then
            // alphabetically. Without a total order the same question can return
            // a different answer twice, which reads as the system being unsure.
            Integer mine  = this.option.Precedent_Count__c == null ? 0 : Integer.valueOf(this.option.Precedent_Count__c);
            Integer yours = o.option.Precedent_Count__c    == null ? 0 : Integer.valueOf(o.option.Precedent_Count__c);
            if (mine != yours) { return mine > yours ? -1 : 1; }
            String a = this.option.Option__c == null ? '' : this.option.Option__c;
            String b = o.option.Option__c    == null ? '' : o.option.Option__c;
            return a.compareTo(b);
        }
    }
}
