# Phase 1 step 287 — fresh boot-drift single-build authorization freeze

## Accepted contract and evidence

Consume accepted step 286, user commit prefix `159f85a`, full
`PASS (149 passes, 0 failures)`, completed commit/push and clean tree. No full
object ID was supplied or invented. Supersede its prepared/pending delivery wording
without changing any accepted artifact. Preserve the exact reviewed single-attempt
contract, changing only state and its two authority-grant fields to freeze/grant it.
All invocation, effect, no-retry, observation binding and source identity fields
remain unchanged. This is a new authority, not reuse of step 278 or older grants.

Keep the accepted 41-field step-285 observation at normalized SHA
`e9be53e174808dfe9e9cdb6e35fcd4eccdbf7c220602cfc4f5cadf939c28a105` and fresh boot
`bcfac4fa-4e6e-450a-aa95-bd591a979b4e`. Preserve semantic display transcription provenance, exit0, no-effect
fields and builder SHA context. Claims describe that invocation only; no continuous
post-observation boot/state assurance is fabricated. Probe authority stays consumed.

## Conditional new one-attempt authority

First apply this overlay, pass its full harness, commit/push and confirm a clean
Arch checkout. Only then transport the two exact regular non-symlink artifacts
together to the bound Slackware-current VM Downloads directory:

- Executor `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor.sh`, SHA `43e07ebfbf2c4ddd263cfbea9214477e620901dbd391aff9ff45c23bd2e8752d`.
- Builder `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh`, SHA `38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7`.

Verify both hashes on Arch and again on the VM before the one invocation. No
executable bit or chmod is required. No new probe copy/invocation is authorized.
The same uninterrupted boot from the accepted observation must still be active.
The executor immediately checks that UUID and every frozen target/package/source/
evidence/boot/Slackpkg/GenInitrd/output-absence guard before the verified one-time
Bash builder launch. It checks the exact regular-file builder SHA again at launch.
Drift rejects before builder entry; never replace the authorization UUID to retry.

After confirmed repository acceptance and copying the pair, the reviewed VM block
is syntax-checked only in repository tests:

```bash
cd ~/Descargas
EXECUTOR='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor.sh'
BUILDER='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh'
[[ -f "$EXECUTOR" && ! -L "$EXECUTOR" && -f "$BUILDER" && ! -L "$BUILDER" ]] &&
printf '%s  %s\n' '43e07ebfbf2c4ddd263cfbea9214477e620901dbd391aff9ff45c23bd2e8752d' "$EXECUTOR" '38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7' "$BUILDER" | sha256sum -c - &&
{
    if sudo bash -- "$EXECUTOR" --execute-authorized-local-source-v4-build-v2 --authorization-boot-id bcfac4fa-4e6e-450a-aa95-bd591a979b4e
    then
        build_attempt_exit_status=0
    else
        build_attempt_exit_status=$?
    fi
    printf 'build_attempt_exit_status\t%s\n' "$build_attempt_exit_status"
}
```

Executor invocation consumes the one-attempt grant even on sudo/preflight failure,
builder failure or interruption. Absence of PASS does not preserve retry authority.
No second invocation after success or failure, manual builder launch, old executor,
chmod remediation, patched constants, error-UUID substitution or manual cleanup is
allowed. Single use is controller-enforced; no persistent attempt marker is added.
Transport/hash failure stops before invocation for review; do not repair/retry the
procedure without a new review. Return all available output and exact exit status.

## Effects, result review and closure

Permitted writes follow the unchanged builder contract: v4 root, manifest/sidecar
and builder-owned `.local-source-v4.build.*` construction/cleanup. This grants no
external cleanup or package/Slackpkg/network/configuration/boot/reboot/runtime/
Phase2 action. Accepted v3, failed-v2 evidence and all source/history remain intact.
Maintain the same VM boot and do not refresh Slackpkg during the pending attempt.

On success route to `phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-result-review-and-strong-safe-pause`. On failure/interruption route to
`phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-failure-result-review` without retry. Actual result and remaining effects must
be reviewed and all remaining transport/build authority revoked before declaring
strong pause. This authorization does not preclaim executor entry, builder entry,
success, output creation or a safe pause. Future runtime work needs fresh target
revalidation and new authorization.

The repository helper repeats full149 accepted predecessor acceptance without live
probe/host guards, executor main or production builder. No immutable source changes.
`machine_action_required=true`, `controller_action_required=true` after repository
acceptance while attempt/result review is pending; `pause_safe=false`,
`strong_safe_pause=false`. Step 279 remains the historical strong-pause checkpoint.
