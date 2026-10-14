#!/usr/bin/env python3
"""Supplied repository-only freeze eligibility; never self-confirm actual pause."""
import hashlib
import json
import re

POLICY_SHA = 'c762ad743db933eb0465b4355340a5013960db879302509a37eed526f060675d'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode())


def exact(actual, expected, label):
    if type(actual) is not type(expected):
        raise ValueError(label)
    different = actual != expected if type(actual) is bytes else canonical(actual) != canonical(expected)
    if different:
        raise ValueError(label)
    return True


def pointer(value, path):
    if path == '':
        return value
    if not path.startswith('/'):
        raise ValueError('invalid JSON pointer')
    for encoded in path[1:].split('/'):
        key = encoded.replace('~1', '/').replace('~0', '~')
        if type(value) is list:
            if not re.fullmatch(r'0|[1-9][0-9]*', key) or int(key) >= len(value):
                raise ValueError('invalid list pointer')
            value = value[int(key)]
        else:
            value = value[key]
    return value


def validate_policy(policy):
    return exact(canonical(policy), POLICY_SHA, 'authored418 policy substitution')


def validate_sources(inputs, source_blobs, sources, policy):
    validate_policy(policy)
    exact(canonical(sources), policy['fixture_canonical_sha256']['sources'], 'whole authored418 source registry')
    exact(sorted(inputs), sorted(sources['inputs']), 'all145 whole JSON inputs')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole source bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole source value ' + key)
    previous = json.loads(inputs['sources417'])
    inherited = {k: v for k, v in sources['inputs'].items() if k not in policy['new_source_keys']}
    exact(inherited, previous['inputs'], 'all141 original input bindings unchanged')
    exact(sources['inert_roots'], previous['inert_roots'], 'all four native roots remain inert')
    exact(sources['reviewer_roots'][:-1], previous['reviewer_roots'], 'all prior reviewer roots unchanged')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(row['path'] for row in roots), 'all44 source roots')
    for row in roots:
        exact(sha(source_blobs[row['path']]), row['sha256'], 'whole root bytes ' + row['path'])
    for row in sources['inert_roots']:
        exact(row['execution_authorized'], False, 'native root never dispatched')
        exact(row['actual_native_binding'], None, 'no native binding')
    return True


def validate_fixtures(fixtures, policy):
    validate_policy(policy)
    exact(sorted(fixtures), sorted(policy['fixture_canonical_sha256']), 'exact authored fixture set')
    for key, value in fixtures.items():
        exact(canonical(value), policy['fixture_canonical_sha256'][key], 'whole authored fixture ' + key)
    return True


def validate_repository(blobs, baseline, policy):
    validate_policy(policy)
    exact(sorted(blobs), sorted(baseline), 'all2266 historical417 paths')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path in policy['prefixes']:
            prefix = policy['prefixes'][path].encode()
            if not raw.startswith(prefix):
                raise ValueError('missing exact418 additive prefix')
            raw = raw[len(prefix):]
        exact(sha(raw), digest, 'unchanged historical417 bytes ' + path)
    return True


def validate_entry(entry,inputs,policy):
    validate_policy(policy);exact(canonical(entry),policy['fixture_canonical_sha256']['entry417'],'WHOLE actual417 entry')
    raw=entry['receipt']['text'].encode('utf-8');exact(sha(raw),entry['receipt']['sha256'],'complete417 transcript SHA');exact(len(raw),entry['receipt']['size_bytes'],'complete417 length')
    exact([s for s in entry['receipt']['text'].splitlines() if s.startswith('PASS: ')],policy['receipt_pass_labels'],'all79 ordered417 PASS')
    exact(re.findall(r'^ create mode 100644 (.+)$',entry['receipt']['text'],re.M),policy['receipt_create_paths'],'eight exact417 creates')
    for marker in policy['receipt_single_markers']:exact(entry['receipt']['text'].count(marker),1,'single417 marker')
    exact(entry['receipt']['text'].split(policy['receipt_push_marker'])[1],policy['receipt_final_tail'],'reported main push empty status matching0a6aad0heads')
    exact(entry['confirmation']['commit_prefix'],'0a6aad0','accepted417 prefix');exact(entry['confirmation']['commit_full'],None,'full user Git ID unknown');exact(entry['confirmation']['new_strong_safe_pause_confirmed'],False,'417 intermediate checkpoint only')
    exact(entry['whole_confirmed416_entry_reference'],policy['expected_prior_entry_reference'],'WHOLE actual prior416 entry');exact(json.loads(inputs['actual416_entry'])['confirmation']['last_confirmed_strong_safe_pause_step'],408,'last confirmed repository pause408 only')
    return True


