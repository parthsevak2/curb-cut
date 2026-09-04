import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import context from '@salesforce/apex/CurbCutEmergency.context';
import raise from '@salesforce/apex/CurbCutEmergency.raise';
import closeIt from '@salesforce/apex/CurbCutEmergency.close';

/**
 * The exception, and it looks like one.
 *
 * Collapsed by default, separated from everything else, and it will not reveal
 * a number to dial until a written reason is on file. That order is the whole
 * design: the reason exists before the call does, not after it.
 */
export default class CurbCutEmergency extends LightningElement {
    @api recordId;
    /** Set per org in Lightning App Builder. Never a number belonging to the person. */
    @api safeguardingNumber = '';
    @api accessTeamNumber = '';
    @api hrDutyNumber = '';

    ctx; error; wiredCtx;
    open = false;
    busy = false;
    raised;

    reason = '';
    squad = 'Safeguarding lead';
    raisedByWhom = 'A family member';
    personKnows = 'Unknown';
    callback = '';

    @wire(context, { handoffId: '$recordId' })
    wired(res) {
        this.wiredCtx = res;
        if (res.data) { this.ctx = res.data; this.error = undefined; }
        else if (res.error) { this.error = res.error?.body?.message || 'Could not load.'; }
    }

    get ready() { return !!this.ctx; }
    get reasonOk() { return (this.reason || '').trim().length >= 15; }
    get canRaise() { return this.reasonOk && !this.busy; }
    // LWC templates take no expressions, so the negation is a getter.
    get raiseDisabled() { return !this.canRaise; }
    get shortBy() { return Math.max(0, 15 - (this.reason || '').trim().length); }
    get reasonHint() {
        return this.reasonOk
            ? 'That will do. It has to survive being read back in six months.'
            : `${this.shortBy} more characters. Say what happened.`;
    }

    get squadOptions() {
        return [
            { label: 'Safeguarding lead', value: 'Safeguarding lead' },
            { label: 'Access team lead',  value: 'Access team lead' },
            { label: 'HR duty officer',   value: 'HR duty officer' }
        ];
    }
    get whoOptions() {
        return [
            { label: 'A family member',        value: 'A family member' },
            { label: 'The person themselves',  value: 'The person themselves' },
            { label: 'A colleague or manager', value: 'A colleague or manager' },
            { label: 'Someone else',           value: 'Someone else' }
        ];
    }
    get knowsOptions() {
        return [
            { label: 'Unknown', value: 'Unknown' },
            { label: 'Yes',     value: 'Yes' },
            { label: 'No',      value: 'No' }
        ];
    }

    get squadNumber() {
        if (this.squad === 'Access team lead') return this.accessTeamNumber;
        if (this.squad === 'HR duty officer')  return this.hrDutyNumber;
        return this.safeguardingNumber;
    }
    get squadTel() { return this.squadNumber ? `tel:${this.squadNumber.replace(/[^+\d]/g, '')}` : ''; }
    get hasSquadNumber() { return !!this.squadNumber; }

    get toggleLabel() { return this.open ? 'Close this' : 'Emergency escalation'; }
    // LWC templates take no expressions, so aria-expanded comes from a getter
    // returning a string. It was dropped once while fixing a parse error, which
    // left a screen reader with no way to tell whether the panel was open.
    get expanded() { return this.open ? 'true' : 'false'; }

    toggle() { this.open = !this.open; }
    clearWritten() {
        const ta = this.template.querySelector('.ta');
        if (ta) { ta.value = ''; }
    }

    onReason(e) { this.reason = e.target.value; }
    onSquad(e)  { this.squad = e.detail.value; }
    onWho(e)    { this.raisedByWhom = e.detail.value; }
    onKnows(e)  { this.personKnows = e.detail.value; }
    onCallback(e) { this.callback = e.target.value; }

    async doRaise() {
        this.busy = true;
        try {
            this.raised = await raise({
                handoffId: this.recordId,
                reason: this.reason,
                squad: this.squad,
                raisedByWhom: this.raisedByWhom,
                personKnows: this.personKnows,
                callbackNumber: this.callback
            });
            await refreshApex(this.wiredCtx);
            this.dispatchEvent(new ShowToastEvent({
                title: `Escalation ${this.raised.Name} recorded`,
                message: 'The reason is on file. The number is now shown below.',
                variant: 'success'
            }));
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Not raised',
                message: e?.body?.message || 'Try again.',
                variant: 'error'
            }));
        } finally { this.busy = false; }
    }

    async doClose() {
        this.busy = true;
        try {
            await closeIt({ escalationId: this.raised.Id, outcome: 'Closed from the console.' });
            this.raised = undefined;
            this.reason = ''; this.callback = '';
            // A textarea holds its text as a child node, not a value attribute,
            // so clearing the field means clearing the element as well. Getting
            // this wrong leaves the last emergency's words sitting in the box
            // for the next one.
            this.clearWritten();
            await refreshApex(this.wiredCtx);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Closed',
                message: 'Any callback number you were given has been cleared.',
                variant: 'success'
            }));
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Could not close it',
                message: e?.body?.message || 'Try again.', variant: 'error'
            }));
        } finally { this.busy = false; }
    }
}
