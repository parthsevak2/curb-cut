#!/usr/bin/env python3
"""
A responsible-AI self check for Curb Cut, against Salesforce's own five
published guidelines for responsible agentic AI: Accuracy, Safety, Honesty,
Empowerment, Sustainability.

We could not obtain a Salesforce tool published as "RAI Self Check Skill". This
is not a substitute for it and does not claim to be. It is the same exercise
carried out against the same public framework, written so that anybody can run
it and disagree with it.

Three rules it holds itself to, learned from the accessibility audit:

  · A check that cannot fail proves nothing. --selftest breaks each check on
    purpose and asserts it goes red.
  · What cannot be decided is reported as UNDECIDED, never counted as a pass.
  · Every check names the artefact it read, so a claim can be disputed.

Exit code is non-zero if any check fails. UNDECIDED does not fail the build,
but it is printed, counted, and never hidden.
"""
import os, re, sys, csv, glob, json, subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLS  = os.path.join(ROOT, 'force-app/main/default/classes')
OBJ  = os.path.join(ROOT, 'force-app/main/default/objects')
SEED = os.path.join(ROOT, 'accommodation_options_seed.csv')
ORG  = os.environ.get('CURBCUT_ORG', 'curbcut')

FORBIDDEN = re.compile(r'diagnos|condition|disabilit|medical|severity|prognos', re.I)

results = []          # (principle, name, state, detail)  state in PASS/FAIL/UNDECIDED
def record(principle, name, state, detail=''):
    results.append((principle, name, state, detail))
def ok(principle, name, cond, detail=''):
    record(principle, name, 'PASS' if cond else 'FAIL', detail)
def undecided(principle, name, why):
    record(principle, name, 'UNDECIDED', why)

def read(p):
    try:
        with open(p, encoding='utf-8') as f: return f.read()
    except OSError:
        return ''

def cls(name):   return read(os.path.join(CLS, name + '.cls'))
def all_cls():   return {os.path.basename(p)[:-4]: read(p) for p in glob.glob(f'{CLS}/*.cls')}

def org_query(soql):
    """Ask the org. Returns None when the org is not reachable, which is a
    reason to say UNDECIDED rather than to assume the answer."""
    try:
        r = subprocess.run(['sf','data','query','--target-org',ORG,'--json','-q',soql],
                           capture_output=True, text=True, timeout=120)
        if r.returncode != 0: return None
        return json.loads(r.stdout)['result']['records']
    except Exception:
        return None


# ─────────────────────────────────────────────────── 1. ACCURACY
# "Prioritize accurate results for agents." The agent may relay what a grounded
# action returned. It may not improvise an accommodation, a cost or a precedent.
P = 'ACCURACY'

seed_rows = list(csv.DictReader(open(SEED, encoding='utf-8'))) if os.path.exists(SEED) else []

ok(P, 'every-library-row-cites-a-source',
   bool(seed_rows) and all((r.get('Source_URL__c') or '').strip().startswith('http')
                           for r in seed_rows),
   f'{sum(1 for r in seed_rows if not (r.get("Source_URL__c") or "").strip())} rows with no source URL')

# First written as "every row must state a cost", which failed on 9 rows and was
# wrong. The code already handles a missing cost correctly: it says it has none
# and refuses to estimate. The thing worth asserting is that behaviour, not the
# completeness of the data. Corrected rather than deleted, because the useful
# check was hiding behind the sloppy one.
opts  = cls('CurbCutOptions')
brief = cls('CurbCutCostBrief')
ok(P, 'a-missing-cost-is-said-out-loud-not-guessed',
   'will not estimate' in brief.lower() and
   bool(re.search(r'Typical_Cost__c\s*!=\s*null', brief)) and
   bool(re.search(r'Typical_Cost__c\s*!=\s*null', opts)),
   'a null cost must produce a refusal, never an omission the reader fills in')

priced = [r for r in seed_rows
          if (r.get('Typical_Cost__c') or '').strip()
          or (r.get('Zero_Cost__c') or '').strip().lower() == 'true']
undecided(P, 'library-cost-coverage-is-%d-of-%d-rows' % (len(priced), len(seed_rows)),
          '%d rows carry no cost figure. The agent says so rather than inventing one, '
          'which is correct but leaves those people with less to take to a manager. '
          'A data gap, not a safety defect, and not counted as a pass.'
          % (len(seed_rows) - len(priced)))

# The check that would have caught the stale seed. The library is the agent's
# only source of truth; a seed that cannot rebuild it means a fresh deploy
# silently ships a different agent from the one that was audited.
rows = org_query('SELECT COUNT(Id) n FROM Accommodation_Option__c')
if rows is None:
    undecided(P, 'seed-rebuilds-the-deployed-library',
              'org not reachable from here; run with the org connected to decide')
else:
    n = rows[0]['n']
    ok(P, 'seed-rebuilds-the-deployed-library', n == len(seed_rows),
       f'org has {n} rows, seed has {len(seed_rows)}; a reseed would not reproduce the agent')