def validate_current_conditions(freeze,inputs,policy):
    validate_policy(policy);old=json.loads(inputs['freeze408']);oldentry=json.loads(inputs['actual408_entry']);plan=json.loads(inputs['plan409'])
    rows=freeze['conditions'];exact(len(rows),9,'all nine WHOLE current conditions')
    exact(oldentry['external_conditions']['all_nine_whole_conditions_confirmed'],True,'actual historical408 all-nine confirmation retained')
    exact(oldentry['external_conditions']['scope'],'repository-joint-contract-proposal399-408-only','historical confirmation scope unexpanded')
    for i,(row,original,external) in enumerate(zip(rows,old['conditions'],oldentry['external_conditions']['conditions'])):
        exact(row['position'],i,'ordered current condition position');exact(row['id'],original['id'],'same complete requirement identity');exact(row['requirement'],original['requirement'],'original requirement retained')
        exact(row['whole_original_externally_confirmed408_condition'],external,'WHOLE externally confirmed408 condition with ALL nested original bodies')
        exact(external['whole_prepared408_condition'],original,'WHOLE prepared408 original untouched')
        reference=plan['pause_policy']['condition_references'][i]
        exact(pointer(oldentry,reference['entry_json_pointer']),original,'WHOLE nested original direct external-entry pointer')
        exact(canonical(original),reference['whole_condition_canonical_sha256'],'exact whole original nested binding')
        exact(row['current_scope'],'repository-internal-manuscript-audit409-418-only','new scope is409-418 only')
        exact(row['repository_review_basis_for409_418'],policy['expected_condition_bases'][i],'complete CURRENT review basis not ID/count summary')
        exact(row['repository_status'],'repository-reviewed-conditional-eligibility-only-pending-complete418-return-and-external-all-nine-confirmation','prepared eligibility not actual confirmation')
        exact(row['current418_actual_user_confirmation'],None,'actual418 receipt confirmation pending');exact(row['current418_external_condition_confirmation'],None,'separate external current confirmation pending')
        exact(row['actual_native_evidence'],None,'no actual native proof');exact(row['actual_global_host_closure'],False,'no global host closure')
    return True


