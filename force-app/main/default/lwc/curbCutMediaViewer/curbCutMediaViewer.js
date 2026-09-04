import { LightningElement, api, wire } from 'lwc';
import media from '@salesforce/apex/CurbCutConsole.media';

/**
 * What they sent, shown as they sent it.
 *
 * No transcript, no caption, no generated alt text, and no button that offers
 * any of those. A signed video is a person speaking; running it through a
 * machine translator is the one thing this system promises never to do, and the
 * surest way for that promise to break is for the machine to be one click away.
 */
export default class CurbCutMediaViewer extends LightningElement {
    @api recordId;
    items; error;

    @wire(media, { barrierId: '$recordId' })
    wired({ data, error }) {
        if (data) {
            this.items = data.map(m => ({
                ...m,
                cls: m.isVideo ? 'item video' : 'item',
                // Tied to the video with aria-describedby. WCAG 1.2.2 wants
                // captions; there are none and there must not be auto-generated
                // ones, so the honest thing is to say that out loud to the
                // person who cannot watch it, rather than leave silence.
                noteId: `nocap-${m.id}`,
                kind: m.isVideo ? 'Signed or spoken video' : (m.isImage ? 'Photo' : 'File'),
                meta: `${m.arrivedAt} · ${m.sizeKb} KB`
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error?.body?.message || 'Could not load what they sent.';
        }
    }

    get hasItems() { return this.items && this.items.length > 0; }
    get loaded()   { return !!this.items; }
    get anyVideo() { return (this.items || []).some(i => i.isVideo); }
}