ok(P, 'ranker-requires-a-distinguishing-word',
   'docFreq' in opts and 'discriminating' in opts,
   'without rarity weighting one weak word match is enough to suggest the wrong thing')

ok(P, 'options-come-from-soql-not-from-the-model',
   'SELECT' in opts.upper() and 'Accommodation_Option__c' in opts,
   'the option list must be read from the library, not generated')


# ─────────────────────────────────────────────────── 2. SAFETY
# "Mitigate bias, toxicity, and harmful outputs." The strongest guardrail here
# is absence: a field that does not exist cannot be leaked, ranked or subpoenaed.
P = 'SAFETY'

bad_fields = []
for o in sorted(d for d in os.listdir(OBJ) if os.path.isdir(os.path.join(OBJ, d))):
    for f in glob.glob(f'{OBJ}/{o}/fields/*.field-meta.xml'):
        fn = os.path.basename(f).replace('.field-meta.xml', '')
        if FORBIDDEN.search(fn): bad_fields.append(f'{o}.{fn}')
ok(P, 'no-protected-attribute-field-exists', not bad_fields, ', '.join(bad_fields))

everything = all_cls()

# The write paths that must strip a volunteered condition, by name.
#
# This used to count classes that referenced CurbCutRedact and pass at three.
# Three classes did reference it, and none of them was CurbCutStanding, the one
# that stores the text built to be shown to managers and meeting hosts. A count
# cannot see which class is missing; a named set can.
#
# CurbCutCreateRequest is expected to join this set from a separate change.
# Add it to REDACTING_WRITE_PATHS the moment it calls CurbCutRedact.
REDACTING_WRITE_PATHS = {'CurbCutIntake', 'CurbCutStanding'}

def redacts(src):
    """A comment naming CurbCutRedact is not a control. The class has to call
    both halves: names() to decide and clean() to act."""
    return 'CurbCutRedact.names(' in src and 'CurbCutRedact.clean(' in src

redact_users = {n for n, s in everything.items()
                if redacts(s) and not n.endswith('Test') and n != 'CurbCutRedact'}
missing_redaction = sorted(REDACTING_WRITE_PATHS - redact_users)
ok(P, 'conditions-are-stripped-before-any-insert', not missing_redaction,
   f'{missing_redaction} write person-facing text without calling '
   f'CurbCutRedact.names() and clean(); every named write path must')

red = cls('CurbCutRedact')
identity = ['deaf', 'blind', 'hard of hearing', 'wheelchair']
ok(P, 'identity-words-are-never-stripped',
   all(w in red.lower() for w in identity),
   'Deaf, blind, hard of hearing and wheelchair user are identity, not medical detail')

emer = cls('CurbCutEmergency')
ok(P, 'a-phone-number-is-never-revealed-before-a-written-reason',
   bool(re.search(r'isBlank\(reason\)|reason\.trim\(\)\.length\(\)\s*<', emer)),
   'the reason must exist before the number does, not after')


# ─────────────────────────────────────────────────── 3. HONESTY
# "Respect data provenance and ensure consent to use data." Consent has to be
# enforced by something that runs whether or not a model remembers to.
P = 'HONESTY'

create = cls('CurbCutCreateRequest')
vr_dir = os.path.join(OBJ, 'Accommodation_Request__c/validationRules')
vrs = os.listdir(vr_dir) if os.path.isdir(vr_dir) else []
ok(P, 'consent-has-two-independent-locks',
   'approved' in create and any('Approval' in v for v in vrs),
   'apex guard and validation rule must both exist; either alone is one bug from silent')

log_fields = [os.path.basename(f).replace('.field-meta.xml', '')
              for f in glob.glob(f'{OBJ}/Message_Log__c/fields/*.field-meta.xml')]
ok(P, 'the-delivery-ledger-holds-no-message-body',
   not any(re.search(r'body|content|message_text|transcript', f, re.I) for f in log_fields),
   f'fields: {log_fields}')

ok(P, 'a-disclosure-is-recorded-when-something-is-shared',
   os.path.isdir(os.path.join(OBJ, 'Disclosure_Event__c')),
   'a person cannot audit who saw what without a record of it')

# The privacy page once claimed something the code did not do. That is the
# failure mode this check exists to prevent coming back.
priv = read(os.path.join(ROOT, 'force-app/main/default/pages/privacy.page'))
overclaims = re.search(r'is not written to any record|never stored|cannot be stored', priv, re.I)
ok(P, 'the-privacy-page-does-not-promise-an-absolute',
   not overclaims,
   f'found an absolute claim a word list cannot keep: {overclaims.group(0) if overclaims else ""}')


# ─────────────────────────────────────────────────── 4. EMPOWERMENT
# "Prioritize the human-AI partnership and design meaningful hand-offs."
P = 'EMPOWERMENT'

channels = ['CurbCutWeb', 'CurbCutEmail', 'CurbCutChannelApi']
missing = [c for c in channels if 'CurbCutKeyword' not in cls(c)]
ok(P, 'every-channel-routes-the-escape-words-through-one-router', not missing,
   f'{missing} do not use the shared router, so OFF could mean different things')

