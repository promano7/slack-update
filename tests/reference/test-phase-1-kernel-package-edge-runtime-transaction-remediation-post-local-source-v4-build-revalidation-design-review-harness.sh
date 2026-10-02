#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
from pathlib import Path
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
root = Path(sys.argv[1])
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-design-review'
prior = 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-resume-planning-boundary-review'
own_hashes = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-design-review.md': 'fe1a2c0982355f492df51242d6f977348ca8480c6551924add1414bfea8c0645', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-design-review-policy.json': '8bc7ae657c08096eae27629bd8355133507025970783ccbc145d218c9143c5c6', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-design-review.tsv': 'd40e8063c3ed7166f1a488641088d9644ba90414f90c22311c3e46062459577d', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-design-review-design.json': 'fbe0774924279d0a2b611a3f4f6e10747d0b7aef3386cb7cf7af4db8c94609c2', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-design-review.sh': 'b1e1634e8e342702ce5901630376cdc00a84660ae36446cfc672fa0ffe23d410'}
fixture = root / 'tests/fixtures/reference/acceptance/phase-1'
policy_path = fixture / (base + '-policy.json')
policy = json.loads(policy_path.read_text())
previous = json.loads((fixture / (prior + '-policy.json')).read_text())
helper = root / 'tools/reference' / (base + '.sh')
design = json.loads((fixture / (base + '-design.json')).read_text())
passes = 0

def check(label, value):
    global passes
    if not value:
        raise SystemExit('FAIL: ' + label)
    passes += 1
    print('PASS: ' + label)

def run(args):
    return subprocess.run([str(x) for x in args], capture_output=True, text=True)

def function(src, name):
    if name == 'tsv_value':
        return re.search(r'(?m)^tsv_value\(\).*$', src).group(0)
    return re.search(r'(?ms)^' + re.escape(name) + r'\(\) \{\n.*?^\}', src).group(0)

accepted = policy['accepted_checkpoint']
for rel, digest in (accepted['sha256_bindings'] | own_hashes).items():
    path = root / rel
    check('exact regular artifact: ' + path.name, path.is_file() and not path.is_symlink() and hashlib.sha256(path.read_bytes()).hexdigest() == digest)
for path in [helper, root / 'tests/reference' / ('test-' + base + '-harness.sh')]:
    check('Bash syntax: ' + path.name, run(['bash', '-n', path]).returncode == 0)
check('review follows accepted next design stage', policy['schema'] == 1 and policy['step'] == 290 and policy['scenario'] == previous['next_stage'] == base and policy['review_only'] and policy['review_status'] == 'PASS')
check('confirmed fc9150c complete155 predecessor', accepted['step'] == 289 and accepted['commit'] == 'fc9150c' and accepted['acceptance_result'] == 'PASS (155 passes, 0 failures)' and accepted['user_commit_and_push_completed'] and accepted['user_worktree_clean'])
check('prefix provenance without invented full commit', accepted['commit_identity_scope'] == 'user-returned-seven-character-prefix-full-object-id-not-supplied' and 'commit_full' not in accepted)
for key in ['accepted_build_result', 'accepted_local_source_v4', 'accepted_authorization_closure', 'accepted_runtime_boundary_after_pause', 'historical_observation', 'accepted_step288_pause_remains_valid_as_historical_checkpoint', 'fresh_boundary', 'preservation', 'revalidation_boundary', 'future_runtime_boundary', 'roadmap', 'strong_pause_completion_conditions']:
    check('unchanged accepted boundary: ' + key, policy[key] == previous[key])
