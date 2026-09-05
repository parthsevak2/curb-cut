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

# Objects an operator may legitimately see in full, each with a stated reason.
# Adding to this list is a privacy decision and should be argued for in review,
# which is the point of making it an explicit list rather than a loose rule.
VIEW_ALL_ALLOWED = {
    'Accommodation_Option__c':
        'Public reference data. Every row carries a source URL and no row is '
        'about a person.',
    'Message_Log__c':
        'Delivery telemetry. Holds a salted hash, never a raw address, and no '
        'message content. An operator cannot debug an undelivered reply without '
        'seeing that the attempt happened.',
}
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

# 2. Every field must be in a permission set. The agent could not see the
#    grounded library for an entire afternoon because of a permissions gap.
#
#    One object is deliberately NOT on the main permission set. Making that an
#    explicit, argued exception rather than loosening the rule is the same
#    pattern as VIEW_ALL_ALLOWED: if the list ever grows, somebody has to write
#    down why.
SQUAD_ONLY = {
    'Emergency_Escalation__c':
        'The telephone exception. Curb Cut promises nobody is ever routed to a '
        'phone, so the ability to make an exception is held by a named squad '
        'through Curb_Cut_Emergency rather than by everyone with a login. '
        'Granting it to a person is a decision.',
}
SQUAD_PS = os.path.join(ROOT, 'force-app/main/default/permissionsets',
                        'Curb_Cut_Emergency.permissionset-meta.xml')
squad_ps = open(SQUAD_PS).read() if os.path.exists(SQUAD_PS) else ''
ps = open(PS).read()
for o in objects():
    if o in SQUAD_ONLY:
        # Still enforced - just against the squad's permission set instead.
        for fn, t in fields(o).items():
            if t.findtext(f'{{{NS}}}type') in ('AutoNumber','Formula','Summary'):
                continue
            check('squad-only-field-in-squad-permset',
                  f'<field>{o}.{fn}</field>' in squad_ps,
                  f'{o}.{fn} missing from Curb_Cut_Emergency')
        check('squad-only-not-in-main-permset',
              f'<object>{o}</object>' not in ps,
              f'{o} is squad-only but appears on the main permission set')
        continue
    for fn, t in fields(o).items():
        ftype = t.findtext(f'{{{NS}}}type')
        if ftype in ('AutoNumber','Formula','Summary'):
            continue
        check('field-in-permset', f'<field>{o}.{fn}</field>' in ps,
              f'{o}.{fn} missing from Curb_Cut_Access')

# 3. Read-all may exist ONLY on the public library. Never on person data.
for m in re.finditer(r'<object>([^<]+)</object>\s*<viewAllRecords>(\w+)</viewAllRecords>', ps):
    obj, view = m.group(1), m.group(2)
    if view == 'true':
        check('viewall-must-be-justified', obj in VIEW_ALL_ALLOWED,
              f'{obj} grants viewAllRecords with no stated justification')

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


# 9. Nothing in the internal console may point at something that is not there.
#    Deploying an app whose tab does not exist gives 'The app you're trying to
#    view is invalid or inaccessible' and no clue which reference is dangling,
#    which cost most of an afternoon.
DEF   = os.path.join(ROOT, 'force-app/main/default')
def stems(sub, suffix):
    d = os.path.join(DEF, sub)
    if not os.path.isdir(d): return set()
    return {os.path.basename(f)[:-len(suffix)] for f in glob.glob(os.path.join(d, '*' + suffix))}

tabs_have  = stems('tabs',       '.tab-meta.xml')
flex_have  = stems('flexipages', '.flexipage-meta.xml')
apps_have  = stems('applications', '.app-meta.xml')
reports_have = {
    os.path.basename(os.path.dirname(f)) + '/' + os.path.basename(f)[:-len('.report-meta.xml')]
    for f in glob.glob(os.path.join(DEF, 'reports', '*', '*.report-meta.xml'))
}
listviews_have = {
    os.path.basename(os.path.dirname(os.path.dirname(f))) + '.' +
    os.path.basename(f)[:-len('.listView-meta.xml')]
    for f in glob.glob(os.path.join(OBJ, '*', 'listViews', '*.listView-meta.xml'))
}

# Every tab an app names must exist. Standard tabs start with 'standard-'.
for app in glob.glob(os.path.join(DEF, 'applications', '*.app-meta.xml')):
    for t in ET.parse(app).getroot().findall(f'{{{NS}}}tabs'):
        name = (t.text or '').strip()
        if name.startswith('standard-'): continue
        check('app-tab-exists', name in tabs_have or name in objects(),
              f'{os.path.basename(app)} lists tab {name}, which does not exist')

