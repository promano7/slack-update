#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
if [[ $# -eq 1 && $1 == --help ]]; then printf 'Usage: %s --output-dir DIR\nRepository-only returned observation freeze; no new target invocation.\n' "${0##*/}"; exit 0; fi
[[ $# -eq 2 && $1 == --output-dir && -n $2 ]] || { printf 'ERROR: expected --output-dir DIR\n' >&2; exit 2; }
python3 - "$repo_root" "$2" <<'PYFREEZE'
from pathlib import Path
import hashlib
import json
import re
import subprocess
import sys
def validate_observation_text(text, field_order, expected_values):
 if not text.endswith('\n') or '\r' in text:raise ValueError('observation must use canonical LF records')
 lines=text.splitlines()
 if len(lines)!=50 or len(field_order)!=50 or len(set(field_order))!=50:raise ValueError('observation must contain exactly fifty fields')
 rows=[]
 for line in lines:
  if line.count('\t')!=1:raise ValueError('observation must use exactly one real tab per field')
  key,value=line.split('\t')
  if not key or not value:raise ValueError('empty observation field')
  rows.append((key,value))
 if [key for key,value in rows]!=field_order:raise ValueError('observation key/order/uniqueness drift')
 values=dict(rows)
 if set(expected_values)!=set(field_order) or values!=expected_values:raise ValueError('observation value or frozen identity drift')
 if not re.fullmatch(r'[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}',values['fresh_boot_id']):raise ValueError('fresh boot UUID is not canonical')
 return values
root=Path(sys.argv[1]);out=Path(sys.argv[2]).absolute();base='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-freeze';prior='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-fresh-target-and-source-revalidation-authorization';own_hashes={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-freeze.md': '2837b4feb553b487985d9d06d21a8a63a0c84e858b271490ec3f074dde57b735', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-freeze-policy.json': '7ca69d1a95bcfa2258a2588f04c75c8ef35d7776d92517342bd4039fe69efd05', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-freeze.tsv': 'a5527f85203e1808a746cc49c1d61fe0e13d5584c27422aecce6619d9eb0d4e8', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-freeze-observation.tsv': '68efaab51288791ddcd515e7438dab6db7cbbe25be750549ce0b0cacf55db832', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-freeze-provenance.json': '91c68d091af1a17b635144ebca0cd513a54034f704e02ad3d47cf98431e6647f', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-freeze-returned-display.txt': 'fd0f4746fe4d06d4423bfbcd453c2c6ef3ff3889894b3f1d44e0a39e8c13425e'}
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
  marker=b'## Phase 1 step 294 ';position=data.find(marker)
  if position<0:raise SystemExit('ERROR: accepted CHANGELOG history missing')
  data=data[position:]
 if hashlib.sha256(data).hexdigest()!=digest:raise SystemExit('ERROR: accepted repository byte drift: '+rel)
suffixes=['-policy.json','.tsv','-observation.tsv','-provenance.json','-returned-display.txt']
for suffix in suffixes:
 p=out/(base+suffix)
 if p.exists() or p.is_symlink():raise SystemExit('ERROR: output already exists')
expected_values=policy['revalidation_result']['fixed_return_values']|{'fresh_boot_id':policy['revalidation_result']['fresh_boot_id']}
try:
 validate_observation_text((fixture/(base+'-observation.tsv')).read_text(),policy['design']['ordered_publication_fields'],expected_values)
except ValueError as error:raise SystemExit('ERROR: invalid reviewed observation: '+str(error))
result=subprocess.run(['bash',str(root/'tests/reference'/('test-'+prior+'-harness.sh'))],capture_output=True,text=True)
if result.returncode or 'Result: PASS (180 passes, 0 failures)' not in result.stdout:raise SystemExit('ERROR: full accepted180 predecessor suite failed\n'+result.stdout+result.stderr)
for suffix in suffixes:(out/(base+suffix)).write_bytes((fixture/(base+suffix)).read_bytes())
print('step_295_revalidation_freeze_status\tPASS')
print('accepted_step294_revalidated\tPASS (180 passes, 0 failures)')
print('observation_status\tPASS')
print('observation_provenance\tsemantic-transcription-of-user-returned-terminal-display')
print('observed_boot_id\ta5430a61-c988-4d52-9d5c-f20bb0a04016')
print('probe_exit_status\t0')
print('probe_execution_authority_consumed\tyes')
print('probe_transport_authority_revoked\tyes')
print('all_operational_authority_closed\tyes')
print('machine_action_required\tno')
print('controller_action_required\tno')
print('strong_safe_pause\tno')
print('next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-review')
PYFREEZE
