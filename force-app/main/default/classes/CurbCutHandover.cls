/**
 * CurbCutHandover — what one agent may tell another about a person.
 *
 * An accommodation request eventually has to leave this system and reach
 * something on the employer's side. Increasingly that something is another
 * agent rather than a person, and agent-to-agent handover is where privacy
 * promises usually quietly die: the sending system serialises whatever it has,
 * because serialising everything is easier than deciding.
 *
 * So this class decides. It is an allow-list, not a filter. Nothing reaches the
 * payload unless it is named here, which means a field added to the schema next
 * year cannot leak by default. The failure mode of a deny-list is silence; the
 * failure mode of an allow-list is a missing field somebody notices.
 *
 * Three things make this different from a normal integration payload:
 *
 *  1. It refuses without explicit consent. Not "omits the consent flag" —
 *     refuses to produce anything at all.
 *  2. It carries an `absent` block, naming what this system does not hold, so a
 *     receiving agent is told plainly that a follow-up question about diagnosis
 *     has no answer anywhere. An agent that does not know something will ask.
 *     The point of saying it is unanswerable is to stop the asking.
 *  3. It carries `must_not_ask`, which is an instruction to the recipient, not
 *     a description of us. We cannot enforce it. We can refuse to be the reason
 *     nobody said it.
 */
public with sharing class CurbCutHandover {

    /** Bumped when the shape changes, so a recipient can pin to what it parsed. */
    private static final String CONTRACT_VERSION = '1.0.0';

    public class RefusedException extends Exception {}

    /**
     * Builds the outbound payload for one approved request.
     * @throws RefusedException when the person did not approve it, or when there is
     *         nothing of theirs to send.
     */
    public static String payloadFor(Id requestId) {
        List<Accommodation_Request__c> found = [
            SELECT Id, Name, Person_Approved__c, Approved_At__c,
                   Interactive_Process_Due__c, Manager_Response__c,
                   Barrier_Report__c, Barrier_Report__r.Functional_Description__c,
                   Barrier_Report__r.Inbound_Modality__c,
                   Barrier_Report__r.Interpreter_Needed__c
            FROM Accommodation_Request__c
            WHERE Id = :requestId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        if (found.isEmpty()) {
            throw new RefusedException('No such request.');
        }
        Accommodation_Request__c ar = found[0];

        // The whole system rests on this one line.
        if (ar.Person_Approved__c != true || ar.Approved_At__c == null) {
            throw new RefusedException(
                'This request was not approved by the person it is about, so there is ' +
                'nothing to hand over. Consent is not a field to omit; it is the reason ' +
                'the payload exists.');
        }

        String words = ar.Barrier_Report__r == null
            ? null : ar.Barrier_Report__r.Functional_Description__c;
        if (String.isBlank(words)) {
            throw new RefusedException(
                'This request has no words of the person attached to it. Sending an ' +
                'employer an empty request spends the person\'s ask on nothing, which ' +
                'is worse than sending nothing at all.');
        }

        Map<String, Object> out = new Map<String, Object>();
        out.put('contract', 'curb-cut/handover');
        out.put('contract_version', CONTRACT_VERSION);
        out.put('reference', ar.Name);

        // What the person actually said, in their words. Functional only: this
        // field has never been allowed to hold a reason.
        out.put('what_is_hard', words);

        out.put('consent', new Map<String, Object>{
            'given_by'   => 'the person this is about',
            'given_at'   => String.valueOf(ar.Approved_At__c),
            'mechanism'  => 'explicit yes in the conversation; a hedge was not accepted',
            'revocable'  => true,
            'revoke_by'  => 'the person replying to the conversation they started'
        });

        out.put('timing', new Map<String, Object>{
            'interactive_process_due' => String.valueOf(ar.Interactive_Process_Due__c),
            'status'                  => ar.Manager_Response__c
        });

        // Reply on the channel they chose. An employer agent that answers a
        // signed video with a phone call has closed the door again.
        if (ar.Barrier_Report__r != null) {
            out.put('reply_on', new Map<String, Object>{
                'channel'             => ar.Barrier_Report__r.Inbound_Modality__c,
                'interpreter_needed'  => ar.Barrier_Report__r.Interpreter_Needed__c == true,
                'never_by_telephone'  => true
            });
        }

        out.put('absent', new Map<String, Object>{
            'diagnosis'       => 'no such field exists in this system',
            'condition'       => 'no such field exists in this system',
            'disability_type' => 'no such field exists in this system',
            'medical_note'    => 'no such field exists in this system',
            'severity'        => 'no such field exists in this system',
            'prognosis'       => 'no such field exists in this system',
            'note' => 'These are not withheld. They were never collected and there is ' +
                      'nowhere to put them. A follow-up request for any of them has no ' +
                      'answer anywhere, from anyone, including from the person, who was ' +
                      'never asked.'
        });

        out.put('must_not_ask', new List<String>{
            'Do not ask this person, or anyone, for a diagnosis or medical documentation ' +
                'in order to process this request.',
            'Do not treat the absence of medical detail as an incomplete submission.',
            'Do not reply by telephone. Reply on the channel named in reply_on.',
            'Do not ask why a preference was withdrawn if one is later withdrawn.'
        });

        out.put('provenance', new Map<String, Object>{
            'system'  => 'Curb Cut',
            'about'   => 'https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut/why',
            'privacy' => 'https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut/privacy'
        });

        return JSON.serializePretty(out);
    }

    /** Invocable so the agent, a flow, or an external caller all use one path. */
    @InvocableMethod(label='Build handover payload'
        description='Builds the agent-to-agent payload for an approved accommodation request. Refuses without explicit consent.')
    public static List<String> build(List<Id> requestIds) {
        List<String> out = new List<String>();
        for (Id rid : requestIds) {
            try {
                out.add(payloadFor(rid));
            } catch (RefusedException r) {
                out.add(JSON.serializePretty(new Map<String, Object>{
                    'contract' => 'curb-cut/handover',
                    'refused'  => true,
                    'reason'   => r.getMessage()
                }));
            }
        }
        return out;
    }
}