# Every tab that fronts a FlexiPage must have that page.
for tab in glob.glob(os.path.join(DEF, 'tabs', '*.tab-meta.xml')):
    fp = ET.parse(tab).getroot().find(f'{{{NS}}}flexiPage')
    if fp is not None:
        check('tab-flexipage-exists', (fp.text or '').strip() in flex_have,
              f'{os.path.basename(tab)} points at FlexiPage {fp.text}, which does not exist')

# Every list view a FlexiPage card names must exist on that object.
for fpf in glob.glob(os.path.join(DEF, 'flexipages', '*.flexipage-meta.xml')):
    root = ET.parse(fpf).getroot()
    for ci in root.iter(f'{{{NS}}}componentInstance'):
        props = {}
        for pr in ci.findall(f'{{{NS}}}componentInstanceProperties'):
            n = pr.find(f'{{{NS}}}name'); v = pr.find(f'{{{NS}}}value')
            if n is not None and v is not None: props[n.text] = (v.text or '').strip()
        if 'entityName' in props and 'filterName' in props:
            ref = props['entityName'] + '.' + props['filterName']
            check('flexipage-listview-exists', ref in listviews_have,
                  f'{os.path.basename(fpf)} shows list view {ref}, which does not exist')

# Every report a dashboard component names must exist.
for db in glob.glob(os.path.join(DEF, 'dashboards', '*', '*.dashboard-meta.xml')):
    for r in ET.parse(db).getroot().iter(f'{{{NS}}}report'):
        check('dashboard-report-exists', (r.text or '').strip() in reports_have,
              f'{os.path.basename(db)} charts report {r.text}, which does not exist')

# Every tab and app the permission set grants must exist, or the grant is a
# silent no-op and the console simply will not open for anyone but an admin.
if os.path.exists(PS):
    psr = ET.parse(PS).getroot()
    for ts in psr.findall(f'{{{NS}}}tabSettings'):
        t = (ts.find(f'{{{NS}}}tab').text or '').strip()
        check('permset-tab-exists', t in tabs_have or t in objects(),
              f'permission set grants tab {t}, which does not exist')
    for av in psr.findall(f'{{{NS}}}applicationVisibilities'):
        a = (av.find(f'{{{NS}}}application').text or '').strip()
        check('permset-app-exists', a in apps_have,
              f'permission set grants app {a}, which does not exist')

# 10. A picklist filter must name a value the picklist actually has. A report
#     filtered on Manager_Response__c = '' returned nothing forever, because
#     every request is created as 'Pending'. Silence is the worst failure mode
#     this project has: a queue that looks empty is a person nobody is helping.
def picklist_values(obj, field):
    f = os.path.join(OBJ, obj, 'fields', field + '.field-meta.xml')
    if not os.path.exists(f): return None
    root = ET.parse(f).getroot()
    if (root.find(f'{{{NS}}}type') is None or root.find(f'{{{NS}}}type').text != 'Picklist'):
        return None
    return {v.text for v in root.iter(f'{{{NS}}}fullName')} - {field}

for lv in glob.glob(os.path.join(OBJ, '*', 'listViews', '*.listView-meta.xml')):
    obj = os.path.basename(os.path.dirname(os.path.dirname(lv)))
    for flt in ET.parse(lv).getroot().findall(f'{{{NS}}}filters'):
        fld = flt.find(f'{{{NS}}}field'); val = flt.find(f'{{{NS}}}value')
        if fld is None or val is None or not (val.text or '').strip(): continue
        vals = picklist_values(obj, fld.text)
        if vals is None: continue
        for one in (val.text or '').split(','):
            one = one.strip()
            if not one: continue
            check('listview-picklist-value-real', one in vals,
                  f'{os.path.basename(lv)} filters {fld.text} = {one}, not a value of that picklist')

for rp in glob.glob(os.path.join(DEF, 'reports', '*', '*.report-meta.xml')):
    for ci in ET.parse(rp).getroot().iter(f'{{{NS}}}criteriaItems'):
        col = ci.find(f'{{{NS}}}column'); val = ci.find(f'{{{NS}}}value')
        if col is None or val is None or not (val.text or '').strip(): continue
        if '.' not in (col.text or ''): continue
        obj, fld = col.text.split('.', 1)
        vals = picklist_values(obj, fld)
        if vals is None: continue
        for one in (val.text or '').split(','):
            one = one.strip()
            if not one: continue
            check('report-picklist-value-real', one in vals,
                  f'{os.path.basename(rp)} filters {col.text} = {one}, not a value of that picklist')


