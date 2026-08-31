import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import triage from '@salesforce/apex/CurbCutConsole.triage';

/**
 * The numbers the person on duty needs before they need anything else.
 *
 * A dashboard three clicks away is a dashboard nobody opens on a bad morning,
 * so the counts sit at the top of the page they land on, each one a link
 * straight into the queue it counts.
 */
export default class CurbCutTriage extends NavigationMixin(LightningElement) {
    data;
    error;
    settled = false;

    @wire(triage)
    wired({ data, error }) {
        if (data) { this.data = data; this.error = undefined; this.settled = true; }
        else if (error) {
            // An operator who sees nothing assumes there is nothing. Say so out
            // loud instead: an empty queue and a broken queue look identical,
            // and only one of them means nobody is waiting.
            this.error = error?.body?.message || 'Could not load the queues. Do not read this as "nobody is waiting".';
            this.settled = true;
        }
    }

    get loaded() { return !!this.data; }

    // Severity is carried by a word as well as a colour, always.
    get waitingTone() {
        if (!this.data?.waiting) return 'calm';
        return this.data.longestWaitHours >= 24 ? 'urgent' : 'live';
    }
    get waitingNote() {
        if (!this.data?.waiting) return 'Nobody is waiting.';
        const h = this.data.longestWaitHours;
        if (h >= 24) return `Longest wait ${Math.floor(h / 24)} day${h >= 48 ? 's' : ''}. Start here.`;
        if (h >= 1)  return `Longest wait ${h} hour${h === 1 ? '' : 's'}.`;
        return 'Just arrived.';
    }

    get decisionTone() { return this.data?.overdue ? 'urgent' : (this.data?.undecided ? 'live' : 'calm'); }
    get decisionNote() {
        if (!this.data?.undecided) return 'Nothing outstanding.';
        return this.data.overdue
            ? `${this.data.overdue} past the date it was due.`
            : 'All still inside the interactive process window.';
    }

    get interpreterTone() { return this.data?.interpreters ? 'live' : 'calm'; }
    get interpreterNote() {
        return this.data?.interpreters
            ? 'Signed video is never machine translated. Each one waits on a person.'
            : 'Nothing waiting on an interpreter.';
    }

    get unreachedTone() { return this.data?.unreached ? 'urgent' : 'calm'; }
    get unreachedNote() {
        return this.data?.unreached
            ? 'Someone asked for help and heard nothing back.'
            : 'Every reply reached someone.';
    }

    goWaiting()      { this.toList('Human_Handoff__c', 'Waiting_For_A_Person'); }
    goDecisions()    { this.toList('Accommodation_Request__c', 'Awaiting_Decision'); }
    goInterpreters() { this.toList('Barrier_Report__c', 'Needs_An_Interpreter'); }
    goUnreached()    { this.toList('Message_Log__c', 'Did_Not_Reach_Them'); }

    toList(objectApiName, filterName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName, actionName: 'list' },
            state: { filterName }
        });
    }
}
