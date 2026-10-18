# SBo coordinator regression scope

Run from the repository root:

```bash
python3 tests/reference/test-sbo-workflow.py
python3 tests/reference/test-sbo-queue-files.py
bash tests/reference/test-sbo-personal-queue-protection.sh
bash tests/reference/test-sbo-dependency-order.sh
bash tests/reference/test-sbo-options.sh
python3 tests/reference/test-apply-secondary-workflow.py
python3 tests/reference/test-result-precedence.py
python3 tests/reference/test-sbo-option-json.py
```

The new standard-library Python driver sources the current Bash reference without
calling `main()`. It calls the real synchronization, core-queue, ABI-extension,
generation-ready gate and final submission coordinators. Discovery, `sbopkg`,
`sqg`, path resolution, private workspace/configuration preparation, collectors,
final merge and ELF recheck are supplied callbacks. These callbacks record exact
argument vectors and write only their authored private list files.

Real Bash file/directory predicates, redirections, `rm`, `touch` and `wc` operate
on owned private files. The current test does not exercise the real resolver,
copy/configuration engine, package database, queue parsers or ELF inspector.
Named guards prohibit updater/main/network/boot entries and unrelated commands;
they are not an OS sandbox. Supplied inconsistent states can isolate helper
branches without representing reachable or authorized native states.

## Independently authored expectations

| Helper boundary | Entries | Checked behavior |
| --- | ---: | --- |
| Synchronization | 54 | Missing commands, preparation stage failures, raw refresh/generator statuses, ready flag, source reset, counts and per-command environment |
| Core queue | 64 | Preselected personal/source paths, resolution failures, source presence, old-list removal, ordered/options stage failures and empty/nonempty counts |
| ABI extension | 24 | Exact trigger value, supplied installed-target outcome, absent/existing extra list and retained/replaced count |
| Ready gate | 72 | Unset/zero/one/other supplied flag, retained/default diagnostic and raw short-circuit sequencing |
| Final submission | 96 | Merge failure, empty/nonempty queue, raw builder status, option-map fallback and broken-object recheck gating |

Each entry compares full stdout/stderr bytes, raw helper return, sixteen named
state fields, ordered callback vectors, caller IFS, an unrelated scalar and the
complete private file/directory inventory except the explicitly observed trace.
Expected text, state transitions, call sequence and file bytes are authored
separately from reference execution; no reference output is used as an oracle.
It does not observe every global variable, descriptor, environment entry,
permission, ownership or xattr. Direct coreutils failures and concurrency are
outside this driver's supplied failure matrix.

Retain these observations of existing behavior:

- Synchronization can return zero after refresh/generation/preparation failures;
  raw statuses and readiness are separate fields. A failed refresh still reaches
  the supplied private-generation stages. Missing command discovery preserves
  prior statuses rather than synthesizing a new failure.
- Per-command `SBOPKG_CONF` and `QUEUEDIR` reach the generator callback and restore
  the caller's prior values. This tests shell scoping with a supplied function,
  not installed `sqg` environment/configuration semantics.
- Core construction removes old core/extra/options files before collection.
  An ordered-collection failure leaves those selected private files absent;
  an option failure can leave the newly collected core. Resolution failure
  occurs before deletion. No transaction or native recovery guarantee follows.
- Only ABI trigger 1 invokes the supplied installed-target collector. Other
  supplied values take the `touch` branch and retain old extra-list contents/count.
- The ready gate returns the failing core or ABI callback's raw status. The final
  submission helper can return zero after a failed builder, while preserving its
  raw status in `SBO_BUILD_STATUS`. An empty final queue retains the old build
  status. Broken-object recheck runs after a nonempty attempted build even when
  that builder failed, and a supplied recheck failure is ignored by this wrapper.

These are current helper observations, not native success, reboot or effect
acceptance. Status 20 in a supplied SBo command is a raw command result. It does
not change the native Slackpkg install-new20 empty AND no-effect requirement or
the upgrade20 failure rule. Stable result mapping and main orchestration retain
their own separate tests and original contracts.

Nine syntax-valid private source mutations reject:refresh status, generator
status, ready assignment, old extra-file deletion, selected queue source, exact
ABI trigger, ready-gate short-circuit, builder status and recheck after failed
build. Focused source controls are retained in delivery validation and are not
normal user runs or exhaustive mutation coverage. The first authoring assembly
used the wrong cwd and left definitions only; its zero return without any PASS
output was not accepted. The completed driver is the one validated here.

The related personal-queue shell regression uses real private configuration
wrappers/copies/symlinks/cleanup and supplied generators; read that script for its
own requirements. Its seven additional JSON checks run only when `jq` is found;
retain the actual count and do not claim those checks ran when absent. Separate
helper/file/workflow/serializer passes are not an actual native composition proof.

No installed SBo refresh/build, native package database, network, ELF scan or boot
operation runs in the new driver. Private file effects and cleanup do not prove
whole-host absence or global cleanup. Phase 1/kernel remain incomplete; A/R/D
unselected, schema 1/reference-v1/C/Phase 2/production closed. Original independent
specification/migration/composition/safe whole review/fresh bounded native grant
and own-platform independent conformance gates remain unchanged.