# 11. Carrier compliance for the text channel.
#     A2P campaign CMcb0b8f321bcc5aa98b2cc45bb3ea594a was rejected under error
#     30909 because a reviewer could not verify consent. The legal pages were
#     fine; the channel had no compliance layer and the site had no page showing
#     the opt-in. Both are now checked here, because "we wrote it down once" is
#     exactly how it was missed.
RELAY = os.path.join(ROOT, 'channels/sms-relay.mjs')
SITE_URL = 'https://orgfarm-7a04c62cb9.my.salesforce-sites.com/curbcut'
PAGES = os.path.join(DEF, 'pages')

if os.path.exists(RELAY):
    relay = open(RELAY).read()

    # The one-time disclosure has to carry every element a carrier requires.
    m = re.search(r'const DISCLOSURE\s*=(.*?);\n', relay, re.S)
    disclosure = m.group(1) if m else ''
    for needle, why in [
        ('Curb Cut',                        'programme name'),
        ('Message frequency varies',        'message frequency'),
        ('Message and data rates may apply','rates disclosure'),
        ('Reply HELP',                      'HELP instruction'),
        ('STOP to stop',                    'STOP instruction'),
        ('/terms',                          'terms link'),
        ('/privacy',                        'privacy link'),
    ]:
        check('sms-disclosure-complete', needle in disclosure,
              f'first-contact SMS disclosure is missing the {why}')

    m = re.search(r'const HELP_REPLY\s*=(.*?);\n', relay, re.S)
    helper = m.group(1) if m else ''
    for needle, why in [
        ('Curb Cut',                        'programme name'),
        ('Message and data rates may apply','rates disclosure'),
        ('STOP to stop',                    'STOP instruction'),
        ('@',                               'a contact address'),
    ]:
        check('sms-help-reply-complete', needle in helper,
              f'HELP reply is missing the {why}')


    # Carrier keyword auto-responses cap at 320 characters. Ours are sent as
    # TwiML, which has no such cap, so an over-long reply passes every test we
    # run and is then silently truncated in the Messaging Service field - and
    # /messaging, which quotes these verbatim as "the exact messages, as sent",
    # becomes a page that lies. One text, short enough for both.
    for const in ['HELP_REPLY', 'STOP_REPLY', 'START_REPLY']:
        m = re.search(const + r'\s*=(.*?);\n', relay, re.S)
        if not m: continue
        literal = ''.join(re.findall(r"'([^']*)'", m.group(1)))
        literal += ''.join(re.findall(r'`([^`]*)`', m.group(1)))
        literal = literal.replace('${SITE}', SITE_URL)
        check('keyword-reply-fits-carrier-field', len(literal) <= 320,
              f'{const} is {len(literal)} characters; the carrier keyword field caps at 320')

    # Reserved keywords belong to the carrier and to the person, not to us. An
    # assistant improvising an answer to STOP is someone asking to be left alone
    # and being answered back.
    for kw in ['stop', 'stopall', 'unsubscribe', 'cancel', 'end', 'quit']:
        check('stop-word-reserved', f"'{kw}'" in relay,
              f'{kw} is a reserved opt-out keyword and the relay does not know it')
    check('help-handled-before-agent',
          relay.find('HELP_WORDS.has(word)') != -1 and
          relay.find('HELP_WORDS.has(word)') < relay.find('agentFor(handle)', relay.find('/sms')),
          'HELP reaches the agent instead of returning the required help text')

# The opt-in page a reviewer lands on must show the whole call to action.
MSG = os.path.join(PAGES, 'messaging.page')
if os.path.exists(MSG):
    msg = open(MSG).read()
    for needle, why in [
        ('+1 276 495 9311',                  'the number'),
        ('you agree to receive text messages','the consent sentence'),
        ('Message frequency varies',         'message frequency'),
        ('Message and data rates may apply', 'the rates disclosure'),
        ('HELP',                             'the HELP keyword'),
        ('STOP',                             'the STOP keyword'),
        ('/terms',                           'a link to the terms'),
        ('/privacy',                         'a link to the privacy policy'),
    ]:
        check('optin-page-complete', needle in msg,
              f'the public opt-in page does not show {why}')
else:
    check('optin-page-exists', False, 'there is no public page showing the opt-in flow')

# 12. A page nobody can open is not a page. Every Visualforce page in the repo
#     must be granted on the site guest profile, or it ships a 401 to the public
#     and to any carrier reviewing the campaign.
# The site's guest profile by name, not "whichever profile file sorts first".
# Adding an unrelated Admin profile once made this check read the wrong file and
# report every public page as unreachable, which is the kind of false alarm that
# teaches people to ignore the suite.
PROF = [f for f in glob.glob(os.path.join(DEF, 'profiles', '*.profile-meta.xml'))
        if 'CurbCut' in os.path.basename(f)]
