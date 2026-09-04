import axe from 'axe-core';
import { base, extended } from '@sa11y/preset-rules';

// A test suite that cannot fail proves nothing. Before trusting any result from
// the component suites, prove the harness detects a violation we plant on
// purpose, and report what axe can and cannot decide inside jsdom.
describe('Sa11y harness control', () => {
    afterEach(() => { document.body.innerHTML = ''; });

    it('FAILS on a deliberately inaccessible image', async () => {
        document.body.innerHTML = '<img src="x.png">';
        await expect(expect(document.body).toBeAccessible()).rejects.toThrow();
    });

    it('reports what axe decides about an uncaptioned video', async () => {
        document.body.innerHTML =
            '<video src="s.mp4" controls preload="metadata"></video>';
        const r = await axe.run(document.body, extended);
        const say = (label, arr) =>
            console.log(`  ${label}: ${arr.map(v => v.id).join(', ') || '(none)'}`);
        say('violations ', r.violations);
        say('incomplete ', r.incomplete);
        say('inapplicable(video-caption)',
            r.inapplicable.filter(v => v.id === 'video-caption'));
        expect(true).toBe(true);
    });
});