check('design JSON and policy agree exactly', policy['design'] == design and policy['design_path'] == 'tests/fixtures/reference/acceptance/phase-1/' + base + '-design.json')
check('reviewed design is not installed or authorized observation', design['state'] == 'reviewed-not-frozen-not-implemented-not-observation-authorized' and design['derivation_is_repository_design_not_transport_or_execution_evidence'] and not (root / design['future_probe_path']).exists())
original = (root / design['historical_baseline_path']).read_text()
check('exact historical baseline preserved', hashlib.sha256(original.encode()).hexdigest() == design['historical_baseline_sha256'] == 'fe1724a39aeaf4d14165df3d4aaada2ba009f9b01474a50c3083d4775bfe6a2b')
planned = original
check('eight unique ordered replacements only', len(design['replacements']) == 8 and [c['label'] for c in design['replacements']] == ['separate-help-and-postbuild-scope', 'add-accepted-v4-manifest-identity', 'replace-prebuild-absence-with-complete-postbuild-validation', 'new-strict-observation-switch', 'postbuild-guard-entry-before-publication', 'separate-observation-status', 'publish-observed-v4-artifact-and-validation-fields', 'separate-sourced-only-library-seam'])
for change in design['replacements']:
    check('replacement unique in its exact predecessor: ' + change['label'], planned.count(change['old']) == 1)
    planned = planned.replace(change['old'], change['new'], 1)
check('exact future derivation identity', hashlib.sha256(planned.encode()).hexdigest() == design['expected_derivation_sha256'])
for name, digest in design['preserved_guard_function_sha256'].items():
    check('unchanged guard body: ' + name, function(planned, name) == function(original, name) and hashlib.sha256(function(planned, name).encode()).hexdigest() == digest)
check('all nine applicable historical guard bodies retained', len(design['preserved_guard_function_sha256']) == 9)
for name, digest in design['new_guard_function_sha256'].items():
    check('exact new planned guard body: ' + name, hashlib.sha256(function(planned, name).encode()).hexdigest() == digest)
check('existing readonly constants identical and ordered', re.findall(r'(?m)^readonly .*$', original) == design['preserved_readonly_declarations'] and [line for line in re.findall(r'(?m)^readonly .*$', planned) if line != design['new_readonly_manifest_declaration']] == design['preserved_readonly_declarations'])
check('only new constant is accepted v4 manifest SHA', design['new_readonly_manifest_declaration'] == "readonly EXPECTED_V4_TREE_MANIFEST_SHA256='a4b0fc122c6274c7fdf70907661511bcf6ba475a2aa3bc46b96e5bcbf6ed3db8'" and planned.count(design['new_readonly_manifest_declaration']) == 1)
check('prebuild v4 final absence replaced, temporary absence retained', 'verify_v4_outputs_absent' not in planned and 'local_source_v4_root_absent' not in planned and 'local_source_v4_temporary_build_roots_absent' in planned)
check('all guard calls precede any PASS publication', '    verify_local_source_v3\n    verify_failed_v2_evidence\n    verify_local_source_v4\n    verify_v4_temporary_outputs_absent\n' in planned and planned.index('    verify_v4_temporary_outputs_absent\n') < planned.index("printf 'post_v4_build_fresh_target_and_source_revalidation_status"))
check('new strict CLI has no boot or path argument', design['cli_switch'] == '--observe-post-v4-build-fresh-target-and-source-revalidation' and "[[ $# -eq 1 && $1 == '" + design['cli_switch'] + "' ]]" in planned and design['cli_accepts_only_one_switch_and_help'] and not design['cli_accepts_boot_argument_or_path_override'])
check('fresh boot UUID read and validator unchanged', 'boot_id=$(cat /proc/sys/kernel/random/boot_id)' in planned and '    validate_fresh_boot_id "$boot_id"' in planned)
check('separate sourced-only seam retained', design['library_only_environment'] == 'SLACK_UPDATE_POST_V4_BUILD_REVALIDATION_LIBRARY_ONLY' and '${' + design['library_only_environment'] + ':-0}' in planned and '[[ ${BASH_SOURCE[0]} != "$0" ]]' in planned and design['library_only_mode_requires_sourcing'])
check('exact fifty unique publication fields', re.findall(r"(?m)^    printf '([A-Za-z0-9_]+)\\t", planned) == design['ordered_publication_fields'] and design['publication_field_count'] == len(set(design['ordered_publication_fields'])) == 50)
old_fields = re.findall(r"(?m)^    printf '([A-Za-z0-9_]+)\\t", original)
removed = {'v4_preflight_boot_drift_fresh_target_and_output_absence_revalidation_status', 'local_source_v4_root_absent', 'local_source_v4_tree_manifest_absent', 'local_source_v4_tree_manifest_sidecar_absent'}
check('every still-applicable old publication field retained in order', [f for f in design['ordered_publication_fields'] if f in old_fields] == [f for f in old_fields if f not in removed])
for field in design['no_effect_fields']:
    check('read-only no-effect publication retained: ' + field, "printf '" + field + "\\tno\\n'" in planned)