def validate_checkpoint_chain(freeze,entry,inputs,policy):
    validate_policy(policy);rows=freeze['complete_accepted_checkpoint_chain409_417'];exact(len(rows),9,'all nine COMPLETE actual409-417 entries')
    for row,expected in zip(rows,policy['expected_checkpoints']):
        n,prefix,passes,insertions,prior=expected;exact(row['step'],n,'exact actual checkpoint step')
        key='actual'+str(n)+'_entry' if n<417 else None;exact(row['source_input_key'],key,'correct whole actual entry source')
        original=json.loads(inputs[key]) if key else entry;exact(row['whole_actual_user_entry'],original,'COMPLETE original actual entry not abbreviated')
        receipt=original['receipt'];confirmation=original['confirmation'];text=receipt['text'];raw=text.encode('utf-8')
        exact(sha(raw),receipt['sha256'],'complete historical receipt SHA');exact(len(raw),receipt['size_bytes'],'complete historical receipt length')
        labels=[line for line in text.splitlines() if line.startswith('PASS: ')];exact(labels,receipt['ordered_PASS_labels'],'every exact ordered actual PASS label');exact(len(labels),passes,'exact ordered actual PASS count')
        exact(re.findall(r'^ create mode 100644 (.+)$',text,re.M),receipt['exact_created_paths'],'all exact actual create paths');exact(len(receipt['exact_created_paths']),8,'eight creates')
        push='   '+prior+'..'+prefix+'  main -> main\n';exact(receipt['reported_push_marker'],push,'actual ordered main push')
        tail=prefix+' (HEAD -> main, origin/main, origin/HEAD) '+confirmation['exact_commit_message']+'\n'
        exact(text.split(push)[1],tail*2+'promano@pc-arch ~/Descargas $ \n','actual push clean status two matching heads final tail')
        markers=['step'+str(n)+'_overlay_application_status\tPASS','step'+str(n)+'_commit_scope_verification_status\tPASS','Result: PASS ('+str(passes)+' passes, 0 failures)','[main '+prefix+'] '+confirmation['exact_commit_message'],' 10 files changed, '+str(insertions)+' insertions(+)','To github.com:promano7/slack-update.git',push]
        for marker in markers:exact(text.count(marker),1,'single exact actual checkpoint marker')
        exact(confirmation['commit_prefix'],prefix,'reported exact user checkpoint prefix');exact(confirmation['commit_full'],None,'historical full user Git ID unknown')
        for k in ['user_application_completed','user_harness_completed','user_commit_and_push_completed','user_worktree_clean','user_head_matches_origin']:exact(confirmation[k],True,'complete reported predecessor acceptance '+k)
        exact(confirmation['new_strong_safe_pause_confirmed'],False,'all409-417 intermediate only');exact(confirmation['last_confirmed_strong_safe_pause_step'],408,'historical confirmed pause still408')
        for k,v in [('commit_prefix',prefix),('commit_full',None),('ordered_pass_count',passes),('changed_files',10),('creates',8),('insertions',insertions),('deletions',0),('previous_commit_prefix',prior),('intermediate_checkpoint_not_strong_pause',True)]:exact(row[k],v,'actual checkpoint metadata '+k)
    return True


