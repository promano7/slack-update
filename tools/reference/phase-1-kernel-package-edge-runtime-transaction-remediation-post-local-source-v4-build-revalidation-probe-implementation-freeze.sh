#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
if [[ $# -eq 1 && $1 == --help ]]; then printf 'Usage: %s --output-dir DIR\nRepository-only implementation freeze; no target observation.\n' "${0##*/}"; exit 0; fi
[[ $# -eq 2 && $1 == --output-dir && -n $2 ]] || { printf 'ERROR: expected --output-dir DIR\n' >&2; exit 2; }
python3 - "$repo_root" "$2" <<'PYFREEZE'
from pathlib import Path
import hashlib
import json
import subprocess
import sys
root=Path(sys.argv[1]);out=Path(sys.argv[2]).absolute();base='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-probe-implementation-freeze';prior='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-probe-implementation-review';own_hashes={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-probe-implementation-freeze.md': 'b5dfe2a4463768fcd901ce8db40c6ccf9621e34504f87c528ec340bdc4d81534', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-probe-implementation-freeze-policy.json': '082209e2c57d10cdc981f82b8417df9d2b686a45df52836089bcf7d9b4304b75', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-probe-implementation-freeze.tsv': 'ada8fa20bb762476434e906c6970eaae481ffd876c7dbc316d33d24e852022d6', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-probe-implementation-freeze-implementation.json': '29faa6336b722bf5926e6dabcfbb01c8f932e050354186829a9da3e0a93abc81'}
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
  marker=b'## Phase 1 step 292 ';position=data.find(marker)
  if position<0:raise SystemExit('ERROR: accepted CHANGELOG history missing')
  data=data[position:]
 if hashlib.sha256(data).hexdigest()!=digest:raise SystemExit('ERROR: accepted repository byte drift: '+rel)
suffixes=['-policy.json','.tsv','-implementation.json']
for suffix in suffixes:
 p=out/(base+suffix)
 if p.exists() or p.is_symlink():raise SystemExit('ERROR: output already exists')
result=subprocess.run(['bash',str(root/'tests/reference'/('test-'+prior+'-harness.sh'))],capture_output=True,text=True)
if result.returncode or 'Result: PASS (250 passes, 0 failures)' not in result.stdout:raise SystemExit('ERROR: full accepted250 predecessor suite failed\n'+result.stdout+result.stderr)
for suffix in suffixes:(out/(base+suffix)).write_bytes((fixture/(base+suffix)).read_bytes())
print('step_293_implementation_freeze_status\tPASS')
print('accepted_step292_revalidated\tPASS (250 passes, 0 failures)')
print('accepted_repository_file_count\t1236')
print('implementation_changed_keys\tstate')
print('production_source_bytes_changed\tno')
print('probe_installed_in_repository\tyes')
print('probe_transported\tno')
print('live_target_observation_performed\tno')
print('machine_action_required\tno')
print('controller_action_required\tno')
print('pause_safe\tno')
print('strong_safe_pause\tno')
print('next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-fresh-target-and-source-revalidation-authorization')
PYFREEZE