check('builder SHA only repository context, no transport requirement', design['frozen_builder_sha_field_is_repository_context_not_observed_transport'] and 'regular_sha256 "$BUILDER' not in planned)
check('point-in-time observation, no atomic or continuous claim', design['observation_provenance_scope'] == 'point-in-time-guarded-observation-not-atomic-snapshot-or-continuous-preservation' and not design['tree_mtime_preservation_claim'])
check('explicit fixture validator parameters, fixed production adapter', '[[ $# -eq 6 ]]' in function(planned, 'verify_v4_tree_at') and '"$EXPECTED_V4_TREE_MANIFEST_SHA256" "$EXPECTED_TARGET_SHA256" \'0:0\'' in function(planned, 'verify_local_source_v4') and design['production_adapter_passes_frozen_paths_sha_and_uid0_gid0'])
check('exact directory/file counts and root ownership', len(design['expected_regular_files']) == 11 and len(design['expected_directories']) == 6 and design['expected_non_root_tree_entry_count'] == 17 and design['production_expected_uid_gid'] == '0:0' and design['regular_file_mode'] == '444' and design['directory_mode'] == '555')
check('hidden additions counted without newline splitting', 'shopt -s nullglob dotglob' in function(planned, 'verify_v4_tree_at') and 'for entry in "$directory"/*' in function(planned, 'verify_v4_tree_at') and '[[ $inventory_count == 17 ]]' in function(planned, 'verify_v4_tree_at'))
check('canonical exact-byte sidecar hash before content use', 'sidecar_expected_sha=$(printf' in planned and '[[ $(regular_sha256 "$sidecar") == "$sidecar_expected_sha" ]]' in planned)
check('manifest digest bound before safe parser and GNU checking', planned.index('[[ $(regular_sha256 "$manifest") == "$expected_manifest_sha" ]]') < planned.index('validate_v4_manifest_text "$(cat -- "$manifest")"') < planned.index('sha256sum -c -- "$manifest"'))
check('signature marker never authenticates packages', design['compatibility_marker_is_not_openpgp_signature'] and "! grep -Fq 'BEGIN PGP SIGNATURE'" in planned and 'local_source_v4_compatibility_asc_is_openpgp_signature\\tno' in planned)
check('later fixture acceptance categories specified', len(design['acceptance_cases_required_before_implementation_freeze']) == 10 and design['generic_tree_validator_accepts_explicit_fixture_bindings_for_later_tests'])

# Assemble only pure design functions; never source or invoke the planned probe.
pure_script = 'set -euo pipefail\nexport LC_ALL=C\n' + re.search(r'(?m)^fail\(\).*$', original).group(0) + '\n' + '\n\n'.join(function(planned, name) for name in ['validate_fresh_boot_id', 'v4_expected_files', 'validate_v4_manifest_text']) + '\n"$@"\n'
valid_rows = [hashlib.sha256(('fixture:' + rel).encode()).hexdigest() + '  ' + rel for rel in design['expected_regular_files']]
valid = '\n'.join(valid_rows)
manifest_cases = [
    ('valid exact canonical manifest', valid, True),
    ('missing row', '\n'.join(valid_rows[:-1]), False),
    ('extra row', valid + '\n' + valid_rows[-1], False),
    ('duplicate row', '\n'.join([valid_rows[0], valid_rows[0], *valid_rows[2:]]), False),
    ('unsorted rows', '\n'.join(list(reversed(valid_rows))), False),
    ('absolute path', valid.replace('./CHECKSUMS.md5', '/CHECKSUMS.md5', 1), False),
    ('parent traversal', valid.replace('./CHECKSUMS.md5', './../CHECKSUMS.md5', 1), False),
    ('dot traversal', valid.replace('./CHECKSUMS.md5', '././CHECKSUMS.md5', 1), False),
    ('binary marker', valid.replace('  ./CHECKSUMS.md5', ' *./CHECKSUMS.md5', 1), False),
    ('one-space separator', valid.replace('  ./CHECKSUMS.md5', ' ./CHECKSUMS.md5', 1), False),
    ('tab separator', valid.replace('  ./CHECKSUMS.md5', '\t./CHECKSUMS.md5', 1), False),
    ('uppercase digest', valid_rows[0][:64].upper() + valid[64:], False),
    ('short digest', valid[1:], False),
    ('escaped filename record', '\\' + valid, False),
    ('empty record', valid.replace('\n', '\n\n', 1), False),
    ('hidden additional path', valid.replace('./testing/PACKAGES.TXT', './testing/.hidden'), False),
    ('trailing path text', valid + ' unexpected', False),
    ('empty manifest', '', False),
]
for label, text, success in manifest_cases:
    result = run(['bash', '-c', pure_script, 'synthetic-design', 'validate_v4_manifest_text', text])
    check('pure design manifest case: ' + label, (result.returncode == 0) == success)
