import { createElement } from 'lwc';
import CurbCutHandoffBrief from 'c/curbCutHandoffBrief';
import { projectRuleset } from '../../../../../../jest/a11y-ruleset';

// Salesforce Sa11y (axe-core, WCAG 2.1 A/AA) against the rendered component.
describe('curbCutHandoffBrief accessibility', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('has no accessibility violations when it first renders', async () => {
        const el = createElement('c-curb-cut-handoff-brief', { is: CurbCutHandoffBrief });
        el.recordId = 'a01000000000001AAA';
        document.body.appendChild(el);
        await Promise.resolve();
        await expect(document.body).toBeAccessible(projectRuleset);
    });
});
