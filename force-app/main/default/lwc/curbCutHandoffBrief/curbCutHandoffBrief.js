import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import brief from '@salesforce/apex/CurbCutConsole.brief';
import pickUp from '@salesforce/apex/CurbCutConsole.pickUp';
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
 */
export default class CurbCutHandoffBrief extends LightningElement {
    @api recordId;
    data;
    error;
    working = false;
    wiredResult;

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
}
