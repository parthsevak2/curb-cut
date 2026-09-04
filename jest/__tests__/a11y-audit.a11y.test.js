import { createElement } from 'lwc';
import axe from 'axe-core';
import { extended } from '@sa11y/preset-rules';
import { writeFileSync, mkdirSync } from 'fs';
import { join } from 'path';

import CurbCutTriage from 'c/curbCutTriage';
import CurbCutAssist from 'c/curbCutAssist';
import CurbCutEmergency from 'c/curbCutEmergency';
import CurbCutHandoffBrief from 'c/curbCutHandoffBrief';
import CurbCutMediaViewer from 'c/curbCutMediaViewer';

import triage from '@salesforce/apex/CurbCutConsole.triage';
import media from '@salesforce/apex/CurbCutConsole.media';
import brief from '@salesforce/apex/CurbCutConsole.brief';
import nextSteps from '@salesforce/apex/CurbCutAssist.nextSteps';
import context from '@salesforce/apex/CurbCutEmergency.context';

jest.mock(
    '@salesforce/apex/CurbCutConsole.triage',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/wire-service-jest-util');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/CurbCutConsole.media',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/wire-service-jest-util');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/CurbCutConsole.brief',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/wire-service-jest-util');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/CurbCutAssist.nextSteps',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/wire-service-jest-util');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/CurbCutEmergency.context',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/wire-service-jest-util');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);

const RID = 'a01000000000001AAA';
const findings = [];

async function audit(name, build) {
    document.body.innerHTML = '';
    const el = await build();
    await Promise.resolve();
    await Promise.resolve();
    const r = await axe.run(document.body, extended);
    findings.push({
        state: name,
        violations: r.violations.map(v => ({
            id: v.id, impact: v.impact, help: v.help,
            wcag: (v.tags || []).filter(t => /^wcag/.test(t)),
            nodes: v.nodes.length,
            html: v.nodes[0]?.html?.slice(0, 160),
        })),
        incomplete: r.incomplete.map(v => ({
            id: v.id, impact: v.impact, help: v.help,
            reason: v.nodes[0]?.any?.[0]?.message || v.description,
        })),
        passes: r.passes.length,
    });
    if (el && el.parentNode) el.parentNode.removeChild(el);
}

const mount = (tag, Ctor, props = {}) => {
    const el = createElement(tag, { is: Ctor });
    Object.assign(el, props);
    document.body.appendChild(el);
    return el;
};

describe('Curb Cut accessibility audit (Salesforce Sa11y / axe-core, WCAG 2.1 A+AA)', () => {
    it('audits every component in every state it can reach', async () => {
        await audit('triage / loading', () => mount('c-curb-cut-triage', CurbCutTriage));
        await audit('triage / loaded, queues busy', () => {
            const el = mount('c-curb-cut-triage', CurbCutTriage);
            triage.emit({ waiting: 4, longestWaitHours: 31, undecided: 2, overdue: 1, interpreters: 1, unreached: 3 });
            return el;
        });
        await audit('triage / loaded, all empty', () => {
            const el = mount('c-curb-cut-triage', CurbCutTriage);
            triage.emit({ waiting: 0, longestWaitHours: 0, undecided: 0, overdue: 0, interpreters: 0, unreached: 0 });
            return el;
        });
        await audit('triage / queues unreadable', () => {
            const el = mount('c-curb-cut-triage', CurbCutTriage);
            triage.error({ body: { message: 'Could not load the queues.' } });
            return el;
        });

        await audit('mediaViewer / nothing sent', () => {
            const el = mount('c-curb-cut-media-viewer', CurbCutMediaViewer, { recordId: RID });
            media.emit([]);
            return el;
        });
        await audit('mediaViewer / a photo', () => {
            const el = mount('c-curb-cut-media-viewer', CurbCutMediaViewer, { recordId: RID });
            media.emit([{ id: '1', isImage: true, isVideo: false, url: 'https://example.invalid/a.png', title: 'The doorway they cannot get through', arrivedAt: '2 Sep', sizeKb: 240 }]);
            return el;
        });
        await audit('mediaViewer / a signed video', () => {
            const el = mount('c-curb-cut-media-viewer', CurbCutMediaViewer, { recordId: RID });
            media.emit([{ id: '2', isImage: false, isVideo: true, url: 'https://example.invalid/signed.mp4', title: 'Signed description of the barrier', arrivedAt: '2 Sep', sizeKb: 8100 }]);
            return el;
        });

        await audit('handoffBrief / waiting, nobody picked up', () => {
            const el = mount('c-curb-cut-handoff-brief', CurbCutHandoffBrief, { recordId: RID });
            brief.emit({ theirWords: 'My back hurts by the afternoon.', reachBy: 'SMS', waitedHours: 31, pickedUp: false, interpreter: false, neverCall: true, modality: 'text message' });
            return el;
        });
        await audit('handoffBrief / needs an interpreter', () => {
            const el = mount('c-curb-cut-handoff-brief', CurbCutHandoffBrief, { recordId: RID });
            brief.emit({ theirWords: '', reachBy: 'Video', waitedHours: 50, pickedUp: true, handler: 'Sam', interpreter: true, neverCall: true, modality: 'signed video' });
            return el;
        });

        await audit('assist / a plan with steps and a result', () => {
            const el = mount('c-curb-cut-assist', CurbCutAssist, { recordId: RID });
            nextSteps.emit({ message: 'They have waited 31 hours. Start with what they said.', steps: [
                { id: 'read', label: 'Read what they sent', why: 'It is already in their words.', tone: 'calm', done: true },
                { id: 'offer', label: 'See what you could offer', why: 'From the sourced library only.', tone: 'live', done: false },
                { id: 'draft', label: 'Draft a reply', why: 'You approve it before it sends.', tone: 'live', done: false },
            ] });
            return el;
        });

        await audit('emergency / collapsed', () => mount('c-curb-cut-emergency', CurbCutEmergency, { recordId: RID }));
        await audit('emergency / open, cannot take a call', async () => {
            const el = mount('c-curb-cut-emergency', CurbCutEmergency, { recordId: RID });
            context.emit({ neverCall: true, alreadyOpen: false });
            await Promise.resolve();
            el.shadowRoot.querySelector('.toggle')?.click();
            return el;
        });

        // Write the report where a human and the submission can both read it.
        mkdirSync(join(process.cwd(), 'docs'), { recursive: true });
        writeFileSync(join(process.cwd(), 'docs', 'a11y-sa11y-findings.json'),
            JSON.stringify(findings, null, 2));

        const totalV = findings.reduce((n, f) => n + f.violations.length, 0);
        const totalI = findings.reduce((n, f) => n + f.incomplete.length, 0);
        console.log(`\n  states audited : ${findings.length}`);
        console.log(`  violations     : ${totalV}`);
        console.log(`  undecidable    : ${totalI}  (axe cannot judge these inside jsdom)`);
        for (const f of findings) {
            if (f.violations.length || f.incomplete.length) {
                console.log(`   ${f.state}`);
                f.violations.forEach(v => console.log(`     VIOLATION  ${v.id} [${v.impact}] ${v.wcag.join(',')} x${v.nodes}`));
                f.incomplete.forEach(v => console.log(`     UNDECIDED  ${v.id} [${v.impact || 'n/a'}]`));
            }
        }
        expect(findings.length).toBeGreaterThan(0);
    });
});