def validate_freeze(freeze,entry,inputs,sources,policy):
    validate_policy(policy);exact(freeze['schema'],1,'integer schema');exact(freeze['step'],418,'integer418')
    exact(freeze['state'],'prepared-internal-manuscript-audit-freeze-pending-complete-final-return-and-external-all-nine-confirmation','PREPARED conditional freeze')
    exact(freeze['scope'],'repository-internal-manuscript-audit409-418-only','bounded current repository scope');exact(freeze['entry_commit_prefix'],'0a6aad0','actual417 accepted prefix')
    for key in policy['null_fields']:exact(freeze[key],None,'unselected or actual final evidence pending '+key)
    for key in policy['false_fields']:exact(freeze[key],False,'no authority promotion host claim or self-confirmation '+key)
    exact(freeze['boundaries'],policy['expected_boundaries'],'complete original closed boundaries')
    exact(freeze['whole_original_requirements_remain_normative'],True,'original norms binding');exact(freeze['frozen_inputs'],sources['inputs'],'all145 complete frozen input bindings')
    exact(freeze['frozen_source_roots'],sources['inert_roots']+sources['reviewer_roots']+[sources['readme']],'all44 roots and native roots inert')
    exact(freeze['whole_accepted417_decision_brief'],json.loads(inputs['brief417']),'WHOLE unselected417 brief/all losses/findings/attachments/separate decisions')
    audit=json.loads(inputs['audit416']);criteria=json.loads(inputs['audit415']);packet=json.loads(inputs['packet407']);plan=json.loads(inputs['plan409'])
    exact(freeze['whole_integrated416_audit_results'],audit,'WHOLE416 findings/dimensions/options/pairs/decisions/dependencies/repairs/cases frozen')
    exact(freeze['whole_frozen407_manuscript_reference'],sources['inputs']['packet407'],'complete frozen original407 manuscript binding');exact(freeze['whole415_complete_member_criteria_reference'],sources['inputs']['audit415'],'complete original member criterion source binding')
    position=0
    for i,category in enumerate(criteria['all15_category1286_member_impact_reviews']):
        for j,member in enumerate(category['member_reviews']):
            row=audit['all1286_member_dependency_dispositions'][position];reference=row['whole_415_member_review_reference']
            exact(reference['json_pointer'],'/all15_category1286_member_impact_reviews/'+str(i)+'/member_reviews/'+str(j),'every whole member in original order')
            exact(pointer(criteria,reference['json_pointer']),member,'whole member original content/specific proof AND case criteria')
            exact(canonical(member),reference['canonical_sha256'],'complete whole member binding,not a sample')
            exact(row['member_id'],member['whole_frozen407_member']['member_id'],'exact member dependency identity');position+=1
    exact(position,1286,'all1286 whole member criteria retained');exact(len(audit['all1286_member_dependency_dispositions']),1286,'no extra or shortened dependency scope')
    exact(freeze['whole_409_pause_policy'],plan['pause_policy'],'WHOLE original current409-418 pause policy')
    exact(freeze['whole_historical_confirmed408_entry'],json.loads(inputs['actual408_entry']),'COMPLETE historical408 receipt/all-nine conditions/context unaltered')
    validate_checkpoint_chain(freeze,entry,inputs,policy);validate_current_conditions(freeze,inputs,policy)
    for key in ['repository_review_eligible_for_conditional_pause','final_pause_requires_all_nine_whole_original_conditions','final_pause_requires_complete_actual_user_receipt','final_pause_requires_separate_external_all_nine_confirmation','open_findings_may_remain_at_repository_pause','no_automatic419']:exact(freeze[key],True,'conditional closure requirement '+key)
    exact(freeze['required_final_commit_message'],'Phase 1 step 418: freeze internal joint manuscript audit for conditional strong safe pause','exact final commit scope/message')
    exact(freeze['final_receipt_rule'],policy['expected_final_receipt_rule'],'COMPLETE final return and separate external ALL9 required')
    exact(freeze['after_final_acceptance'],policy['expected_after_final_acceptance'],'STOP/nextNULL/new request after externally confirmed418')
    exact(freeze['last_confirmed_strong_safe_pause_step'],408,'no current418 confirmed pause yet');exact(freeze['actual_host_state'],'unobserved-not-claimed-absent','actual host unobserved');exact(freeze['actual_live_bindings'],None,'no current live binding');exact(freeze['actual_global_host_closure'],False,'no global host closure')
    exact(freeze['native_cases_run'],0,'no native tests');exact(freeze['native_proofs_added'],0,'no native proof');exact(freeze['remaining_review_and_approval_order'],plan['approval_order'],'whole independent actual safe review then separate fresh grant')
    return True


def review(entry,freeze,inputs,source_blobs,sources,policy):
    validate_entry(entry,inputs,policy);validate_sources(inputs,source_blobs,sources,policy);validate_freeze(freeze,entry,inputs,sources,policy)
    return {'step':418,'state':'prepared-conditional-repository-pause-awaiting-complete-final-return-and-external-all-nine-confirmation','whole_conditions':9,'actual_checkpoint_receipts':9,'retained_open_findings':13,'selected_options':None,'approved_contract_migration':None,'independent_impact_review_accepted':False,'runtime_authority':False,'native_cases_run':0,'native_proofs_added':0,'actual_strong_safe_pause_confirmed':False,'all_nine_current418_conditions_externally_confirmed':False,'repository_review_eligible_for_conditional_pause':True,'last_confirmed_strong_safe_pause_step':408,'actual_host_state':'unobserved-not-claimed-absent','actual_live_bindings':None,'actual_global_host_closure':False,'machine_action_required':False,'controller_action_required':False,'no_automatic419':True,'next_authorized_stage_after418':None,'future_batch_requires_new_user_request':True}
