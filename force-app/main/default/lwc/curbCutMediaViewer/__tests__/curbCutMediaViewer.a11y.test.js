import { createElement } from 'lwc';
import CurbCutMediaViewer from 'c/curbCutMediaViewer';
import media from '@salesforce/apex/CurbCutConsole.media';
import { projectRuleset } from '../../../../../../jest/a11y-ruleset';

jest.mock(
    '@salesforce/apex/CurbCutConsole.media',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/wire-service-jest-util');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);

// Salesforce Sa11y (axe-core, WCAG 2.1 A/AA) against the rendered component.
describe('curbCutMediaViewer accessibility', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    const mount = () => {
        const el = createElement('c-curb-cut-media-viewer', { is: CurbCutMediaViewer });
        el.recordId = 'a01000000000001AAA';
        document.body.appendChild(el);
        return el;
    };

    it('is accessible when nothing was sent', async () => {
        mount();
        media.emit([]);
        await Promise.resolve();
        await expect(document.body).toBeAccessible(projectRuleset);
    });

    it('is accessible showing a photo', async () => {
        mount();
        media.emit([{
            id: '1', isImage: true, isVideo: false,
            url: 'https://example.invalid/a.png',
            title: 'The doorway they cannot get through',
            arrivedAt: '2 Sep', sizeKb: 240,
        }]);
        await Promise.resolve();
        await expect(document.body).toBeAccessible(projectRuleset);
    });

    it('is accessible showing a signed video', async () => {
        mount();
        media.emit([{
            id: '2', isImage: false, isVideo: true,
            url: 'https://example.invalid/signed.mp4',
            title: 'Signed description of the barrier',
            arrivedAt: '2 Sep', sizeKb: 8100,
        }]);
        await Promise.resolve();
        await expect(document.body).toBeAccessible(projectRuleset);
    });

    it('points every video at a description that actually exists', async () => {
        const el = mount();
        media.emit([{
            id: '2', isImage: false, isVideo: true,
            url: 'https://example.invalid/signed.mp4',
            title: 'Signed description of the barrier',
            arrivedAt: '2 Sep', sizeKb: 8100,
        }]);
        await Promise.resolve();
        const video = el.shadowRoot.querySelector('video');
        const ref = video.getAttribute('aria-describedby');
        expect(ref).toBeTruthy();
        // LWC rewrites ids inside a shadow root, so the only claim worth making
        // is that the id the video points at resolves to a real element with
        // real words in it.
        const target = el.shadowRoot.querySelector(`[id="${ref}"]`);
        expect(target).not.toBeNull();
        expect(target.textContent.trim().length).toBeGreaterThan(20);
    });
});
