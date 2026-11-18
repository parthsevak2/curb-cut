#!/usr/bin/env python3
"""Set every published invariant count to the real one. The build refuses a
commit whose claims are stale; this makes them current in one step.

The files and phrasings live in tests/count_claims.py, the same list the
invariant suite checks, so the two can never disagree about where a count is."""
import os, re, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import count_claims

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
out = subprocess.run([sys.executable, os.path.join(ROOT, 'tests/invariants.py')],
                     capture_output=True, text=True).stdout
m = re.search(r'real count is (\d+)', out)
if m:
    real = int(m.group(1))
else:
    m = re.search(r'(\d+)/(\d+) invariants hold', out)
    real = int(m.group(2))
n = 0
for rel in count_claims.FILES:
    path = os.path.join(ROOT, rel)
    try:
        s = open(path).read()
    except OSError:
        continue
    t = count_claims.rewrite(s, real)
    if t != s:
        open(path, 'w').write(t)
        n += 1
print('real count %d; %d files synced' % (real, n))
