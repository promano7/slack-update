# Current SBo normalization integration570

After accepting the complete actual569 return,570 adds a separate
[111-command plan](../../tests/reference/sbo-normalization-integration-plan.json)
and [runner](../../tests/reference/run-sbo-normalization-integration.py).
It changes no runtime, existing test, support, fixture or native criterion.
The current runtime SHA256 is
`eb141d314b3a483285c6d65d430fdd5c56c7492cbf06a10723a33024ab58b8e4`.
The original [106 plan](../../tests/reference/sbo-emission-integration-plan.json)
and [runner](../../tests/reference/run-sbo-emission-integration.py) remain byte
unchanged and historical563-runtime-bound; they are not silently rebound.

## Selection and comparison

Positions1-106 retain every entire original row, ordered command vector, full
stdout/stderr/status oracle, driver hash and support identity. Positions107-111
append these unchanged introduction-step oracles in order:

| Position | Step | Current driver | Declared shared support |
| --- | --- | --- | --- |
|107|565|target-normalization-emission-status|none|
|108|566|target-normalization-inputs|none|
|109|567|normalization-publication|none|
|110|568|owner-normalization|unchanged567 publication driver|
|111|569|selection-normalization|unchanged567 publication driver|

The historical exclusions512/516/519/524/527/532/536/540/548/556 are retained;
frozen564 is added. Its historical characterization remains immutable and is
not a safety pass. Its refusal on the repaired runtime is expected.

The new plan binds the current runtime, its runner and historical106 plan/runner
by SHA256. Before and after execution, the runner checks its plan bytes, these
bindings and every driver's declared source/support hashes. The preserved106
rows are compared as entire values, not reconstructed selected fields.
The original101/96 ancestry and support declarations remain inside those rows
and original plans without re-authoring their oracles.

Each command runs freshly with captured complete stdout, stderr and return status;
timeout is240 seconds per command. A timeout or mismatch retains its complete
failed row and stops. A successful run does not infer arbitrary source trust or
OS containment from source hashes, callback guards, UID, timeouts or private roots.
No aggregate scenario count is interpreted as native acceptance.

Only position56 permits its inherited one consistent `/tmp/tmp.[A-Za-z0-9]+`
private-root substitution. Both original full outputs and both roots are kept;
no other line, diagnostic, ordering, timing text or output is normalized.
All other commands require exact complete stdout/stderr/status equality.
The per-command report preserves full expected and actual results and bindings.
Preparation and PC delivery capture separate aggregate stdout/stderr as well.
Preparation snapshots bracket the full execution before documentation finalization.
Only Markdown documentation is authored afterwards; runtime, tests, supports and
both integration artifacts stay identical to the executed snapshot. Final571
finishes documentation before its fresh integration, then collects the PC run.
The PC report/captures are written beside the overlay, outside the project tree;
retain these files with the complete terminal return, including any failure.

## Scope and limits

The [565 writer repair](sbo-target-normalization-emission-status.md),
[566 input matrix](sbo-target-normalization-inputs.md),
[567 publication paths](sbo-normalization-publication.md),
[568 owner composition](sbo-owner-normalization.md) and
[569 ABI/dry-run composition](sbo-selection-normalization.md) retain their scopes.
The567 adapter stages complete producer input before the renamed otherwise
unchanged normalizer; concurrent upstream SIGPIPE/backpressure and combined
producer failures are outside this evidence. Shared567 mechanics for568/569 are
explicit and hashed, not independent trust. Private writer faults and selected
cleanup establish no real disk-exhaustion/read/allocation/move/remove fault
composition, arbitrary successful-output trust, durability, all-resource/global
reset, owner/ACL/xattr/time restoration or whole concurrent pipeline conformance.
Disabled ABI may create/touch a target and retain stale counts/error. Ignored
caller controls can still fail later with different diagnostics/gate attempts;
not every negative control changes the final status. Counts overlap.

The fresh111 integration checks the selected repository regressions. It does not
establish a stable CLI, entire JSON/NDJSON/schema conformance, complete native
workflow, package/boot recovery, host cleanup or independent semantic acceptance.
Only the565 normalizer write gate changed runtime in this block.

## Final gate

Final571 repeats this exact plan/runner/runtime/test selection freshly in
preparation and on the PC. Complete actual571 acceptance must come BEFORE a
separate whole reading and comparison of the inherited header, every condition,
every exact nested original and all new effects, obligations, failures, cleanup
and limits. No count, digest, previous PASS or prior read flag substitutes for
that reading. Only afterwards consider qualified STATIC pause/STOP.

Last confirmed qualified outer STATIC pause remains563; actual570/new pause
pending. Preserve the entire original563 and every564+ exact delivered ZIP.
All UNKNOWN provenance/recording/incomplete491-history/IO/trust/containment/cleanup
qualifications remain open, including observed extras564/566. Phase1/kernel are
incomplete; original native scenarios/criteria/findings/gaps, unselected A/R/D,
dormant repairs, schema1/reference-v1/C/Phase2/production and fresh bounded grant
requirements remain unchanged. Native evidence/live bindings null, host
unobserved/global closure false; no native operation or old-right revival.