for label, args, success in [
    ('canonical fresh format', ['bcfac4fa-4e6e-450a-aa95-bd591a979b4e'], True),
    ('canonical all-zero format', ['00000000-0000-0000-0000-000000000000'], True),
    ('uppercase', ['BCFAC4FA-4E6E-450A-AA95-BD591A979B4E'], False),
    ('trailing whitespace', ['bcfac4fa-4e6e-450a-aa95-bd591a979b4e '], False),
    ('wrong length', ['bcfac4fa-4e6e-450a-aa95-bd591a979b4'], False),
    ('missing argument', [], False),
    ('extra argument', ['bcfac4fa-4e6e-450a-aa95-bd591a979b4e', 'extra'], False),
]:
    result = run(['bash', '-c', pure_script, 'synthetic-design', 'validate_fresh_boot_id', *args])
    check('pure UUID case: ' + label, (result.returncode == 0) == success)
check('pure design file inventory exact', run(['bash', '-c', pure_script, 'synthetic-design', 'v4_expected_files']).stdout.splitlines() == design['expected_regular_files'])
authorization = policy['authorization']
check('only repository design freeze open', [k for k, v in authorization.items() if v] == ['repository_only_revalidation_design_freeze_authorized'])
check('accepted design review grant consumed', not authorization['repository_only_revalidation_design_review_authorized'])
for key in ['machine_action_required', 'controller_action_required', 'pause_safe', 'strong_safe_pause']:
    check('current repository workstream state: ' + key, policy[key] is False)
check('next stage follows provisional roadmap', policy['next_stage'] == previous['roadmap']['preferred_steps'][2]['stage'] == base.replace('design-review', 'design-freeze'))
check('acceptance excludes all production host entry', policy['repository_acceptance_scope'] == dict(accepted_predecessor_full_repository_acceptance_required=True, production_main_entered=False, production_builder_entered=False, live_target_observation_performed=False, production_host_guards_entered=False, production_constants_modified=False, full_future_probe_installed=False, pure_design_uuid_and_manifest_validators_exercised=True))
rows = [line.split('\t') for line in (fixture / (base + '.tsv')).read_text().splitlines()]
check('strict unique real-tab record', all(len(row) == 2 and all(row) for row in rows) and len(rows) == len(dict(rows)))
record = dict(rows)
check('record confirmed predecessor and design identity', record['step'] == '290' and record['accepted_checkpoint_commit'] == 'fc9150c' and record['expected_future_probe_sha256'] == design['expected_derivation_sha256'] and record['design_state'] == design['state'])
check('record current state unknown and no runtime or installed probe', record['current_boot_id'] == 'not-observed' and record['future_probe_installed'] == record['prior_live_binding_reusable'] == record['runtime_attempt_authorized'] == 'no')
check('record permissions and next stage consistent', all(record[k] == ('yes' if v else 'no') for k, v in authorization.items()) and record['next_stage'] == policy['next_stage'])
for argv in [['--help'], ['--bogus'], [], ['--output-dir'], ['--output-dir', '']]:
    result = run(['bash', '--', helper, *argv])
    check('strict helper CLI ' + repr(argv), result.returncode == (0 if argv == ['--help'] else 2))
