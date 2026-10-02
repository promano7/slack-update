#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
if [[ $# -eq 1 && $1 == --help ]]; then printf 'Usage: %s --output-dir DIR\nRepository-only runtime boundary review; no runtime or target action.\n' "${0##*/}"; exit 0; fi
[[ $# -eq 2 && $1 == --output-dir && -n $2 ]] || { printf 'ERROR: expected --output-dir DIR\n' >&2; exit 2; }
python3 - "$repo_root" "$2" <<'PYFREEZE'
from pathlib import Path
import hashlib
import json
import re
import subprocess
import sys
def validate_runtime_boundary_fixture(fixture, boundary):
 candidate=boundary['candidate'];source=boundary['source']
 checks={'source_manifest_sha256':source['manifest_sha256'],'source_target_sha256':source['target_sha256'],'source_checksum_format':source['checksum_representation'],'source_preserved':True,'fresh_transaction':True,'pre_refresh_pkglist_absent':True,'post_refresh_pkglist_regular':True,'post_refresh_pkglist_non_symlink':True,'refresh_exit':0,'same_transaction_binding':True,'all_unexpected_candidate_counts_zero':True}
 for key,value in checks.items():
  if fixture.get(key)!=value or type(fixture.get(key)) is not type(value):raise ValueError('future gate drift: '+key)
 if re.search(re.escape(candidate['stdout_and_stderr_error_signal']),fixture.get('refresh_stdout','')+fixture.get('refresh_stderr',''),re.I):raise ValueError('refresh download error signal')
 text=fixture.get('pkglist_text','')
 if not text.strip():raise ValueError('fresh pkglist empty')
 rows=[line.split() for line in text.splitlines() if line.strip()]
 if rows!=[candidate['expected_target_fields']]:raise ValueError('candidate set is not one exact target row')
 if not re.fullmatch(r'[0-9a-f]{64}',fixture.get('bound_pkglist_sha256','')):raise ValueError('pkglist SHA binding invalid')
 if hashlib.sha256(text.encode()).hexdigest()!=fixture['bound_pkglist_sha256']:raise ValueError('pkglist bytes do not match binding')
 return True
root=Path(sys.argv[1]);out=Path(sys.argv[2]).absolute();base='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-review';prior='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-freeze';own_hashes={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-review.md': '7a125a35305954cc8ffabba1152ca9c90b3a5f1b4ef84c8cf7713369c6887dab', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-review-policy.json': 'ddce16fe5615349fac0d415a4a0ddf529ce64d3786a6861386131ce00a1b5d7f', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-review.tsv': '284c078f2cf383a2935820dfabd8aa2e3dbdac6109012198d943227d44f3bd34', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-review-boundary.json': 'ae5dfd645b38120b645b8461f611a3c2bc50f57c05c3d125a64b3141f8ea832a'}
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
  marker=b'## Phase 1 step 295 ';position=data.find(marker)
  if position<0:raise SystemExit('ERROR: accepted CHANGELOG history missing')
  data=data[position:]
 if hashlib.sha256(data).hexdigest()!=digest:raise SystemExit('ERROR: accepted repository byte drift: '+rel)
suffixes=['-policy.json','.tsv','-boundary.json']
for suffix in suffixes:
 p=out/(base+suffix)
 if p.exists() or p.is_symlink():raise SystemExit('ERROR: output already exists')
result=subprocess.run(['bash',str(root/'tests/reference'/('test-'+prior+'-harness.sh'))],capture_output=True,text=True)
if result.returncode or 'Result: PASS (263 passes, 0 failures)' not in result.stdout:raise SystemExit('ERROR: full accepted263 predecessor suite failed\n'+result.stdout+result.stderr)
for suffix in suffixes:(out/(base+suffix)).write_bytes((fixture/(base+suffix)).read_bytes())
print('step_296_runtime_boundary_review_status\tPASS')
print('accepted_step295_revalidated\tPASS (263 passes, 0 failures)')
print('v4_runtime_pkglist_generation_observed\tno')
print('current_candidate_binding_created\tno')
print('future_executor_installed\tno')
print('historical_executor_rerun_authorized\tno')
print('all_operational_authority_closed\tyes')
print('machine_action_required\tno')
print('controller_action_required\tno')
print('strong_safe_pause\tno')
print('next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-freeze')
PYFREEZE
