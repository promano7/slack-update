# Configuration file resolver regression

Run from the repository root with Python 3 and Bash:

```bash
python3 tests/reference/test-configuration-resolver.py
```

The 84 scenarios source an exact-byte private copy of the reference and call
only `resolve_configuration_file`. Relocation places `BASH_SOURCE` in a private
source tree, including spaces in its directory name. Files are deliberately
not valid configuration text: this resolver selects paths without parsing them.

| Selection condition | Current behavior |
| --- | --- |
| Nonempty absolute `SLACK_UPDATE_CONFIG` | Use it, even when installed/source alternatives exist |
| Nonempty relative or tilde-prefixed override | Reject; no implicit tilde expansion |
| Missing, directory or broken-link explicit override | Reject without selecting a fallback |
| Unset or empty override, installed regular file present | Select the installed path |
| Installed file present but modeled unreadable | Reject without choosing source fallback |
| Installed file absent and private source file available | Select the source fallback with a physical parent directory |
| No usable installed file or source fallback | Reject with the installed path's missing-file diagnostic |

The matrix checks unset/empty overrides against five source states and three
installed-file models. Nine explicit override cases are checked against available
and missing source fallbacks under all three installed-file models. Expectations
include exact status, selected path and stderr, with stale `CONFIG_FILE` seeded.
Successful resolution also accepts symlinks to regular files. Explicit `..` path
components are preserved rather than canonicalized. These are current behaviors,
not new symlink or canonical-path safety guarantees.

## Test boundaries

The reference source is copied without modification. Its Bash `[` function is
replaced only for the installed path's `-f`/`-r` checks and one requested unreadable
private path; other file predicates use Bash's real builtin on private fixtures.
The harness rejects file probes outside its expected textual path prefix. Installed-file presence
and unreadability are modeled, not measured. No `/etc` configuration file is
statted, read, created or changed by the tested resolver path. The unreadable case
does not validate native permissions or root's ability to read mode-000 files.

Bash runs real private-directory `cd`, `dirname` and `pwd` operations. The harness
creates private files/directories/symlinks, checks source/input bytes remain
unchanged, then removes the temporary tree. Each subprocess has a ten-second
timeout. It calls no parser, validator, configuration application, environment
initializer, main or workflow. Function replacements are not an OS sandbox;
review future resolver calls before extending the test to changed code.

Eight private source mutations were rejected with unchanged expectations:
ignored override, selected empty override, accepted relative path, preferred source
fallback, wrong fallback location, selected missing fallback, ignored unreadability
and changed missing-file diagnostic. No defect or behavior change was found in
the actual resolver. Native Slackware acceptance, original obligations/findings,
contract alternatives, phase gates and separate execution authority are unchanged.
