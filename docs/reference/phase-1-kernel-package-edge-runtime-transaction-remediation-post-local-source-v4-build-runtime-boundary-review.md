# Phase 1 step 296 — post-local-source-v4 runtime boundary review

## Accepted checkpoint and preserved evidence

Consume confirmed step 295, commit prefix `eac059c`, full
`PASS (263 passes, 0 failures)`, completed commit/push and clean tree.
No full commit ID is invented. Step 288 remains the historical strong-pause
checkpoint. Preserve accepted fifty-field observation/provenance and all source,
builders, executors and failed-runtime evidence. Step-294 observation authority
is consumed and transport/remaining operational rights are closed; no new action.
UUID `a5430a61-c988-4d52-9d5c-f20bb0a04016` describes the returned invocation only, not a
current or continuously preserved boot. Original stream bytes were not supplied.

## Source identity and metadata compatibility

Review accepted v4 root `/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4` and exact file URI.
Manifest SHA `a4b0fc122c6274c7fdf70907661511bcf6ba475a2aa3bc46b96e5bcbf6ed3db8`, sidecar SHA
`7cd7b99c730f388ddc949d22ad5ed98da703ea8050dfa31dc11456683f2176fc` and target SHA `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`
remain required. Keep all eleven files, six directories, seventeen non-root
entries, safe paths, owner 0:0, 0444/0555 modes, five priority trees, FILELIST,
compatibility marker and absence of temporary build roots. Inputs remain read-only.
The `.asc` marker authenticates nothing; SHA bindings anchor source identity.

The accepted root-cause review identifies why tagged v3 MD5 records yielded an
empty fresh pkglist: the package path was not the last field and the line did not
end with a package extension. V4 uses untagged `<32 lowercase hex><two spaces>path`
records, nine eligible bindings. The historical v2 source guard still expects
tagged records and v3 paths/manifests. Replacing a root string alone is insufficient;
a later separately reviewed executor must validate the complete v4 checksum format.
Building and observing v4 does not prove runtime pkglist generation or candidates.
No current pkglist SHA, current candidate count or candidate-binding file is claimed.

## Future same-transaction candidate gate

A later authorized transaction must own fresh WORKDIR/TEMP and absent pkglist
before local refresh. Require regular non-symlink nonempty pkglist afterwards,
refresh exit0, and absence of case-insensitive human-spaced `Error downloading from `
in both streams. Exit0 alone is insufficient; no old pkglist/candidate evidence reuse.

Every nonblank package row must have the eight exact target fields:

```text
slackware64 kernel-headers 6.18.45 x86 1 kernel-headers-6.18.45-x86-1 ./slackware64/d txz
```

Require exactly one such candidate, no duplicate/missing/unexpected header,
install-new, non-header or boot-package candidates, no malformed/extra/traversal row.
Bind pkglist SHA and source manifest/target SHA inside that same transaction; recheck
artifact bytes before binding/apply. This eight-field contract is a future gate,
not an assertion that Slackpkg already emitted that row from v4.

## Future executor, restoration and authority gates

Historical v2 remains immutable at SHA `deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d` and is
only a review input. It retains old v3/boot bindings and must not be sourced,
transported or rerun. Reserved separate future artifact: `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor.sh`.
It is absent, has no SHA and no implementation/transport/execution authorization.
No production source is created or patched by this step.

Later work needs separate executor design/implementation review and freeze,
fresh target/source revalidation, new single-attempt authorization and immediate
preflight. Preserve the same uninterrupted boot of that future authorized binding;
do not use the consumed 294 UUID as a new grant or substitute UUID on drift.
Future preflight must validate all preserved guards and absent new transaction
paths. Predecessor artifact availability has not been observed in this step;
its SHA/type and any bounded staging must be separately validated/authorized.

Install backup/cleanup traps before first mutation. Isolate temporary Slackpkg
configuration/workdir/cache; keep refresh and reference apply without external
network. Reference apply is reachable only after exact candidate binding and later
reviewed payload/config identities. Restore accepted header/package names, Slackpkg
configuration/mirrors/state, GenInitrd and boot exactly. Record every stage stream,
exit and cleanup outcome. Publish success only after restoration invariants;
partial/failure output is never success. Package/evidence/publication paths and
rollback mechanics still require later detailed executor review; no write granted.
Never repair accepted source/evidence or manually clean them to obtain PASS.

## Repository acceptance and continuation

Bind all 1256 accepted predecessor files and exact step-295 CHANGELOG tail.
Rerun complete full263 acceptance, which includes full180/full232/full250 and
historical full206. Exercise only an exact pure review oracle on synthetic text/
contract state, extracted through AST without helper module actions. These tests
prove gate semantics, not a production selector or live Slackpkg behavior.
No executor is sourced/executed, candidate bound, pkglist refreshed or VM contacted.

Open only boundary freeze at step 297. No runtime attempt is planned in 289–298;
strong pause needs that freeze and authority/effect closure at 298, with user
checkpoint confirmation. `machine_action_required=false`,
`controller_action_required=false`, `pause_safe=false`, `strong_safe_pause=false`.
Phase1 matrix/kernel-package-edge remain incomplete. Next: `phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-freeze`.
