# Phase 1 execution-control failure-paths runtime target-binding review

Step 181-r1 revises the accepted step-181 target-binding observation after the
first VM probe correctly reported that no `slack-update` repository was present
on the validation VM. The runtime-boundary contract from step 180 remains
unchanged: the binding must record the reference-script and effective-config
SHA-256 identities, but the target itself does not need to host the repository.

## Standalone runtime observation

The revised probe at
`tools/reference/phase-1-execution-control-failure-paths-runtime-target-binding-probe.sh`
is materialized by the overlay on the controller repository. During that
materialization, the SHA-256 identities of
`tools/reference/slack-update-reference.sh` and
`data/config/slack-update.conf` are embedded directly into the probe. The
resulting single file can therefore be copied to the Slackware-current
validation VM without copying, cloning, or refreshing the repository there.

The probe must be run through `sudo` on
`vbox-slackcurrent.vbox-slackcurrent.org`. It reads hostname, FQDN, running
kernel, Slackware version and boot ID, reports the two embedded controller-side
source identities, and verifies the capabilities required by the frozen
step-180 design: Bash, Python 3, SHA-256 tooling, tar, `flock`, process/signal
tools, `crontab`, a running `crond`, and creation of an ephemeral network
namespace.

The `unshare --net` check only creates a temporary namespace and runs `true`;
it does not contact an external network or change host networking. The root
crontab check is read-only. The probe must not refresh repositories, install or
remove packages, modify boot state, reboot, or alter persistent configuration.
If a capability is absent, the chain stops instead of changing the VM.

A successful observation starts with `binding_status\tPASS` and also reports
`target-repository-required\tno` and
`source-identity-origin\tcontroller-repo-frozen-at-step-181-r1`. The complete
output is the input to step 182, which will freeze the exact target binding
before any runtime executor implementation is authorized.

## Authorization boundary

Step 181-r1 changes only the mechanics of source/configuration identity
transport. It preserves the step-181 authorization boundary: only the read-only
target observation is allowed. The four failure-path scenarios, their runtime
executor, repository/network refresh, package actions, boot actions, reboot,
and Phase 2 remain unauthorized. A later Slackware-current publication does
not invalidate this identity/capability review because no live package
candidate set is bound.

The acceptance matrix remains incomplete and this is not the requested
end-of-session strong safe pause. Exact helper, probe, source, configuration,
policy and record SHA-256 identities are frozen and cross-checked by the policy,
record and step-181 harness after overlay application.

The next stage is
`phase-1-execution-control-failure-paths-runtime-target-binding-freeze`.
`pause_safe=false`.
