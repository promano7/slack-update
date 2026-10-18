# Development setup and installation status

The available implementation is the shell reference. There is no released C
application, selected C build system, repository installer or Slackware package
yet. The [roadmap](roadmap.md#current-phase-and-release-gate) defines when later
implementation and packaging work can begin.

## Prepare a source checkout

Use Git to obtain the source, then inspect the reference with Bash:

```bash
git clone https://github.com/promano7/slack-update.git
cd slack-update
bash -n tools/reference/slack-update-reference.sh
bash tools/reference/slack-update-reference.sh --help
```

For an existing checkout, start in its repository root instead of cloning
another copy. These inspection commands need no root privileges or Slackware
package tools. `bash -n` checks syntax; `--help` returns before configuration
loading, root checks, lock acquisition and runtime initialization. Neither
command validates an update or completes an acceptance scenario.

Invoke the script through `bash` so inspection does not depend on executable
bits surviving an archive extraction. Do not invoke it without an operation
flag to test the checkout: the default operation is the legacy apply workflow.

## Tools depend on the task

| Task | Environment and tools |
| --- | --- |
| Read the repository and inspect shell syntax/help | Git and Bash; no C compiler or package installation required |
| Run a focused regression harness | The tools and fixtures used by that particular harness; some use Python 3 and Unix utilities |
| Perform real reference acceptance | A separately reviewed Slackware 15.0 or Slackware-current environment, its package/boot tools and scenario prerequisites |
| Build the planned C application | Future work; the build system and minimum compiler versions are not selected |

There is no single top-level build or test command for every file in this
repository. The [current integrated selection](reference/repository-regression-block-467-474.md)
lists 54 named commands; it is a bounded regression selection, not every harness.
Run it as an ordinary developer without sudo. It requires Python 3, Bash,
jq, Unix advisory locking/flock, timeout, awk and the GNU coreutils/findutils/
sed used by the individual scopes. Delivery verification helpers require
Python 3.9 or newer. The drivers use the Python standard library; supplied
package, transport and boot callbacks do not require installed Slackware tools.

The synthetic GenInitrd test supplies only the exact target-initrd UID query;
its paths, links, bytes and permission checks remain real private operations.
The current selection excludes the recorded cron mirror dependency and the
installed-initrd probe disagreement. Read their limits in the testing guide.
No claim that every historical test is unprivileged, isolated or passing follows. Use the applicable checks in
[CONTRIBUTING](../CONTRIBUTING.md#reference-script-changes). Historical checkpoint
harnesses can bind exact full source snapshots; do not run all historical
scripts indiscriminately on a later checkout.

## Configuration lookup

The reference selects configuration in this order:

1. An alternate absolute file path selected by `SLACK_UPDATE_CONFIG`.
2. `/etc/slack-update/slack-update.conf` when no alternate is selected.
3. The checkout's `data/config/slack-update.conf` when the system file is absent
   and that source-tree fallback exists.

The alternate path is intended for tests. A selected alternate that is missing
or unreadable is an error, not a request to fall back to another file. Running
from a checkout can still load an existing system configuration, so do not
assume the repository defaults are active merely because the script is local.

The [checked-in configuration](../data/config/slack-update.conf) is the current
schema-1 example. It is parsed as data, never sourced as shell code. The future
configuration shown in the [C design](design.md#planned-configuration-and-desktop-preferences)
uses a different proposed shape and is not accepted by the shell parser.

## Installation paths and runtime state

The script header documents a manual copy layout for the reference; it does
not constitute a production installer or an instruction to deploy this checkout.

| Purpose | Reference location or checked-in default |
| --- | --- |
| Manually installed reference script | `/usr/local/sbin/slack-update` |
| System configuration | `/etc/slack-update/slack-update.conf` |
| Working state | `/var/lib/slack-update` |
| Logs | `/var/log/slack-update` |
| Instance lock | `/var/run/slack-update.lock` |
| Package database | `/var/log/packages` |

Working, log, lock and package database paths are configurable. The manual
script-copy layout needs its separate system configuration; it cannot rely on
the checkout fallback being present beside the installed script.

The current reference requires root for `--check`, `--dry-run` and `--apply`
after loading valid configuration. It normalizes its execution environment,
acquires a lock and prepares runtime state/logging. Check and dry-run avoid
package/boot apply but can still write local state or logs and perform transport
probes. The future unprivileged C frontends do not describe today's shell
privilege model.

Real runs also depend on the selected operation and configuration: for example,
`flock` for locking, `slackpkg` for repository checks, `wget` for a network mirror
probe and module-specific tools for enabled work. This is not an exhaustive
dependency or native-readiness checklist; consult the source and scenario guide.

## Continue with the appropriate guide

- [Reference operations, output and results](reference-usage.md)
- [Current configuration format and modes](configuration.md)
- [Testing scope and historical snapshots](testing.md)
- [Contribution and focused verification rules](../CONTRIBUTING.md)
- [Real Slackware acceptance scenarios](../tests/acceptance/reference/README.md)
- [Contracts, audits and evidence navigation](reference/README.md)
- [Planned C architecture and interfaces](design.md)

Real acceptance runs need the scenario's reviewed scope and recoverable target.
Preparing a checkout or copying reference files does not grant a system operation
or reopen a historical authorization.
