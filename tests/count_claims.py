"""Every place the repository quotes the size of the invariant suite.

One list, read by two tools: tests/invariants.py fails the build when any of
these numbers is stale, and tests/sync_counts.py rewrites them in one step.
Keeping both on the same list is the point. The count drifted twice while the
check watched two files and the sync tool watched five different ones.

Deliberately absent: docs/story.html (a dated article, 25 September 2026,
whose "now" is that day) and docs/hackathon/ (the record as judged).
"""
import re

FILES = [
    'README.md',
    'CONTRIBUTING.md',
    'CI.md',
    '.github/workflows/invariants.yml',
    'docs/TECHNICAL-DESIGN.md',
    'docs/index.html',
    'deck/build.js',
    'force-app/main/default/pages/docs.page',
]

# Each pattern has exactly one group: the three-digit count. Written narrowly
# on purpose, so "517 checks, against the live pages" (accessibility) can sit
# on the same line as the invariant count without being mistaken for it.
PATTERNS = [
    re.compile(r'(\d{3})\s+(?:structural\s+)?invariant', re.I),
    re.compile(r'invariants?\s+(\d{3})\b', re.I),
    re.compile(r'invariants\.py`?\s+(?:#\s*)?(?:runs\s+)?(\d{3})\s+(?:structural\s+)?checks', re.I),
    re.compile(r'same\s+(\d{3})\s+checks', re.I),
    re.compile(r'(\d{3})</td>\s*<td>\s*structural invariants', re.I),
    re.compile(r"""(\d{3})['"],\s*['"]structural invariants""", re.I),  # deck table rows
]


def claims(text):
    """Yield (start, end, number) for every quoted count in text."""
    seen = set()
    for pat in PATTERNS:
        for m in pat.finditer(text):
            span = m.span(1)
            if span not in seen:
                seen.add(span)
                yield span[0], span[1], int(m.group(1))


def rewrite(text, real):
    """Return text with every quoted count set to real."""
    spans = sorted(claims(text), reverse=True)
    for start, end, _ in spans:
        text = text[:start] + str(real) + text[end:]
    return text
