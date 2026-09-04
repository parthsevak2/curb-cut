import { createElement } from 'lwc';
import CurbCutTriage from 'c/curbCutTriage';
import triage from '@salesforce/apex/CurbCutConsole.triage';
import { registerApexTestWireAdapter } from '@salesforce/wire-service-jest-util';
import { projectRuleset } from '../../../../../../jest/a11y-ruleset';

const triageWire = registerApexTestWireAdapter(triage);

// Salesforce Sa11y (axe-core, WCAG 2.1 A/AA) against the rendered component.
// The loading state is trivially accessible, so the states that matter are the
// loaded board and the error banner. Both are audited here.
describe('curbCutTriage accessibility', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    const mount = () => {
        const el = createElement('c-curb-cut-triage', { is: CurbCutTriage });
        document.body.appendChild(el);
        return el;
    };

    it('is accessible while the queues are still counting', async () => {
        mount();
        await Promise.resolve();
        await expect(document.body).toBeAccessible(projectRuleset);
    });

    it('is accessible with a loaded board', async () => {
        mount();
        triageWire.emit({
            waiting: 4, longestWaitHours: 31,
            undecided: 2, overdue: 1,
            interpreters: 1, unreached: 3,
        });
        await Promise.resolve();
        await expect(document.body).toBeAccessible(projectRuleset);
    });

    it('is accessible when every queue is empty', async () => {
        mount();
        triageWire.emit({
            waiting: 0, longestWaitHours: 0,
            undecided: 0, overdue: 0,
            interpreters: 0, unreached: 0,
        });
        await Promise.resolve();
        await expect(document.body).toBeAccessible(projectRuleset);
    });

    it('is accessible when the queues could not be read', async () => {
        mount();
        triageWire.error({ body: { message: 'Could not load the queues.' } });
        await Promise.resolve();
        await expect(document.body).toBeAccessible(projectRuleset);
    });
});
