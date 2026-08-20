# Phase 1 optional-module mode source remediation implementation

Step 128 consumes the narrow source authorization granted in step 127 and
applies the exact source remediation designed in step 126.

## Applied source delta

The only runtime source change is inside `probe_boot_module()` for `boot=auto`.
The historical branch that treated a partial preparation capability set as
available/runnable is removed. No replacement policy branch is introduced.
Incomplete auto layouts therefore reach the already-existing fail-closed
fallback and become unavailable and non-runnable.

The implementation does not alter either validated complete preparation layout:
`mkinitrd-managed` and `direct-generic-no-initrd` remain available/runnable in
auto mode. Capability probes are unchanged. Enabled-mode strict semantics and
disabled-mode bypass semantics are unchanged.

## Exact-delta proof

The step-128 harness does not merely inspect landmarks. It reconstructs the
pre-edit source by reinserting the exact removed branch at the single authorized
location and requires that reconstructed file to have the step-127 authorized
SHA-256. This proves that the applied runtime source delta is exactly the
consumed branch removal and nothing else.

The post-edit SHA-256 is recorded during overlay application and is then bound by
the implementation record and policy.

## Regression boundary

The repository-local regression must prove:

- `boot=auto` with `mkinitrd-managed` remains available/runnable;
- `boot=auto` with validated `direct-generic-no-initrd` remains available/runnable;
- initrd-only partial auto capability is unavailable/non-runnable;
- GRUB-only auto capability without a validated direct-generic layout is
  unavailable/non-runnable;
- auto mode with no preparation capability is unavailable/non-runnable;
- enabled mode retains strict unavailable behavior for an incomplete layout;
- disabled mode remains disabled/non-runnable regardless of capabilities;
- the configuration template and frozen 15-row contract remain byte-identical.

## Authorization and machine boundary

Step 128 consumes the step-127 source authorization. After application,
`authorization_consumed=true` and `further_source_change_authorized=false`.
No additional runtime source edit is authorized by this step.

No Slackware machine action or repository refresh is required for step 128.
Slackware 15.0 and Slackware-current remain mandatory targets for later runtime
validation. A successful step 128 advances only to
`phase-1-configuration-module-mode-source-remediation-regression-review`.
