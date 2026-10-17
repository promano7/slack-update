# Flatpak update wrapper regression scope

Run from the repository root:

```sh
python3 tests/reference/test-flatpak-update.py
```

The driver calls the real unchanged `update_flatpak` function. Command discovery
and the Flatpak command are supplied callbacks. It does not run installed Flatpak,
inspect its configuration, contact a remote, update any installation or invoke
normal initialization/main/apply. Only shell control flow, assignments, output
routing and private callback trace writes are real.

## Matrix and observations

Fifteen authored sequences combine one missing-command case, eight single-command
statuses (0/1/2/20/42/69/127/255) and six two-call sequences: success/missing,
failure/missing, missing/success, missing/failure, failure/success and success/failure.
Each crosses four initial status seeds (-1/0/42/255) and two command-output profiles.
There are 120 scenarios and 336 wrapper calls. Every scenario uses one fresh Bash
process for two repeats, resetting the seed before each repeat; calls within a
two-call sequence deliberately carry the actual stored state forward.

Expected stored-status sequences are authored with the profile. Assertions compare
complete ordered lookup/command argument vectors, all wrapper and supplied command
output on stdout/stderr, every raw wrapper return, selected status/module globals,
IFS and the exact private trace inventory. Paths contain spaces. The discovery
callback always writes noise to both standard channels, which the real wrapper's
redirections must suppress. The command callback optionally emits separate stdout
and stderr text; those channels must remain distinct and pass through the wrapper.

The current reference observations are:

- Discovery precedes command dispatch. A present command receives exactly
  `update -y --noninteractive`.
- A present command resets the prior status to zero, then retains the raw nonzero
  command status on failure. A later success clears a previous failure.
- Missing discovery prints the existing skip message and leaves the previous
  Flatpak status unchanged, including a failure retained from a preceding call.
- All selected wrapper returns are zero, including supplied command failures.
  The status assignment succeeds; the command result remains in `FLATPAK_STATUS`.
  This is a helper return, not the apply/main/application result or native success.
- Module activation fields and selected unrelated globals are preserved. The test
  seeds one supplied auto/running profile; it does not test native probe policy,
  every mode/run combination or callers that bypass module selection.

## Sensitivity and complementary checks

Eight syntax-valid private reference mutations are rejected using unchanged-driver
assertions on one full-matrix scenario each: success reset, raw-status retention,
discovery polarity, command arguments, missing-state preservation, wrapper-return
propagation, discovery stderr suppression and command stderr routing. A selected
scenario repeats its one- or two-call sequence twice. These are focused checks,
not eight full-matrix reruns. Neither reference nor oracle mutations ship.

Keep [optional probes](optional-module-probes.md),
[secondary apply](apply-secondary-workflow.md), [result precedence](result-precedence.md),
[apply JSON](apply-json-result.md) and
[stable exit codes](../../tests/reference/test-error-exit-codes.sh) for their
separate activation/orchestration/status/serialization boundaries. Passing these
separate checks does not establish an actual native composition or tool contract.
In particular, the raw20 observation here changes no native install-new20
empty-AND-no-effect requirement or upgrade20 failure criterion.

Guards reject known unwanted function/command entries; they are not OS containment,
independent observation or an execution-right mechanism. Private callbacks/traces
do not establish native behavior, host absence, actual cleanup or Flatpak acceptance.
Original criteria, open findings and unselected alternatives remain binding.
Phase1/kernel are incomplete; schema1/reference-v1/C/Phase2/production remain closed.
Separate specification/impact, explicit migration if norms change, actual composition,
independent safe whole review, fresh bounded native authority before effects and
later own-platform conformance remain due. No historical binding/right is renewed.
