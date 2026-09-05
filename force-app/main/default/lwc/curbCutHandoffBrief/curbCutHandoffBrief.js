import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import brief from '@salesforce/apex/CurbCutConsole.brief';
import pickUp from '@salesforce/apex/CurbCutConsole.pickUp';
import bookInterpreter from '@salesforce/apex/CurbCutConsole.bookInterpreter';
import forRecord from '@salesforce/apex/CurbCutShow.forRecord';
import USER_NAME from '@salesforce/schema/User.Name';
import USER_ID from '@salesforce/user/Id';
import { getRecord, getFieldValue, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

/**
 * The handoff record, rearranged around the person rather than the row.
 *
 * What matters first is what they already said, once, in their own words --
 * and that was behind a lookup nobody clicks. Second is how to reach them,
 * which is the rule most easily broken by someone being helpful. Everything
 * else is bookkeeping.
 *
 * Third, and only on request, is what the person asked to be known ahead of
 * them. That is a disclosure they made while not in the room, so it is not
 * loaded with the page. The viewer says who they are reading as, presses a
 * button, and every showing is written to a ledger the person can read back.
 */
export default class CurbCutHandoffBrief extends LightningElement {
    @api recordId;
    data;
    error;
    working = false;
    wiredResult;

    // What this person asked you to know. Nothing is fetched until the viewer
    // asks, because fetching is showing, and showing is recorded.
    readingAs = 'Manager only';
    shown;
    showError;
    asking = false;

    @wire(getRecord, { recordId: USER_ID, fields: [USER_NAME] })
    user;

    @wire(brief, { handoffId: '$recordId' })
    wired(result) {
        this.wiredResult = result;
        if (result.data) { this.data = result.data; this.error = undefined; }
        else if (result.error) {
            this.error = result.error?.body?.message || 'Could not load this handoff.';
        }
    }

    get loaded() { return !!this.data; }
    get canTake() { return this.data && !this.data.pickedUp && !this.working; }
    // Booking is offered only where it is the blocking step, so it never becomes
    // a button people press out of habit on records it does not apply to.
    get needsInterpreter() { return !!this.data?.interpreter; }

    get waitedText() {
        const h = this.data?.waitedHours ?? 0;
        if (h >= 24) { const d = Math.floor(h / 24); return `${d} day${d === 1 ? '' : 's'}`; }
        if (h >= 1)  return `${h} hour${h === 1 ? '' : 's'}`;
        return 'less than an hour';
    }
    get waitTone() { return (this.data?.waitedHours ?? 0) >= 24 ? 'urgent' : 'live'; }

    get statusLine() {
        if (!this.data) return '';
        return this.data.pickedUp
            ? `${this.data.handler || 'Someone'} has this. They waited ${this.waitedText}.`
            : `Nobody has this yet. They have been waiting ${this.waitedText}.`;
    }

    // The audiences a person can choose, in the words they chose from. The
    // values are the picklist values on Access_Preference__c.Shared_With__c.
    get roleOptions() {
        return [
            { label: 'Their manager',         value: 'Manager only' },
            { label: 'A meeting host',        value: 'Meeting hosts' },
            { label: 'Someone on their team', value: 'My team' },
        ].map((o) => ({ ...o, selected: o.value === this.readingAs }));
    }
    get roleWords() {
        return (this.roleOptions.find((o) => o.selected) || this.roleOptions[0]).label
            .toLowerCase();
    }
    get hasShown()     { return Array.isArray(this.shown) && this.shown.length > 0; }
    get nothingShared(){ return Array.isArray(this.shown) && this.shown.length === 0; }
    get nothingLine() {
        return `Nothing is shared with ${this.roleWords}. If they wanted you to know something, they would have chosen you.`;
    }
    get revealStatus() {
        if (this.asking) return 'Looking, and recording that you looked.';
        if (this.hasShown) {
            const n = this.shown.length;
            return `Showing ${n} thing${n === 1 ? '' : 's'} they asked ${this.roleWords} to know. This was recorded.`;
        }
        if (this.nothingShared) return this.nothingLine;
        return '';
    }

    roleChanged(e) {
        this.readingAs = e.target.value;
        // A different audience is a different question. Ask again.
        this.shown = undefined;
        this.showError = undefined;
    }

    /**
     * Ask, as the audience the viewer named. The Apex writes the ledger row
     * before it returns a word, so if this resolves, the person can already
     * see who looked.
     */
    async reveal() {
        this.asking = true;
        this.showError = undefined;
        try {
            const rows = await forRecord({
                recordId: this.recordId,
                viewerRole: this.readingAs
            });
            this.shown = Array.isArray(rows) ? rows : [];
        } catch (e) {
            this.shown = undefined;
            this.showError = e?.body?.message
                || 'We could not record that you looked, so nothing was shown.';
        } finally {
            this.asking = false;
        }
    }

    get reachLine() {
        if (!this.data?.reachBy) return 'No channel recorded. Do not guess: ask the access team.';
        return `Reach them by ${this.data.reachBy.toLowerCase()}.`;
    }

    async take() {
        this.working = true;
        try {
            await pickUp({
                handoffId: this.recordId,
                handlerName: getFieldValue(this.user.data, USER_NAME)
            });
            await refreshApex(this.wiredResult);
            // The standard fields on the left are a separate cache. Without
            // this they keep showing Handler Name blank while this panel says
            // the handoff is taken, and a record that contradicts itself is
            // how two people end up working the same person, or nobody does.
            await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            this.dispatchEvent(new ShowToastEvent({
                title: 'You have this one',
                message: 'Reach them on the channel above. Never by telephone.',
                variant: 'success'
            }));
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Could not take it',
                message: e?.body?.message || 'Try again, or tell the access team.',
                variant: 'error'
            }));
        } finally {
            this.working = false;
        }
    }

    async book() {
        this.working = true;
        try {
            await bookInterpreter({
                handoffId: this.recordId,
                interpreterName: getFieldValue(this.user.data, USER_NAME)
            });
            await refreshApex(this.wiredResult);
            await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Interpreter booked',
                message: 'Tell them now. The waiting was the whole cost.',
                variant: 'success'
            }));
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Could not book it',
                message: e?.body?.message || 'Try again.', variant: 'error'
            }));
        } finally { this.working = false; }
    }
}
