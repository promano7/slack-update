# Static ELF metadata helper regression scope

Run from the repository root:

```bash
python3 tests/reference/test-elf-metadata.py
bash tests/reference/test-elf-architecture-resolution.sh
python3 tests/reference/test-optional-module-probes.py
python3 tests/reference/test-apply-secondary-workflow.py
python3 tests/reference/test-result-precedence.py
python3 tests/reference/test-apply-json-result.py
python3 tests/reference/test-dry-run-environment.py
python3 tests/reference/test-sbo-workflow.py
```

The new Python standard-library driver sources the Bash reference without calling
`main()`. It calls the real magic/path helpers, header and dynamic-section parsers,
cache compatibility predicate and missing-dependency classifier. Bash, AWK, `od`,
`tr`, `readlink` and `sort` operate on owned private files or supplied bytes.
`readelf` is a supplied callback: it records exact mode/`--`/object/locale arguments,
emits authored text and appends supplied diagnostics through the real redirection.
The test does not parse installed binaries or invoke the installed cache reader.

Named guards prohibit updater/main/boot/network/cache-refresh/scan entries and
unrelated commands. These guards are not OS containment. File fixtures include
ELF-prefix data, text, an inert script, short/empty files, directories, missing
paths, symlink chains, dangling/self links and an option-looking filename. Some
regular fixtures are executable, but the harness does not invoke them. A four-byte
ELF prefix is not a complete executable or a native binary-validity proof.

## Cases and independently authored results

| Boundary | Entries | Expected observations |
| --- | ---: | --- |
| Magic and path | 96 | Twelve profiles, two helpers and selected od/tr/readlink faults; canonical link result or raw rejection |
| Header parser | 68 | Seventeen text profiles, two reader statuses and empty/nonempty supplied diagnostics |
| Needed-library parser | 44 | Eleven text profiles, two reader statuses and real sorting or a supplied draining sort failure |
| Cache predicate | 189 | Nine private cache profiles, three names and seven valid/malformed identity queries |
| Dependency classifier | 560 | Five header identities, seven needed sets, four caches and separate header/dynamic reader outcomes |

Expected bytes, statuses and call order are authored separately from reference
execution. The cache oracle compares the mathematical four-field tuples; it does
not copy the AWK program. One synthetic query differs only in class, while other
queries isolate data encoding and machine. Identity labels are opaque supplied
strings, not assertions about native platforms or valid machine/class pairings.

Each entry checks full stdout/stderr, raw return, readelf callback vectors/order,
error-file append bytes, caller IFS, an unrelated scalar and private file/directory/
link inventory. Only the explicitly expected error/trace bytes may change.
It does not observe every variable, descriptor, mode, ownership or xattr. The
test's always-preseeded error file demonstrates append behavior for these supplied
messages; it is not a permissions, storage-failure or concurrent-writer test.

## Preserve current helper semantics

- Magic detection checks a regular-file predicate and four bytes, following file
  symlinks. Path resolution uses real `readlink -f` before the same magic check.
  These helpers do not establish source containment or full ELF validity.
- Header fields require nonempty class/data/machine strings. Repeated fields use
  the last value; data/machine preserve embedded colons, while class uses the
  second colon-delimited field. Unknown nonempty labels can be returned.
- Needed-library parsing is C-sorted and unique, ignores other tags and can return
  blank or unbracketed data from deliberately malformed direct reader output.
  A greedy bracket extraction takes the last bracketed value in the authored row.
- A nonzero supplied reader may emit parsed stdout while the pipeline still
  returns nonzero. The rightmost failing pipeline stage determines raw status.
  These partial bytes do not establish that the classifier accepts the metadata.
- Cache lookup requires exact name/class/data/machine. Its raw predicate does not
  verify a fifth path field or path existence. A four-column direct-input row is
  deliberately tested outside the normal architecture-tagged cache producer.
- The classifier returns 0 for a missing compatible dependency, 1 when every
  nonempty needed name resolves (including no names), and 2 for reader failure.
  It short-circuits after failed header inspection and skips empty needed names.

These observations do not amend native acceptance or declare a missing native
library, compatible Slackware installation or healthy executable. The real cache
producer, directory scanner and post-build recheck remain separate boundaries.

Ten syntax-valid private source mutations reject:magic bytes, canonical path
output, required class, data colon retention, needed-name uniqueness, each of
the three identity match fields, unreadable-object status and missing-dependency
status. These focused controls have separate delivery logs and are not normal
user runs or exhaustive mutation coverage. Initial source assembly used an
incorrect cwd-relative output path and failed before the file existed; no PASS
was inferred. The completed driver and its expanded final matrix pass.

The existing architecture-resolution shell regression requires `jq`; it uses
private files and supplied metadata/cache callbacks. The separate static-inspection
shell script also reads installed cache/binaries and has its own broader scope.
It is not part of this focused selection. Separate parser/workflow/result/JSON
passes do not prove actual native composition or own-platform conformance.

Phase 1/kernel remain incomplete; A/R/D unselected, schema 1/reference-v1/C/Phase 2/
production closed. Install-new20 still requires empty AND no effect; upgrade20
remains failure. Original independent specification/migration/composition/safe
whole review/fresh bounded native grant and own-platform conformance gates remain.
Private effects/cleanup establish no global host absence or cleanup guarantee.