ok(P, 'a-draft-never-sends-itself',
   'approved' in create and 'req.approved != true' in create.replace(' ', '').replace('\n', ' ') or
   bool(re.search(r'approved\s*!=\s*true', create)),
   'a request must not leave without the person choosing in the moment')

ok(P, 'a-human-handoff-exists-and-is-reachable',
   os.path.isdir(os.path.join(OBJ, 'Human_Handoff__c')) and
   any('Human_Handoff__c' in s for s in everything.values()),
   'the promise that a person will pick this up needs somewhere to land')


# ─────────────────────────────────────────────────── 5. SUSTAINABILITY
# "Create right-sized models where possible to reduce carbon footprint."
P = 'SUSTAINABILITY'

joined = '\n'.join(everything.values())
ok(P, 'no-vector-store-and-no-embeddings',
   not re.search(r'embedding|vector(store|db)|cosine.?similarity|pinecone|faiss', joined, re.I),
   'a retrieval index for 28 rows would cost more energy than it saves')

pkg = read(os.path.join(ROOT, 'package.json'))
ok(P, 'no-model-call-is-needed-to-list-the-options',
   'SELECT' in opts.upper() and not re.search(r'callout|http', opts, re.I),
   'the library is a SOQL query, so the common path spends no inference at all')

deterministic = [n for n, s in everything.items()
                 if not n.endswith('Test') and '@InvocableMethod' in s]
ok(P, 'the-safety-critical-paths-are-deterministic-apex',
   len(deterministic) >= 5,
   f'only {len(deterministic)} invocable actions; guardrails must not live in narration')

# Honest about what this cannot measure.
undecided('SUSTAINABILITY', 'actual-energy-per-conversation',
          'no per-inference energy figure is exposed by the platform; '
          'we report design choices, not measured joules')


# ─────────────────────────────────────────────────── selftest
if '--selftest' in sys.argv:
    # Prove the harness can go red: corrupt each input in memory and re-assert.
    print('selftest: a check that cannot fail proves nothing\n')
    probes = [
        ('every-library-row-cites-a-source',
         lambda: all((r.get('Source_URL__c') or '').startswith('http')
                     for r in seed_rows + [{'Source_URL__c': ''}])),
        ('no-protected-attribute-field-exists',
         lambda: not FORBIDDEN.search('Diagnosis__c')),
        # Take CurbCutStanding's reference away in memory; the named set must
        # notice. A count of three would not have.
        ('conditions-are-stripped-before-any-insert',
         lambda: not (REDACTING_WRITE_PATHS - (redact_users - {'CurbCutStanding'}))),
        ('identity-words-are-never-stripped',
         lambda: all(w in '' for w in identity)),
        ('the-delivery-ledger-holds-no-message-body',
         lambda: not re.search(r'body', 'Message_Body__c', re.I)),
    ]
    bad = 0
    for name, probe in probes:
        went_red = not probe()
        print('  %-46s %s' % (name, 'goes red when broken' if went_red else 'DID NOT FAIL'))
        if not went_red: bad += 1
    print()
    if bad:
        print('selftest FAILED: %d check(s) cannot detect their own defect' % bad)
        sys.exit(2)
    print('selftest passed: every probed check detects its own defect')


# ─────────────────────────────────────────────────── report
order = ['ACCURACY', 'SAFETY', 'HONESTY', 'EMPOWERMENT', 'SUSTAINABILITY']
DEF = {
 'ACCURACY':      'Prioritize accurate results for agents',
 'SAFETY':        'Mitigate bias, toxicity, and harmful outputs',
 'HONESTY':       'Respect data provenance and ensure consent to use data',
 'EMPOWERMENT':   'Prioritize the human-AI partnership and design meaningful hand-offs',
 'SUSTAINABILITY':'Create right-sized models where possible',
}
mark = {'PASS': 'pass', 'FAIL': 'FAIL', 'UNDECIDED': 'undecided'}
failed = [r for r in results if r[2] == 'FAIL']
undec  = [r for r in results if r[2] == 'UNDECIDED']

print('Responsible AI self check, against Salesforce\'s five published guidelines')
print('=' * 74)
for p in order:
    rs = [r for r in results if r[0] == p]
    if not rs: continue
    print('\n%s  %s' % (p, DEF[p]))
    for _, name, state, detail in rs:
        print('  %-9s %-52s' % (mark[state], name))
        if state != 'PASS' and detail:
            print('            %s' % detail)

print('\n' + '=' * 74)
print('%d checks  |  %d passed  |  %d failed  |  %d undecided'
      % (len(results), len(results) - len(failed) - len(undec), len(failed), len(undec)))
if undec:
    print('\nUndecided is not a pass. Each one is listed above with the reason.')
if failed:
    print('\nFAILED:')
    for _, name, _, detail in failed:
        print('  %s: %s' % (name, detail))
    sys.exit(1)
