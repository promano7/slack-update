# Retaining unresolved private SBo cleanup bindings

Step525 repairs the selected bookkeeping loss reproduced by the
[524 source-bound audit](sbo-workspace-cleanup-binding-audit.md). Complete supplied
actual524 is accepted first: HEAD/local origin
`1713c06049502a4fcc8e3aaf70b1cc96125d57c8`, parent
`5da5f6910955627fe6e7dd8c137427b69d59a3e0`, tree
`5534cd549b63634810eef9dee11b2434d8ab500b`, policy SHA256
`097b4526266283d836bcd55870b60afa48385dffc9147a3e58a44b0cfc81c945`.
Ordered outputs, three paths/178 additions, subject, reported push, clean local
refs and full source/mode/tree report agree. Inline output is reconstructed from
the user message, not an original terminal byte attachment or independent capture.

## Behavior and limits

When the recorded owned path is now a symlink, or its canonical path differs
from the recorded canonical path, `remove_owned_sbo_queue_workspace` still
returns1 without invoking rm. It now leaves both recorded binding fields intact.
No new variable, removal, retry loop, rebinding or external operation is added.

| Condition | Status | Binding | Removal |
| --- | ---: | --- | --- |
| Empty/unset owned path | 0 | Unchanged, including stale canonical/unset fields | Not called |
| Failed canonicalization | 1 | Both retained | Not called |
| Symlink or canonical mismatch | 1 | Both retained | Not called |
| Failed rm | 1 | Both retained | Attempted |
| Successful matching-path rm | 0 | Both cleared | Attempted |

Two direct calls with the same persistent mismatch/symlink each return1 and
recheck canonicalization. The second no longer returns0 merely because the
first discarded its bookkeeping. Caller locals/IFS and existing result handling
are unchanged. A failing rm may already have removed the resource; retaining its
binding is not proof that the resource exists. Successful rm output/status trust,
missing-path success and empty-path fast return retain their existing meanings.

Retained metadata is unresolved cleanup bookkeeping, not renewed ownership or
permission to delete a changed path. Matching canonical strings do not prove
inode identity, continuous custody or absence of races. A later matching-path
call, initialization or workspace preparation can still consume/overwrite these
fields under existing policy; this change adds no persistent quarantine record.
Top-level cleanup still ignores helper errors. Native rights, grants and actual
host cleanup are unaffected. Caller/lifecycle propagation needs separate review.

## Regression and historical expectations

```sh
python3 tests/reference/test-sbo-workspace-cleanup-binding.py
```

The32 cases are16 conditions under both ordinary direct invocation and an
explicitly conditional call with errexit enabled, each with two helper calls.
Conditions include empty/unset binding, ordinary/missing workspace, supplied
canonical mismatch, actual symlink/dangling symlink/ancestor symlink,
readlink status1/43/127 and valid stdout with43, and rm status1/43/127 or removal
followed by43. Twenty-four cases exercise persistent helper failure.

Actual private files/directories/symlinks, readlink and rm are used where not
fault-supplied. Exact NUL-framed statuses/bindings and command argument vectors,
full selected private inventory/modes/bytes/link targets, protected target
sentinel, outer local-name sentinels and IFS are checked. Only the one exact trace
path is excluded from this new inventory. Paths include spaces and an apostrophe.
Named guards and private fixture disposal are not OS containment or unprivileged,
Slackware/native, whole-host, ACL/xattr, race or atomic-snapshot proof.

Six existing drivers change only their expected two ownership fields for the
supplied mismatch case: count76, count-apply136, final-listing54, listing-apply84,
parent104 and parent-apply176. Existing status/output/order/counter/copy/build/
retained-resource expectations remain. Their old historical scope documents and
receipts retain original claims that mismatch cleared the fields. For current
source this document supersedes that narrow expectation. Their scaffolding still
excludes every `.events` name and checks named logs separately; the new driver's
single exact exclusion does not broaden those older inventories.

Six valid-shell faulty variants are rejected: exact old524 runtime; clearing just
the path; clearing just the canonical field; deleting despite mismatch; ignoring
rm error; and ignoring readlink error. Full variants and failed assertions are
retained in preparation. These same-author selected controls do not constitute
independent semantic acceptance or a historical/native mutation matrix.

Fifteen normal commands run fresh in preparation, zero reused: new binding test,
six existing SBo drivers, runtime lifecycle/logging, main setup/completion,
result precedence, instance-lock helpers and apply/dry-run JSON. Full ordered
vectors/status/stdout/stderr/source hashes are retained; actual525 must repeat
these15 commands. No full82 selection or native matrix is claimed. Audit524
remains byte-for-byte unchanged and MUST NOT run on repaired source: its hash
binding intentionally requires old523/524 runtime.

The source-control generator initially traversed one parent too far when loading
old524 and raised FileNotFoundError before creating/executing a variant. Its
first script and correction record are retained; fixing only the lookup allowed
all six controls to run. Normal runtime/driver expectations were unchanged.
The first private whitespace check compared an unborn index with an empty tree,
reporting old unchanged whitespace. Its first script/reproduced diagnostics and
correction are retained. Constructing the exact verified base tree and checking
only its current delta resolves that checker-scope error; no historical or
current source was altered to suppress the diagnostics.

The first physical packaging inventory rejected one unmanifested18,350,080-byte
0600 file before policy or ZIP creation. Its full bytes/first generator/inventory/
rejection and exact-fixture comparison are retained in preparation. It is a strict
prefix of the named exact26,424,442-byte fixture, whose complete hash agrees with
the accepted base. Origin/cause remain UNKNOWN; no test/user/copy/common-cause
inference. Only the fully saved extra was removed. Correct canonical equality is
not global/historical absence or provenance closure. This new open obligation
joins the older unknown extras and incomplete491 binary-history qualification.
Normal test records remain current: no runtime/driver/fixture changed afterward.

## Block and acceptance boundaries

Actual524 is the first accepted step in the new524-531 block;532-535 are reserves
only if required. Prepared525 is not committed or accepted on the user's PC.
The root README remains due at block end. Last confirmed outer STATIC pause523
and immutable historical records remain intact; no new pause is confirmed here.

All whole inherited conditions and original native criteria remain binding.
A new scoped pause needs complete final actual acceptance first, then separate
whole-condition/nested-original reading and new-effect/cleanup/limit review.
That final reading has not yet occurred in this block. Runtime/test improvement
is not native authority, independent acceptance or Phase1 completion. Kernel,
13 audit findings,16 native gaps,five families20 scenarios, schema1/reference-v1/
C/Phase2/production gates, incomplete491 binary history, unknown extras and their
provenance obligations remain open as previously qualified. No old source/boot/
run/grant/right is reused or renewed. Actual live bindings/native evidence stay
null and actual host state unobserved, with global closurefalse.
