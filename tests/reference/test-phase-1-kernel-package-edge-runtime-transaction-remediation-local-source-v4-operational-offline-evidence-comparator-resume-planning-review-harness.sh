#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 -B - "$repo_root" <<'PYTEST'
from pathlib import Path
import ast
import copy
import hashlib
import json
import runpy
import subprocess
import sys
import tempfile

root = Path(sys.argv[1])
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-evidence-comparator-resume-planning-review'
fixture = root / 'tests/fixtures/reference/acceptance/phase-1'
review_path = root / 'tools/reference' / (base + '.py')
review = runpy.run_path(str(review_path))
passes = 0


def check(label, condition):
    global passes
    if not condition:
        raise AssertionError(label)
    passes += 1
    print('PASS: ' + label, flush=True)


def rejects(fn, *args):
    try:
        fn(*args)
    except (ValueError, KeyError, TypeError, OSError):
        return True
    return False


def load(tail):
    return json.loads((fixture / (base+'-'+tail+'.json')).read_bytes())


history = review['verify'](root)
policy = load('policy'); retained = load('retained-obligations'); plan = load('plan')
confirmation = load('checkpoint-confirmation'); receipt = load('step348-user-acceptance')
sources = review['validate_retained'](retained, history, policy)
check('all1719 accepted348 source bytes preserved', len(history) == 1719)
check('complete200 ordered original348 return and exact commit push heads accepted', review['validate_return'](confirmation, receipt, policy))
check('reported83ae543 scoped strong pause348 retained without full object invention', confirmation['strong_safe_pause'] and confirmation['commit_full'] is None and confirmation['scope'] == 'repository-offline-transition-core-workstream339-348-only')
check('new user scope plans exactly ten stages349-358', review['validate_plan'](plan, sources) and len(plan['route']) == 10)
check('last confirmed pause348 and conditional358 remain distinct', plan['last_confirmed_strong_safe_pause_step'] == 348 and plan['conditional_pause_step'] == 358 and not plan['strong_safe_pause'])
check('full independent provenance contract retained from335', plan['independence_boundary'] == sources['oracle335']['independence_contract'])
check('full source-bound contracts retained without abbreviated proof substitution', len(sources['reconciliation347']['retained_full_normative_rows']['exact_contract_views']) == 8)
check('26 unrun original cases per platform remain separately pending', all(sum(row['platform'] == p for row in sources['gaps348']['native_case_templates']) == 26 for p in ['Slackware-15.0','Slackware-current']))
check('all46 native proofs and16 native gaps remain blockers', len(sources['gaps348']['qualified_proofs']) == 46 and len(sources['gaps348']['native_gap_rows']) == 16)
for role, binding in retained['model_modules'].items():
    check('unchanged accepted pure core module '+role, hashlib.sha256(history[binding['path']]).hexdigest() == binding['sha256'])
for role, binding in retained['source_bindings'].items():
    check('full normative source remains bound '+role, hashlib.sha256(history[binding['path']]).hexdigest() == binding['sha256'])
for key in review['FALSE_FIELDS']:
    for value in [True, 0]:
        bad = copy.deepcopy(plan); bad[key] = value
        check('no native promotion or int boolean substitution '+key+'/'+repr(value), rejects(review['validate_plan'], bad, sources))
for key in review['TRUE_FIELDS']:
    bad = copy.deepcopy(plan); bad[key] = False
    check('required predecessor scope or stop boundary '+key, rejects(review['validate_plan'], bad, sources))
for key, value in [('scope','actual-native-runtime'),('actual_host_state','absent'),('actual_live_bindings',{'boot':'old'}),('compatibility_targets',['Slackware-current']),('compatibility_claim','both-platform-pass'),('last_confirmed_strong_safe_pause_step',349),('preferred_step_range',[349,360]),('conditional_pause_step',349),('native_cases_run',1),('native_proofs_added',True),('comparator_execution_scope','native-test-runner'),('schema',True),('step',True)]:
    bad = copy.deepcopy(plan); bad[key] = value
    check('planning cannot select target host compatibility or authority '+key, rejects(review['validate_plan'], bad, sources))
for name in review['COUNTS']:
    bad = copy.deepcopy(plan); bad['counts'][name] -= 1
    check('no inherited obligation count waiver '+name, rejects(review['validate_plan'], bad, sources))
bad = copy.deepcopy(plan); bad['counts']['capabilities'] = True
check('nested bool int count substitution rejected', rejects(review['validate_plan'],bad,sources))
bad = copy.deepcopy(plan); bad['extra_native_grant'] = 'historical'
check('unrecognized plan field rejected', rejects(review['validate_plan'],bad,sources))
for i, row in enumerate(plan['route']):
    bad = copy.deepcopy(plan); bad['route'][i]['entry_requires_confirmed_step'] = 348
    if i:
        check('complete immediate predecessor required at step'+str(row['step']), rejects(review['validate_plan'],bad,sources))
    bad = copy.deepcopy(plan); bad['route'][i]['runtime_authorized'] = True
    check('roadmap cannot authorize native dispatch at step'+str(row['step']), rejects(review['validate_plan'],bad,sources))
bad = copy.deepcopy(plan); bad['route'].reverse()
check('reordered route rejected',rejects(review['validate_plan'],bad,sources))
bad = copy.deepcopy(plan); bad['pause_conditions'] = bad['pause_conditions'][:-1]
check('all nine original pause requirements mandatory',rejects(review['validate_plan'],bad,sources))
bad = copy.deepcopy(plan); bad['independence_boundary']['expectation_author'] = 'subject selfreport'
check('candidate generated expectation cannot replace original independence contract',rejects(review['validate_plan'],bad,sources))
for name in retained['registers']:
    bad = copy.deepcopy(retained); bad['registers'][name] = bad['registers'][name][:-1]
    check('complete ordered normative index required '+name, rejects(review['validate_retained'],bad,history,policy))
