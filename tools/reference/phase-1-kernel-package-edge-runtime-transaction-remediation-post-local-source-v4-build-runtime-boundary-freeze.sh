#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
if [[ $# -eq 1 && $1 == --help ]]; then printf 'Usage: %s --output-dir DIR\nRepository-only runtime boundary freeze; no runtime or target action.\n' "${0##*/}"; exit 0; fi
[[ $# -eq 2 && $1 == --output-dir && -n $2 ]] || { printf 'ERROR: expected --output-dir DIR\n' >&2; exit 2; }
python3 - "$repo_root" "$2" <<'PYFREEZE'
from pathlib import Path
import hashlib
import json
import re
import subprocess
import sys
def validate_boundary_freeze(reviewed, frozen, expected_next):
 if reviewed.get('step') != 296 or reviewed.get('state') != 'runtime-boundary-reviewed-not-frozen-not-implemented-not-authorized':raise ValueError('unexpected reviewed boundary')
 expected=dict(reviewed,step=297,state='runtime-boundary-frozen-not-implemented-not-authorized',next_stage=expected_next)
 if json.dumps(frozen,sort_keys=True,separators=(',',':')) != json.dumps(expected,sort_keys=True,separators=(',',':')):raise ValueError('freeze changes reviewed contract')
 if type(frozen.get('step')) is not int:raise ValueError('step type drift')
 return True
root=Path(sys.argv[1]);out=Path(sys.argv[2]).absolute();base='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-freeze';prior='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-review';own_hashes={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-freeze.md': '080bc1cd12411ce0f87e7bd26614c263ed3784f0626b28987388d27f875dd995', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-freeze-policy.json': 'b467799112533335f1aa867d197c1d66db76fc41e5c7792111628bc1c3f5dfa2', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-freeze.tsv': 'a9ce10a55a4c392fe93c4dc995e54818e845e7604e8a60650feb2bb35c4e231b', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-freeze-boundary.json': '59907c7852b96de5be84f3358366971800d42ca2c8bd76ebb901738d12787931'}
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
  marker=b'## Phase 1 step 296 ';position=data.find(marker)
  if position<0:raise SystemExit('ERROR: accepted CHANGELOG history missing')
  data=data[position:]
 if hashlib.sha256(data).hexdigest()!=digest:raise SystemExit('ERROR: accepted repository byte drift: '+rel)
suffixes=['-policy.json','.tsv','-boundary.json']
for suffix in suffixes:
 p=out/(base+suffix)
 if p.exists() or p.is_symlink():raise SystemExit('ERROR: output already exists')
reviewed=json.loads((root/policy['runtime_boundary_path']).read_text())
frozen=json.loads((root/policy['runtime_boundary_freeze_path']).read_text())
try:validate_boundary_freeze(reviewed,frozen,'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-boundary-closure-and-strong-safe-pause')
except ValueError as error:raise SystemExit('ERROR: '+str(error))
if (root/frozen['executor']['future_executor_path']).exists() or (root/frozen['executor']['future_executor_path']).is_symlink():raise SystemExit('ERROR: future executor must remain absent')
result=subprocess.run(['bash',str(root/'tests/reference'/('test-'+prior+'-harness.sh'))],capture_output=True,text=True)
if result.returncode or 'Result: PASS (252 passes, 0 failures)' not in result.stdout:raise SystemExit('ERROR: full accepted252 predecessor suite failed\n'+result.stdout+result.stderr)
for suffix in suffixes:(out/(base+suffix)).write_bytes((fixture/(base+suffix)).read_bytes())
print('step_297_runtime_boundary_freeze_status\tPASS')
print('accepted_step296_revalidated\tPASS (252 passes, 0 failures)')
print('source_candidate_executor_contracts_changed\tno')
print('v4_runtime_pkglist_generation_observed\tno')
print('current_candidate_binding_created\tno')
print('future_executor_installed\tno')
print('all_operational_authority_closed\tyes')
print('machine_action_required\tno')
print('controller_action_required\tno')
print('strong_safe_pause\tno')
print('next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-boundary-closure-and-strong-safe-pause')
PYFREEZE
