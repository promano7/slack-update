# Main setup failure regression

Run from the repository root:

```bash
python3 tests/reference/test-main-setup-failures.py
```

The independent Python 3 standard-library driver sources the reference in Bash
and calls its real `main` and argument parser. It extends the existing
[stable-exit regression](../../tests/reference/test-error-exit-codes.sh) with
exact ordered traces and an operation/output/descriptor matrix. It does not
replace that regression or the [real private-file loader test](main-configuration-failures.md).

## Cases and expectations

The 216 scenarios combine four operation spellings (omitted, check, dry-run,
apply), three output modes (human, JSON, events), two inherited descriptor-3
states (closed or open to a private file) and nine supplied setup outcomes:

| Supplied callback outcome | Expected main status and stopping point |
| --- | --- |
| Privilege returns 1 or 8 | Preserve that status; no lock callback |
| Lock returns 1 or 6 | Preserve that status; no trap-installation callback |
| Selected initializer returns 1 or 23 | Map to 1 after trap callback; no rotation |
| Logging returns 1 or 23 | Map to 1 after rotation; no banner |
| All setup callbacks succeed | Reach banner control, which exits deliberately with 96 |

The raw 23 values exercise normalization, not an additional stable process code.
The synthetic privilege result 1 checks forwarding and is not a claim that the
current native privilege helper produces it. The 96 banner sentinel is a test
stop, not a successful workflow result. Every case checks exact status, complete
trace, empty stdout, exact callback diagnostic (or empty stderr) and empty or
absent descriptor artifact. Dry-run must select only its own initializer; the
other operations must select the normal initializer. All callbacks succeed
except the selected failure, so earlier incidental errors cannot satisfy a case.

## Replaced boundaries and limits

Environment initialization, configuration loading, privilege checking, locking,
trap installation, runtime initialization, rotation, logging and banner rendering
are replaced. The callbacks write only private trace/channel files. They do not
normalize the host environment, resolve configuration, check actual privileges,
acquire a real lock, install traps, create production runtime state or configure
real logging. In particular, this does not test lock ownership/release, cleanup,
signals, file permissions, descriptor closure or logging redirection semantics.

The workflow, event, time and final-result functions abort if reached. Direct
`id` and `flock` calls also abort. These guards and the exact trace detect the
reviewed boundaries; they are not OS containment against arbitrary future code.
Review new commands and effects before using this driver on changed source.
Python creates/removes private files and Bash sources the current reference;
neither the ordinary apply workflow nor a native Slackware workload is dispatched.

Failures before the banner do not produce JSON/NDJSON in the current main path,
even with structured-output flags. This suite verifies that path using callbacks;
it does not validate the actual JSON/event serializers or runtime logging setup.
The positive controls establish setup reachability only and stop before events.

This repository regression changes no reference behavior and closes no native
acceptance case. Original contracts, open findings, unselected decisions,
platform-specific evidence and separate execution gates retain their scope.
