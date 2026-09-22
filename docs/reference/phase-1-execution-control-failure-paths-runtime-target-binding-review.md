# Phase 1 execution-control failure-paths runtime target-binding review

Step 181 consumes the accepted step-180 runtime-boundary design and freezes the
read-only target-binding review for the **`execution-control-failure-paths`**
family. The selected target is the Slackware-current validation VM with FQDN
`vbox-slackcurrent.vbox-slackcurrent.org`.

## Read-only runtime observation

The runtime observation is performed by
`tools/reference/phase-1-execution-control-failure-paths-runtime-target-binding-probe.sh`. It must be run through `sudo` on the validation VM. It reads the
hostname, FQDN, running kernel, Slackware version, boot ID, and the SHA-256
identities of `tools/reference/slack-update-reference.sh` and
`data/config/slack-update.conf`. It also verifies the capabilities required by
the frozen step-180 design: Bash, Python 3, SHA-256 tooling, tar, `flock`,
process/signal tools, `crontab`, a running `crond`, and creation of an ephemeral
network namespace.

The `unshare --net` check only creates a temporary namespace and runs `true`;
it does not contact an external network or change host networking. The root
crontab check is read-only. The probe must not refresh repositories, install or
remove packages, modify boot state, reboot, or alter persistent configuration.
If a required capability is absent, the chain stops and reports the missing
capability instead of changing the VM.

The probe can discover the established VM repo paths
`/home/promano/GitHub/slack-update` or
`/home/promano/Descargas/slack-update-main`; if discovery is ambiguous, an
explicit `--repo-root` is required. A successful observation prints a TSV
record beginning with `binding_status	PASS`. That complete output is the input
to step 182, which will freeze the exact target binding before any runtime
executor implementation is authorized.

## Authorization boundary

Step 181 authorizes only this read-only target observation and, after a
successful observation, the next target-binding freeze. It does **not**
authorize the four failure-path scenarios, implementation of their runtime
executor, repository refresh, network refresh, package actions, boot actions,
reboot, or Phase 2. A later Slackware-current publication does not invalidate
this identity/capability review because no live package candidate set is bound.

The acceptance matrix remains incomplete and this is not the requested
end-of-session strong safe pause.

Frozen helper SHA-256: `b186507eb8e94312e6360142e1dc797b63ba46a55f5d3a7b2aa729b6fd5ccd72`.  
Frozen probe SHA-256: `a2f54a55ff191cec920b067130c0e4520d4987b01755e9170762f1738656ecfe`.  
Frozen policy SHA-256: `38d595562c77071df235f788b0bae08b5a7ceb0112265b485226c6307772647f`.  
Frozen record SHA-256: `6325a4e1b39fa705ce0d34a464f4971380f89fa6580740d671769dc3991295b0`.

The next stage is
`phase-1-execution-control-failure-paths-runtime-target-binding-freeze`.
`pause_safe=false`.
