# Configuration-to-runtime assignment regression

Run from the repository root with Python 3 and Bash:

```bash
python3 tests/reference/test-configuration-application.py
```

The 288 scenarios source the reference and call only `apply_configuration`, the
in-memory configuration assignment function. This does not invoke `--apply`,
main, package management, boot preparation or any update workflow. No configuration
file is resolved/parsed and no semantic validation or environment setup is run.

Authored mappings cover all 26 copied scalar values and six package arrays.
Every target begins with stale state. The test compares every copied scalar and
every array's complete length, order and values, plus preserved schema/source
and ELF-array sentinels. It does not extract expected assignments from the subject.

| Supplied state | Coverage |
| --- | --- |
| Distinct scalar/list baseline | Detect cross-assignment or omitted destinations |
| Each scalar with special text | Preserve spaces, Unicode, tabs, newline, quotes, backslash and literal shell-like text |
| Each package list | Empty/single/multiple entries, repeated spaces, package spelling, literal backslash and tab |
| All scalars or all lists emptied | Clear earlier target values instead of retaining stale data |
| Four caller IFS values | Preserve newline/tab, space, custom punctuation and empty IFS |
| Three successive applications in one process | Change all scalars, clear all arrays, then restore original values |

There are 71 single-call cases under each IFS plus one three-call sequence per
IFS: 288 subprocess scenarios, 296 assignment calls. Every call must succeed with
empty stderr. Every Bash subprocess has a ten-second timeout. Supplied values
are passed as argv data and assigned with `printf -v`, without evaluation.

Eight private source mutations were rejected with unchanged expectations:
cross-assigned/missing scalar, wrong array source, consumed backslash, appended
array, wrong list delimiter, overwritten ELF array and overwritten caller IFS.
The actual function passed without a reference source fix.

## Limits

Some inputs deliberately bypass the validator, including empty required values
and package text outside its allowed grammar. These are assignment-function
probes, not configurations accepted by the normal loader. No package-name
normalization, semantic safety or native module behavior is established here.
The schema version and ELF path source are not copied by this function; the ELF
scan array is set by validation and must remain untouched during assignment.

This is not a workflow test, OS sandbox or native absence-of-effects proof.
Review newly called functions before running against changed assignment code.
Original historical policies, native criteria, findings/decisions/grants and
phase gates remain unchanged; Phase 1 and the later release gates remain open.
