# Phase 1 step 294 — post-local-source-v4 fresh target/source observation authorization

## Accepted implementation and new conditional grant

Consume confirmed step 293, commit prefix `c1482cb`, complete
`PASS (232 passes, 0 failures)`, completed commit/push and clean tree.
No full commit ID is invented. Step 288 remains the historical strong-pause
checkpoint. Preserve the entire frozen design/implementation and every accepted
source/evidence file. No production code changes in this authorization step.

Grant one new read-only observation, conditional on applying/accepting this overlay,
committing/pushing it, a clean user checkout and review of that complete return
before controller release. No invocation or transport has been issued/performed
in this repository preparation. True operational flags are conditional grants,
not an assertion of current release, current machine state or completed execution.

Bind target `vbox-slackcurrent.vbox-slackcurrent.org`, x86_64, kernel 6.18.45,
Slackware 15.0+, exact package database and frozen records/configuration/source.
Bind only `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-fresh-target-and-source-revalidation-probe.sh`, SHA `4d1bc852cf0bfea9b5131687bbe5cf70703cae04ae73a342a4afc7192a8440db`,
with exactly `--observe-post-v4-build-fresh-target-and-source-revalidation` through `sudo bash --`. Transport only that probe to the
bound VM user Downloads. Verify regular non-symlink type and exact SHA on Arch and
again on the VM; no executable bit or chmod is needed. No builder or executor copy.

Read a canonical UUID freshly from the kernel. No boot argument is supplied,
no historical binding is reused, and a freshly read equal UUID is allowed.
Preserve all frozen guards: target/database/header/generic, no huge/modules,
Slackpkg configuration/state, staged target, accepted v3, failed-v2 evidence,
boot/GenInitrd, accepted v4 manifest/sidecar/tree/owner/modes/content/FILELIST,
non-authenticating compatibility marker and absent temporary outputs.
The builder SHA field is frozen repository context, not a transported/observed builder.

## Single-use controller protocol and allowed effects

One sudo/probe invocation consumes the grant on success, sudo/preflight failure,
probe failure or interruption. No automatic/manual retry or constant/UUID change
is allowed. Transport/hash failure stops for review before invocation; do not repair
or retry this procedure without a new review. No target persistent attempt marker
is added; the controller protocol enforces single use. Never infer spare authority
from absent PASS or incomplete output. No historical probe or runtime rerun.

The probe performs read-only checks. No writes to acceptance roots, source, manifests,
failed-runtime evidence, packages, Slackpkg, configuration or boot are authorized.
Controller transport writes only the exact probe outside acceptance roots. Controller
capture creates one new directory in VM Downloads and exactly probe.stdout,
probe.stderr and probe.exit-code. These explicit evidence writes are outside the
preserved tree and are distinct from probe effects. No capture cleanup is authorized.
Atime, sudo/audit logging and controller capture are not asserted unchanged.
User-mediated transfer of that single probe is allowed; package/repository network
access and probe network access remain closed. No build/package/Slackpkg/configuration/
boot/reboot/cleanup/chmod/Phase2 action or new runtime authority is granted.

## Return capture and effect review

After repository acceptance has been returned and controller release issued,
the reviewed transport block is:

```bash
cd /home/promano/GitHub/slack-update
PROBE='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-fresh-target-and-source-revalidation-probe.sh'
[[ -z $(git status --porcelain --untracked-files=all) ]] &&
[[ -f "tools/reference/$PROBE" && ! -L "tools/reference/$PROBE" ]] &&
printf '%s  %s\n' '4d1bc852cf0bfea9b5131687bbe5cf70703cae04ae73a342a4afc7192a8440db' "tools/reference/$PROBE" | sha256sum -c - &&
[[ ! -e "/home/promano/Descargas/$PROBE" && ! -L "/home/promano/Descargas/$PROBE" ]] &&
cp -- "tools/reference/$PROBE" /home/promano/Descargas/
```

If a destination file already exists, stop and report it; do not overwrite, remove
or change permissions. Transfer the verified copy through the normal VM mechanism.
Only on the bound Slackware-current VM, after release, run this block once:

```bash
(
    cd -P -- ~/Descargas || exit
set -euo pipefail
export LC_ALL=C
PROBE='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-fresh-target-and-source-revalidation-probe.sh'
[[ -f "$PROBE" && ! -L "$PROBE" && $(readlink -f -- "$PROBE") == "$PWD/$PROBE" ]] || { printf 'ERROR: missing or unsafe frozen probe\n' >&2; exit 1; }
printf '%s  %s\n' '4d1bc852cf0bfea9b5131687bbe5cf70703cae04ae73a342a4afc7192a8440db' "$PROBE" | sha256sum -c -
observation_return_dir=$(mktemp -d "$PWD/slack-update-step294-observation.XXXXXXXX")
printf 'observation_return_directory\t%s\n' "$observation_return_dir"
if sudo bash -- "$PROBE" --observe-post-v4-build-fresh-target-and-source-revalidation > "$observation_return_dir/probe.stdout" 2> "$observation_return_dir/probe.stderr"
then
    observation_attempt_exit_status=0
else
    observation_attempt_exit_status=$?
fi
printf '%s\n' "$observation_attempt_exit_status" > "$observation_return_dir/probe.exit-code"
cat -- "$observation_return_dir/probe.stdout"
cat -- "$observation_return_dir/probe.stderr" >&2
printf 'post_v4_revalidation_attempt_exit_status\t%s\n' "$observation_attempt_exit_status"
)
```

The directory is printed before invocation so interrupted output can be recovered.
The probe exit code is captured directly without a pipeline; the shell block's final
status is not used as the probe result. Captured stdout/stderr are displayed in
sequence, not reconstructed in original interleaving. Return all three original
files, or the complete display plus the explicit exit status; preserve even empty
stderr and all available files on failure/interruption. Do not rerun to recover
missing output. Success requires exit0, empty stderr and all fifty exact unique
ordered real-tab fields with frozen identities, fresh UUID and nine no-effect fields.
Validate actual returned data before declaring observation acceptance.

Repository tests syntax-check both command blocks. They exercise the exact VM body
after its fixed Downloads cd in temporary fixtures with the actual frozen source
hash and mocked sudo only. They never call production main/host guards or mutate
production constants. Full232 accepted predecessor acceptance is mandatory before
publishing authorization metadata, including its full250 synthetic suite.

On success route to `phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-freeze`; on failure/interruption route to
`phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-failure-result-review` without retry. Complete returned output/exit/effects review and
consumption/revocation of all remaining probe/transport authority precede any
freeze or strong pause. PASS is point-in-time evidence, not an atomic snapshot,
continuous preservation guarantee or runtime authorization.

`machine_action_required=true`, `controller_action_required=true` describe the
conditional pending observation/result review after repository acceptance.
Until release no machine command is to be run. `pause_safe=false`,
`strong_safe_pause=false`. The 289–298/optional 299–300 route stays provisional;
no runtime attempt is planned. No success/current boot/target preservation is claimed.
