/**
 * Takes the condition back out of what somebody wrote.
 *
 * The privacy policy said, in public: "if you tell the agent about a medical
 * condition anyway, it is not written to any record." That was false. There is
 * no field called Diagnosis__c, which is the claim the whole project is built
 * on and which is true - but Functional_Description__c is free text, and
 * "I have multiple sclerosis and some days I cannot type for long" was being
 * stored verbatim, sentence and all.
 *
 * The agent was instructed not to record it. Instructions are not a control.
 * The action recorded whatever text it was handed, so the promise held only for
 * as long as a model remembered to keep it.
 *
 * What this does NOT touch, deliberately:
 *
 *   Deaf, blind, hard of hearing, wheelchair user and the like are not stripped.
 *   They are how people describe themselves and how they describe what they
 *   need, they are identity as often as they are medicine, and the interpreter
 *   routing depends on reading them. Redacting how somebody names themselves
 *   would be its own insult.
 *
 * And it cannot catch every phrasing in every language. So the copy now says
 * what this actually does rather than promising an absolute the code cannot
 * deliver. Overclaiming on a privacy page is worse than the gap it hides.
 */
public with sharing class CurbCutRedact {

    public static final String MARK = '[not recorded]';

    /**
     * Named conditions. Longest first, so "multiple sclerosis" is taken before
     * a shorter fragment inside it can be.
     */
    private static final List<String> CONDITIONS = new List<String>{
        'ehlers danlos syndrome', 'ehlers-danlos', 'chronic fatigue syndrome',
        'myalgic encephalomyelitis', 'multiple sclerosis', 'muscular dystrophy',
        'rheumatoid arthritis', 'ulcerative colitis', 'cerebral palsy',
        'motor neurone disease', 'traumatic brain injury', 'spinal cord injury',
        'borderline personality disorder', 'obsessive compulsive disorder',
        'post traumatic stress disorder', 'bipolar disorder', 'eating disorder',
        'panic disorder', 'anxiety disorder', 'autism spectrum disorder',
        'crohns disease', 'crohn s disease', 'sickle cell', 'long covid',
        'kidney disease', 'heart failure', 'brain injury', 'spina bifida',
        'cystic fibrosis', 'parkinsons', 'parkinson s', 'alzheimers',
        'alzheimer s', 'huntingtons', 'huntington s', 'endometriosis',
        'fibromyalgia', 'schizophrenia', 'epilepsy', 'epileptic', 'diabetes',
        'diabetic', 'arthritis', 'psoriasis', 'narcolepsy', 'sleep apnea',
        'sleep apnoea', 'concussion', 'aneurysm', 'dementia', 'hepatitis',
        'dialysis', 'chemotherapy', 'lymphoma', 'leukemia', 'leukaemia',
        'melanoma', 'glaucoma', 'tinnitus', 'migraines', 'migraine', 'lupus',
        'asthma', 'cancer', 'stroke', 'crohns', 'colitis', 'dyslexia',
        'dyspraxia', 'dyscalculia', 'depression', 'depressive', 'psychosis',
        'anorexia', 'bulimia', 'autism', 'autistic', 'aspergers', 'asperger s',
        'adhd', 'ptsd', 'ocd', 'copd', 'pots', 'hiv', 'aids', 'als', 'ibs',
        'tbi', 'bpd', 'me cfs'
    };

    private static List<Pattern> compiled;

    private static List<Pattern> patterns() {
        if (compiled != null) { return compiled; }
        compiled = new List<Pattern>();
        for (String c : CONDITIONS) {
            // Tolerate any punctuation or spacing between the words, so
            // "Crohn's disease" and "crohns disease" are both caught.
            String body = c.replaceAll(' ', '[^a-zA-Z0-9]{1,3}');
            compiled.add(Pattern.compile('(?i)\\b' + body + '\\b'));
        }
        return compiled;
    }

    /** True when the text names something we would refuse to store. */
    public static Boolean names(String text) {
        if (String.isBlank(text)) { return false; }
        for (Pattern p : patterns()) {
            if (p.matcher(text).find()) { return true; }
        }
        return false;
    }

    /**
     * Removes what it recognises and leaves the rest of the sentence intact,
     * because the functional half is the part the person actually needs read.
     * "I have multiple sclerosis and some days I cannot type for long"
     * becomes "I have [not recorded] and some days I cannot type for long".
     */
    public static String clean(String text) {
        if (String.isBlank(text)) { return text; }
        String out = text;
        for (Pattern p : patterns()) {
            out = p.matcher(out).replaceAll(MARK);
        }
        // Collapse a run of markers so three redactions do not read as noise.
        out = out.replaceAll('(\\[not recorded\\][^a-zA-Z0-9]{0,3}){2,}', MARK + ' ');
        return out.trim();
    }

    /** What to tell somebody, once, when we have just taken something out. */
    public static String notice() {
        return 'You named a condition. I took it out before saving anything, and '
             + 'there is nowhere in this system to put it. I work from what is '
             + 'hard, never from why.';
    }
}
