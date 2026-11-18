# Security policy

Curb Cut exists to hold less than people expect. There is no diagnosis field,
condition words are removed before anything is saved, phone numbers are stored
only as keyed hashes, and nothing reaches an employer without the person's
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

## How codes and handles are protected

Claim codes, return codes and ledger handles are stored only as HMAC-SHA256
under a 256-bit key unique to each org. The key lives in the protected
hierarchy setting `Curb_Cut_Secret__c`, is granted in no permission set or
profile (an invariant fails the build if it ever is), never sits in a String
where a debug log could record it, and is created once by
`scripts/apex/generate-key.apex`, which never prints it. Each purpose derives
its own key, so a claim code can never be replayed as a return code.

Codes issued before a deployment set its key still match their old salted
hash, so they keep working; those older rows stay guessable from an org export
until they are revoked or closed, and new rows are not. Anyone who can read the
setting itself, meaning org administrators, can still compute codes.

Keep **Setup → Schema Settings → Restrict access to custom settings** on (it is
on by default in current orgs). In an unmanaged install, "protected" only hides
a setting from users who lack that restriction.

Guest uploads must begin with a real photo or video header (JPEG, PNG, GIF,
WebP, HEIC or HEIF, MP4 or MOV, WebM), the bytes must match the kind the person
chose, and one request holds at most five files. A refused file creates nothing
but a "Rejected" line in the ledger.

## Known hardening still ahead

Kept here on purpose, so nobody has to discover them:

- Inside an org, the audience gate on standing preferences ("Manager only",
  "Meeting hosts") is honored on trust and enforced by the disclosure ledger,
  not by row-level security.
- Claim codes and return codes can be tried repeatedly; nothing yet slows
  down somebody guessing. Codes are six characters from a thirty-character
  alphabet, which is large but not large enough to rely on alone.
- The five-file limit is per request. A visitor who opens a new request each
  time is not yet rate-limited; a site-wide cap would hand an attacker a way to
  shut the door on everyone, so this needs a better answer than a counter.

