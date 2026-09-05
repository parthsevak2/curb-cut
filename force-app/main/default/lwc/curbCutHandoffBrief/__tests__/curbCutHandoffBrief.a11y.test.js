import { createElement } from 'lwc';
import CurbCutHandoffBrief from 'c/curbCutHandoffBrief';
import brief from '@salesforce/apex/CurbCutConsole.brief';
import forRecord from '@salesforce/apex/CurbCutShow.forRecord';
import { projectRuleset } from '../../../../../../jest/a11y-ruleset';

jest.mock(
    '@salesforce/apex/CurbCutConsole.brief',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/wire-service-jest-util');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);

// Imperative, not wired: fetching a preference is showing it, and showing it
// is recorded, so the component only calls this when the viewer presses the
// button. The mock resolves with whatever the state under test needs.
jest.mock(
    '@salesforce/apex/CurbCutShow.forRecord',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const LOADED = {
    theirWords: 'The room is too loud to think in',
    reachBy: 'Text message', modality: 'Text',
    interpreter: false, neverCall: true,
    waitedHours: 3, handler: null, pickedUp: false,
    barrierId: 'a00000000000001AAA',
};

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

// Salesforce Sa11y (axe-core, WCAG 2.1 A/AA) against the rendered component.
describe('curbCutHandoffBrief accessibility', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        forRecord.mockReset();
    });

    const mount = () => {
        const el = createElement('c-curb-cut-handoff-brief', { is: CurbCutHandoffBrief });
        el.recordId = 'a01000000000001AAA';
        document.body.appendChild(el);
        return el;
    };

    const reveal = async (el) => {
        el.shadowRoot.querySelector('button.ask').click();
        await flush();
        await flush();
    };

    it('has no accessibility violations when it first renders', async () => {
        mount();
        await Promise.resolve();
        await expect(document.body).toBeAccessible(projectRuleset);
    });

    it('is accessible with a loaded brief and nothing yet revealed', async () => {
        mount();
        brief.emit(LOADED);
        await Promise.resolve();
        await expect(document.body).toBeAccessible(projectRuleset);
    });

    it('is accessible showing what the person asked the viewer to know', async () => {
        const el = mount();
        brief.emit(LOADED);
        await Promise.resolve();
        forRecord.mockResolvedValue([{
            preferenceId: 'a02000000000001AAA',
            statement: 'Please send me the agenda the day before, in writing',
            scope: 'Always', savedOn: '2 September 2026', shownTo: 'Dana Osei',
        }]);
        await reveal(el);
        // The words must be on the page, verbatim, before we audit them.
        const quote = el.shadowRoot.querySelector('.said blockquote');
        expect(quote).not.toBeNull();
        expect(quote.textContent).toBe('Please send me the agenda the day before, in writing');
        expect(forRecord).toHaveBeenCalledWith({
            recordId: 'a01000000000001AAA', viewerRole: 'Manager only'
        });
        await expect(document.body).toBeAccessible(projectRuleset);
    });

    it('is accessible when nothing is shared with the audience the viewer named', async () => {
        const el = mount();
        brief.emit(LOADED);
        await Promise.resolve();
        forRecord.mockResolvedValue([]);
        await reveal(el);
        expect(el.shadowRoot.querySelector('.said')).toBeNull();
        expect(el.shadowRoot.querySelector('[role="status"]').textContent)
            .toContain('Nothing is shared');
        await expect(document.body).toBeAccessible(projectRuleset);
    });

    it('is accessible when the ledger could not be written', async () => {
        const el = mount();
        brief.emit(LOADED);
        await Promise.resolve();
        forRecord.mockRejectedValue({ body: {
            message: 'We could not record that you saw this, so we have not shown it.'
        } });
        await reveal(el);
        expect(el.shadowRoot.querySelector('.said')).toBeNull();
        expect(el.shadowRoot.querySelector('[role="alert"]')).not.toBeNull();
        await expect(document.body).toBeAccessible(projectRuleset);
    });

    it('never asks Apex until the viewer does', async () => {
        mount();
        brief.emit(LOADED);
        await Promise.resolve();
        await flush();
        expect(forRecord).not.toHaveBeenCalled();
    });
});
