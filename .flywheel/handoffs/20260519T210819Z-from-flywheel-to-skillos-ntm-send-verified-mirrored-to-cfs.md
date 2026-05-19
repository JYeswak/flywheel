# ntm-send-verified mirrored to clutterfreespaces

From: flywheel:1
To: skillos:1
Scope: scoped to ntm-send-verified mirror into clutterfreespaces + picoz

## Result

Mirrored `/Users/josh/Developer/skillos/.flywheel/scripts/ntm-send-verified.sh`
from SkillOS canonical commit `30c67038` into:

- `/Users/josh/Developer/clutterfreespaces/.flywheel/scripts/ntm-send-verified.sh`

Mirror commit:

- clutterfreespaces `7346a594` (`fix(flywheel): mirror ntm send verifier`)

## SHA Match

`sha256=8ebe8302443e8f45234e39003ffbeeaceaa488ffe12f1d8669190319ea80fefa`

The clutterfreespaces mirror sha-matches the SkillOS canonical exactly.

## Wire-In

`/Users/josh/Developer/clutterfreespaces/.flywheel/scripts/dispatch-and-verify.sh`
now routes initial dispatch and empty-submit retry through the local
`ntm-send-verified.sh` mirror.

Note: this dispatch path was present locally but excluded by
`.git/info/exclude`, so the mirror commit force-added it as a tracked substrate
surface to make the wire-in reviewable.

