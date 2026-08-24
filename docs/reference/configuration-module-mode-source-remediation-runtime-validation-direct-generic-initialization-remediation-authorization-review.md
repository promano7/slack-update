# Phase 1 direct-generic initialization remediation authorization review

Step 136 reviews and grants the narrow source-edit authorization designed in
step 135. It is a repository-only authorization boundary: it does not itself
modify the reference implementation, configuration template, optional-module
contract, package state, boot state, repositories, or validation machines.

## Authorized edit

The authorization is consumable only while the pre-edit reference source has
SHA-256:

`c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c`

The only authorized source delta is relocation of this existing assignment:

`GENERIC_KERNEL_LINK=/boot/vmlinuz-generic`

from inside `classify_direct_generic_boot_layout()` to immediately after the
single existing top-level anchor:

`GENINITRD_VERSIONED_INITRD_DIRECTORY=/boot`

The implementation must preserve exactly one assignment, the exact value, and
its current mutability. Adding `readonly`, changing either direct-generic
function signature, changing the classifier's explicit `generic_link` argument,
or changing any boot-layout rule is outside the authorization.

Any pre-edit source SHA-256 mismatch makes this authorization invalid and a new
review is required. The authorization is single-use: a successful implementation
must record it as consumed and must not infer permission for any subsequent
source edit.

## Preserved boundaries

The configuration template and frozen optional-module contract remain
byte-identical. The accepted step-134 failure review and step-135 design remain
unchanged. `mkinitrd-managed`, validated `direct-generic-no-initrd`, the
previously remediated `boot=auto` partial fail-closed path, enabled semantics,
and disabled semantics are not authorized to change.

Step 136 does not apply the relocation; it records `source_change_applied=false`
and authorizes only the future step-137 implementation of the exact relocation.

## Machine boundary

No Slackware-current rerun is authorized. The consumed step-132 execution slot
remains non-reusable. Slackware 15.0 remains held and unauthorized. No reboot,
package mutation, boot mutation, repository refresh, or other machine action is
permitted by this step.

A successful step 136 advances only to the repository-local remediation
implementation. The checkpoint remains independent of Slackware repository
publication state and is safe to pause.