check('guest-profile-present', bool(PROF),
      'no CurbCut guest profile in source; public page access is unverifiable')
if PROF:
    prof = ET.parse(PROF[0]).getroot()
    granted = {(pa.find(f'{{{NS}}}apexPage').text or '').strip()
               for pa in prof.findall(f'{{{NS}}}pageAccesses')
               if (pa.find(f'{{{NS}}}enabled').text or '') == 'true'}
    for pg in glob.glob(os.path.join(PAGES, '*.page')):
        name = os.path.basename(pg)[:-len('.page')]
        check('guest-can-open-page', name in granted,
              f'{name} is not granted on the guest profile; the public gets a 401')


# 13. Carriers reject a campaign whose privacy policy does not say, in so many
#     words, that mobile information is not shared for marketing. Error 30908.
#     Meaning it is not enough; the words have to be findable.
PRIV = os.path.join(PAGES, 'privacy.page')
if os.path.exists(PRIV):
    priv = open(PRIV).read().lower()
    for needle, why in [
        ('mobile information', 'the phrase "mobile information"'),
        ('opt-in consent',     'text-message opt-in consent'),
        ('third party',        'a statement about third parties'),
        ('marketing',          'a statement about marketing purposes'),
    ]:
        check('privacy-states-mobile-sharing', needle in priv,
              f'the privacy policy does not contain {why}, which carriers check for')


# 14. Every figure the public site quotes must be recorded in docs/EVIDENCE.md
#     with its source and its denominator. The site's entire argument is that a
#     claim should be checkable, and it once shipped "61 out of every 100"
#     against the wrong denominator. A number without a source is decoration.
EV = os.path.join(ROOT, 'docs/EVIDENCE.md')
if os.path.exists(EV):
    evidence = open(EV).read()
    figure = re.compile(r'\$[\d,]+|\b\d{1,3}(?:,\d{3})+\b|\b\d+(?:\.\d+)?%')
    for pg in glob.glob(os.path.join(PAGES, '*.page')):
        body = re.sub(r'<style.*?</style>', '', open(pg).read(), flags=re.S)
        for fig in sorted(set(figure.findall(body))):
            check('figure-has-evidence', fig in evidence,
                  f'{os.path.basename(pg)} states {fig}, which is not recorded in docs/EVIDENCE.md')
else:
    check('evidence-file-exists', False, 'docs/EVIDENCE.md is missing; the site quotes unsourced numbers')


# 15. Every field must carry help text, and no help text may leak a medical
#     frame. Help text is what an operator reads at four in the afternoon;
#     it is the last place guidance actually lands, and it was empty on all
#     46 fields while the documentation was thorough.
for obj in objects():
    for fld in fields(obj):
        fp = os.path.join(OBJ, obj, 'fields', fld + '.field-meta.xml')
        if not os.path.exists(fp): continue
        root = ET.parse(fp).getroot()
        help_el = root.find(f'{{{NS}}}inlineHelpText')
        desc_el = root.find(f'{{{NS}}}description')
        check('field-has-help-text', help_el is not None and (help_el.text or '').strip(),
              f'{obj}.{fld} has no inline help text')
        check('field-has-description', desc_el is not None and (desc_el.text or '').strip(),
              f'{obj}.{fld} has no description')
        # A medical word may appear only in text that is refusing it. Check each
        # string on its own: an earlier version concatenated the help text with
        # the description, so a description saying 'never' laundered a help text
        # saying 'record the condition and severity'. The negative test caught
        # the check rather than the code, which is the whole reason to run one.
        for label, el in (('help text', help_el), ('description', desc_el)):
            body = (el.text or '') if el is not None else ''
            if not FORBIDDEN.search(body):
                continue
            refuses = any(w in body.lower() for w in
                          ['never', 'no field', 'nowhere', 'not record', 'nobody knows',
                           'without ever', 'do not', 'must not'])
            check('help-text-refuses-medical', refuses,
                  f'{obj}.{fld} {label} mentions a medical concept without refusing it: '
                  f'{body[:70]}')

# Every object an operator works in should have a compact layout, so the
# highlights panel says something useful instead of the record name twice.
for obj in objects():
    cl = glob.glob(os.path.join(OBJ, obj, 'compactLayouts', '*.compactLayout-meta.xml'))
    check('object-has-compact-layout', bool(cl),
          f'{obj} has no compact layout; its highlights panel is Salesforce default')
    lay = glob.glob(os.path.join(DEF, 'layouts', obj + '-*.layout-meta.xml'))
    check('object-has-layout', bool(lay),
          f'{obj} has no page layout in source; the org is running an auto-generated one')


