# Accessibility Expert Skill reflection

This is the organisers' reflection prompt, run over Curb Cut as it stood on the last day of the submission period. It was applied by a review panel of language models, one reviewer per part of the scope, and a second, independent pass tried to refute each finding. No daily screen reader user and no human ethics reviewer has been through this yet; that stays the largest gap.

## What we ran

The prompt, verbatim:

> Act as an accessibility expert grounded in WCAG 2.1 AA guidelines. Review [my content/design/code] and flag any accessibility issues, missing alt text, color contrast problems, keyboard navigation gaps, or unclear reading order. For each issue, explain the barrier it creates and suggest a specific fix.

Scope: The seven live public pages and their source, the five Lightning Web Components and console pages, and the submission content: the Devpost description with its five images, both caption files, the judge guide and the README.

Run on 7 September 2026. Findings raised: 40. Verified by the second pass so far: 0, of which 0 were not upheld. Fixed the same day: 13. Still open: 27.

## Done well, in the reviewers' words

- Contrast is genuinely strong in the light theme: body text 15.9:1, secondary text 8.4:1, small labels 5.25:1, teal/ochre/alert accents 5.1 to 7.3:1 on their backgrounds, and the focus ring (#0B57C7) is 5.8:1 on the page ground with a pale second ring so it stays visible beside dark filled buttons.
- Keyboard path is clean: a working skip link to main (tabindex=-1), every control is a native button, link, select, textarea, or details/summary, no custom widgets, no keyboard traps, Enter and Ctrl+Enter both submit the ask form, and after a network error the button is re-enabled and refocused so retry is one press.
- Focus management on /ask is deliberate: after each step focus lands on the new section heading (tabindex=-1 set on the fly), the saved claim code moves focus to its heading, and the copy button announces the code letter by letter.
- Status messages: three role=status aria-live=polite regions with aria-atomic, visible to sighted users as well, and a separate visually-hidden live region so the three-state text-size control is announced by size rather than by a meaningless second 'pressed'.
- The six-letter claim code is exposed to screen readers as real visually-hidden text spelled letter by letter, with the visual copy aria-hidden, which is the correct pattern (aria-label on a paragraph would be ignored).
- Alt text: the 100-square tally is role=img with an alt that carries the full statistic including the 33/6 split and medians; the site mark is an inline SVG with aria-hidden and the visible name beside it; the single raster image on /docs has a descriptive alt.
- Reduced motion is honoured twice over: the entrance animations are gated behind prefers-reduced-motion: no-preference and a blanket rule cancels all animation and transitions when reduce is set.
- Reflow: /, /ask, /why, /messaging, /privacy and /terms produce no horizontal scroll at 320px CSS width (verified live); the sticky masthead becomes static on narrow or short viewports and every focusable element has scroll-margin-top so it cannot be hidden behind the header.
- Reader controls persist across pages via localStorage wrapped in try/catch, the OS prefers-contrast: more request is honoured, and a dark theme is provided with its own token set.
- Forms: every field has a for/id label plus aria-describedby help text; the empty-submit error is announced and focus returns to the field; the progress rail carries its state in visually-hidden words ('you are here', 'done', 'not started') as well as fill.
- Document structure: lang=en, unique and descriptive page titles, one h1 per page, sensible h2/h3/h4 nesting, heading ids that are unique, aria-current=page on the nav, and the docs page has its own labelled nav.
- docs/SCREEN-READER-WALK.md is honest that it was produced by a script from Chromium's accessibility tree and not by a screen-reader user, and it says so on its first line.
- Touch targets are 44 to 48px for buttons, starters, nav links and the fold summaries, with a specific rule for stand-alone links in paragraphs.
- Every interactive thing is a real control: <button>, <a href>, <input>, <select>, <textarea> or a lightning base component. tests/lwc_audit.py forbids onclick on a div, and there are none.
- One visible focus indicator on every control (outline 3px #0b57c7, offset 2px), measured at 6.56:1 on white, 6.19:1 on the emergency wash and 5.80:1 on the assistant's result wash. Targets are 34 to 44px tall.
- Colour never carries state alone. Each data-tone or tone class is paired with a sentence (triage notes, the handoff status line, step labels), and the CSS comments say why. Done steps change their words ('Taken by Sam'), not only their styling.
- curbCutHandoffBrief shows the right pattern for async work: an always-present role=status region with aria-atomic, an aria-busy guard on the reveal button that keeps focus where it was, and notifyRecordUpdateAvailable so the standard fields stop contradicting the panel.
- The signed-video note is honest and visible to everyone, tied to the <video> with aria-describedby, and a test proves the idref resolves through LWC's synthetic shadow DOM. The report says plainly that this does not satisfy 1.2.2.
- Disclosure done properly in curbCutEmergency: aria-expanded from a string getter, with a comment recording the time it was lost. Decorative dot and triangle are aria-hidden.
- Every field has a <label for>; comboboxes carry labels; components use h2 and never h1; the flexipage rich-text guides use headings so they are navigable.
- prefers-reduced-motion disables the one animation; prefers-contrast: more darkens borders and secondary text; rem units and an auto-fit grid mean the triage board reflows at 320px without horizontal scroll.
- Errors are said out loud in role=alert, and the triage error refuses to look like an empty queue ('Do not read this as nobody is waiting'). Every async outcome fires a toast, including a clipboard failure.
- Body and secondary text contrast is high almost everywhere: 17.99:1 for buttons, 8.42:1 for .soft/.why, 10.59:1 for the video note, 8.24:1 for the emergency red on white, 7.06:1 for the badge.
- The Sa11y harness uses the 100-rule extended preset, excludes exactly one rule in one place with the reason beside it, includes a control test that proves the matcher can fail, and the report lists what axe could not decide rather than calling it a pass.
- Every image in the description has a written, sentence-length alt in tests/render_devpost_description.py (line 6); the Slack alt is dated and specific, and the judge guide transcribes the whole Slack exchange as text under the screenshot (lines 124-149), so the picture is never the only source.
- The full film on YouTube carries a manually uploaded English caption track (the watch page lists an 'English' track alongside 'English (auto-generated)'), and the captions are real text, not burned in, so they can be resized and restyled by the viewer.
- Caption reading speed is gentle (7.7 to 11.7 characters a second, never above 12), cues never overlap, and each cue starts about 0.3 s before the voice (measured with ffmpeg silencedetect on curb-cut-3min.mp4).
- The music bed is mixed at -23 dB with sidechain ducking under the voice (video/mix_music.py), so speech stays intelligible for hard-of-hearing viewers.
- The two film links in the description use descriptive text ('Watch the three-minute cut', 'The full film, 4:59, every channel live'), and the README evidence table names each source (Disability:IN, US BLS, JAN, Statistics Canada, Government of Canada) rather than 'here'.
- Headings render as real h3s in a sensible order; the six doors are a real unordered list; README and the guide use markdown headings and tables with header rows.
- The judge guide gives a keyboard-only path ('Tab, and Enter or Space. Nothing needs a mouse'), names the Bigger text and Contrast controls, and those names match the live page (button#tsize reads 'Bigger text').
- Voice has a text equivalent on the same number, so a Deaf judge can test the phone channel by SMS; the guide gives the number and the keyword as text.
- The description says plainly what is not done ('No one who uses a screen reader every day has tested this yet'), which is the honest position and lets judges weigh the claims.

## Findings

Severity is 1 to 5, where 5 means a person is excluded or harmed. Status says what happened next.

### Focus is dropped when the button you just pressed is disabled or removed, including at the moment the emergency number appears (severity 3)

Where: curbCutEmergency.html lines 32-56 (the whole form, submit button included, sits in <template if:false={raised}> and is unmounted when curbCutEmergency.js line 104 sets `raised`; the dial link at line 61 replaces it) and line 70 (Close button, disabled={busy}, then unmounted at js line 131); curbCutHandoffBrief.js line 52 `get canTake() { return this.data && !this.data.pickedUp && !this.working; }` with html line 67, so 'I am picking this up' is unmounted the instant it is pressed and never comes back; curbCutHandoffBrief.html line 77 disabled={working}; curbCutAssist.html lines 24-25 and 48, disabled={busy} on all five action buttons and Ask.. Criterion: WCAG 2.4.3 Focus Order (and the expectation that focus is managed on dynamic changes); contrast with the project's own correct pattern at curbCutHandoffBrief.js lines 113-114 and html line 31 (aria-busy guard, 'the button keeps focus')..

Barrier or risk: Chrome blurs a control the moment it becomes disabled, and every browser moves focus to the document body when the focused element is removed. On a Lightning record page that means a keyboard or screen-reader operator is dropped to the top, with the global header, app navigation, highlights panel, and the whole detail section between them and where they were. In the emergency panel this happens exactly when the phone number is revealed: the toast says 'The number is now shown below', and the operator's focus is nowhere near it. In the assistant it happens on every press, so a screen-reader user who asks a question is sent away from the answer.

Fix proposed: Never disable or unmount the control that was just pressed. Copy the reveal() guard (`if (this.busy) return;` plus aria-busy={busy} on the button) to runStep, askIt, sendHolding, doRaise, doClose, take and book, and drop `!this.working` from canTake. Where the control legitimately goes away on success, move focus deliberately in the same code path: to the .dial link after raise, to the .toggle after close, to the 'Picked up by ...' paragraph (give it tabindex="-1") after pick-up, and to the result panel title after an assistant answer. Do it after render (a renderedCallback flag or `await Promise.resolve()`), and add a Jest assertion on document.activeElement after each press, which jsdom supports.

Status: Open

### The assistant's result panel is a live region created together with its text, so the first answer or refusal may go unannounced (severity 3)

Where: curbCutAssist.html lines 32-41: `<template if:true={hasResult}><div class={resultCls} role="status" aria-live="polite">`. The region does not exist until `result` is set in curbCutAssist.js lines 64, 77 and 89. Nothing is announced while the Apex call runs (the buttons simply go disabled).. Criterion: WCAG 4.1.3 Status Messages.

Barrier or risk: Live regions are reliable only when the region already exists and its contents change; a region inserted into the DOM with its text already inside is announced inconsistently across screen reader and browser pairs (role=alert gets special handling on insertion, role=status does not). So a screen-reader operator presses 'See what you could offer them' or 'Ask', hears nothing, and presses again, and the 'Refused' panel, the one response the project most wants heard by staff, is the one most likely to be missed. curbCutHandoffBrief.html line 35 already does this correctly with an always-present <p role="status" aria-live="polite" aria-atomic="true">.

Fix proposed: Render one status element unconditionally inside <template if:true={ready}> and only change its text: 'Working...' when busy is set, then `${resultTitle}. ${result.message}` when the call returns (aria-atomic="true"). Keep the visual panel, the <pre> body and the Copy button outside the live region so a long library listing is not read in one breath and the button is not inside a status. Add a Jest state for 'assist / result shown' and 'assist / refused'; neither exists today.

Status: Open

### Text-field borders are the only thing that shows where the field is, and they measure 1.56:1 (severity 3)

Where: curbCutAssist.css line 109 `.ask-input { border: 1px solid #c9d0d4 }` on a white card; curbCutEmergency.css line 30 `.ta, .inp { border: 1px solid #c9d0d4; background: #fff }` inside the #fdf7f6 box (the two fills differ by 1.02:1, so the fill gives no edge either). Measured #c9d0d4 on #fff = 1.56:1 against the 3:1 minimum. The prefers-contrast: more block at curbCutAssist.css line 119 fixes it only for people who have set that OS preference.. Criterion: WCAG 1.4.11 Non-text Contrast.

Barrier or risk: A low-vision operator cannot see where the 'Ask about this one' box, the emergency 'Why is this happening?' box or the callback-number field begins and ends, so they click beside it, or type into what they think is a field. The project already holds itself to 3:1 for input borders on the public site (tests/contrast_audit.py line 62, 'input borders, which must be perceivable') and the handoff brief's select uses a 2px #5e6568 border at 5.94:1, so the standard exists; these three fields missed it.

Fix proposed: Use the .pick treatment from curbCutHandoffBrief.css line 31 on .ask-input, .ta and .inp: `border: 2px solid #5e6568` (5.94:1), or at minimum #6b7174 (4.95:1). Then add the five LWC CSS files to tests/contrast_audit.py so the console's borders and text are measured, not assumed.

Status: Open

### The emergency reason's 15-character rule, and why the submit button is disabled, are never given to assistive technology (severity 3)

Where: curbCutEmergency.html lines 33-36: <textarea id="why"> is labelled, but the <p class="hint">{reasonHint}</p> that says '15 more characters. Say what happened.' has no aria-describedby link and is not live; line 53 `disabled={raiseDisabled}` keeps 'Record the reason and get the number' disabled until curbCutEmergency.js line 41 (`length >= 15`) is satisfied. Same pattern for the callback hint at lines 48-51.. Criterion: WCAG 3.3.2 Labels or Instructions; 1.3.1 Info and Relationships.

Barrier or risk: A screen-reader operator focuses the box and hears only 'Why is this happening?', types a short reason, tabs on, and the submit button is simply not there: disabled buttons are skipped by Tab, and nothing says why. In a safeguarding call that is time lost with no explanation. The disabled button also drops to 2.39:1 (white on #ca9d98 at opacity .45), which is allowed for disabled controls but makes its label, the one that says what will happen, hard to read for exactly the person deciding whether to press it.

Fix proposed: Put `aria-describedby` on the textarea pointing at the hint (and on the callback input pointing at its hint). Prefer keeping the button enabled and validating on press: show the Apex message already written at CurbCutEmergency.cls line 71 ('Say why, in a sentence someone reviewing this in six months could understand...') in a role="alert" paragraph and move focus back to the textarea. If the disabled state is kept, make the hint aria-live="polite" so 'That will do' is heard when the threshold is crossed.

Status: Open

### Signed or spoken media has no end state: once a human interpreter has done the work, the console has nowhere to show it (severity 3)

Where: curbCutMediaViewer.html lines 28-35 (video plus the 'waiting on a human interpreter' note) and js line 27; CurbCutConsole.cls media() lines 143-171 returns only the file. Barrier_Report__c has five fields (Access_Profile, Anonymous, Functional_Description, Inbound_Modality, Interpreter_Needed) and Human_Handoff__c adds Interpreter_Booked_At and Interpreter_Name; there is no field for a human interpretation or transcript anywhere. Inbound_Modality includes 'Voice note', and audio files fall outside the isVideo/isImage sets (CurbCutConsole.cls lines 164-165), so they render as 'File' with only a download link.. Criterion: WCAG 1.2.2 Captions (Prerecorded) and 1.2.3 Audio Description or Media Alternative, for the operators who use the console.

Barrier or risk: The refusal to machine-translate is right, and the note is honest while an interpretation is pending. But pending is the only state the design has. After the interpreter is booked and has interpreted the video, a blind operator handling a signed video, or a Deaf operator handling a spoken video or voice note, still gets the file and nothing else, so they cannot work those records at all. A human interpretation is entirely consistent with the project's rule; the system just has no place to put it.

Fix proposed: Add a long-text field on Barrier_Report__c (for example Human_Interpretation__c, help text 'Written by the named human interpreter. Never generated.') and a companion Interpreted_By__c, editable from the record. Have media() return it, and in curbCutMediaViewer show it under the video in place of the 'no captions' note once it is filled, with the interpreter's name and date. Render audio files with <audio controls> instead of a bare download link. Keep the note for the pending state.

Status: Open

### Phone image alt describes an SMS conversation that is not in the picture (severity 3)

Where: tests/render_devpost_description.py line 6, ALT['on-a-phone']; placed at submission/devpost/Q0-project-description.txt line 31; file submission/images/on-a-phone.png. Criterion: WCAG 1.1.1 Non-text Content.

Barrier or risk: The alt says 'The same conversation by text, on a basic phone with no internet: options in her own words, and a number to reply with.' The picture is the web ask page on a phone: Curb Cut nav, A+ and Contrast buttons, 'Tell me what is hard right now', the four steps. No conversation, no options, no number. A screen-reader judge is handed evidence sighted judges cannot see, and because it follows the Slack image, 'the same conversation' reads as the Slack one. The alt was clearly written for the SMS mock (video/mocks/sms.png), which matches it exactly.

Fix proposed: Either swap the file for video/mocks/sms.png (three phone screens: she texts CURB CUT, four options with costs, the draft, 'yes') and keep the alt, or keep the file and write what is shown: 'The ask page on a phone: the same page, not a cut-down one, with the Bigger text and Contrast buttons and the heading Tell me what is hard right now.'

Status: Fixed 7 Sep: the alt text describes the picture.

### Films are not marked as captioned, no transcript is offered, and the committed captions disagree with the final narration (severity 3)

Where: Q0 line 53; submission/JUDGE-TEST-GUIDE.md lines 12-13; README.md line 12; submission/curb-cut-demo.srt (22 cues, 16:38) versus scratchpad video/script.py (22:40) and the two 12-cue scratchpad SRTs. Criterion: WCAG 1.2.2 Captions (Prerecorded); 1.2.1 / 1.2.3 media alternative.

Barrier or risk: A Deaf or hard-of-hearing judge has no way to know before clicking that either film has captions, and no transcript exists to read instead. YouTube does carry an uploaded English track (verified from the watch page), but the three-minute cut is on Google Drive, which shows captions only if a track was added under Manage caption tracks, and that cannot be checked from outside. The committed SRT and VIDEO-NARRATION.md differ from the scene table that built the final film on 5 of 22 lines: cue 2 reads 'One in four isn't a number on a slide. It's your sister...' where the narration now says 'One in four adults has a disability. About three in a hundred have told their employer...'; cues 16, 20, 21 and 22 differ too. If that file is the one on YouTube, captions contradict the audio. The scratchpad's curb-cut-demo.srt is the 2:49 cut, while the repo file of the same name is the 4:59 film, an easy way to upload the wrong track.

Fix proposed: Play both films with captions on and check every cue against the audio; upload the 12-cue SRT to the Drive file (Manage caption tracks) or host the short cut on YouTube as well; regenerate submission/curb-cut-demo.srt and VIDEO-NARRATION.md from the final script.py and rename the short cut's file curb-cut-3min.srt everywhere; then next to each film link in all three documents write '(captioned; transcript)' with a link to a transcript page.

Status: Open

### Forced-colours mode (Windows High Contrast) erases the only visual state on the tally, the progress rail and the current-page marker (severity 2)

Where: CurbCutShell.component lines 344 (.dots span.on), 445-448 (.rail li[data-state]), 133 (.nav a[aria-current=page] uses box-shadow); rendered on / and /ask. Evidence: the developer's own forced-colours captures in the scratchpad (home320-forced-tally.png shows 100 identical hollow squares; ask320-forced-form.png shows four identical rail pills with no filled numeral).. Criterion: 1.4.1 Use of Color (and 1.4.11 Non-text Contrast); the CSS comment says the split 'survives greyscale', which is true, but forced-colours strips background fills, border colours and box-shadows, so filled vs hollow and filled numeral vs hollow numeral become identical..

Barrier or risk: A sighted person using Windows High Contrast sees the 61-of-100 graphic as 100 empty squares with a key whose two swatches look the same, and on /ask cannot see which of the four steps they are on (that state is only in screen-reader text). The current page in the nav is marked only by a slightly heavier weight once the inset box-shadow underline is dropped.

Fix proposed: Add an @media (forced-colors: active) block: set forced-color-adjust:none on .dots span.on and .tally-key i.on with background:CanvasText; give .rail li[data-state=now] .n background:Highlight and color:HighlightText (or add a glyph via ::before, e.g. content:"\25CF" / "" for done and now); and replace the nav's box-shadow underline with border-bottom or text-decoration, which forced-colours keeps.

Status: Fixed 7 Sep: a forced-colors block keeps the tally squares, the current rail step and the current nav link visible.

### The busy-state focus hand-off on /ask targets a display:none element, so keyboard focus drops to body; the standing form hands focus to the wrong status line (severity 2)

Where: ask.page function busy() lines 244-249 (status.focus()) called before say() at lines 339, 538 and before saySt() at 456, 502, 514; CurbCutShell.component line 256 (.statusLine:empty { display:none }). Verified live: on load getComputedStyle(#status).display is 'none' and calling status.focus() leaves document.activeElement on BODY.. Criterion: 2.4.3 Focus Order (focus must land somewhere meaningful during and after the action; the code's stated intent is defeated by the ordering) with 4.1.3 Status Messages still met because the live region does announce..

Barrier or risk: On the most common first path, typing your own words and pressing 'Show me what I could ask for', the button is disabled and focus falls to the top of the document for the whole request (up to the 30-second timeout); a screen-reader or keyboard user who presses Tab or an arrow key during the wait is back at the skip link. 'I'd rather talk to a person' as a first action does the same. For 'Remember this', busy() focuses the main #status near the top of the page rather than #standingStatus: if #status is empty nothing happens, and if it holds the earlier options message, focus jumps from the bottom of the page to the top and re-reads stale text ('Here is what other people have asked for...') while a standing preference is being saved.

Fix proposed: Call say() / saySt() before busy() so the target is rendered, pass the relevant status element into busy(on, btn, statusEl), and replace .statusLine:empty { display:none } with a rule that keeps the element in layout (for example min-height with visibility handled by content), or simply keep the region rendered and empty.

Status: Fixed 7 Sep: the status line is written before the button is disabled, so focus lands on a rendered element.

### /docs scrolls horizontally at 320px because raw URLs are used as link text with no overflow-wrap (severity 2)

Where: docs.page: <a> elements whose text is the full URL (Google Drive link measured at 611px right edge, Lightning console links at 512px and 478px, Slack invite at 427px, source lists in the Evidence section) and <code> spans in prose (up to 363px); the shell defines overflow-wrap only for .sms (CurbCutShell.component line 513). Verified live at 320px: document.documentElement.scrollWidth 616 vs clientWidth 320. The other six pages measure 320/320.. Criterion: 1.4.10 Reflow (content must present without two-dimensional scrolling at 320 CSS px; data tables are exempt and are already wrapped in .tbl overflow-x:auto, but these are paragraphs and list items)..

Barrier or risk: A low-vision reader at 400% zoom, or anyone on a narrow phone, has to scroll sideways on every line of the README, judge guide and evidence sections, and the 'Bigger text' control makes it worse. This is the page that tells judges how to verify accessibility.

Fix proposed: Add .docs a, .docs code, .docs p, .docs li { overflow-wrap: anywhere; } and, better, replace URL-as-text links with descriptive text ('the three-minute cut on Google Drive', 'the Slack workspace invite') so screen readers are not read a 90-character string either.

Status: Fixed 7 Sep: overflow-wrap on links, code and text in the docs page.

### /docs 'Source:' lines use an undefined --mute token and fall to 3.0:1 in the dark theme (severity 2)

Where: docs.page line 18: .docs .mute { color: var(--mute, #5B6167); } ; --mute is defined nowhere in the shell, so the hard-coded fallback applies. Live in dark mode the computed colour is rgb(91,97,103) on body background rgb(15,18,20) = 3.0:1. In light mode it is 5.55:1 and passes. The site's own Contrast button does not help because it only overrides --ink-soft, --ink-mute and --line.. Criterion: 1.4.3 Contrast (Minimum): normal-size text needs 4.5:1..

Barrier or risk: The eight lines that tell a reader what each document is and which repository file it came from are barely legible for anyone whose OS is set to dark mode, including the people who chose dark mode for low-vision or light-sensitivity reasons.

Fix proposed: Change the rule to .docs .mute { color: var(--ink-mute); } so it follows both themes (6.15:1 in dark) and responds to the site's Contrast control.

Status: Fixed 7 Sep: the docs page uses the theme token, 6.15:1 in dark mode.

### Five sections are labelled by a heading that belongs to a different section, producing duplicate and wrong region names (severity 2)

Where: CurbCutHome.page line 31 ('In one sentence' box labelled by sec-sixty-one-employers-in-2, whose h2 is in the next section at line 43) and line 114 (the thesis section labelled by sec-reach-it-however-you-2, the h2 of the doors section at line 125); why.page line 100 (thesis section labelled by sec-every-rule-so-far-2, whose h2 is at line 114); privacy.page line 17 ('The short version' labelled by sec-what-does-not-exist-2, h2 at 34); terms.page line 17 ('The short version' labelled by sec-the-programme-2, h2 at 35). messaging.page does this correctly with aria-label.. Criterion: 1.3.1 Info and Relationships and 2.4.6 Headings and Labels: a region's accessible name must describe that region..

Barrier or risk: In a screen reader's landmarks or regions list the home page shows 'Sixty-one employers in a hundred paid nothing' twice and 'Reach it however you're able to' twice; choosing the first of each lands on the plain-language summary or the thesis, not the content named. The plain-language box, which exists precisely for people who find the long text hard, is the one that is mis-named on three pages.

Fix proposed: Give each of those sections its own name: aria-label="In one sentence" / aria-label="The short version" / aria-label="The thesis" (as messaging.page already does), or add a visually-hidden h2 inside them with class="vh" and point aria-labelledby at that.

Status: Fixed 7 Sep: the two sections have their own names.

### The text-size control's visible label is not contained in its accessible name; the chosen option button has the same problem after it is pressed (severity 2)

Where: CurbCutShell.component applySize(): visible text 'Bigger text' / 'Biggest text' / 'Normal text' while aria-label is set to 'Text size: normal. Press to change.' etc. (verified live: textContent 'Bigger text', aria-label 'Text size: normal. Press to change.'). ask.page line 299 sets aria-label 'Ask for this one: <title>' and after a press the visible text becomes 'Chosen' (line ~305) while the name is unchanged. The Contrast button passes because 'Contrast' appears in its name.. Criterion: 2.5.3 Label in Name: the visible text label must be part of the accessible name..

Barrier or risk: A voice-control user (Dragon, Voice Control) who says 'click Bigger text' gets no match and has to fall back to numbered overlays; a screen-reader user hears 'Text size: normal' for a button that visibly reads 'Bigger text', which is confusing rather than blocking. The person most likely to use this control is the one who needs it most.

Fix proposed: Keep the visible words at the start of the name: aria-label = label + '. Text size is ' + state (for example 'Bigger text. Text size is normal.'), or make the visible text itself carry the state ('Text size: normal') and drop aria-label. For the pick button, when pressed set aria-label to 'Chosen: ' + title.

Status: Fixed 7 Sep: the visible words now start the accessible name.

### Lists styled with list-style:none carry no role="list", so WebKit/VoiceOver flattens them (severity 2)

Where: CurbCutShell.component lines 212 (.kwlist), 382 (.steps), 393 (.negs), 433 (.rail), 454 (.starters); verified live on /ask that .rail and .starters compute list-style-type none with no role, and on /terms .kwlist likewise. None of these sit inside <nav>. The screen-reader walk was generated from Chromium's tree, which does not drop the role, so it could not catch this.. Criterion: 1.3.1 Info and Relationships (list structure must be programmatically determinable); WebKit removes list semantics from lists with no markers unless role="list" is present..

Barrier or risk: In Safari with VoiceOver (the default on every iPhone, the most likely device for the 'no work email, no desk' worker the site is built for) the four-step 'Where you are' rail, the six starter buttons, the five steps on the home page, the six 'what can't happen' items and the control-word lists are announced as loose text with no 'list, 4 items' framing, no item position, and no list navigation.

Fix proposed: Add role="list" to ol.rail, ul.starters, ol.steps, ul.negs and ul.kwlist (and role="listitem" is not needed on the li elements). This is harmless in Chromium and Firefox.

Status: Fixed 7 Sep: role="list" on every list styled without markers.

### The chosen option's selected state reuses the focus ring, so two identical rings are on screen at once (severity 2)

Where: ask.page line 29: .btn.pick[aria-pressed="true"] { outline:3px solid var(--focus); outline-offset:2px; } , same colour and width as the global button:focus-visible rule; the click handler then moves focus to #draftBtn (line ~305), which draws its own identical ring.. Criterion: 2.4.7 Focus Visible (the keyboard focus indicator must be identifiable, which it is not when the same indicator also means 'selected'); 1.4.1 is met because the text changes to 'Chosen'..

Barrier or risk: A sighted keyboard user who has just chosen an option sees a blue ring on 'Chosen' and a blue ring on 'Help me ask for this' and cannot tell which one Enter will activate; on a page where one of the buttons eventually sends something to an employer, that ambiguity matters.

Fix proposed: Style the pressed state with a fill rather than an outline: background var(--deep-bg), border-color var(--deep), and a check glyph via ::before with content:"\2713" / "" so it also survives forced colours; leave the outline for focus only.

Status: Fixed 7 Sep: the chosen option is shown with a fill and a check mark, not the focus ring.

### Choosing a photo or video sends it immediately, with no confirmation and no way to cancel (severity 2)

Where: ask.page lines 433-438: the change handlers on #photoFile and #videoFile call sendFile(), which reads the file and calls CurbCutWeb.sendMedia straight away; the only pre-checks are file presence and the 4 MB limit.. Criterion: 3.3.4 Error Prevention (Legal, Financial, Data): a submission of user-controllable data should be reversible, checked, or confirmable. 3.2.2 On Input is technically met because the label says 'Send a photo'..

Barrier or risk: Someone with a tremor, low vision or a cognitive disability who taps the wrong item in the file picker (a personal photo, a video of themselves signing at home) has it delivered to a human desk with no undo, on a site whose central promise is that nothing leaves without a clear yes. Screen-reader users get no chance to hear the chosen file name before it goes.

Fix proposed: After selection, show the file name and size with two buttons, 'Send this photo' and 'Choose a different one', and only call sendMedia from the first; announce the chosen file name in #mediaStatus.

Status: Open

### Two assistant text colours fall under 4.5:1, and the console's colours were never in the contrast suite (severity 2)

Where: curbCutAssist.css lines 92-95 `.panel-title` uses --ink-mute #6b7174 at .68rem (about 10.9px, bold, so not large text): 4.38:1 on the result wash #eaf3f0 and 4.32:1 on the refused wash #fbeceb. curbCutAssist.css line 59 `.step.is-done { opacity: .62 }` fades the whole step: `.why` (#4a4e4f) becomes effectively #8f9192 on white, 3.17:1 at .84rem. docs/A11Y-SA11Y-REPORT.md lines 55-58 says contrast is 'measured elsewhere ... 28 checks and passes', but tests/contrast_audit.py line 16 reads only CurbCutShell.component (the public site); none of the five LWC stylesheets are measured, and axe reports color-contrast as incomplete for all 12 states.. Criterion: WCAG 1.4.3 Contrast (Minimum).

Barrier or risk: A low-vision operator cannot comfortably read the 'WHAT YOU COULD OFFER' / 'REFUSED' / 'ANSWER' eyebrow that tells them what kind of response they are looking at, or the explanation under a step that has been completed. The report's coverage claim would lead a reviewer to believe these had been checked.

Fix proposed: Set .panel-title to --ink-soft #4a4e4f (7.34:1 and above on both washes). Mark done steps without opacity: keep the strike-through and change .why to #5e6568 (5.94:1) and the number circle to a check mark. Extend tests/contrast_audit.py to parse the five LWC CSS files and their :host tokens, including blended opacity states, and correct the sentence in the report.

Status: Open

### Reading order on the record pages contradicts the design's own priority: the person's words come after every field and related list (severity 2)

Where: Curb_Cut_Handoff_Record.flexipage-meta.xml lines 30-73 place curbCutHandoffBrief, curbCutAssist, the guide and curbCutEmergency in the `sidebar` region; Curb_Cut_Barrier_Record.flexipage-meta.xml lines 30-49 place curbCutMediaViewer in `sidebar`. Both use flexipage:recordHomeTemplateDesktop (Header and Right Sidebar), in which the sidebar region follows the main region (force:detailPanel then force:relatedListContainer) in source order.. Criterion: WCAG 1.3.2 Meaningful Sequence; 2.4.3 Focus Order.

Barrier or risk: curbCutHandoffBrief.js lines 14-18 says what matters first is what the person already said, then how to reach them. A sighted operator gets that at a glance on the right. A screen-reader or keyboard operator reads the highlights panel, every detail field and every related list first, and only then reaches 'Never by telephone', the person's words, 'I am picking this up' and the photo or video. The operator most likely to break the channel rule is the one who meets the raw fields before the brief.

Fix proposed: Move curbCutHandoffBrief to the top of the `main` region above force:detailPanel on the handoff page, and curbCutMediaViewer to the top of `main` on the barrier page (or switch both pages to a left-sidebar template). Keep the guide, the assistant and the emergency panel in the sidebar, where 'deliberately unlike everything else' still holds.

Status: Open

### Triage tiles don't say, by name or by look, that they open a queue (severity 2)

Where: curbCutTriage.html lines 16-41: each <button class="card"> is named only by its content ('4 waiting for a person Longest wait 1 day. Start here.'); curbCutTriage.js lines 66-77 navigate to a list view; curbCutTriage.css lines 13-19 give the tile a #d8dde1 border (1.37:1), no link styling and only a hover tint.. Criterion: WCAG 2.4.4 Link Purpose (In Context); 4.1.2 Name, Role, Value; 1.4.11 for the affordance.

Barrier or risk: A screen-reader operator hears a statistic, not something that goes anywhere, and the button role does not say it navigates; a sighted keyboard user sees four stat tiles and has no reason to Tab to them. Because they are buttons rather than links, 'open in a new tab' and the screen reader's links list don't work, and the counts at the top of the page, the whole point of the component, are the least discoverable way into the queues.

Fix proposed: Render each tile as an <a href> built with this[NavigationMixin.GenerateUrl] (still handling click for in-app navigation), add 'Open the queue' as visible text or an slds-assistive-text span at the end of the name, and give the tile a visible affordance: an underlined label or a trailing arrow and a border of at least 3:1 (#8e949a, the existing top stripe, measures 3.0:1 on white; #6b7174 is safer).

Status: Open

### The emergency disclosure loses its name when open: 'Close this' says nothing about what 'this' is (severity 2)

Where: curbCutEmergency.js line 83 `get toggleLabel() { return this.open ? 'Close this' : 'Emergency escalation'; }`, rendered at curbCutEmergency.html line 3.. Criterion: WCAG 4.1.2 Name, Role, Value; 2.4.6 Headings and Labels.

Barrier or risk: Once the panel is open, the only control that closes it is announced as 'Close this, button, expanded'. A screen-reader operator arriving from elsewhere on a long record page (or after losing focus, see the first finding) cannot tell that this is the emergency escalation, nor that the state is already conveyed by aria-expanded. In a panel that exists for the one moment the no-telephone promise is broken, the control should keep its name.

Fix proposed: Keep the accessible name stable ('Emergency escalation') and let aria-expanded carry open/closed; if a visible 'Close' is wanted, use 'Close emergency escalation'. Add aria-controls pointing at the .box.

Status: Open

### Photos are described by their file name, and the video has no name at all (severity 2)

Where: curbCutMediaViewer.html line 26 `<img src={m.url} alt={m.title}>`; `title` is ContentVersion.Title (CurbCutConsole.cls line 162), which the web upload sets to the device file name (ask.page line 420 passes `file.name`; CurbCutMedia.cls lines 135-136 fall back to the word 'Photo'). The same title is printed again in the .meta line at line 36. Line 29 <video> has aria-describedby but no accessible name; line 37 'Download the original' is identical for every item.. Criterion: WCAG 1.1.1 Non-text Content; 2.4.4 Link Purpose (In Context).

Barrier or risk: A screen-reader operator hears 'IMG_4021.jpeg', then 'IMG_4021.jpeg, 2 September, 240 KB', and learns nothing they could act on: not that it is a photo the person sent instead of typing, nor when. On the video they hear 'video' and the controls. The project's rule against machine description is right and nothing here asks for one; the alternative should state what the thing is, honestly, without describing what is in it.

Fix proposed: Build the alt from kind and time, not the file name: 'Photo the person sent on 2 September, in place of words. Not described by the system.' Give the video `aria-label="Signed or spoken video the person sent, {arrivedAt}"` alongside the existing aria-describedby. Make the link 'Download the original {kind}'. Keep the file name in the .meta line only.

Status: Open

### Console image alt leaves out the question and the refusal, and 'her' has no referent (severity 2)

Where: tests/render_devpost_description.py line 6, ALT['console-refusal']; Q0 line 19; submission/images/console-refusal.png. Criterion: WCAG 1.1.1 Non-text Content.

Barrier or risk: The picture's meaning is its words: 'What is this person's diagnosis?' answered with 'No. And not because of a permission setting. There is no field for a diagnosis, condition, disability type, medical note, severity or prognosis anywhere in this system', plus the proof lines '0 matches across 61 fields in 9 objects' and 'A build fails if anyone adds one'. The alt carries none of it, and 'what is wrong with her' names a person the description never introduces (the request shown is anonymous). A screen-reader judge gets the paragraph's paraphrase but not the evidence.

Fix proposed: Alt: 'Console mock-up. Asked What is this person's diagnosis?, the assistant answers: No. And not because of a permission setting. There is no field for a diagnosis, condition, disability type, medical note, severity or prognosis anywhere in this system. Beside it the request shows only the person's own words, I keep missing things in meetings, reachable by text, anonymous. Small print: 0 matches across 61 fields in 9 objects; a build fails if anyone adds one.' Or quote the refusal as text under the image, as the judge guide does at lines 171-173.

Status: Fixed 7 Sep: the alt text carries the question and the refusal.

### The one-in-four card is an image of text whose alt drops a paragraph and the sources line, and the sources line is under 4.5:1 (severity 2)

Where: tests/render_devpost_description.py line 6, ALT['one-in-four']; Q0 line 3; submission/images/one-in-four.png (source submission/images/src/one-in-four.html), sources line measured at about 3.7:1 (ink 116,127,122 on 243,241,236). Criterion: WCAG 1.4.5 Images of Text; 1.1.1; 1.4.3 Contrast (Minimum).

Barrier or risk: The card is nothing but text. Sighted judges read 'Curb Cut was built for them: a way to find out what could help, and to ask for it in your own words, without saying why' and 'Sources: CDC, Disability Impacts All of Us; Disability:IN Disability Equality Index 2025, 655 employers'; the alt compresses the first and omits the second, so the attribution never reaches a screen-reader judge. Anyone who enlarges text, reflows, or uses a high-contrast mode cannot do so on a PNG, and the grey sources line is below the 4.5:1 small-text minimum.

Fix proposed: Put the card's words in the description as text (a blockquote under PROBLEM TO SOLVE) and drop the image; or, if the image stays, make the alt the full text including the sources line and darken that line to at least 4.5:1 (about #5c6660 on that ground).

Status: Fixed 7 Sep: the alt text carries the card's words and sources.

### Low-contrast proof lines inside the console mock (severity 2)

Where: submission/images/console-refusal.png: 'HH-00042 · WAITING 4 MINUTES' about 2.5:1; '0 MATCHES ACROSS 61 FIELDS IN 9 OBJECTS / A BUILD FAILS IF ANYONE ADDS ONE' about 2.8:1; 'THEIR WORDS · NOT A SUMMARY' about 3.2:1 (pixel-sampled with ffmpeg). Criterion: WCAG 1.4.3 Contrast (Minimum), which applies to text in images.

Barrier or risk: The lines that carry the proof (the field count and the build check) are the least readable things in the picture. At Devpost's rendered width the letters are roughly 9 px, which makes the grey harder still for a low-vision judge.

Fix proposed: Regenerate the mock with those labels at 4.5:1 or better (a grey like #5f6663 on #fafaf7 gives about 5.5:1), and carry the two proof lines in the alt or in the paragraph above.

Status: Open

### Emoji prefixes are announced on every heading, every door, and four paragraphs (severity 2)

Where: tests/render_devpost_description.py lines 7-8 (ICON, DOORS) and the inline prefixes in render(): rendered h3s '🧱 Problem to solve', '✔ What happens after you press send', '💛 What we got wrong', '⚠ What isn't done', '🤍 Who this is for'; list items '🌐 Web', '📱 Text', '📞 Voice', '✉️ Email', '💬 Slack', '🤝 Any assistant'; paragraphs starting 🚪, 🔒, ▶, ✿, 📖. Criterion: WCAG 1.1.1 Non-text Content (decorative content must be ignorable); 2.4.6 Headings and Labels.

Barrier or risk: A judge moving by headings hears 'brick, Problem to solve', 'yellow heart, What we got wrong', 'white heart, Who this is for', 'warning sign, What isn't done'; each door begins 'globe with meridians', 'mobile phone', 'telephone receiver'. '✿' (black florette) and '▶' are read inconsistently across screen readers. Devpost strips aria-hidden, so there is no way to mark them decorative.

Fix proposed: Delete the emoji from ICON, DOORS and the inline prefixes. Where a marker carries meaning, say it in words ('Not done yet:' instead of ⚠).

Status: Partly fixed 7 Sep: the emoji before paragraphs are gone; headings and the six doors keep one each as visual signposts.

### Raw URLs used as link text, and two URLs not linked at all (severity 2)

Where: Q0 line 26 (Slack invite, emitted as plain escaped text by the renderer), line 35 (console address, plain text), lines 55 and 57 (link text is the URL); JUDGE-TEST-GUIDE.md lines 8, 12-13, 34, 113, 164, 166; README.md lines 12 and 30. Criterion: WCAG 2.4.4 Link Purpose (In Context); 2.4.9 as best practice.

Barrier or risk: A screen reader reads the Slack invite letter by letter ('join dot slack dot com slash t slash havihidigital slash shared underscore invite slash z t dash 4 9 3 m f 6 b t t...') with nothing to activate, and a judge with a motor impairment must select and copy 70 characters. Where URLs are links, the links list (VoiceOver rotor, JAWS Insert+F7) shows 'orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut/ask' and '.../curbcut/docs' instead of what each does.

Fix proposed: Link every URL and use words as the text: 'join the Slack workspace', 'the desk's console (org login needed)', 'Try the ask page, no login', 'the evidence page', 'the code on GitHub, MIT', 'the three-minute cut (captioned)', 'the full film, 4:59 (captioned)'. In markdown: [join the Slack workspace](https://join.slack.com/...).

Status: Fixed 7 Sep: every link in the description has words for its text.

### Captions are one block per scene, up to 48 words shown for 22 seconds, with no music cue (severity 2)

Where: scratchpad video/curb-cut-demo.srt and curb-cut-3min.srt (identical): cue 1 246 characters for 21.8 s, cue 2 235 for 20.1 s, cue 7 226 for 20.1 s, cue 10 165 for 14.9 s; repo submission/curb-cut-demo.srt cue 1 the same; produced by video/captions.py, one cue per scene line; cue 5 ends at 1:20.2 while the voice runs to about 1:21.7. Criterion: WCAG 1.2.2 Captions (Prerecorded); caption practice (DCMP/BBC: at most 2 lines, about 42 characters a line, about 7 s a cue).

Barrier or risk: A 246-character cue renders as five or six lines across the lower third, covering the screen recording it describes, and stays static while four sentences are spoken, so a Deaf viewer cannot tell which sentence matches what is happening. The music bed is never signalled, so a Deaf viewer does not know there is music, and one caption disappears about 1.5 s before its voice finishes.

Fix proposed: In captions.py split each line at sentence or clause boundaries into cues of at most two lines and 7 s, timed to the per-line voice files (voice/NN.wav) rather than words/140; add '[soft music]' on the first cue and '[music fades]' at the end; never end a cue before its voice does.

Status: Open

### No audio description; the narration never says what is typed or drafted on screen, and two cards in the full film are silent (severity 2)

Where: 3-min cut scene 0 (rec/flow.mp4, 0:00-0:27): the typed sentence and the options that appear are not named; scene 8 (frames/agent-yes_gate-3.png, 1:10-1:22): 'I am asking to have captions turned on in all my meetings' and the date are not spoken; scene 7 (cards/c06.png): the card's 'two separate locks' text is not spoken; full film cards c04 and c08 have empty narration lines in script.py ('Silence. Let them read it.'). Criterion: WCAG 1.2.5 Audio Description (Prerecorded); 1.2.3.

Barrier or risk: A blind judge hears 'She hedges, and it waits. She says yes, and only then does it move' but not what she typed, what the agent drafted, or the date she was given, which are the proof the film exists to show. The silent cards in the full film are six seconds of music for them.

Fix proposed: Publish a described transcript (each narration line plus one line saying what is on screen, e.g. 'She types: The office lights give me a headache by lunch. Three lighting options appear, each with a usual cost.') and link it beside both film links; where the hold allows, let the narration in script.py name the on-screen words for scenes 0, 8 and 9 and give the two silent cards a spoken line.

Status: Open

### Text-heavy frames are held too briefly and rendered too small to read (severity 2)

Where: cards/c06.png at 1:01-1:10 of the 3-min cut: 48 words on the card plus a 13-word caption in a 9 s hold (about 320 words a minute); video/mocks/sms.png at 1:28-1:49: three phones of roughly 300 words at about 13 px on a 1920-px frame (about 6 px in a 960-px player); the footer paragraph in rec/flow.mp4 at 0:10 at about 14 px. Criterion: WCAG 2.2.1 Timing Adjustable (content gone before it can be read); 1.4.4 Resize Text (text in video cannot be enlarged).

Barrier or risk: A viewer with dyslexia, low vision or a cognitive disability cannot read the gate card before it fades, and the SMS mock's message text is illegible at any normal player size, so 'real options come back with what they usually cost' exists only in the narration.

Fix proposed: Cut each card to the sentence that is narrated (or hold text cards at least 1 s per 3 words), show one phone at a time at 28 px or larger, and put the full card and phone text in the transcript.

Status: Open

### README verification list is an ASCII table inside a code block (severity 2)

Where: README.md lines 83-96. Criterion: WCAG 1.3.1 Info and Relationships.

Barrier or risk: Count, suite, command and note are related only by spacing. A screen reader reads one run ('127 Apex tests sf apex run test -o curbcut -l RunLocalTests 512 structural invariants...') with no column headers, and the block cannot reflow for large text or narrow screens.

Fix proposed: Make it a markdown table like the ones at lines 14 and 28, with headers Count | Suite | Command | Note.

Status: Open

### Arrow glyphs inside call-to-action links are read aloud (severity 1)

Where: CurbCutHome.page lines 18, 110, 375 and why.page line 247: <span class="arrow">&rarr;</span> inside the link text; also the literal '&rarr;' in 'Go to the ask page →' on the home page card. Live HTML renders these as &#8594; with no aria-hidden.. Criterion: 1.1.1 Non-text Content / 2.4.4 Link Purpose: decorative symbols should be hidden from assistive technology..

Barrier or risk: Screen readers append 'right arrow' or 'rightwards arrow' to 'Ask now', 'Start on this page', 'Try it' and 'Go to the ask page', which is noise on the four most important links on the site.

Fix proposed: Add aria-hidden="true" to each span.arrow, and wrap the bare &rarr; in the card link in the same span.

Status: Open

### Dark theme control borders fall just under 3:1 against raised surfaces (severity 1)

Where: CurbCutShell.component dark tokens: --line-firm #5F676A on --raised #181C1E = 2.97:1 (the comment claims 3.25:1, which is only true against --ground). Affected: the dashed file-input border inside the raised 'Send a photo' panel (.upload input[type=file], .showme background raised) and the rail numeral circles (.rail .n inside .rail li background raised).. Criterion: 1.4.11 Non-text Contrast: UI component boundaries need 3:1 against adjacent colours..

Barrier or risk: In dark mode the two file-choosers and the step numerals have edges that a low-vision user may not see as controls; the shortfall is marginal (2.97 vs 3.0) but the site advertises AAA-level care, and the file inputs are the entry point for Deaf users sending signed video.

Fix proposed: Raise the dark --line-firm to about #676F72 (3.3:1 on raised, 3.6:1 on ground), or give the file input and rail numerals a border colour token that is checked against --raised.

Status: Open

### Facts tables lose header semantics on narrow screens and two of them omit scope on row headers (severity 1)

Where: CurbCutShell.component .facts rules: @media (max-width:34rem) { .facts th, .facts td { display:block } }, used on /why, /messaging, /privacy, /terms; why.page lines 170-200 and messaging.page rows use <th> with no scope, whereas privacy.page and terms.page use scope="row".. Criterion: 1.3.1 Info and Relationships (header/data cell relationships must survive presentation changes)..

Barrier or risk: Under 34rem (most phones, and any desktop at 200% zoom with larger text) Safari and some Chromium versions drop table roles when cells are display:block, so VoiceOver reads the 'What an agent built for disabled people could do to them' table and the programme facts as unrelated paragraphs; missing scope adds ambiguity for the two-column tables on /why and /messaging in every viewport.

Fix proposed: Add scope="row" to every <th> in why.page and messaging.page, and add role="table", role="row", role="rowheader" and role="cell" to the .facts markup so the roles are explicit regardless of display; or keep display:table and let the wrapper scroll.

Status: Open

### The threat-model table in the technical design is whitespace-aligned text inside <pre> (severity 1)

Where: docs.page line 618: <pre class="tdd">Adversary                 Mitigation ... , section 10 of the Technical design, rendered as preformatted text with columns made from spaces.. Criterion: 1.3.1 Info and Relationships (tabular data must be marked up as a table)..

Barrier or risk: A screen reader reads each row as one run-on line with no way to move by column or hear which mitigation belongs to which adversary; at narrow widths pre-wrap also scrambles the alignment for sighted readers.

Fix proposed: Emit that section as a real <table> with <th scope="col">Adversary</th> and <th scope="col">Mitigation</th>, the same way the README and Evidence sections already do.

Status: Open

### Lists styled with list-style: none lose their list semantics in Safari and VoiceOver, and the assistant hides its step numbers too (severity 1)

Where: curbCutAssist.css line 43 `.steps { list-style: none }` on the <ol>, with the number span aria-hidden at curbCutAssist.html line 19; curbCutHandoffBrief.css lines 12 and 37 (.flags, .said); curbCutTriage.css line 9 (.cards).. Criterion: WCAG 1.3.1 Info and Relationships.

Barrier or risk: Safari strips the list role when list markers are removed, so VoiceOver users hear no 'list, 5 items' and no position. In the assistant the ordinal is also hidden, so 'Start at the top' and 'work down the list' (CurbCutAssist.cls lines 103-105) have no order for a VoiceOver operator.

Fix proposed: Add role="list" to those <ol> and <ul> elements. In the assistant, drop aria-hidden from the number span (or add an slds-assistive-text 'Step 1 of 5') so the order is spoken.

Status: Open

### The two most interactive components are audited only in their empty states by their own tests, and no audited state covers a result, a refusal or a raised escalation (severity 1)

Where: force-app/main/default/lwc/curbCutAssist/__tests__/curbCutAssist.a11y.test.js (no wire mock, so `ready` is false and only the header renders); curbCutEmergency/__tests__ (collapsed, so only the toggle renders). jest/__tests__/a11y-audit.a11y.test.js does cover assist-with-steps and emergency-open, but its 'assist / a plan with steps and a result' state sets no result, and no state includes the assistant's result or refused panel, the emergency raised state with the dial link, or any focused or disabled control. docs/a11y-sa11y-findings.json predates the current curbCutHandoffBrief (its handoff states now pass 24 checks, not 11).. Criterion: Not a WCAG criterion; this is why findings one to four were invisible to a green suite..

Barrier or risk: Reviewers reading '131 axe checks passed, 0 WCAG violations' will assume the states an operator actually works in were audited. The live region, the disabled submit and the unmounted buttons never appeared in front of axe.

Fix proposed: Add states: assist with a result, assist refused, emergency raised (dial link shown), handoff after pick-up. Add a focus-management assertion after each press (`expect(document.activeElement)` is supported in jsdom). Regenerate docs/a11y-sa11y-findings.json from the current build and update the counts in the report.

Status: Open

### The opening line and the numbers paragraph are the two hardest things a judge reads (severity 1)

Where: Q0 line 1 (Flesch-Kincaid grade 10.6: 'a workplace accommodation system whose principal is the worker... a deterministic safety layer'); line 39 (grade 17.4: one 40-word sentence listing six figures); line 21 ('A deterministic layer decides what may be true... holds the consent gate'); the rest of the description sits at grade 7.2. Criterion: WCAG 3.1.5 Reading Level (AAA; cited because plain language is in the brief).

Barrier or risk: 'Principal' reads as 'main' to most people; 'deterministic layer', 'consent gate' and 'structural invariants' are engineers' words in the first sentence a judge, or a worker, hears.

Fix proposed: Line 1: 'Curb Cut works for the worker, not the employer. An Agentforce agent talks; plain code decides what may be stored or sent; it runs on six channels; and a console gives the person answering somewhere to stand.' Line 39: break into a short list, one figure per line, and say '512 checks on the code's structure'.

Status: Open

### Image placement breaks the reading order (severity 1)

Where: Q0 line 3 ([image: one-in-four] sits between the intro line and the PROBLEM TO SOLVE heading); lines 29-31 (two images back to back with no text between). Criterion: WCAG 1.3.2 Meaningful Sequence; 2.4.6 Headings and Labels.

Barrier or risk: A judge moving heading to heading lands on 'Problem to solve' after the statistics card has already gone by, under 'Project Name'. The two consecutive images make the phone alt's 'The same conversation' attach to the Slack picture.

Fix proposed: Move the one-in-four image under the PROBLEM TO SOLVE heading, and put a sentence between the Slack and phone images, or move the phone image up under the 'Text CURB CUT' door it illustrates.

Status: Open

### Judge guide names buttons by colour, has a stray asterisk, and an alt that points forward (severity 1)

Where: submission/JUDGE-TEST-GUIDE.md line 35 ('Press one of the grey buttons'); line 47 (unpaired '*' at the end of the paragraph renders as a literal star); line 122 (alt 'The same exchange as a screenshot...' precedes the exchange, lines 124-149). Criterion: WCAG 1.3.3 Sensory Characteristics; 1.1.1 Non-text Content.

Barrier or risk: A blind judge cannot tell which buttons are grey (the example label saves it); the stray asterisk is read aloud as 'star'; 'the same exchange' has nothing to refer to yet.

Fix proposed: 'Press one of the example buttons under the box, for example My back hurts by the afternoon'; delete the trailing '*' on line 47; alt 'Screenshot of the Slack client showing the exchange transcribed below'.

Status: Open

### Ask-page screenshots show a stale 'A+' label and an alt that mentions a box the crop does not include (severity 1)

Where: submission/images/ask-no-login.png and on-a-phone.png (button reads 'A+'); JUDGE-TEST-GUIDE.md line 49 says 'Bigger text'; the live /curbcut/ask renders <button id="tsize">Bigger text</button>; ALT['ask-no-login'] says 'one box' but the crop ends above the text box. Criterion: WCAG 1.1.1 Non-text Content; 2.5.3 Label in Name (in spirit: judges should see the label they are told to press).

Barrier or risk: A judge comparing the screenshots with the guide looks for an 'A+' button that no longer exists; a screen-reader judge is told there is 'one box' that is not in the picture.

Fix proposed: Re-capture both screenshots from the live page, cropping to include the text box and the example buttons, and change the alt to describe what is shown ('The ask page before anything is typed: the heading Tell me what is hard right now, four steps, a banner saying Nothing has been sent to anyone, and the box with six example sentences above it').

Status: Open

## Residual risk

Everything marked Open is real work that is not done. The ones we would do first are the highest severity items above. Everything marked Fixed was deployed and re-audited the same day, and the repository history shows each change.
