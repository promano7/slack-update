#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
out=${1:-$acceptance_dir}
mkdir -p "$out"

step217_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review-policy.json"
step217_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review.tsv"
probe="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-first-attempt-failure-probe.sh"

[[ -f $step217_policy && ! -L $step217_policy ]] || { echo 'ERROR: accepted step-217 policy missing' >&2; exit 1; }
[[ -f $step217_record && ! -L $step217_record ]] || { echo 'ERROR: accepted step-217 record missing' >&2; exit 1; }
[[ -f $probe && ! -L $probe ]] || { echo 'ERROR: step-218 probe missing' >&2; exit 1; }

python3 - "$step217_policy" <<'PY'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['scenario']=='phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review'
PY

cat > "$out/phase-1-kernel-package-edge-runtime-transaction-first-attempt-failure-review-policy.json" <<'JSON'
{
  "scenario": "phase-1-kernel-package-edge-runtime-transaction-first-attempt-failure-review",
  "step": 218,
  "review_status": "PASS",
  "observed_runtime_result": "FAIL",
  "observed_error": "refreshed local pkglist contains 2032 package rows instead of exactly one",
  "failure_class": "candidate-binding-guard-assumption",
  "mutation_had_started": true,
  "cleanup_verification_required": true,
  "failure_probe_sha256": "0f9388cde7fcb178e8f06ff2b200d503c29fb454fa9502091701cc5d2752098d",
  "failure_probe_acknowledgement": "--observe-failure-cleanup",
  "review_revision": "218-r1",
  "preflight_encoding_compatibility": "literal-backslash-t-or-real-tab",
  "machine_action_required": true,
  "machine_action_type": "read-only-failure-characterization",
  "runtime_rerun_authorized": false,
  "package_action_authorized": false,
  "slackpkg_mutation_authorized": false,
  "network_access_authorized": false,
  "boot_action_authorized": false,
  "reboot_authorized": false,
  "persistent_configuration_change_authorized": false,
  "published_success_evidence_expected": false,
  "failed_evidence_root_must_be_preserved": true,
  "pause_safe": false,
  "next_stage": "phase-1-kernel-package-edge-runtime-transaction-first-attempt-failure-characterization-freeze"
}
JSON

cat > "$out/phase-1-kernel-package-edge-runtime-transaction-first-attempt-failure-review.tsv" <<'TSV'
step	218
review_status	PASS
observed_runtime_result	FAIL
observed_error	refreshed local pkglist contains 2032 package rows instead of exactly one
failure_class	candidate-binding-guard-assumption
mutation_had_started	yes
cleanup_verification_required	yes
failure_probe_sha256	0f9388cde7fcb178e8f06ff2b200d503c29fb454fa9502091701cc5d2752098d
failure_probe_acknowledgement	--observe-failure-cleanup
review_revision	218-r1
preflight_encoding_compatibility	literal-backslash-t-or-real-tab
machine_action_required	yes
machine_action_type	read-only-failure-characterization
runtime_rerun_authorized	no
package_action_authorized	no
slackpkg_mutation_authorized	no
network_access_authorized	no
boot_action_authorized	no
reboot_authorized	no
persistent_configuration_change_authorized	no
published_success_evidence_expected	no
failed_evidence_root_must_be_preserved	yes
pause_safe	no
next_stage	phase-1-kernel-package-edge-runtime-transaction-first-attempt-failure-characterization-freeze
TSV

printf 'review_status\tPASS\n'
printf 'runtime_rerun_authorized\tno\n'
printf 'failure_probe_sha256\t%s\n' '0f9388cde7fcb178e8f06ff2b200d503c29fb454fa9502091701cc5d2752098d'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-first-attempt-failure-characterization-freeze\n'
