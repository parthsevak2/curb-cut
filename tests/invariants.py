#!/usr/bin/env python3
"""
Offline invariants for Curb Cut. No org required, runs in about a second.

Every check here exists because the corresponding thing actually broke during
the build. This is the incident log expressed as tests.
"""
import os, re, sys, csv, glob, json
import xml.etree.ElementTree as ET

NS   = 'http://soap.sforce.com/2006/04/metadata'
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OBJ  = os.path.join(ROOT, 'force-app/main/default/objects')
CLS  = os.path.join(ROOT, 'force-app/main/default/classes')
PS   = os.path.join(ROOT, 'force-app/main/default/permissionsets/Curb_Cut_Access.permissionset-meta.xml')
AGENT= os.path.join(ROOT, 'force-app/main/default/aiAuthoringBundles/Curb_Cut/Curb_Cut.agent')
CSV_ = os.path.join(ROOT, 'accommodation_options_seed.csv')

# The one object that is public reference data. Everything else is about a person.
PUBLIC_LIBRARY = 'Accommodation_Option__c'
FORBIDDEN = re.compile(r'diagnos|condition|disabilit|medical|severity|prognos', re.I)

fails, checks = [], 0
def check(name, ok, detail=''):
    global checks
    checks += 1
    if not ok:
        fails.append(f'{name}: {detail}')

def objects():
    return sorted(d for d in os.listdir(OBJ) if os.path.isdir(os.path.join(OBJ, d)))

def fields(o):
    out = {}
    for f in glob.glob(f'{OBJ}/{o}/fields/*.field-meta.xml'):
        t = ET.parse(f).getroot()
        out[os.path.basename(f).replace('.field-meta.xml','')] = t
    return out

# 1. The absence IS the design. A field named for a condition must never exist.
for o in objects():
    for fn in fields(o):
        check('no-diagnosis-field', not FORBIDDEN.search(fn),
              f'{o}.{fn} names a medical concept')

# 2. Every field must be in the permission set. The agent could not see the
#    grounded library for an entire afternoon because of a permissions gap.
ps = open(PS).read()
for o in objects():
    for fn, t in fields(o).items():
        ftype = t.findtext(f'{{{NS}}}type')
        if ftype in ('AutoNumber','Formula','Summary'):
            continue
        check('field-in-permset', f'<field>{o}.{fn}</field>' in ps,
              f'{o}.{fn} missing from Curb_Cut_Access')

# 3. Read-all may exist ONLY on the public library. Never on person data.
for m in re.finditer(r'<object>([^<]+)</object>\s*<viewAllRecords>(\w+)</viewAllRecords>', ps):
    obj, view = m.group(1), m.group(2)
    if obj != PUBLIC_LIBRARY:
        check('no-viewall-on-person-data', view == 'false',
              f'{obj} grants viewAllRecords; it holds data about a person')

# 3b. The guest permission set must never exceed what a guest may hold, and must
#     never see a person. Salesforce allows guests read and create only; an edit
#     permission makes the whole set unassignable, which fails at runtime rather
#     than at deploy.
GUEST_PS = os.path.join(ROOT, 'force-app/main/default/permissionsets/Curb_Cut_Guest.permissionset-meta.xml')
if os.path.exists(GUEST_PS):
    g = open(GUEST_PS).read()
    for m in re.finditer(r'<object>([^<]+)</object>\s*<viewAllRecords>(\w+)</viewAllRecords>', g):
        check('guest-no-viewall', m.group(2) == 'false',
              f'guest set grants viewAllRecords on {m.group(1)}')
    check('guest-no-edit', '<allowEdit>true</allowEdit>' not in g,
          'guest set grants edit; Salesforce permits guests read and create only')
    for m in re.finditer(r'<object>([^<]+)</object>\s*<viewAllRecords>', g):
        pass
    # A guest must never be able to create or read a disclosure ledger entry
    # about someone else.
    check('guest-no-disclosure-access', '<object>Disclosure_Event__c</object>' not in g,
          'guest set grants access to Disclosure_Event__c')
    check('guest-no-profile-access', '<object>Access_Profile__c</object>' not in g,
          'guest set grants access to Access_Profile__c')

# 4. Lookups must resolve inside the package.
objs = set(objects())
for o in objects():
    for fn, t in fields(o).items():
        ref = t.findtext(f'{{{NS}}}referenceTo')
        if ref:
            check('lookup-resolves', ref in objs, f'{o}.{fn} -> {ref} not in package')

# 5. Validation rules must reference real fields and real picklist values.
picklists = {}
for o in objects():
    for fn, t in fields(o).items():
        vals = [v.text for v in t.iter(f'{{{NS}}}fullName')][1:]
        if t.findtext(f'{{{NS}}}type') == 'Picklist':
            picklists[f'{o}.{fn}'] = vals
for vr in glob.glob(f'{OBJ}/*/validationRules/*.xml'):
    o = vr.split('/objects/')[1].split('/')[0]
    formula = ET.parse(vr).getroot().findtext(f'{{{NS}}}errorConditionFormula') or ''
    for m in re.finditer(r'ISPICKVAL\(\s*(\w+__c)\s*,\s*"([^"]+)"', formula):
        key = f'{o}.{m.group(1)}'
        check('validation-picklist-value', m.group(2) in picklists.get(key, []),
              f'{os.path.basename(vr)} tests for "{m.group(2)}" which {key} does not have')

# 6. Every apex:// target in the Agent Script must exist as a deployable class.
if os.path.exists(AGENT):
    script = open(AGENT).read()
    have = {os.path.basename(p).replace('.cls','') for p in glob.glob(f'{CLS}/*.cls')}
    for t in sorted(set(re.findall(r'apex://([A-Za-z]+)', script))):
        check('apex-target-exists', t in have, f'agent calls apex://{t}, no such class')
    # The router must have instructions. Without them a bare "yes" fell into
    # topic_selector and the request was never created.
    router = re.search(r'start_agent [a-z_]+:(.*?)\n\w', script, re.S)
    check('router-has-instructions', bool(router and 'instructions:' in router.group(1)),
          'start_agent has no instructions block; routing will fall through')

# 7. Seed CSV must match the library's field API names, and must be LF.
if os.path.exists(CSV_):
    raw = open(CSV_, 'rb').read()
    check('csv-is-lf', b'\r' not in raw, 'CSV has CRLF; Bulk API 2.0 rejects it')
    header = raw.decode().splitlines()[0].split(',')
    lib = set(fields(PUBLIC_LIBRARY))
    for h in header:
        check('csv-header-is-a-field', h in lib, f'CSV column {h} is not a field on {PUBLIC_LIBRARY}')

# 8. AiAuthoringBundle does not exist below API 66.0.
proj = json.load(open(os.path.join(ROOT, 'sfdx-project.json')))
check('api-version', float(proj.get('sourceApiVersion', 0)) >= 66.0,
      f"sourceApiVersion {proj.get('sourceApiVersion')} < 66.0")

print(f'{checks - len(fails)}/{checks} invariants hold')
for f in fails:
    print(f'  FAIL  {f}')
sys.exit(1 if fails else 0)