# 16. A cost of zero must mean "the employer pays nothing", never "we do not
#     know". Nine of twenty-four library rows carried a placeholder 0 with
#     Zero_Cost false, which the Apex happened to guard against and the MCP
#     surface did not: it answered "typically about $0, once" for a booked ASL
#     interpreter. Someone could repeat that to their employer.
if os.path.exists(CSV_):
    import csv as _csv
    with open(CSV_, newline='') as fh:
        for row in _csv.DictReader(fh):
            cost = (row.get('Typical_Cost__c') or '').strip()
            zero = (row.get('Zero_Cost__c') or '').strip().lower() == 'true'
            if cost in ('0', '0.0', '0.00'):
                check('zero-cost-means-free', zero,
                      f"{row.get('Option__c')} stores a cost of 0 without Zero_Cost true; "
                      f'leave the figure blank when none is published')
            if zero and cost not in ('', '0', '0.0', '0.00'):
                check('zero-cost-is-consistent', False,
                      f"{row.get('Option__c')} is marked zero-cost but carries a figure of {cost}")


# 17. The agent-to-agent payload is an allow-list, so a field added to the
#     schema next year cannot leak by default. These names must never appear in
#     the builder at all, in a SELECT or anywhere else.
HO = os.path.join(CLS, 'CurbCutHandover.cls')
if os.path.exists(HO):
    ho = open(HO).read()
    for banned in ['Person_Handle__c', 'Recipient_Hash__c', 'OwnerId', 'CreatedById',
                   'Decline_Reason__c', 'Access_Profile__c']:
        check('handover-allowlist', banned not in ho,
              f'CurbCutHandover references {banned}; the handover payload is an '
              f'allow-list and this is not on it')
    # The refusal is the whole design, so it must actually be there.
    check('handover-refuses-without-consent',
          'Person_Approved__c != true' in ho and 'RefusedException' in ho,
          'CurbCutHandover no longer refuses to build a payload without consent')
    check('handover-declares-absence',
          'must_not_ask' in ho and 'no such field exists in this system' in ho,
          'CurbCutHandover no longer tells the recipient what it must not ask for')

# The MCP surface must never gain a tool that sends anything. A model can be
# talked into calling a tool; it cannot be talked into calling one that is not
# there.
MCP = os.path.join(ROOT, 'channels/mcp-server.mjs')
if os.path.exists(MCP):
    mcp = open(MCP).read()
    tool_names = re.findall(r"name:\s*'(curbcut_[a-z_]+)'", mcp)
    for t in tool_names:
        check('mcp-has-no-send-tool',
              not any(w in t for w in ['send', 'submit', 'file_', 'notify', 'email']),
              f'the MCP server exposes {t}; nothing reachable by another model may '
              f'send an accommodation request on a person behalf')
    check('mcp-refuses-medical', 'FORBIDDEN' in mcp and 'refused' in mcp,
          'the MCP server no longer refuses medical input')


# 18. No Apex reply may tell someone to reply STOP to control anything. STOP is
#     the carrier's keyword: it unsubscribes the person from the number entirely
#     and is intercepted before it reaches us, so anyone following that advice
#     loses the whole service and keeps the thing they were turning off. The
#     site and the agent both say OFF; CurbCutStanding said STOP, and a test
#     asserted that it did.
def strip_apex_comments(src):
    # Comments discuss STOP on purpose - the whole reason the rule exists is
    # written down next to the code that broke it. Only string literals ship.
    src = re.sub(r'/\*.*?\*/', '', src, flags=re.S)
    return re.sub(r'//[^\n]*', '', src)

for cls in glob.glob(os.path.join(CLS, '*.cls')):
    if cls.endswith('Test.cls'):
        continue
    body = strip_apex_comments(open(cls).read())
    for m in re.finditer(r"'([^'\n]*[Rr]eply STOP[^'\n]*)'", body):
        check('never-instructs-reply-stop', False,
              f'{os.path.basename(cls)} tells someone to reply STOP: "{m.group(1)[:60]}"')


# 19. Every custom component a Lightning page names must exist in source, and
#     every report a chart names must too. A missing one renders as nothing at
#     all -- no error, no gap, just a page that quietly does less than it says.
lwc_have = {os.path.basename(d) for d in glob.glob(os.path.join(DEF, 'lwc', '*'))
            if os.path.isdir(d)}
