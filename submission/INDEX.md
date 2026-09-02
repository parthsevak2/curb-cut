# Curb Cut — asset index

Drive folder (shared to parth@havihi.digital as writer):
https://drive.google.com/drive/folders/1V52WDKnujvybWffCGhWPM9Rs2Vxs4gDE

**Drive note.** The connector can create folders but not files — every file
creation returned "The caller does not have permission", tested four ways
(plain text, Google Doc, unconverted upload, and at root). The five folders
below exist and are shared; the files are in `submission/` in the repo and were
delivered to you directly. Drag each into its folder, or re-authorise the Drive
connector with file-creation scope and I will upload them myself.

| Drive folder | What belongs in it |
|---|---|
| 01 — Submission | `DEVPOST-ANSWERS.md`, `VIDEO-SCRIPT.md`, `RUN-REQUIRED-TOOLS.md` |
| 02 — Technical Design | `TECHNICAL-DESIGN.md` |
| 03 — Deck and Visuals | `Curb-Cut.pptx` |
| 04 — Evidence and Test Output | audit output, adversarial run scores |

---

## Devpost — Project assets, paste these

| Slot | Link |
|---|---|
| **Code** * | `https://github.com/parthsevak2/curb-cut` — flip public first |
| **Documentation** * | https://claude.ai/code/artifact/80443669-bf1c-4365-883d-b0d1238b474a |
| **Video** * | your YouTube/Vimeo link |
| Design | https://claude.ai/code/artifact/a9157ad2-d803-46ab-ba5e-0ef3f0d13ef5 |
| Presentation slides | upload `Curb-Cut.pptx` to Drive, paste its link |
| Prototype | https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut |

---

## Everything, with what each one is for

**Live product**
- Public site — https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut
  Anonymous, no login. `/ask` is the page somebody uses on a hard day.
- Org `00DgK00000YIJ5SUAX` · agents `Curb_Cut` v7 and `Curb_Cut_Desk` v5, both Active.

**Published pages**
- **Evidence** — https://claude.ai/code/artifact/13947fab-1a4d-4586-a406-8e9ab39b5c22
  Every figure read from the deployed org, including what is still wrong.
- **Walkthrough** — https://claude.ai/code/artifact/80443669-bf1c-4365-883d-b0d1238b474a
  Eight people, eight channels, every command run before it went on the page.
- **Diagrams** — https://claude.ai/code/artifact/a9157ad2-d803-46ab-ba5e-0ef3f0d13ef5
  Five mechanisms: the router, the absence map, the claim code, the yes-gate,
  the inference boundary.
- **Privacy** — https://claude.ai/code/artifact/7d520923-e7bb-490e-b158-063404c053bd
- **Terms** — https://claude.ai/code/artifact/742cd290-a320-45a5-bed6-bde0d256da9b

**Documents**
- `TECHNICAL-DESIGN.md` — 14 sections: the constraint that generated the
  architecture, the absence map, the channel router, claim codes, why there is
  no RAG, redaction and its limit, the consent gate, observability, agent
  design, threat model, 8 ADRs, environmental design, scale, and how to verify
  every claim in it.
- `DEVPOST-ANSWERS.md` — every form field paste-ready, including the error-rate
  and environmental answers.
- `VIDEO-SCRIPT.md` — 2:57, shot by shot, three marked silences.
- `RUN-REQUIRED-TOOLS.md` — the two tools that gate the submission.
- `Curb-Cut.pptx` — 13 slides, editable, speaker notes throughout.

---

## Still needs you

1. **Run the Accessibility Expert Skill and RAI Self Check.** Mandatory. Not in
   the org, not public, not available here. Start at Devpost → Additional
   details → Support Channel & Resources. Send me the output and I will fix
   what is fixable and draft the answers.
2. **Record the video** against `VIDEO-SCRIPT.md`.
3. **Flip the repo public** and paste the link.
4. **Upload the files** into the Drive folders, or re-authorise Drive for me.
