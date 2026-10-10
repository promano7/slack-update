# Phase 1 step 361: read-only source inventory

Step 360 is accepted at reported commit `9a9cd12`: 81 ordered PASS, zero failures,
the exact eight-file commit with seven additions, a successful push, and reported
clean matching heads. The complete pasted message is retained as an explicitly
disclosed UTF-8 transcription with a final storage newline. No original terminal
byte stream, full commit ID, independent GitHub inspection or target-host state
is invented. The last confirmed repository-scoped strong pause remains 358.

## Implemented behavior

The new Python tool reads the four exact review sources selected by 359 under the
unchanged 360 contract. It statically copies the frozen data rules rather than
importing an inspected program. Its CLI binds the original contract and policy
metadata by exact path, SHA and size before parsing JSON, then reads only the
explicitly approved source paths. No discovery, PATH command resolution, shell
execution, source/import/eval, payload decoding, generator invocation or network
operation is performed. The tool returns a complete JSON inventory to stdout.

An absolute repository root is opened by walking directory descriptors from `/`
with `O_DIRECTORY`, `O_NOFOLLOW` and `O_CLOEXEC`. Source ancestors are walked the
same way. Final entries must be regular at no-follow stat before content opening
and at fstat after a read-only, no-follow, nonblocking, close-on-exec open. The
reader bounds declared and observed sizes, reads at most the bound plus one byte,
and rejects source/path identity or metadata drift during the read, wrong byte
counts, SHA drift, invalid UTF-8 and NUL. All descriptors close on success and
failure. These checks are bounded local observations, not a continuous native
writer fence or proof that a later executable consumes these same bytes.

All original byte, line, path, source-count and record budgets remain unchanged.
Capacity is not permission to add sources. A failure returns no successful partial
inventory. Source snippets alone may be explicitly truncated at a UTF-8 codepoint
boundary; source and full-line hashes retain the complete byte anchors. LF defines
physical lines, CRLF remains literal, and no text normalization occurs.

## Inventory and limitations

| Review source | Lexical records |
| --- | ---: |
| Reference specification | 8,080 |
| Historical v2 worker body | 1,230 |
| Historical v2 generator | 272 |
| Historical generated v2 artifact | 5,524 |
| Total | 15,106 |

The complete inventory retains all records, not just these counts. Each record
includes source SHA, one-based line number, zero-based byte offset, raw line byte
length, full raw-line SHA, bounded snippet, kind and the explicit status
`lexical-candidate-context-and-runtime-relation-unresolved`.

Nine kinds identify definition-like text, source/eval/exec names, substitutions,
redirection or pipelines, here documents, command-like names, payload markers,
variable-bearing text and trap/process-looking text. The patterns are deliberately
lexical. Comments, quoted text, here documents, foreign-language blocks and base64
lines may match. Such matches are neither executable edges nor confirmed calls.
No matches never establish absence of dependencies or effects. Stable source,
line and kind order and repeated records are retained.

The generated historical artifact is a distinct review input with an explicit
non-independent role. Its encoded copy remains encoded. Counting its text does
not count a second independent worker. Actual source versions and byte consumption
of installed interpreters, slackpkg/pkgtools, libraries, archive/install hooks,
dynamic helpers and platform primitives remain unobserved on both supported
Slackware targets. The whole native transitive graph and containment proof remain
open. Five global unresolved relation categories remain in every report, even an
inventory with no textual hints.

## Controls and evidence boundary

All eighteen required 360 control families are represented in the 361 harness.
Temporary repository controls exercise a dangerous shell sentinel that remains
unexecuted, encoded payload preservation, symlink and path refusal, special-file
refusal, encoding and bounds, observed read/stat/SHA/size drift, exact source
anchors, lexical ambiguity, unknown relations, generated-copy roles, multiplicity,
and rejection of false native authority or completeness. A separately written
literal hint-kind vector checks scanner output. CLI failure controls require empty
stdout, and descriptor closure is checked across repeated success/failure paths.

FIFO, directory and character-device rejection use actual local object metadata.
Socket-type rejection uses an explicitly modeled stat result: the initial attempt
to create a local Unix socket was denied by this execution environment with
`PermissionError: [Errno 1] Operation not permitted`. The failed attempt and the
subsequent narrower test are recorded. The harness never creates or connects a
socket. This control proves the local type-refusal branch for supplied socket
metadata; it does not prove behavior of a real socket object on a native platform.
Read-drift controls also include explicitly injected syscall-return and metadata
changes in temporary files. No such private control is a native fault observation.

The complete real repository inventory is reproduced by the public CLI and checked
against its stored byte-bound report. Stored lexical agreement is repository
progress, not an independent native oracle or operational conformance evidence.

## Retained gates and next step

All 1,823 accepted predecessor sources remain exact except additive CHANGELOG.
The inherited original contracts and normative rows retain all 16 native gaps,
46 unproven proofs, 52 unrun two-platform cases and 12 uncaptured raw evidence
groups. No actual native successor, collector, verifier, issuer, platform primitive
or live binding is selected. Host state remains unobserved; Production and Phase 2
remain closed; Phase 1 and the kernel edge remain incomplete.

No target-machine or controller action, package/refresh/reboot/restoration/native
publication or historical authority reuse is authorized or required. The scope is
repository source inspection. Later Slackware-current refresh does not invalidate
this repository work or permit reusing a historical native binding.

361 is prepared, not user-confirmed and not a new pause. After its complete user
tests, exact commit, push, clean status and matching heads are accepted, 362 reviews
entrypoints and call sites against these source anchors. README reconciliation is
still due 367; the final scoped pause at 368 remains conditional on its complete
receipt and the original pause conditions.
