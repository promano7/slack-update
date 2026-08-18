# Phase 1 configuration boundary review

## Purpose

Step 117 starts a fresh Phase 1 review boundary after the accepted Slackware 15.0 ELILO oldkernel cleanup closure. It inventories hardcoded assumptions in the production reference engine without changing runtime behavior or creating a configuration file.

## Scope

The inventory reviews `tools/reference/slack-update-reference.sh` and reports three evidence classes:

- uppercase shell assignments that may encode defaults or policy;
- literal system paths under `/etc`, `/var`, `/boot`, `/usr`, `/run`, or `/tmp`;
- external package, boot, and module-management command names.

A reported item is only a review candidate. Presence in the inventory never means that the item should become user-configurable.

## Classification rules for step 118

Every inventory item must be assigned to exactly one of these classes before migration begins:

1. `user-configurable-default` — safe operational policy whose default must preserve existing behavior;
2. `environment-derived` — state that should be detected rather than configured;
3. `internal-constant` — implementation detail that may be centralized but is not user-facing configuration;
4. `safety-invariant` — security/safety boundary that must remain non-configurable;
5. `deferred-module-mode` — module enablement policy reserved for the later `enabled`/`disabled`/`auto` work.

## Non-configurable safety boundary

The following must not become user-configurable during this configuration migration:

- destructive authorization gates or confirmation digests;
- accepted evidence hashes and reviewed transaction scopes;
- fail-closed validation behavior;
- target host/kernel confirmations used by acceptance boundaries;
- recovery/rollback authorization lineage;
- restrictions against unreviewed package, boot, module, or recovery mutation.

## Step 117 guarantees

Step 117 is repository-local and read-only with respect to runtime behavior. It does not:

- create or install a runtime configuration file;
- modify `tools/reference/slack-update-reference.sh`;
- perform package operations;
- refresh repositories or access the network;
- alter boot, module, or service state;
- authorize migration or destructive action.

The next stage may define a schema and behavior-preserving defaults only after this inventory has been reviewed.
