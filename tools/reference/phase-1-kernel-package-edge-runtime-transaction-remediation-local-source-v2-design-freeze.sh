#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-design-freeze'
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-design-review'
prev_helper="$repo_root/tools/reference/${prev}.sh"
prev_doc="$repo_root/docs/reference/${prev}.md"
prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-design-freeze.sh --output-dir DIR

Generate the repository-only step-225 local-source-v2 design-freeze policy and TSV record.
This helper performs no target-machine, package, Slackpkg, network, boot, or reboot action.
USAGE
}

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }
regular() { [[ -f $1 && ! -L $1 ]]; }
require_hash() {
    local path=$1 expected=$2 label=$3 actual
    regular "$path" || fail "$label is missing or unsafe: $path"
    actual=$(sha "$path")
    [[ $actual == "$expected" ]] || fail "$label SHA-256 mismatch: $actual"
}

[[ ${1:-} == '--help' ]] && { usage; exit 0; }
[[ $# -eq 2 && $1 == '--output-dir' ]] || { usage >&2; exit 2; }
out_dir=$2
[[ -d $out_dir && ! -L $out_dir ]] || fail 'output directory must already exist and must not be a symlink'

require_hash "$prev_helper" '8d81a78fc92b35601976d83133e28a0509ab8b7940dca03ad0b0061ef4db8c30' 'accepted step-224 helper'
require_hash "$prev_doc" '206b56d8fec4e9310bb16e6de41612e42a3385aaca75026098b5cb355dbd6431' 'accepted step-224 document'
require_hash "$prev_harness" 'a56eb3a73b3897e4f70252cd4a89b492c93dc95d464688593ae7d27f86308158' 'accepted step-224 harness'
require_hash "$prev_policy" '5bb886adbbaa6e48649dd094b19e9f9d47e0d00e42af41a9bfef8c6bf8510dbe' 'accepted step-224 policy'
require_hash "$prev_record" 'b740a6963432a0e744099a4facad2b627f39d5e5321ac1a784e5d0082efac1a9' 'accepted step-224 record'

helper_sha=$(sha "${BASH_SOURCE[0]}")
python3 - "$prev_policy" "$prev_record" "$out_dir/${base}-policy.json" "$out_dir/${base}.tsv" "$helper_sha" <<'PYGEN'
import copy,json,pathlib,sys
prev_policy_path, prev_record_path, out_policy_path, out_record_path, helper_sha = sys.argv[1:]
p224=json.load(open(prev_policy_path,encoding='utf-8'))
record={}
for line in pathlib.Path(prev_record_path).read_text(encoding='utf-8').splitlines():
    if not line: continue
    k,v=line.split('\t',1); record[k]=v
assert p224['step']==224 and p224['review_status']=='PASS'
assert p224['local_source_v2_design']['state']=='design-reviewed-not-implemented'
assert p224['authorization']['repository_only_local_source_v2_design_freeze_authorized'] is True
assert p224['authorization']['local_source_v2_builder_implementation_authorized'] is False
assert p224['authorization']['local_source_v2_build_authorized'] is False
assert p224['machine_action_required'] is False
assert record['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-design-freeze'

design=copy.deepcopy(p224['local_source_v2_design'])
design['state']='design-frozen-not-implemented'
refresh=copy.deepcopy(p224['future_refresh_acceptance_contract'])
refresh.pop('not_authorized_by_step_224',None)
refresh['not_authorized_by_step_225']=True
policy={
  'schema':1,
  'scenario':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-design-freeze',
  'step':225,
  'review_only':True,
  'review_status':'PASS',
  'accepted_step_224':{
    'helper_sha256':'8d81a78fc92b35601976d83133e28a0509ab8b7940dca03ad0b0061ef4db8c30',
    'document_sha256':'206b56d8fec4e9310bb16e6de41612e42a3385aaca75026098b5cb355dbd6431',
    'harness_sha256':'a56eb3a73b3897e4f70252cd4a89b492c93dc95d464688593ae7d27f86308158',
    'policy_sha256':'5bb886adbbaa6e48649dd094b19e9f9d47e0d00e42af41a9bfef8c6bf8510dbe',
    'record_sha256':'b740a6963432a0e744099a4facad2b627f39d5e5321ac1a784e5d0082efac1a9',
  },
  'frozen_runtime_identity':copy.deepcopy(p224['frozen_runtime_identity']),
  'preservation_contract':copy.deepcopy(p224['preservation_contract']),
  'local_source_v2_design':design,
  'future_refresh_acceptance_contract':refresh,
  'design_freeze_contract':{
    'accepted_step_224_design_semantics_must_not_change':True,
    'builder_implementation_must_conform_exactly_to_frozen_design':True,
    'builder_implementation_review_may_not_authorize_execution':True,
    'v2_build_requires_later_explicit_runtime_authorization':True,
    'runtime_executor_remediation_requires_frozen_v2_build_result':True,
  },
  'authorization':{
    'repository_only_local_source_v2_design_freeze_authorized':False,
    'repository_only_local_source_v2_builder_implementation_review_authorized':True,
    'local_source_v2_builder_implementation_authorized':False,
    'local_source_v2_builder_execution_authorized':False,
    'local_source_v2_build_authorized':False,
    'target_observation_authorized':False,
    'runtime_candidate_binding_authorized':False,
    'runtime_executor_remediation_authorized':False,
    'runtime_rerun_authorized':False,
    'package_action_authorized':False,
    'slackpkg_mutation_authorized':False,
    'repository_refresh_authorized':False,
    'network_access_authorized':False,
    'boot_action_authorized':False,
    'reboot_authorized':False,
    'persistent_configuration_change_authorized':False,
    'evidence_cleanup_authorized':False,
    'phase_2_start_authorized':False,
  },
  'implementation_boundary':{
    'builder_implementation_review_is_repository_only':True,
    'builder_execution_may_not_begin_until_later_explicit_authorization':True,
    'local_source_v2_build_may_not_begin_until_later_explicit_authorization':True,
    'next_artifact':'repository-only-v2-builder-implementation-review',
  },
  'helper_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-design-freeze.sh',
  'helper_sha256':helper_sha,
  'machine_action_required':False,
  'controller_action_required':False,
  'future_work_requires_explicit_authorization':True,
  'pause_safe':False,
  'strong_safe_pause':False,
  'next_stage':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-review',
}
pathlib.Path(out_policy_path).write_text(json.dumps(policy,indent=2,sort_keys=True)+'\n',encoding='utf-8')
rows=[
 ('step','225'),('review_status','PASS'),
 ('accepted_step_224_policy_sha256','5bb886adbbaa6e48649dd094b19e9f9d47e0d00e42af41a9bfef8c6bf8510dbe'),
 ('accepted_step_224_record_sha256','b740a6963432a0e744099a4facad2b627f39d5e5321ac1a784e5d0082efac1a9'),
 ('frozen_boot_id',policy['frozen_runtime_identity']['boot_id']),
 ('local_source_v1_must_be_preserved_unchanged','yes'),
 ('failed_runtime_evidence_root_must_be_preserved_unchanged','yes'),
 ('local_source_v2_design_state','design-frozen-not-implemented'),
 ('local_source_v2_root',design['root']),
 ('local_source_v2_mirror_uri',design['mirror_uri']),
 ('local_source_v2_tree_manifest',design['tree_manifest']),
 ('target_filename',design['target_filename']),
 ('target_sha256',design['target_sha256']),
 ('target_relative_path',design['target_relative_path']),
 ('CHECKSUMS_md5_asc_required','yes'),
 ('CHECKSUMS_md5_asc_role',design['CHECKSUMS_md5_asc']['role']),
 ('CHECKSUMS_md5_asc_authenticity_claim','no'),
 ('priority_trees',','.join(design['priority_tree_contract']['effective_x86_64_priority_trees'])),
 ('priority_PACKAGES_TXT_required','yes'),
 ('target_priority_tree',design['priority_tree_contract']['target_stanza_tree']),
 ('global_pkglist_row_count_guard_retired','yes'),
 ('refresh_workdir_strategy',refresh['workdir_strategy']),
 ('pre_refresh_pkglist_must_be_absent','yes'),
 ('refresh_exit_status_must_be_zero','yes'),
 ('refresh_error_downloading_signal_must_be_absent','yes'),
 ('candidate_guard_scope',refresh['candidate_guard_scope']),
 ('target_candidate_row_count',str(refresh['target_candidate_row_count'])),
 ('predecessor_installed_required_at_binding_time','yes'),
 ('predecessor_record',refresh['predecessor_record']),
 ('target_source_binding_required','yes'),
 ('candidate_binding_and_consumption_same_transaction_required','yes'),
 ('evidence_encoding',refresh['evidence_encoding']),
 ('repository_only_local_source_v2_builder_implementation_review_authorized','yes'),
 ('local_source_v2_builder_implementation_authorized','no'),
 ('local_source_v2_builder_execution_authorized','no'),
 ('local_source_v2_build_authorized','no'),
 ('runtime_executor_remediation_authorized','no'),
 ('runtime_rerun_authorized','no'),
 ('package_action_authorized','no'),
 ('slackpkg_mutation_authorized','no'),
 ('repository_refresh_authorized','no'),
 ('network_access_authorized','no'),
 ('boot_action_authorized','no'),
 ('reboot_authorized','no'),
 ('evidence_cleanup_authorized','no'),
 ('phase_2_start_authorized','no'),
 ('machine_action_required','no'),('controller_action_required','no'),
 ('future_work_requires_explicit_authorization','yes'),
 ('pause_safe','no'),
 ('next_stage','phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-review'),
]
pathlib.Path(out_record_path).write_text(''.join(f'{k}\t{v}\n' for k,v in rows),encoding='utf-8')
PYGEN
