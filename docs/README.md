# Documentation

Start with the [project overview](../README.md). The documents below separate
the available shell reference, the planned C application and the detailed
acceptance material. For the current phase and unfinished work, use the
[roadmap](roadmap.md#current-phase-and-release-gate).

## Reading routes

| What you need | Read |
| --- | --- |
| Project purpose, source-tree entry point and basic usage | [README](../README.md) |
| Prepare a checkout and understand reference installation | [Development setup](development-setup.md) |
| Development phases and completion gates | [Roadmap](roadmap.md) |
| Planned C components, modules, security and interfaces | [Planned application design](design.md) |
| Current reference configuration and default values | [Configuration guide](configuration.md) and [default file](../data/config/slack-update.conf) |
| Supported reference operations, output and results | [Usage guide](reference-usage.md) and [shell source](../tools/reference/slack-update-reference.sh) |
| Contribution, language and documentation rules | [Contributing](../CONTRIBUTING.md) |
| Detailed contracts, audits and evidence | [Reference documentation](reference/README.md) |
| Select applicable checks and historical snapshots | [Testing guide](testing.md) |
| New bounded ELF recheck work and defect characterization | [Recheck repair and focused verification](reference/elf-recheck-emission-status.md) |
| Earlier completed integration, with later outer531 closure | [524-531 review](reference/repository-regression-block-524-531.md) |
| Current bounded regression block and focused workspace checks | [Current testing status](testing.md#current-bounded-block-and-integrated-selection) and [reference index](reference/README.md#current-repository-regression-coverage) |
| Real Slackware acceptance scenarios | [Acceptance guide](../tests/acceptance/reference/README.md) |
| Changes by step or version | [CHANGELOG](../CHANGELOG.md) |
| Earlier README checkpoints and original design text | [Historical README through step 418](reference/readme-through-step418.md) |

Actual540 is accepted at `12f4d41bb6e2e8ea544e4597f5dca54a1a2d2189` with clean
reported main, exact source tree and push. Prepared541 retains every selected
post-build ELF path-emission error until the input loop completes and refuses
before list publication/clearing. See the [repair scope](reference/elf-recheck-emission-status.md)
for108 direct cases, five fresh focused commands, preserved baseline/old-warning
failures, four source controls and remaining limits. Actual541/new pause pending.
Last externally confirmed qualified STATIC pause remains539. Block540-547,
reserves548-551 only if justified; final actual acceptance precedes a separate
whole-condition/original/new-effects review. No native or host closure claimed.

The [540 audit](reference/elf-recheck-emission-audit.md) remains immutable history,
excluded after repair. Keep the entire539 continuation and original deliveries
with nested history/failures/unknown extras/incomplete491/recovery qualifications.

The design's proposed configuration and result examples describe future
interfaces. Use the checked-in configuration and the shell reference for the
currently available formats. The roadmap records the gate for starting C work.

## Working with reference material

- To review remaining acceptance work, start with the roadmap and follow the
  reference index to the original inventory and scenario criteria.
- To review an operational proposal, read its linked complete requirements,
  findings and evidence dependencies. A summary or directory listing does not
  establish compatibility or select a proposal.
- To verify a change, select checks that apply to that change. Historical
  checkpoint harnesses can require the exact source snapshot they describe;
  real acceptance scripts require their own reviewed execution scope.

Keep overview text here and in the README short. Record per-step changes in
CHANGELOG; keep contracts, audits and detailed evidence reviews in reference
documentation. The full [documentation policy](../CONTRIBUTING.md#documentation-policy)
defines when the README should change.
