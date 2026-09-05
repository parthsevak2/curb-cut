#!/usr/bin/env python3
"""Set every published invariant count to the real one. The build refuses a
commit whose claims are stale; this makes them current in one step."""
import re, subprocess, sys
out = subprocess.run(['python3','tests/invariants.py'], capture_output=True, text=True).stdout
m = re.search(r'real count is (\d+)', out) or re.search(r'(\d+)/(\d+) invariants hold', out)
real = int(m.group(1)) if 'real count' in (m.group(0) if m else '') else int(m.group(2))
files = ['submission/TECHNICAL-DESIGN.md','submission/DEVPOST-ANSWERS.md','submission/devpost/Q1-accessibility.txt',
         'submission/devpost/Q3-error-rate.txt','submission/devpost/Q4-environmental.txt','deck/build.js','README.md',
         'submission/JUDGE-TEST-GUIDE.md','submission/INDEX.md','submission/RUN-REQUIRED-TOOLS.md','docs/A11Y-SA11Y-REPORT.md']
n=0
for f in files:
    try: s=open(f).read()
    except OSError: continue
    t=re.sub(r'\b(\d{3})(\s+(?:structural\s+)?invariant)', lambda mm: str(real)+mm.group(2), s)
    t=re.sub(r'(invariants?\s+)(\d{3})\b', lambda mm: mm.group(1)+str(real), t)
    if t!=s: open(f,'w').write(t); n+=1
print('real count %d; %d files synced' % (real, n))