for fpf in glob.glob(os.path.join(DEF, 'flexipages', '*.flexipage-meta.xml')):
    root = ET.parse(fpf).getroot()
    for ci in root.iter(f'{{{NS}}}componentInstance'):
        nm = ci.find(f'{{{NS}}}componentName')
        name = (nm.text or '').strip() if nm is not None else ''
        if not name or ':' in name:          # namespaced platform components
            continue
        check('flexipage-lwc-exists', name in lwc_have,
              f'{os.path.basename(fpf)} places {name}, which is not in force-app/lwc')
        props = {}
        for pr in ci.findall(f'{{{NS}}}componentInstanceProperties'):
            n = pr.find(f'{{{NS}}}name'); v = pr.find(f'{{{NS}}}value')
            if n is not None and v is not None: props[n.text] = (v.text or '').strip()
    for ci in root.iter(f'{{{NS}}}componentInstance'):
        nm = ci.find(f'{{{NS}}}componentName')
        if nm is None or nm.text != 'flexipage:reportChart':
            continue
        for pr in ci.findall(f'{{{NS}}}componentInstanceProperties'):
            n = pr.find(f'{{{NS}}}name')
            if n is not None and n.text == 'reportName':
                want = (pr.find(f'{{{NS}}}value').text or '').strip()
                check('flexipage-chart-report-exists',
                      any(want == r.split('/')[-1] for r in reports_have),
                      f'{os.path.basename(fpf)} charts report {want}, which is not in source')

# Every LWC that calls Apex must call a class that exists, or it renders nothing.
for js in glob.glob(os.path.join(DEF, 'lwc', '*', '*.js')):
    for m in re.finditer(r"@salesforce/apex/([A-Za-z0-9_]+)\.([A-Za-z0-9_]+)", open(js).read()):
        cls_name, method = m.group(1), m.group(2)
        path = os.path.join(CLS, cls_name + '.cls')
        check('lwc-apex-class-exists', os.path.exists(path),
              f'{os.path.basename(js)} imports {cls_name}.{method}, no such Apex class')
        if os.path.exists(path):
            body = open(path).read()
            check('lwc-apex-method-is-exposed',
                  re.search(r'@AuraEnabled[^\n]*\n\s*public\s+static[^\n]*\b' + method + r'\s*\(', body)
                  is not None,
                  f'{cls_name}.{method} is called from LWC but is not @AuraEnabled')


# ---------------------------------------------------------------------------
# Every keyword we advertise must actually be routed.
#
# Six control words were printed in user-facing copy across three channels and
# none of them was routed anywhere. HUMAN returned an ASL interpreter card.
# PERSON returned "face the person when speaking". OFF - the word that withdraws
# a standing disclosure - returned "I do not have good information on that",
# so a withdrawal silently failed and the sharing stayed on.
#
# Every one of those passed every test in the suite, because nothing checked
# that a promise made in a string was kept by a router. This does.
# ---------------------------------------------------------------------------
def read(p):
    with open(p, encoding='utf-8') as fh:
        return fh.read()

kw_src = read(os.path.join(CLS, 'CurbCutKeyword.cls'))
routed = set()
for m in re.finditer(r"'([A-Z]+)'\s*=>\s*new Set<String>\{(.*?)\}", kw_src, re.S):
    routed.add(m.group(1))
    for phrase in re.findall(r"'([^']+)'", m.group(2)):
        routed.add(phrase.upper())

# Words the agent handles inside a draft exchange rather than the router: these
# only mean anything while a draft is on the table.
IN_DRAFT = {'YES', 'CHANGE', 'DELETE', 'NO'}

advertised = {}
sources = (glob.glob(os.path.join(CLS, '*.cls'))
           + glob.glob(os.path.join(DEF, 'pages', '*.page'))
           + glob.glob(os.path.join(ROOT, 'channels', '*.mjs')))
for f in sources:
    body = strip_apex_comments(read(f)) if f.endswith('.cls') else read(f)
    for m in re.finditer(r'\b(?:[Rr]eply|[Ss]end|[Tt]ext)\s+(?:with\s+the\s+word\s+)?([A-Z]{2,12})\b', body):
        advertised.setdefault(m.group(1), set()).add(os.path.basename(f))

for word, where in sorted(advertised.items()):
    if word in IN_DRAFT:
        continue
    check('advertised-keyword-is-routed', word in routed,
          f'copy in {", ".join(sorted(where))} tells people to send {word}, '
          f'but CurbCutKeyword does not route it')

