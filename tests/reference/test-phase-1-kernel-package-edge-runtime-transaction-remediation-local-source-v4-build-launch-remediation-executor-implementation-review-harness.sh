#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PY'
from pathlib import Path
import hashlib,json,shutil,subprocess,sys,tempfile
root=Path(sys.argv[1])
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-implementation-review'
prior='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-design-freeze'
fixture=root/'tests/fixtures/reference/acceptance/phase-1'
helper=root/'tools/reference'/(base+'.sh')
policy=json.loads((fixture/(base+'-policy.json')).read_text())
previous=json.loads((fixture/(prior+'-policy.json')).read_text())
own_hashes={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-implementation-review.md': '353aa3c7c2f2217646e3aeb141ea83bf310107674806d65c0c867681b65685b3', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-implementation-review-policy.json': 'a0a6fb6c7fd7de0172d0b6a0e5ef698e7d00ec38088d182b581a4f85d9abc8ce', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-implementation-review.tsv': '6a9addada4d287e848ba5b9328ed642454c488c2bac489225aa2145e77fdba59', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor.sh': '43e07ebfbf2c4ddd263cfbea9214477e620901dbd391aff9ff45c23bd2e8752d', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-implementation-review.sh': '009c20563eff10cd9521b84820a4f1edb8860132a498d1ff48d4c178e8f08b90'}
passes=0
def check(label,value):
    global passes
    if not value:raise SystemExit('FAIL: '+label)
    passes+=1
    print('PASS: '+label)
def run(args):return subprocess.run([str(x) for x in args],capture_output=True,text=True)
for rel,digest in (own_hashes|policy['accepted_checkpoint']['sha256_bindings']).items():
    p=root/rel
    check('artifact binding: '+p.name,p.is_file() and not p.is_symlink() and hashlib.sha256(p.read_bytes()).hexdigest()==digest)
for p in [helper,root/'tests/reference'/('test-'+base+'-harness.sh')]:
    check('Bash syntax: '+p.name,run(['bash','-n',p]).returncode==0)
check('step and accepted commit',policy['step']==274 and policy['review_status']=='PASS' and policy['accepted_checkpoint']['commit']=='f1d28b9')
check('no operational or pause claim',all(policy[k] is False for k in ['machine_action_required','controller_action_required','pause_safe','strong_safe_pause']))
check('only implementation freeze is open',[k for k,v in policy['authorization'].items() if v]==['repository_only_executor_implementation_freeze_authorized'])
i=policy['implementation']
check('reviewed implementation has no production entry',i['state']=='implemented-reviewed-not-frozen-not-production-executed' and not i['production_main_entered'] and not i['production_builder_entered'] and not i['live_target_observation_performed'])
check('frozen design preserved',i['frozen_design']==previous['frozen_design'])
check('preservation contract unchanged',policy['preservation']==previous['preservation'])
executor=root/i['executor_path']
baseline=(root/i['baseline_path']).read_text()
implemented=executor.read_text()
check('executor SHA-256 matches',hashlib.sha256(executor.read_bytes()).hexdigest()==i['executor_sha256'])
check('immutable baseline SHA-256 matches',hashlib.sha256(baseline.encode()).hexdigest()==i['baseline_sha256'])
check('immutable builder SHA-256 matches',hashlib.sha256((root/i['builder_path']).read_bytes()).hexdigest()==i['builder_sha256'])
expected=baseline
for rule in i['derivation_recipe']:
    check('allowlisted derivation: '+rule['label'],expected.count(rule['before'])==rule['occurrences']==1)
    expected=expected.replace(rule['before'],rule['after'],1)
check('exact allowlisted executor derivation',expected==implemented)
import re,os
def function_text(text,name):
    start=re.search(r'(?m)^'+re.escape(name)+r'\(\) \{',text).start()
    end=re.search(r'(?m)^[A-Za-z_][A-Za-z_0-9]*\(\) \{',text[start+1:])
    return text[start:start+1+end.start() if end else len(text)].rstrip('\n')
for name in i['frozen_design']['guard_functions_preserved_exactly']:
    check('unchanged verification function: '+name,function_text(baseline,name)==function_text(implemented,name))
old_constants=[line for line in baseline.splitlines() if line.startswith('readonly ') and not line.startswith('readonly EXPECTED_BOOT_ID=')]
new_constants=[line for line in implemented.splitlines() if line.startswith('readonly ')]
check('all non-boot readonly constants unchanged',old_constants==new_constants)
check('no historical boot default','EXPECTED_BOOT_ID' not in implemented and 'd34855ae-e039-4005-a842-1bef51082195' not in implemented)
main=implemented[implemented.index('\nmain() {'):]
check('all final preflight checks precede launch',main.index('    verify_local_source_v3\n')<main.index('    verify_failed_v2_evidence\n')<main.index('    verify_v4_outputs_absent\n')<main.index('    launch_verified_builder '))
check('fresh authorized boot comparison retained','[[ $boot_id == "$authorization_boot_id" ]]' in main)
check('one exact Bash launch',implemented.count('if bash -- "$builder" --build-local-source-v4; then')==1 and main.count('launch_verified_builder ')==1)
check('executor Bash syntax',run(['bash','-n',executor]).returncode==0)
clean_env=os.environ.copy();clean_env.pop('SLACK_UPDATE_V4_BUILD_LAUNCH_LIBRARY_ONLY',None)
def direct(args,library=False):
    env=clean_env.copy()
    if library:env['SLACK_UPDATE_V4_BUILD_LAUNCH_LIBRARY_ONLY']='1'
    return subprocess.run(['bash','--',str(executor)]+args,capture_output=True,text=True,env=env)
def seam(code,args=(),env_extra=None):
    env=clean_env.copy();env.update(env_extra or {})
    source='SLACK_UPDATE_V4_BUILD_LAUNCH_LIBRARY_ONLY=1 source -- "$1"; shift; '
    return subprocess.run(['bash','--noprofile','--norc','-c',source+code,'step274-test',str(executor)]+[str(x) for x in args],capture_output=True,text=True,env=env)
check('default help is non-mutating',direct(['--help']).returncode==0)
check('direct execution refuses library mode',direct(['--help'],library=True).returncode==2)
loaded=seam('declare -F parse_authorization_boot_id launch_verified_builder main >/dev/null')
check('sourced seam defines functions without main entry',loaded.returncode==0 and loaded.stdout=='' and loaded.stderr=='')
uuid='12345678-1234-1234-1234-123456789abc'
switch='--execute-authorized-local-source-v4-build-v2'
valid=seam('parse_authorization_boot_id "$@"',[switch,'--authorization-boot-id',uuid])
check('strict parser accepts exact interface',valid.returncode==0 and valid.stdout==uuid+'\n')
invalid_cases=[('missing-all',[]),('old-switch',['--execute-authorized-local-source-v4-build']),('missing-uuid',[switch,'--authorization-boot-id']),('missing-boot-option',[switch,uuid]),('extra-argument',[switch,'--authorization-boot-id',uuid,'extra']),('duplicate-boot-option',[switch,'--authorization-boot-id',uuid,'--authorization-boot-id',uuid]),('unknown-option',[switch,'--unknown',uuid]),('uppercase-uuid',[switch,'--authorization-boot-id',uuid.upper()]),('malformed-uuid',[switch,'--authorization-boot-id','invalid']),('executable-looking-input',[switch,'--authorization-boot-id','$(printf injected)'])]
for label,args in invalid_cases:
    rejected=seam('parse_authorization_boot_id "$@"',args)
    check('parser rejects '+label,rejected.returncode==2 and rejected.stdout=='')
    rejected=direct(args)
    check('default entry rejects '+label+' before host preflight',rejected.returncode==2 and rejected.stdout=='')
with tempfile.TemporaryDirectory(prefix='step274-launch-') as test_tmp:
    test_tmp=Path(test_tmp)
    inert=test_tmp/'transported builder with spaces.sh'
    marker=test_tmp/'entry-marker'
    inert.write_text("#!/bin/bash\nprintf '%s\\n' \"$#\" \"$1\"\nprintf entered > \"$STEP274_ENTRY_MARKER\"\n")
    inert.chmod(0o644)
    digest=hashlib.sha256(inert.read_bytes()).hexdigest()
    def launch(path,digest,code='launch_verified_builder "$@"'):
        marker.unlink(missing_ok=True)
        return seam(code,[path,digest],{'STEP274_ENTRY_MARKER':str(marker)})
    result=launch(inert,digest)
    check('actual launch succeeds at 0644 through spaced path',result.returncode==0 and marker.exists() and result.stdout.startswith('1\n--build-local-source-v4\n'))
    check('success published after zero','v4_v2_authorized_build_executor_status\tPASS\n' in result.stdout)
    check('builder bytes and mode preserved',hashlib.sha256(inert.read_bytes()).hexdigest()==digest and (inert.stat().st_mode&0o777)==0o644)
    result=launch(test_tmp/'missing.sh',digest)
    check('missing builder rejected before entry and success',result.returncode!=0 and not marker.exists() and 'v4_v2_authorized_build_executor_status' not in result.stdout)
    symlink=test_tmp/'builder-link';symlink.symlink_to(inert)
    result=launch(symlink,digest)
    check('symlink rejected before entry and success',result.returncode!=0 and not marker.exists() and 'v4_v2_authorized_build_executor_status' not in result.stdout)
    inert.write_text('#!/bin/bash\nprintf changed > "$STEP274_ENTRY_MARKER"\n')
    result=launch(inert,digest)
    check('changed builder rejected before entry and success',result.returncode!=0 and not marker.exists() and 'v4_v2_authorized_build_executor_status' not in result.stdout)
    inert.write_text('#!/bin/bash\nprintf entered > "$STEP274_ENTRY_MARKER"\nexit 37\n')
    digest=hashlib.sha256(inert.read_bytes()).hexdigest()
    result=launch(inert,digest)
    check('surrogate exit 37 propagated',result.returncode==37 and marker.exists())
    check('no success after failure','v4_v2_authorized_build_executor_status' not in result.stdout and 'authorization_consumed\tyes' not in result.stdout)
    result=launch(inert,digest,'command() { return 1; }; launch_verified_builder "$@"')
    check('unavailable Bash rejected before entry',result.returncode!=0 and not marker.exists() and 'required command missing: bash' in result.stderr)
    result=seam('launch_verified_builder')
    check('launch rejects missing binding arguments',result.returncode!=0)
check('acceptance scope excludes production main and target observation',policy['evidence_scope']=='repository-only-implementation-acceptance-no-production-main-or-target-observation')
check('non-mutating help',run(['bash','--',helper,'--help']).returncode==0)
check('unknown option rejected',run(['bash','--',helper,'--bogus']).returncode!=0)
with tempfile.TemporaryDirectory(prefix='repository-stage-') as tmp:
    tmp=Path(tmp);out=tmp/'review output';out.mkdir()
    result=run(['bash','--',helper,'--output-dir',out])
    check('complete accepted predecessor acceptance reruns',result.returncode==0 and 'accepted_predecessor_revalidated\tyes' in result.stdout)
    for suffix in ['-policy.json','.tsv']:
        check('exact review output '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('existing review outputs rejected',run(['bash','--',helper,'--output-dir',out]).returncode!=0)
    link=tmp/'output-link';link.symlink_to(out,target_is_directory=True)
    check('symlink output directory rejected',run(['bash','--',helper,'--output-dir',link]).returncode!=0)
    replica=tmp/'replica';shutil.copytree(root,replica)
    tampered=replica/'tools/reference'/(prior+'.sh')
    tampered.write_bytes(tampered.read_bytes()+b'\n# changed accepted predecessor\n')
    rejected=tmp/'rejected';rejected.mkdir()
    check('changed predecessor rejected before publication',run(['bash','--',replica/'tools/reference'/(base+'.sh'),'--output-dir',rejected]).returncode!=0 and not list(rejected.iterdir()))
    tampered.write_bytes((root/'tools/reference'/(prior+'.sh')).read_bytes())
    altered=replica/'tests/fixtures/reference/acceptance/phase-1'/(base+'-policy.json')
    altered.write_bytes(altered.read_bytes()+b'\n')
    check('changed policy rejected before publication',run(['bash','--',replica/'tools/reference'/(base+'.sh'),'--output-dir',rejected]).returncode!=0 and not list(rejected.iterdir()))
record=dict(line.split('\t') for line in (fixture/(base+'.tsv')).read_text().splitlines())
check('record matches review and continuation',record['step']==str(policy['step']) and record['review_status']=='PASS' and record['next_stage']==policy['next_stage'])
for key,value in policy['authorization'].items():check('record authority: '+key,record[key]==('yes' if value else 'no'))
for rel in list(own_hashes)+['tests/reference/test-'+base+'-harness.sh']:
    check('no trailing whitespace: '+Path(rel).name,all(line==line.rstrip() for line in (root/rel).read_text().splitlines()))
check('CHANGELOG records stage','## Phase 1 step 274 ' in (root/'CHANGELOG.md').read_text())
print(f'Result: PASS ({passes} passes, 0 failures)')
PY
