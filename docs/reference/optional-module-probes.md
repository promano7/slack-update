# Optional-module probe regression

Run from the repository root:

```bash
python3 tests/reference/test-optional-module-probes.py
```

This independent Python 3 standard-library driver invokes the real Flatpak,
SBo, ELF and Cinnamon activation probes in Bash. It also tests the real Cinnamon
installation detector separately. It does not call the boot probe or the
five-module dispatcher. The [result-priority test](result-precedence.md) separately
checks how supplied unavailable-module states affect final diagnostics/status.

## Matrix and expectations

| Selected entry | Scenarios | Supplied dimensions |
| --- | --- | --- |
| Flatpak probe | 6 | Three modes, command present/absent |
| SBo probe | 12 | Three modes, independent sbopkg/sqg availability |
| ELF probe | 12 | Three modes, independent readelf/ldconfig availability |
| Cinnamon probe | 12 | Three modes, detected installation and git availability |
| Cinnamon detector | 8 | Command, package presence and private checkout directory |

All 50 scenarios call their selected entry twice: 100 selected-entry calls.
Before each module-probe call, the driver poisons its state/run/reason and
availability fields. Exact records verify reset values, internal return status,
state, run flag, reason, all availability flags and preserved IFS. The complete
ordered discovery trace is asserted for both calls.

Disabled modes reset state and availability without querying dependencies.
Active Flatpak requires its command; SBo and ELF each require both dependencies.
Unavailable states retain the precise missing-dependency reason. Probe return 0
does not mean a module will run: state/run fields report availability separately.

Cinnamon enabled mode needs git but does not require a detected installation.
Auto needs both; when installation and git are absent, the installation reason
takes priority. Both active modes query detection before git. The real detector
short-circuits through command, package presence, then a managed checkout's `.git`
directory. Only an absent preceding result permits the next predicate.

Expected tuples, reasons and traces are authored test data. The test does not
capture reference output as its own oracle or share another test's fixtures.
The 42 module cases use a detection callback; eight detector cases use the real
function and an actual private checkout-directory predicate. Nested callback
invocations are not counted as additional selected-entry calls.

## Modeled boundaries and private filesystem use

`command -v` uses a fixed callback for the six expected command names. No
module executable is discovered or executed. The `/sbin/ldconfig` executable
predicate is modeled by a Bash test wrapper; the real installed path is not
statted or invoked. The package-presence helper is a callback, so no installed
package database or package-name parser is exercised.

For module cases, Cinnamon detection is supplied. For detector cases, the real
function uses modeled command/package presence plus a private empty `.git`
directory when selected. Its presence is unchanged after each case. Trace writes
are also private. Other path probes and selected runtime/workflow functions
abort. Source guards are not OS containment; review new calls before running
this driver against changed reference code.

Main, configuration loading, runtime initialization, boot inspection, actual
module updates and native Slackware workloads are not entered. This test does
not establish command behavior, native dependency/installation discovery, package
database semantics, boot reachability or conformance on either required platform.
Original findings, criteria, decisions and separate execution gates remain; no
schema freeze or Phase 1 completion follows from these repository regressions.