# The relay mirrors the control words so it can answer without a round trip.
# Two lists that disagree is how this broke in the first place.
relay = read(os.path.join(ROOT, 'channels', 'sms-relay.mjs'))
m = re.search(r'const CONTROL_WORDS = new Set\(\[(.*?)\]\)', relay, re.S)
check('relay-mirrors-control-words', m is not None,
      'sms-relay.mjs has no CONTROL_WORDS mirror')
if m:
    mirrored = {w.upper() for w in re.findall(r"'([^']+)'", m.group(1))}
    apex_control = set()
    for intent in ('HUMAN', 'WHO', 'OFF'):
        mm = re.search(r"'" + intent + r"'\s*=>\s*new Set<String>\{(.*?)\}", kw_src, re.S)
        if mm:
            for phrase in re.findall(r"'([^']+)'", mm.group(1)):
                apex_control.add(phrase.replace(' ', '').upper())
    missing = apex_control - mirrored
    check('relay-control-words-cover-apex', not missing,
          'sms-relay.mjs would send these to the agent instead of routing them: '
          + ', '.join(sorted(missing)))

# STOP belongs to the carrier and must never be offered as our own switch.
for intent in ('OFF', 'WHO', 'HUMAN'):
    mm = re.search(r"'" + intent + r"'\s*=>\s*new Set<String>\{(.*?)\}", kw_src, re.S)
    if mm:
        words = {w.upper() for w in re.findall(r"'([^']+)'", mm.group(1))}
        check('control-word-not-carrier-reserved', 'STOP' not in words,
              f'{intent} claims STOP, which the carrier owns and intercepts')

# A handoff must never route anyone to a telephone.
handoff_src = strip_apex_comments(read(os.path.join(CLS, 'CurbCutCreateHandoff.cls')))
check('handoff-refuses-telephone',
      "'phone'" in handoff_src and 'NEVER' in handoff_src,
      'CurbCutCreateHandoff no longer refuses telephone as a reply channel')



# ---------------------------------------------------------------------------
# The adversarial scorer must be scoring the runner that actually runs.
#
# There are two harnesses. The pty one numbers its scenarios 01-08; the headless
# Agent API one numbers them 01-11 and is the one the scorer's rules name. Run
# the wrong one and all 23 assertions go inconclusive - and until this was
# fixed, the process still exited 0. This is a static check, so CI catches the
# drift without needing a live agent.
# ---------------------------------------------------------------------------
scorer = read(os.path.join(ROOT, 'tests', 'score_adversarial.py'))
runner = read(os.path.join(ROOT, 'tests', 'headless_agent_api.mjs'))
scored = set(re.findall(r'\("([0-9]{2}_[a-z_]+)"', scorer))
runnable = set(re.findall(r"'([0-9]{2}_[a-z_]+)'", runner))
for scen in sorted(scored):
    check('adversarial-scenario-is-runnable', scen in runnable,
          f'score_adversarial.py asserts on {scen}, which '
          f'headless_agent_api.mjs never produces')

check('adversarial-silence-is-not-success',
      'sys.exit(1)' in scorer and "counts[\"????\"]" in scorer,
      'score_adversarial.py no longer fails when assertions are inconclusive; '
      'an empty transcript would read as a green run')



# ---------------------------------------------------------------------------
# A volunteered condition must be taken out on the one shared write path.
#
# There is no Diagnosis__c, which is true and is the claim the project rests on.
# Functional_Description__c is free text, and "I have multiple sclerosis and
# some days I cannot type for long" was stored whole while the privacy policy
# said in public that it was not written to any record.
# ---------------------------------------------------------------------------
intake = strip_apex_comments(read(os.path.join(CLS, 'CurbCutIntake.cls')))
check('intake-redacts-before-insert',
      'CurbCutRedact.clean' in intake and 'CurbCutRedact.names' in intake,
      'CurbCutIntake no longer redacts; a volunteered condition would be stored '
      'verbatim in Functional_Description__c')

redact = read(os.path.join(CLS, 'CurbCutRedact.cls'))
for identity in ('deaf', 'blind', 'hard of hearing', 'wheelchair'):
    check('redaction-spares-identity-words',
          f"'{identity}'" not in redact.lower().split('CONDITIONS')[-1].split('};')[0],
          f'"{identity}" is how people describe themselves and the interpreter '
          f'routing reads it; it must never be redacted')

# The privacy page must not go back to promising an absolute the code cannot keep.
priv = read(os.path.join(DEF, 'pages', 'privacy.page'))
check('privacy-page-does-not-overclaim',
      'it is not written to any record' not in priv,
      'privacy.page has gone back to claiming a volunteered condition is never '
      'written down, which the redaction list cannot guarantee')



