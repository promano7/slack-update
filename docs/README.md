# Documentation

Start with the [project overview](../README.md). The documents below separate
the available shell reference, the planned C application and the detailed
acceptance material. For the current phase and unfinished work, use the
[roadmap](roadmap.md#current-phase-and-release-gate).

## Reading routes

| What you need | Read |
| --- | --- |
| Project purpose, source-tree entry point and basic usage | [README](../README.md) |
| Development phases and completion gates | [Roadmap](roadmap.md) |
| Planned C components, modules, security and interfaces | [Planned application design](design.md) |
| Current reference configuration and default values | [Configuration file](../data/config/slack-update.conf) |
| Source and supported reference options | [Shell reference](../tools/reference/slack-update-reference.sh) and the README usage section |
| Contribution, language and documentation rules | [Contributing](../CONTRIBUTING.md) |
| Detailed contracts, audits and evidence | [Reference documentation](reference/README.md) |
| Real Slackware acceptance scenarios | [Acceptance guide](../tests/acceptance/reference/README.md) |
| Changes by step or version | [CHANGELOG](../CHANGELOG.md) |
| Earlier README checkpoints and original design text | [Historical README through step 418](reference/readme-through-step418.md) |

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
