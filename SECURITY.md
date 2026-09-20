# Security policy

Curb Cut exists to hold less than people expect. There is no diagnosis field,
condition words are removed before anything is saved, phone numbers are stored
only as salted hashes, and nothing reaches an employer without the person's
explicit yes. A hole in any of that is the most serious kind of bug this
project can have.

## Reporting

Use GitHub's private vulnerability reporting on this repository, or email
**curbcut@havihi.digital**. Say what you found, how to reproduce it, and what
it exposes. You will get an acknowledgement within 72 hours and an honest
answer about the fix within two weeks. Please do not open a public issue for
anything that exposes a person's data.

## Scope

The Apex, pages, agent definitions and the channel programs in this
repository. A deployed instance belongs to the org that runs it; report
instance-specific issues to that org's access desk, and platform issues to
Salesforce's own responsible disclosure programme.

## Known hardening still ahead

Kept here on purpose, so nobody has to discover them:

- The hashing salts for handles, claim codes and return codes ship in source.
  Deployments should treat org read access as equivalent to brute-force access
  on those hashes until the salts move to protected settings with HMAC, which
  is planned work.
- The guest file upload accepts any content the size gate allows; magic-byte
  validation and per-session limits are planned work.
- Inside an org, the audience gate on standing preferences ("Manager only",
  "Meeting hosts") is honored on trust and enforced by the disclosure ledger,
  not by row-level security.
