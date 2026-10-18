# Private boot artifact validation regression

Run `python3 tests/reference/test-boot-artifact-validation.py` when changing
kernel-version filtering, mkinitrd scalar parsing, installed-version selection,
output precedence or generated GRUB candidate validation. Requirements are
Python 3.9 or newer, Bash, awk and chmod on Linux. The test sources the reference
without calling main. It uses authored private files and real helpers, with a
supplied `grub-script-check` callback and command-discovery result.

| Boundary | Entries | Main checks |
| --- | ---: | --- |
| Safe version token | 20 | Exact raw status, separators, whitespace, shell syntax and opaque allowed tokens |
| mkinitrd scalar reader | 44 | Two requested keys, exact value/error/status, comments, exports, quoting, duplicates, missing files, symlink and unterminated final line |
| Installed kernel resolver | 12 | Real package parser, record count, unique version, duplicate records, archive/path spellings and malformed records |
| Initrd output resolver | 10 | Primary/legacy/default precedence, malformed primary blocking fallback, missing file and absolute-path check |
| GRUB candidate validator | 34 | Candidate shape, mode change, discovery order, callback vector/status, version selection and actual text path readers |

Each call checks raw return and selected output globals through a NUL-delimited
packet, with exact empty stderr and preserved caller IFS. The expected results
come from authored fixtures rather than importing or evaluating the reference
function text. Mutation preparation is separate from the shipped driver.

## Reader behavior and limits

The safe-version predicate is a token filter, not a semantic kernel-version
parser. Tokens such as `-`, `_` and `...` are currently accepted. The scalar
reader does not source its input: authored command substitution and backtick
text is rejected, and the private execution marker remains absent. It trims
lines, supports a leading export and strips comments before quote processing;
therefore a hash inside a quoted value does not behave like shell quoting.
An unterminated final input record is read. A repeated requested key fails even
if the values match, while a prior successfully parsed value remains observable
on the duplicate failure. Missing, directory and malformed inputs have distinct
authored diagnostics. A regular-file symlink is followed by these readers.

The installed-version resolver uses the real package-record parser. Repeated
records of one version increase its count and can succeed, including different
architectures. A second version is ambiguous. These checks establish neither
package ownership nor actual installed package-database state. A successful
direct resolver call preserves its preexisting `INITRD_VALIDATION_ERROR`; its
caller remains responsible for initialization. The output resolver likewise
preserves that error on success. Primary parse errors block legacy/default
fallback. An absolute value containing `..` is accepted without canonicalization
or output existence checks. These implementation observations do not amend the
native acceptance criteria or approve failure-handling semantics.

## Generated GRUB candidate behavior

Candidate validation rejects missing, directory, symlink and empty candidates.
On an ordinary nonempty file it performs real private chmod to 0600 before
checking for the validator. The mode change remains even if discovery or the
supplied validator fails; candidate bytes remain unchanged. Callback statuses
23 and 126 remain both the raw return and validation status, distinct from the
stable application exit-code mapping. Discovery and validator argument/order
are checked independently of the text-path reader assertions.

For a direct-generic layout, the real path readers inspect linux/linuxefi and
initrd/initrdefi lines using awk. Both `/boot/...` and their alternate `/...`
spellings are exercised, including multiple initrd fields. Post-transition
version takes precedence over a deliberately different fallback; an empty
post-transition version uses the fallback. Unsafe version and wrong initrd
basename fail. The initrd-state path is checked by basename, while candidate
references can use the configured named initrd or versioned initrd spelling.
This does not bind actual artifacts on disk.

The readers search the candidate globally. A fixture with the kernel in one
menuentry and the initrd in another currently passes. Unknown layouts bypass
the direct-generic content checks after the supplied syntax callback succeeds;
a direct-generic layout with unknown transition state requires a kernel path
but not a generated initrd line. These are bounded text-validation observations,
not evidence of paired boot entries, syntactic GRUB validity or bootability.
The test never calls an installed GRUB checker, generator or initrd builder.

