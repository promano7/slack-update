# Mirror resolver and ChangeLog probe regression scope

Run from the repository root:

```sh
python3 tests/reference/test-mirror-probe.py
```

The driver calls real `resolve_active_slackpkg_mirror`,
`probe_slackpkg_mirror_changelog` or `check_slackware_updates`. It uses the real
whitespace helper, private mirrors/ChangeLog files and real shell readability
predicates, except for two explicitly modeled denial profiles. Command discovery,
`wget` and `slackpkg` execution are supplied callbacks; no network request or
installed package command runs. Normal main, workflow, summary and event paths
are excluded.

## Scenarios and observations

There are 28 resolver profiles, 198 probe scenarios and 240 check-helper scenarios.
Each top-level entry runs twice with reset stale state in a fresh Bash process:
466 scenarios and 932 top-level entries. Nested resolver/probe calls are not
counted as additional top-level entries. The test asserts exact stdout/stderr,
raw function returns, active mirror and diagnostics, check status/error, timeout,
IFS, seven outer variables shadowed by helpers and complete ordered callback/
readability traces. Private files, directories and symlinks must remain unchanged;
only the trace file is excluded from the inventory comparison.

The resolver profiles include blank/comment-only input, HTTP/HTTPS/FTP, CRLF and
outer whitespace, an unterminated final line, multiple/duplicate active lines,
comments alongside one mirror, literal inline-comment text, unsupported/uppercase/
relative locations, local paths with spaces, `file://`, missing/modeled unreadable
files, private symlinks and a literal shell-looking location. The last is data
passed in a single argument; it is not evaluated. No broad injection-safety or
URL-validation claim follows from this one supplied input.

Each of the ten supported remote profiles crosses two discovery outcomes,
three supplied transport statuses (0/4/255) and three timeouts (1/15/90).
Other probe profiles use one default transport state. For eight selected profiles,
check-helper cases cross two slackpkg discovery outcomes, five raw check statuses
(0/100/1/20/255) and three supplied transport profiles. Some fields deliberately
remain unused after an earlier rejection. These combinations exercise ordering,
not native reachability or installed command semantics.

The independently authored active values, ChangeLog targets, rejection categories
and expected argument vectors require these current distinctions:

- Resolver state resets before reading. Exactly one nonblank/noncomment line
  is required; identical duplicate active lines still count as multiple mirrors.
  CRLF/outer whitespace are trimmed, while inline comments remain literal text.
- The probe appends `ChangeLog.txt`, removing only one trailing slash. Supported
  remote locations require discovery before the supplied `wget` call with exact
  `--spider --quiet --timeout=VALUE --tries=1 -- TARGET` arguments. Any supplied
  nonzero transport result becomes a probe failure with its own diagnostic.
- Local and `file://` targets use readability only. A readable empty file,
  directory or private symlink is accepted by the current predicate. Missing,
  broken-link and modeled denial cases fail. This does not validate file type,
  ChangeLog content, safe containment, freshness or repository authenticity.
- The resolver accepts a single unsupported location as text; the probe rejects
  it. Supported scheme spelling is case-sensitive. Private mirror-file symlinks
  are followed; no native source-trust guarantee is inferred.
- A missing slackpkg command stops before mirror resolution and preserves stale
  mirror fields because those helpers were not called. Mirror rejection maps to
  check status69 and stops before the supplied slackpkg action. Check status0/100
  returns success; raw1/20/255 retains the raw status but returns failure. The
  current check-20 projection does not alter native install-new/upgrade criteria.

Denial profiles use a supplied negative readability result for an existing private
regular file, independent of root/nonroot permission semantics. Missing paths,
regular files, directories and private symlinks use real predicates. Guards allow
only the two expected private readability paths; they are not OS containment.

## Sensitivity and related checks

Fourteen syntax-valid private source mutations are rejected on one full-matrix
row each, two entries per row, using the unchanged driver. They cover resolver
active/error resets, trimming, comment exclusion, exact-one counting and final
line handling; probe target/scheme/discovery/transport/timeout/local predicates;
and check-helper mirror-before-command ordering and raw100 acceptance. These are
focused controls, not fourteen complete matrix reruns.

The first timeout mutation control unexpectedly passed because its selected row
had missing wget discovery, so the mutated timeout argument was never used.
Retain the initial runner/log and select a row with available wget, successful
transport and timeout15 for the corrected control. The test/reference are
unchanged; no clean-first-attempt sensitivity claim is made.

Keep [check orchestration](check-workflow.md), [check JSON](check-json-result.md),
[dry-run workflow](dry-run-workflow.md), [main completion](main-completion.md) and
[stable exit codes](../../tests/reference/test-error-exit-codes.sh) for their
separate callback/result/serialization boundaries. A probe is not an update
transaction, a main/application status or native acceptance.

Original native criteria, open findings and unselected alternatives remain
binding. Phase 1/kernel are incomplete; schema1/reference-v1/C/Phase2/production
remain closed. Separate specification/impact review, explicit migration if norms
change, actual composition binding, independent safe whole review, fresh bounded
native authority before effects and later platform conformance remain due.
Actual host state and global cleanup are not observed; no historical binding or
execution right is renewed by this private regression.