# ---------------------------------------------------------------------------
# The SMS webhook must fail closed.
#
# signatureValid() used to return true when no auth token was configured, and
# channels/.env shipped with TWILIO_AUTH_TOKEN empty. Every unsigned request was
# therefore treated as genuine: anyone who learned the URL could post a forged
# From and Body, drive the agent, create handoffs and write to the ledger.
# ---------------------------------------------------------------------------
relay_src = read(os.path.join(ROOT, 'channels', 'sms-relay.mjs'))
check('webhook-fails-closed-without-a-token',
      'if (!TWILIO_AUTH_TOKEN) return false;' in relay_src,
      'signatureValid no longer fails closed; an empty TWILIO_AUTH_TOKEN would '
      'make every unsigned webhook look valid')
check('webhook-refuses-to-start-unverified',
      'Refusing to start' in relay_src,
      'the relay no longer refuses to start without a token, so it can be run '
      'accidentally in a mode that accepts forged messages')
check('unverified-mode-cannot-be-public',
      "=== '1' && !PUBLIC_URL" in relay_src,
      'ALLOW_UNVERIFIED must refuse to combine with PUBLIC_URL')

# The voice door must use the same router as every other door.
#
# /sms checked CONTROL_WORDS and asked /curbcut/v1/message. /voice passed the
# transcript straight to the agent. A caller who said "human" got a model, and
# a caller who said "off" was told the system had no good information, with
# the sharing left on. "One router, every door" was false for the one door
# that works without carrier registration. This looks inside the /voice
# handler alone, so moving the check into the text path does not satisfy it.
voice_block = re.search(r"startsWith\('/voice'\)(.*?)startsWith\('/sms'\)", relay_src, re.S)
voice_src = voice_block.group(1) if voice_block else ''
check('voice-uses-the-shared-router',
      'CONTROL_WORDS' in voice_src and '/curbcut/v1/message' in voice_src,
      'the /voice handler in sms-relay.mjs no longer checks CONTROL_WORDS and '
      'asks /curbcut/v1/message; a caller saying HUMAN or OFF would get the '
      'agent instead of the router')



# ---------------------------------------------------------------------------
# The claim code is shown exactly once. Focus must land on it.
#
# Every other async update on /ask moves focus to its heading. The standing-
# preference save set tabindex on the heading and then never called focus(), so
# the single moment that matters most - a code somebody has to write down before
# they close the page - left a screen-reader user exactly where they were.
# ---------------------------------------------------------------------------
ask_src = read(os.path.join(DEF, 'pages', 'ask.page'))
check('code-panel-takes-focus',
      "codeH.focus()" in ask_src and 'id="codeHeading"' in ask_src,
      'saving a standing preference no longer moves focus to the claim code, '
      'which is shown once and cannot be recovered')

check('focus-ring-works-on-any-ground',
      'box-shadow:0 0 0 3px var(--ground)' in read(
          os.path.join(DEF, 'components', 'CurbCutShell.component')),
      'the focus indicator lost its second ring; a single blue ring is 5.7:1 on '
      'the page ground but only 2.7:1 against a dark filled button beside it')


# ---------------------------------------------------------------------------
# The count in this file is quoted in the deck, in four Devpost answers and in
# the technical design document. It has already drifted once: the suite grew and
# every public claim silently became wrong. A number a judge can check is worth
# nothing if it is stale, so the number checks itself.
# ---------------------------------------------------------------------------
CLAIM_FILES = [
    'submission/TECHNICAL-DESIGN.md', 'submission/DEVPOST-ANSWERS.md',
    'submission/devpost/Q1-accessibility.txt', 'submission/devpost/Q3-error-rate.txt',
    'submission/devpost/Q4-environmental.txt',
    'deck/build.js',
]
# Both orders: "494 structural invariants" and "Structural invariants   494".
CLAIM = re.compile(r'(\d{3})\s+(?:structural\s+)?invariant|invariants?\s+(\d{3})', re.I)
stale = []
for rel in CLAIM_FILES:
    for m in CLAIM.finditer(read(os.path.join(ROOT, rel))):
        num = m.group(1) or m.group(2)
        # +1 because this very check has not been counted yet when it runs
        if int(num) != checks + 1:
            stale.append(f'{rel} claims {num}')
check('published-invariant-count-is-current', not stale,
      f'the real count is {checks + 1}: ' + '; '.join(stale))

print(f'{checks - len(fails)}/{checks} invariants hold')
for f in fails:
    print(f'  FAIL  {f}')
sys.exit(1 if fails else 0)
