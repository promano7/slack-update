# Private instance-lock regression

Run from the repository root on Linux, without root:

```bash
python3 tests/reference/test-instance-lock.py
```

The Python 3 standard-library driver uses Bash, the installed `flock` command
and Python's Unix `fcntl.flock`. It calls the real `acquire_instance_lock` and
`release_instance_lock` helpers in private child processes. It complements the
[signal cleanup test](../../tests/reference/test-signal-cleanup.sh) and
[main setup callback test](main-setup-failures.md), which cover different boundaries.

## Scenarios and observed behavior

| Cases | Count | Expected behavior |
| --- | --- | --- |
| New/existing lock file, child exit 0/17 | 4 | Real acquisition, release, repeated release, reacquisition; process exit releases the final held lock |
| Holder and contender | 1 | Second process returns 6 promptly with closed descriptor; after release it can acquire; the old holder cannot release the new holder's lock |
| Missing parent, directory target, nondirectory parent | 3 | Opening fails with 1; descriptor stays closed; later release remains safe |
| Modeled missing command | 1 | Return 1 before opening the lock file, preserving its supplied contents |
| Modeled unlock-command failure | 1 | Real acquisition followed by supplied unlock failure; descriptor close still releases the lock and repeated release is inert |
| Unowned descriptor open/closed, ownership flag zero/unset | 4 | Repeated release closes descriptor 9 without creating a missing lock file or inventing ownership |

The 14 scenarios make 41 helper calls. A separate Python file description probes
the actual kernel lock nonblockingly while the Bash process remains alive. The
holder/contender exchange uses stdin/stdout handshakes, without sleep-based race
assumptions. Each helper reply has a five-second deadline; child exits also have
a deadline. Failure cleanup targets only the private child process groups.

Replies assert status, ownership flag, descriptor state and the modeled failed
unlock count. Tests also check exact helper diagnostics, relevant C-locale Bash
open-error text, unchanged unrelated/parent-file bytes and lock inode retention.
Normal acquisition uses `>` and clears existing lock-file contents; preserving
those contents is not a promised behavior. Release leaves the lock file present.
An unset ownership flag remains unset after unowned release.

## Real operations and modeled failures

Normal acquisition, contention, release, retry and process-exit release use the
real installed `flock` and actual private files. A separate Python lock probe
provides an independent observation of availability in this test environment.
It is not independent project acceptance or evidence from either Slackware target.

Two explicit model boundaries cover errors: missing-command mode replaces only
the `command -v flock` result, while unlock-failure mode delegates acquisition to
the real binary and supplies status 23 for `flock -u`. Status 23 is an injected
command failure, not a new stable process code. Closing descriptor 9 must still
release that real lock after the modeled unlock failure.

Source declarations are loaded without main. The driver prohibits main, runtime,
configuration, root checking, trap installation and workflow cleanup functions.
It does not install application traps or call a native Slackware workload. The
existing signal regression separately exercises real signals and cleanup in its
own private fixtures. The new test's emergency process-group cleanup is test
infrastructure, not evidence of application signal-cleanup behavior.

These checks do not establish production path containment, symlink/hardlink
policy, owner/mode correctness, unwritable-file behavior under another UID,
distributed-filesystem locking or resistance to arbitrary source changes. Guards
are not OS containment; review new calls/effects before running changed source.
No production lock path or target configuration is used. Original native cases,
findings, phase gates and separate platform/run execution scopes remain unchanged.
