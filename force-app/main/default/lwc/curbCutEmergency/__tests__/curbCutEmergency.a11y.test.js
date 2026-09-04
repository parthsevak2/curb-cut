import { createElement } from 'lwc';
import CurbCutEmergency from 'c/curbCutEmergency';
import { projectRuleset } from '../../../../../../jest/a11y-ruleset';

// Salesforce Sa11y (axe-core, WCAG 2.1 A/AA) against the rendered component.
describe('curbCutEmergency accessibility', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('has no accessibility violations when it first renders', async () => {
        const el = createElement('c-curb-cut-emergency', { is: CurbCutEmergency });
        el.recordId = 'a01000000000001AAA';
        document.body.appendChild(el);
        await Promise.resolve();
        await expect(document.body).toBeAccessible(projectRuleset);
    });
});
