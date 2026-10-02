#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
if [[ $# -eq 1 && $1 == --help ]]; then printf 'Usage: %s --output-dir DIR\nRepository-only observation authorization; no target invocation.\n' "${0##*/}"; exit 0; fi
[[ $# -eq 2 && $1 == --output-dir && -n $2 ]] || { printf 'ERROR: expected --output-dir DIR\n' >&2; exit 2; }
python3 - "$repo_root" "$2" <<'PYFREEZE'
from pathlib import Path
import hashlib
import json
import subprocess
import sys
root=Path(sys.argv[1]);out=Path(sys.argv[2]).absolute();base='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-fresh-target-and-source-revalidation-authorization';prior='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-probe-implementation-freeze';own_hashes={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-fresh-target-and-source-revalidation-authorization.md': '425d89f501909b1292ea7204afaa6aef02ac756b92f93b14843fd6303abbf950', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-fresh-target-and-source-revalidation-authorization-policy.json': '844f8bc58c71088ed949abb28fcd9f56fddaa99c28c99c4d95f93c632da33b47', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-fresh-target-and-source-revalidation-authorization.tsv': '8fd86c655751c487b827ade2de9e569d303f67c0284c0b37353b01988b5f4dc0', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-fresh-target-and-source-revalidation-authorization-authorization.json': '765b0f387b41810a27e196dbcbd0331b9bd28b0b63771a2a4ec0dd5df4e5c25d'}
fixture=root/'tests/fixtures/reference/acceptance/phase-1'
if not out.is_dir() or out.resolve()!=out:raise SystemExit('ERROR: unsafe output directory')
for rel,digest in own_hashes.items():
 p=root/rel
 if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or hashlib.sha256(p.read_bytes()).hexdigest()!=digest:raise SystemExit('ERROR: changed or unsafe freeze input: '+rel)
policy=json.loads((fixture/(base+'-policy.json')).read_text())
for rel,digest in policy['accepted_checkpoint']['sha256_bindings'].items():
 p=root/rel
 if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or not p.resolve().is_relative_to(root):raise SystemExit('ERROR: unsafe accepted input: '+rel)
 data=p.read_bytes()
 if rel=='CHANGELOG.md':
  marker=b'## Phase 1 step 293 ';position=data.find(marker)
  if position<0:raise SystemExit('ERROR: accepted CHANGELOG history missing')
  data=data[position:]
 if hashlib.sha256(data).hexdigest()!=digest:raise SystemExit('ERROR: accepted repository byte drift: '+rel)
suffixes=['-policy.json','.tsv','-authorization.json']
for suffix in suffixes:
 p=out/(base+suffix)
 if p.exists() or p.is_symlink():raise SystemExit('ERROR: output already exists')
result=subprocess.run(['bash',str(root/'tests/reference'/('test-'+prior+'-harness.sh'))],capture_output=True,text=True)
if result.returncode or 'Result: PASS (232 passes, 0 failures)' not in result.stdout:raise SystemExit('ERROR: full accepted232 predecessor suite failed\n'+result.stdout+result.stderr)
for suffix in suffixes:(out/(base+suffix)).write_bytes((fixture/(base+suffix)).read_bytes())
print('step_294_observation_authorization_status\tPASS')
print('accepted_step293_revalidated\tPASS (232 passes, 0 failures)')
print('accepted_repository_file_count\t1242')
print('repository_acceptance_and_controller_release_required\tyes')
print('controller_release_issued\tno')
print('probe_invocations_issued\t0')
print('maximum_probe_invocations\t1')
print('probe_transported\tno')
print('live_target_observation_performed\tno')
print('conditional_machine_action_required_after_acceptance\tyes')
print('pause_safe\tno')
print('strong_safe_pause\tno')
print('next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-freeze')
PYFREEZE
