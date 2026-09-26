# Phase 1 kernel-package-edge local-source construction builder implementation freeze

Step 206 consumes the accepted step-205 repository review and freezes the exact reviewed builder bytes as the only implementation eligible for later target execution.

## Frozen implementation

The frozen builder remains `tools/reference/phase-1-kernel-package-edge-local-source-build.sh` with SHA-256 `59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92`. No source changes are made by this step. The accepted step-205 policy, record, helper, harness, document, and builder identities are bound explicitly so any later repository drift fails closed.

The implementation contract remains unchanged: production accepts only `--build-local-source`, requires root, consumes exactly `kernel-headers-6.18.45-x86-1.txz` with SHA-256 `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`, excludes the 6.18.44 predecessor from builder input, constructs exactly one package candidate, and publishes only after deterministic validation and read-only finalization.

The repository-only `SLACK_UPDATE_LOCAL_SOURCE_BUILDER_LIBRARY_ONLY=1` seam remains test-only and does not authorize runtime path overrides. The builder remains forbidden from network access, package-database mutation, `slackpkg` configuration mutation, boot mutation, or reboot.

## Authorization boundary

This freeze does **not** authorize executing the builder, copying the target artifact to the VM, constructing the local source, refreshing repositories/candidates, changing packages or boot state, rebooting, or starting Phase 2. No machine action is required.

The only next authority is repository-only `phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-review`, which must define and review the exact fail-closed transfer/staging boundary before any artifact is copied to `vbox-slackcurrent`. The active chain remains open and `pause_safe=false`.
