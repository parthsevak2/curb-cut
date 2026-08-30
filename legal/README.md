# Legal pages

Source for the two documents A2P 10DLC campaign registration requires.
Published as Artifacts; the live URLs are recorded in `channels/.env.example`.

Both describe the system as actually built, not as aspired to:

- The privacy policy's central claim -- that no field exists for a diagnosis,
  condition, disability type, medical note, severity or prognosis -- is enforced
  by `tests/invariants.py`, which fails the build if anyone adds one.
- The terms distinguish `STOP` (carrier opt-out, stops all messages) from
  `DELETE`, `OFF` and `WHO` (in-conversation actions). That distinction exists
  because the agent originally told people to reply STOP to revoke a standing
  preference. STOP is a reserved carrier keyword: the message would have been
  intercepted, the person would have received a generic unsubscribe
  confirmation, and the preference would have stayed live and stayed disclosed
  while they believed they had turned it off.
