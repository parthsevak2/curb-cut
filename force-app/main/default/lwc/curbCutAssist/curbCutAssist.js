import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import nextSteps from '@salesforce/apex/CurbCutAssist.nextSteps';
import offer from '@salesforce/apex/CurbCutAssist.offer';
import draftReply from '@salesforce/apex/CurbCutAssist.draftReply';
import ask from '@salesforce/apex/CurbCutAssist.ask';
import logSent from '@salesforce/apex/CurbCutAssist.logSent';

/**
 * The assistant for the person answering.
 *
 * Grounded and deterministic on purpose: an operator repeating a fluent
 * invention to a manager spends somebody's one ask on a thing that does not
 * exist. And it refuses staff exactly as it refuses everyone else, because the
 * internal tool is where a privacy promise usually gets quietly exempted.
 */
export default class CurbCutAssist extends LightningElement {
    @api recordId;

    plan;
    error;
    busy = false;
    result;
    resultTitle = '';
    refused = false;
    question = '';
    wiredPlan;

    @wire(nextSteps, { handoffId: '$recordId' })
    wired(res) {
        this.wiredPlan = res;
        if (res.data) { this.plan = res.data; this.error = undefined; }
        else if (res.error) {
            this.error = res.error?.body?.message || 'Could not read this handoff.';
        }
    }

    get ready() { return !!this.plan; }
    get steps() {
        return (this.plan?.steps || []).map((s, i) => ({
            ...s,
            n: i + 1,
            cls: `step tone-${s.tone}${s.done ? ' is-done' : ''}`,
            actionable: s.id === 'offer' || s.id === 'draft' || s.id === 'hold'
        }));
    }
    get hasResult() { return !!this.result; }
    get resultCls() { return this.refused ? 'panel refused' : 'panel'; }

    handleQuestion(e) { this.question = e.target.value; }

    async runStep(e) {
        const id = e.currentTarget.dataset.id;
        if (id === 'offer') { await this.call(offer, 'What you could offer'); }
        else if (id === 'draft') { await this.call(draftReply, 'A reply, ready to send'); }
        else if (id === 'hold') { await this.sendHolding(); }
    }

    async call(fn, title) {
        this.busy = true;
        try {
            const r = await fn({ handoffId: this.recordId });
            this.result = r;
            this.refused = r.refused;
            this.resultTitle = title;
        } catch (err) {
            this.toast('Could not do that', err?.body?.message || 'Try again.', 'error');
        } finally { this.busy = false; }
    }

    async askIt() {
        if (!this.question?.trim()) return;
        this.busy = true;
        try {
            const r = await ask({ handoffId: this.recordId, question: this.question });
            this.result = r;
            this.refused = r.refused;
            this.resultTitle = this.refused ? 'Refused' : 'Answer';
        } catch (err) {
            this.toast('Could not answer', err?.body?.message || 'Try again.', 'error');
        } finally { this.busy = false; }
    }

    async sendHolding() {
        this.busy = true;
        try {
            const d = await draftReply({ handoffId: this.recordId });
            this.result = d;
            this.refused = false;
            this.resultTitle = 'Holding message';
            await logSent({
                handoffId: this.recordId,
                channel: this.plan?.channel,
                detail: 'holding message sent by an operator'
            });
            await refreshApex(this.wiredPlan);
            this.toast('Recorded in the ledger',
                'Copy the text above and send it on their channel.', 'success');
        } catch (err) {
            this.toast('Could not record it', err?.body?.message || 'Try again.', 'error');
        } finally { this.busy = false; }
    }

    copy() {
        const text = this.result?.body || this.result?.message || '';
        if (!text) return;
        // Clipboard can be blocked; a silent failure would have someone believe
        // they had copied a reply they had not.
        if (navigator.clipboard?.writeText) {
            navigator.clipboard.writeText(text)
                .then(() => this.toast('Copied', 'Paste it into their channel.', 'success'))
                .catch(() => this.toast('Could not copy',
                    'Select the text above and copy it manually.', 'warning'));
        } else {
            this.toast('Could not copy', 'Select the text above and copy it manually.', 'warning');
        }
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
