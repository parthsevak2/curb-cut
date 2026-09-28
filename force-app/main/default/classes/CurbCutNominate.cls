/**
 * Somebody pointing us at a workplace that should have this.
 *
 * One rule shapes the whole thing: a nomination is about the workplace,
 * never about the person who sent it. No hash, no handle, no channel
 * session, no link to any other record. A person works the queue and
 * reaches out kindly, and the workplace cannot be told who asked, because
 * nothing that could tell them was ever written down.
 */
public with sharing class CurbCutNominate {

    /** Channel values Nomination__c accepts; anything else arrives as External. */
    private static final Set<String> CHANNELS = new Set<String>{
        'Email', 'SMS', 'Voice', 'Web', 'Slack', 'External', 'MCP' };

    /**
     * Write the nomination down and say what happens next. A blank payload is
     * somebody asking how, so they get the how-to rather than a nomination
     * called "my workplace".
     *
     * Only the first line is kept. An email that says NOMINATE and a name
     * carries a signature below it - a name, a number, exactly what this
     * record promises never to hold - so everything after the first line
     * break is discarded unread.
     */
    public static String act(String payload, String channel) {
        if (String.isBlank(payload)) {
            return CurbCutKeyword.wording('NOMINATE');
        }
        String name = payload.split('\r?\n', 2)[0]
            .replaceAll('\\s+', ' ').trim();
        // The same refusal as everywhere else: a condition typed beside the
        // workplace is taken out before anything is stored.
        Boolean took = CurbCutRedact.names(name);
        if (took) { name = CurbCutRedact.clean(name); }
        name = name.trim().left(255);
        if (String.isBlank(name)) {
            return CurbCutKeyword.wording('NOMINATE');
        }
        try {
            insert new Nomination__c(
                Workplace__c = name,
                Channel__c   = CHANNELS.contains(channel) ? channel : 'External'
            );
        } catch (Exception e) {
            return 'I could not write that down just now, and I am not going to '
                 + 'pretend I did. Write to ' + System.Label.CurbCut_Support_Email
                 + ' and a person will take the name.';
        }
        return (took ? CurbCutRedact.notice() + '\n\n' : '')
             + 'Done: ' + name + '. A person will reach out to them kindly. '
             + 'They will never be told who asked, because I keep the workplace '
             + 'name and nothing about you.';
    }
}