with tempfile.TemporaryDirectory(prefix='step290-design-') as directory:
    tmp = Path(directory); planned_path = tmp / 'design-only-bash-syntax.sh'; planned_path.write_text(planned)
    check('whole in-memory planned source Bash syntax', run(['bash', '-n', planned_path]).returncode == 0)
    output = tmp / 'design output'; output.mkdir()
    result = run(['bash', '--', helper, '--output-dir', output])
    check('complete accepted155 predecessor actually reruns', result.returncode == 0 and 'accepted_step289_revalidated\tPASS (155 passes, 0 failures)' in result.stdout)
    for suffix in ['-policy.json', '.tsv', '-design.json']:
        check('exact design publication ' + suffix, (output / (base + suffix)).read_bytes() == (fixture / (base + suffix)).read_bytes())
    check('helper reports no installed probe or live observation', 'future_probe_installed\tno' in result.stdout and 'live_target_observation_performed\tno' in result.stdout and 'strong_safe_pause\tno' in result.stdout)
    before = {p.name: p.read_bytes() for p in output.iterdir()}
    check('duplicate output rejected without overwrite', run(['bash', '--', helper, '--output-dir', output]).returncode != 0 and {p.name: p.read_bytes() for p in output.iterdir()} == before)
    link = tmp / 'output-link'; link.symlink_to(output, target_is_directory=True)
    check('symlink output rejected', run(['bash', '--', helper, '--output-dir', link]).returncode != 0)
    nested = output / 'nested'; nested.mkdir()
    check('symlink output ancestor rejected', run(['bash', '--', helper, '--output-dir', link / 'nested']).returncode != 0 and not list(nested.iterdir()))
    check('missing output directory rejected', run(['bash', '--', helper, '--output-dir', tmp / 'missing']).returncode != 0 and not (tmp / 'missing').exists())
    replica = tmp / 'replica'; shutil.copytree(root, replica, ignore=shutil.ignore_patterns('.git'))
    rejected = tmp / 'rejected'; rejected.mkdir(); replica_helper = replica / helper.relative_to(root)
    for rel in list(accepted['sha256_bindings']) + [k for k in own_hashes if k != helper.relative_to(root).as_posix()]:
        target = replica / rel; original_bytes = target.read_bytes(); target.write_bytes(original_bytes + b'\n')
        result = run(['bash', '--', replica_helper, '--output-dir', rejected])
        check('changed input rejected before publication: ' + target.name, result.returncode != 0 and not list(rejected.iterdir()))
        target.write_bytes(original_bytes)
    for section, key, value in [
        ('authorization', 'new_probe_execution_authorized', True),
        ('authorization', 'new_probe_implementation_authorized', True),
        ('fresh_boundary', 'current_boot_id', 'bcfac4fa-4e6e-450a-aa95-bd591a979b4e'),
        ('design', 'production_expected_uid_gid', '1000:1000'),
        ('design', 'expected_derivation_sha256', '0' * 64),
    ]:
        target = replica / policy_path.relative_to(root); original_bytes = target.read_bytes(); bad = json.loads(original_bytes)
        bad[section][key] = value; target.write_text(json.dumps(bad) + '\n')
        result = run(['bash', '--', replica_helper, '--output-dir', rejected])
        check('permission, binding or design drift rejected: ' + key, result.returncode != 0 and not list(rejected.iterdir()))
        target.write_bytes(original_bytes)
check('future production probe still absent after acceptance', not (root / design['future_probe_path']).exists())
for rel in list(own_hashes) + ['tests/reference/test-' + base + '-harness.sh']:
    check('no trailing whitespace: ' + Path(rel).name, all(line == line.rstrip() for line in (root / rel).read_text().splitlines()))
changelog = (root / 'CHANGELOG.md').read_text()
check('CHANGELOG confirms predecessor and distinguishes design stage', '## Phase 1 step 290 ' in changelog and 'fc9150c' in changelog and 'Step 288 remains the accepted historical strong-pause checkpoint' in changelog and '## Phase 1 step 289 ' in changelog)
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST
