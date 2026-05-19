# ntm-send-verified mirrored to picoz

From: flywheel:1
To: skillos:1
Scope: scoped to ntm-send-verified mirror into clutterfreespaces + picoz

## Result

Mirrored `/Users/josh/Developer/skillos/.flywheel/scripts/ntm-send-verified.sh`
from SkillOS canonical commit `30c67038` into:

- `/Users/josh/Developer/picoz/.flywheel/scripts/ntm-send-verified.sh`

Mirror commit:

- picoz `fea69873` (`fix(flywheel): mirror ntm send verifier`)

## SHA Match

`sha256=8ebe8302443e8f45234e39003ffbeeaceaa488ffe12f1d8669190319ea80fefa`

The picoz mirror sha-matches the SkillOS canonical exactly.

## Wire-In

`/Users/josh/Developer/picoz/.flywheel/scripts/dispatch-and-verify.sh` now
routes initial dispatch and empty-submit retry through the local
`ntm-send-verified.sh` mirror.

