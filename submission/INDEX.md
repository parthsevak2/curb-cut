# Curb Cut. Asset index

Drive folder (shared to parth@havihi.digital as writer):
https://drive.google.com/drive/folders/1V52WDKnujvybWffCGhWPM9Rs2Vxs4gDE

**Drive note.** Write access works now that the connector is reconnected with
read and write. Text documents are uploaded directly. Binary files, the `.pptx`
and the `.svg`s, still have to be dragged in from the chat, because the connector
converts uploads to Google types and a converted deck is not the deck.

| Drive folder | What belongs in it |
|---|---|
| 01, Submission | `DEVPOST-ANSWERS.md`, `VIDEO-SCRIPT.md`, `RUN-REQUIRED-TOOLS.md` |
| 02, Technical Design | `TECHNICAL-DESIGN.md` |
| 03, Deck and Visuals | `Curb-Cut.pptx` |
| 04. Evidence and Test Output | audit output, adversarial run scores, `A11Y-SA11Y-REPORT.md` |

---

## Devpost. Project assets, paste these

| Slot | Link |
|---|---|
| **Code** * | `https://github.com/parthsevak2/curb-cut`. Flip public first |
| **Documentation** * | https://claude.ai/code/artifact/80443669-bf1c-4365-883d-b0d1238b474a |
| **Video** * | your YouTube/Vimeo link |
| Design | https://claude.ai/code/artifact/a9157ad2-d803-46ab-ba5e-0ef3f0d13ef5 |
| Presentation slides | upload `Curb-Cut.pptx` to Drive, paste its link |
| Prototype | https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut |

---

## Everything, with what each one is for

**Live product**
- Public site, https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut
  Anonymous, no login. `/ask` is the page somebody uses on a hard day.
- Org `00DgK00000YIJ5SUAX` · agents `Curb_Cut` v7 and `Curb_Cut_Desk` v5, both Active.

**Published pages**
- **Evidence**, https://claude.ai/code/artifact/13947fab-1a4d-4586-a406-8e9ab39b5c22
  Every figure read from the deployed org, including what is still wrong.
- **Walkthrough**, https://claude.ai/code/artifact/80443669-bf1c-4365-883d-b0d1238b474a
  Eight people, eight channels, every command run before it went on the page.
- **Diagrams**, https://claude.ai/code/artifact/a9157ad2-d803-46ab-ba5e-0ef3f0d13ef5
  Five mechanisms: the router, the absence map, the claim code, the yes-gate,
  the inference boundary.
- **Privacy**, https://claude.ai/code/artifact/7d520923-e7bb-490e-b158-063404c053bd
- **Terms**, https://claude.ai/code/artifact/742cd290-a320-45a5-bed6-bde0d256da9b

**Documents**
- `TECHNICAL-DESIGN.md`, 14 sections: the constraint that generated the
  architecture, the absence map, the channel router, claim codes, why there is
  no RAG, redaction and its limit, the consent gate, observability, agent
  design, threat model, 8 ADRs, environmental design, scale, and how to verify
  every claim in it.
- `DEVPOST-ANSWERS.md`. Every form field paste-ready, including the error-rate
  and environmental answers.
- `VIDEO-SCRIPT.md`, 2:57, shot by shot, three marked silences.
- `RUN-REQUIRED-TOOLS.md`, the two tools that gate the submission. One is now
  done with a real run; one still needs a message sent.
- `Curb-Cut.pptx`, 24 slides in four segments, editable, speaker notes throughout.
- `docs/A11Y-SA11Y-REPORT.md`, the Salesforce Sa11y audit: what it passed, what
  it could not decide, and the two defects it found.

---

## Still needs you

1. **Send the message about the RAI Self Check.** `devpost/ASK-THE-ORGANISERS.txt`,
   to the Slack sandbox, the Devpost support channel, and the two named
   organisers, all at once. The accessibility half is done: Salesforce's own
   Sa11y tooling was found, installed and run, and Q1 is written around what it
   found. Q2 has a written fallback if nothing comes back.
2. **Record the video** against `VIDEO-SCRIPT.md`.
3. **Flip the repo public** and paste the link.
4. **Upload the files** into the Drive folders, or re-authorise Drive for me.
