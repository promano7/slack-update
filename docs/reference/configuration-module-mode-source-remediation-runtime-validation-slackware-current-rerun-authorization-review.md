# Phase 1 step 139 — Slackware-current rerun authorization review

Step 139 closes the repository-only direct-generic initialization remediation
chain and grants a fresh, single-use authorization for one non-mutating
Slackware-current runtime validation rerun. Step 139 itself performs no machine
action.

The authorization is bound to the accepted remediated reference source SHA-256
`aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7` and the unchanged configuration template SHA-256
`4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba`. It also requires the exact accepted step-138 regression record,
policy, and locale-stable helper.

## Preserved target binding

The VM characterization accepted in step 132 remains the target boundary:

- FQDN: `vbox-slackcurrent.vbox-slackcurrent.org`;
- running kernel expected at execution: `6.18.45`;
- root device: `/dev/sda2`;
- required profile: `grub-direct-generic-no-initrd`;
- direct generic GRUB entry: `Slackware-current slack-update direct generic (no initrd)`.

The exact step-132 target-binding policy remains immutable at SHA-256
`97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6`. Its old source identity is historical and is not reused as the
execution authorization after the step-137 remediation.

## Fresh rerun harness

The step-133 authorization was consumed by the failed execution and remains
non-reusable. The old execution harness is therefore preserved unchanged at
SHA-256 `9f54d2c7d27f46e7d522a8046274d67860a5a59f455e796e467b7f6d23961d62`.

A new rerun harness is frozen at `tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun.sh` with SHA-256
`0099213437acb8184019dd4f98f63de8f1c6821924ad08f93e8ff85f4288b120`. Its runtime characterization, direct-generic probe, non-mutation
checks, evidence archive, and fail-closed behavior are preserved from the
original harness. The authorization plumbing is changed only to bind execution
to this step-139 policy, the accepted remediated source identity, and the exact
step-132 target-binding policy.

The future execution is limited to exactly one run. It forbids repository
refresh, package mutation, boot mutation, and reboot. Only the evidence
workspace under `/var/tmp/slack-update-acceptance` may be created. The evidence
archive and SHA-256 sidecar must be copied to `/home/promano` as `promano:users`
and preserved until review.

Slackware 15.0 remains held and unauthorized until the Slackware-current rerun
evidence is reviewed and explicitly releases it.

## Safe-pause boundary

`pause_safe=true`. The checkpoint is independent of new Slackware repository
publications because no repository refresh is required or authorized. If the
bound VM has changed while paused, the rerun harness rechecks hostname, kernel,
boot command line, root device, generic-kernel symlink, no-initrd condition, and
GRUB entry before invoking the runtime probe and fails closed on any mismatch.

The only next stage is `phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-execution`. That execution must not occur under any
older authorization.
