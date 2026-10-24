# Slack-Update

Slack-Update is a modular update manager being developed for **Slackware 15.0**
and **Slackware-current**. The planned C application will provide a command-line
interface, a system tray application and desktop notifications over shared
update logic, using Slackware tools without a systemd dependency.

The repository currently contains the **shell reference implementation** and
its validation material. The C application is planned work.

Current repository regressions cover CLI/configuration, workflow and result
handling, SBo queue selection and ordering, static ELF helpers, runtime logging
and private boot-artifact validation, including selected private file-operation
failure paths. See the [testing guide](docs/testing.md)
for the exact integrated selection, dependencies and known limitations. These
checks complement the remaining real Slackware acceptance work.

## Project status

**Phase 1 is incomplete.** The reference acceptance matrix must be completed
on both supported Slackware targets before `reference-v1`, the C port, Phase 2
or production use can proceed. The version 1 result schema is also pending.

Five acceptance families with 20 scenarios remain: the kernel-package edge,
boot safety failures, SBo/ELF, Cinnamon and Flatpak. The kernel operational
design also has unresolved contract and native implementation requirements.
All 13 manuscript audit findings remain open; alternatives A/R/D are unselected
and the original requirements remain binding.

The prepared [524-531 integrated review](docs/reference/repository-regression-block-524-531.md)
selects86 current repository checks, including private workspace cleanup/admission
and their lifecycle/apply compositions. Final actual acceptance and a separate
whole-condition review remain due before a new scoped STATIC pause; the last
confirmed outer pause is523. Incomplete binary history and unknown extra provenance
remain open qualifications.

See the [development roadmap](docs/roadmap.md),
[remaining acceptance inventory](tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-after-execution-control-closure.tsv)
and [unselected contract alternatives](docs/reference/phase-1-operational-joint-unselected-a-r-d-decision-brief-review.md).
Repository reviews and historical test results do not establish native
conformance or authorize another system operation.

## Installation

There is no released C application or supported production installation yet.
Development uses the reference directly from a source checkout:

```bash
git clone https://github.com/promano7/slack-update.git
cd slack-update
bash tools/reference/slack-update-reference.sh --help
```

The reference configuration is
[data/config/slack-update.conf](data/config/slack-update.conf).
It describes the required paths and module settings; the repository does not
provide an installer or a selected C build system.

## Reference usage

Always select the intended operation explicitly. **Running the reference with
no operation flag selects the legacy apply workflow and can change the system.**
Real acceptance runs need their own reviewed, recoverable Slackware environment;
see the [acceptance guide](tests/acceptance/reference/README.md).

| Option | Purpose |
| --- | --- |
| `--help` | Show supported options and configuration lookup |
| `--check` | Check repository updates without package or boot apply |
| `--dry-run` | Plan without package or boot apply |
| `--apply` | Run the update workflow, including system changes |
| `--json` | Emit the final structured result |
| `--events` | Emit provisional NDJSON progress events |

`--check` and `--dry-run` can still write local state or logs and perform
transport probes. `--json` and `--events` are mutually exclusive. The current
machine-readable outputs do not constitute a frozen version 1 result schema.

Configuration is read from `/etc/slack-update/slack-update.conf`, with
`data/config/slack-update.conf` as the source-tree fallback.
`SLACK_UPDATE_CONFIG` selects an alternate absolute path for tests.
Optional modules support `enabled`, `disabled` and `auto` modes.

### Exit codes

| Code | Meaning |
| ---: | --- |
| `0` | Success; no reboot required |
| `1` | General failure before a complete apply result |
| `2` | Partial apply or failed post-update verification |
| `3` | Critical boot preparation failure; do not reboot |
| `4` | Success; reboot recommended |
| `5` | Success; reboot required |
| `6` | Another instance is running |
| `7` | Invalid configuration or arguments |
| `8` | Required privilege denied or unavailable |

Codes `4` and `5` are successful outcomes. Apply precedence is `3 > 2 > 5 > 4 > 0`.
A successful check returns `0` whether updates are available or not; a kernel
headers change alone does not require code `5`. Intermediate action events can
carry raw command statuses; the final process/result status uses this table.

## Documentation and contributing

- [Development roadmap and phase gates](docs/roadmap.md)
- [Prepared integrated regression selection and limits](docs/reference/repository-regression-block-524-531.md)
- [Reference acceptance guide](tests/acceptance/reference/README.md)
- [Configuration example](data/config/slack-update.conf)
- [Contribution and documentation policy](CONTRIBUTING.md)
- [Change history](CHANGELOG.md)
- [Documentation index](docs/README.md)

Detailed audits, contracts and evidence reviews live in `docs/reference/`.
The historical README archive preserves earlier designs and checkpoint text;
its former "Current" headings and commands describe their original checkpoints.

## License

GNU General Public License, version 3 or later (`GPL-3.0-or-later`).
See [LICENSE](LICENSE).