bad = copy.deepcopy(retained); first = next(iter(bad['registers'])); bad['registers'][first][0]['canonical_row_sha256'] = '0'*64
check('altered full obligation content cannot be indexed',rejects(review['validate_retained'],bad,history,policy))
bad = copy.deepcopy(retained); bad['registers'][first][0]['position'] = False
check('nested indexed bool int ordinal substitution rejected',rejects(review['validate_retained'],bad,history,policy))
bad = copy.deepcopy(retained); del bad['model_modules']['schema']
check('missing frozen core module blocks planning',rejects(review['validate_retained'],bad,history,policy))
bad = copy.deepcopy(retained); bad['frozen_artifact_registry339_347'].pop()
check('missing frozen339-347 source input blocks planning',rejects(review['validate_retained'],bad,history,policy))
for key in ['user_application_completed','user_harness_completed','user_commit_and_push_completed','user_head_matches_origin','user_worktree_clean','complete_ordered_return_matches_prepared_and_installed','confirmation_external_to_immutable_repository']:
    bad = copy.deepcopy(confirmation); bad[key] = False
    check('incomplete external predecessor confirmation blocks planning '+key,rejects(review['validate_return'],bad,receipt,policy))
for key, value in [('runtime_authority',True),('commit_full','83ae543'+'0'*33),('actual_host_state','globally-closed'),('actual_live_bindings',{'epoch':'reused'}),('scope','global-host-closure'),('required_not_proven_native_proofs',0),('step',True)]:
    bad = copy.deepcopy(confirmation); bad[key] = value
    check('old receipt cannot invent actual host commit authority or proof '+key,rejects(review['validate_return'],bad,receipt,policy))
for name, text in [('truncated',receipt['text'][:-1]),('pass label changed',receipt['text'].replace('PASS: ','PASS: altered ',1)),('push omitted',receipt['text'].replace('   fed2808..83ae543  main -> main','')),('foreign final HEAD',receipt['text'].replace('83ae543 (HEAD -> main','0000000 (HEAD -> main',1))]:
    bad = copy.deepcopy(receipt); bad['text'] = text; bad['original_display_size_bytes'] = len(text.encode()); bad['original_display_sha256'] = hashlib.sha256(text.encode()).hexdigest()
    check('original predecessor return cannot be normalized or forged '+name,rejects(review['validate_return'],confirmation,bad,policy))
roadmap = (fixture/(base+'-roadmap.tsv')).read_text().splitlines()
check('roadmap TSV matches all ordered plan deliverables', len(roadmap)==11 and all(line.split('\t')==[str(row['step']),row['stage'],str(row['entry_requires_confirmed_step']),'no',row['deliverable']] for line,row in zip(roadmap[1:],plan['route'])))
tree = ast.parse(review_path.read_text())
imports = {node.module if isinstance(node,ast.ImportFrom) else alias.name for node in ast.walk(tree) if isinstance(node,(ast.Import,ast.ImportFrom)) for alias in (node.names if isinstance(node,ast.Import) else [None])}
check('planning reviewer has only declarative standard library imports',imports=={'pathlib','hashlib','json','sys'})
check('planning reviewer has no dynamic eval or exec calls',not any(isinstance(n,ast.Call) and isinstance(n.func,ast.Name) and n.func.id in {'eval','exec','compile','__import__'} for n in ast.walk(tree)))
for argv in [[],['--execute'],['--check',''],['--check',str(root),'--execute'],['--collect',str(root)]]:
    result = subprocess.run([sys.executable,'-B',str(review_path),*argv],capture_output=True,text=True)
    check('strict planning CLI '+repr(argv).replace(str(root),'<repository>'),result.returncode==2)
result = subprocess.run([sys.executable,'-B',str(review_path),'--check',str(root)],capture_output=True,text=True)
check('current source-bound349 reviewer CLI passes without authority',result.returncode==0 and 'runtime_authority\tno' in result.stdout and 'conditional_next_pause_step\t358' in result.stdout)

# Exact historical source reconstruction permits the unchanged348 verifier to
# inspect its original prepared flags. Complete prior test labels are receipt-bound;
# no recursive rerun is needed for unchanged code at this planning-only step.
with tempfile.TemporaryDirectory(prefix='step349-historical348-') as directory:
    historical = Path(directory)
    for relative, raw in history.items():
        p = historical/relative; p.parent.mkdir(parents=True,exist_ok=True); p.write_bytes(raw)
    old_path = historical/'tools/reference'/('phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-core-freeze-gap-register-and-safe-pause-review.py')
    old_review = runpy.run_path(str(old_path))
    check('unchanged348 verifier accepts exact1719 historical source',len(old_review['verify'](historical))==1710)
    damaged = historical / retained['model_modules']['schema']['path']
    damaged.write_bytes(damaged.read_bytes()+b'\n# Synthetic source corruption.\n')
    check('changed accepted pure core source blocks inherited348 verification',rejects(old_review['verify'],historical))
check('prepared349 never confirms a new actual pause or native case',not plan['strong_safe_pause'] and not plan['user_step349_checkpoint_confirmed'] and plan['native_cases_run']==0)
print('Result: PASS ('+str(passes)+' passes, 0 failures)',flush=True)
PYTEST