## Repair 1: synthetic GenInitrd ownership fixture

The original step473 application failed on the user's machine before staging,
commit or push. The new artifact driver, direct-generic policy and private GRUB
transaction tests passed. The existing generated-initrd post-state test then
failed its first positive validation and aborted on an unset INITRD_OK. The
complete original delivered material and supplied interrupted return are retained.
There is no accepted actual473 final commit or report from that attempt.

The fixture creates an initrd as its caller, while real transition validation
requires UID0 ownership. The original suite passed here under UID0. Supplying
UID1000 to the exact initrd ownership query reproduced the same assertion sequence
and nounset abort; an added private diagnostic identified the root-owner guard.
This was a supplied-result reproduction, not an actual unprivileged run: the
available environment denied an attempted UID switch. It does not independently
observe the ownership of the user's now-cleaned temporary file.

The repaired synthetic test supplies a UID result only for the exact four-argument
`stat -c %u -- TARGET_INITRD` request. All other stat queries, including real
permission bits, use the installed command. The fixture's first positive models
UID0. Six added checks then require rejection of supplied UID1000, invalid state,
failure status, the exact root-ownership error, an unsatisfied initrd flag and
successful revalidation after restoring supplied UID0. INITRD_OK starts at zero;
failed positive assertions now show the transition validation error. The suite
has 52 checks. No sudo, chown, installed initrd or relaxed reference guard is used.
The callback is explicitly synthetic and is not native ownership conformance.

The revised delivery applies only to the exact original473 pending tree with
accepted HEAD472 and an empty index, or can be applied normally to the clean
accepted472 checkout. The user's interrupted attempt used the former state.
The repair verifies every original pending source byte/mode/path and the exact
HEAD/tree before writing the reviewed five-path postimage. It does not discard
unrelated changes. File replacements are individual; whole-transaction atomicity
is not claimed. The original failed473 report remains pending, not accepted.

## Other boundaries

The passing normal selection also runs the existing direct-generic policy,
private GRUB transaction, generated-initrd post-state, initrd-blocks-GRUB,
boot coordinator, module policy and apply JSON regressions. They retain their own supplied
operations, fixtures and scopes. No original native boot acceptance scenario is
closed by this selection. The earlier cron failure remains recorded in the
runtime/logging scope and its delivery; this step does not rerun or repair it.

An initial attempt also ran `test-initrd-installed-kernel.sh`: 69 checks with
one failure. The test deliberately supplies an absent GRUB directory and expects
the auto boot module to be available from the mkinitrd capability alone. The
current real probe sets a managed layout only when both initrd and GRUB are
available, so it reports unavailable. This expectation/implementation disagreement
is unresolved; neither the original assertion nor the reference is changed.
Its complete failing output and relevant source excerpts remain in this delivery.
It is outside the final eight passing commands, not a passing or closed native
scenario. Static repository regression is not a claim that every historical
test passes. Final block documentation must carry this limitation forward.

The new driver does not cover chmod faults, actual unreadability under another
user, descriptor races, concurrent replacement, installed-command conformance,
all parser inputs or native artifact composition. Named guards are harness
checks, not OS containment or a complete call-graph proof. Real private files
and permission changes are effects. Python-owned temporary cleanup does not
prove reference cleanup, atomic snapshots or global host absence of effects.

Ten syntax-valid private source mutations are rejected: version separator,
duplicate scalar, key selection, version ambiguity, output precedence, absolute
output, empty candidate, candidate permissions, raw validator return and the
direct-layout version guard. This finite sensitivity check is not exhaustive.

Phase 1 and kernel work remain incomplete. The current block opens no native
authority. Actual native evidence and live bindings remain null, actual host
state unobserved-not-claimed-absent and actual global host closure false. A new
strong STATIC repository pause remains conditional on the final actual return
and a separate review of every whole inherited condition.
