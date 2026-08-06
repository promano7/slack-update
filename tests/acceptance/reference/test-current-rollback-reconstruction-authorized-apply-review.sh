#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../../.." && pwd -P)
DEFAULT_OUTPUT_ROOT=${ROLLBACK_AUTH_REVIEW_OUTPUT_ROOT:-/var/tmp/slack-update-acceptance/current-rollback-reconstruction-authorized-apply-review}
SOURCE_PLAN_SCRIPT=${ROLLBACK_AUTH_SOURCE_PLAN_SCRIPT:-$REPOSITORY_ROOT/tests/acceptance/reference/test-current-rollback-source-and-plan-preflight.sh}
SOURCE_PLAN_POLICY=${ROLLBACK_AUTH_SOURCE_PLAN_POLICY:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-rollback-source-and-plan-preflight-policy.json}
ACCEPTED_SOURCE_PLAN=${ROLLBACK_AUTH_ACCEPTED_SOURCE_PLAN:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-rollback-source-and-plan-preflight-20260806-accepted.json}
REVIEW_POLICY=${ROLLBACK_AUTH_REVIEW_POLICY:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-rollback-reconstruction-authorized-apply-review-policy.json}
REVIEW_SCRIPT=$REPOSITORY_ROOT/tests/acceptance/reference/test-current-rollback-reconstruction-authorized-apply-review.sh

TARGET=
CONFIRM_HOSTNAME=
CONFIRM_HOSTNAME_FQDN=
CONFIRM_SOURCE_PLAN_EVIDENCE_SHA256=
CONFIRM_ACTIVE_KERNEL=
CONFIRM_ROLLBACK_KERNEL=
CONFIRM_AUTHORIZATION_REVIEW_SHA256=
SOURCE_PACKAGE=
SOURCE_SIGNATURE=
OUTPUT_DIR=
ROOT_PREFIX=
PACKAGE_DATABASE=
PASS_COUNT=0
FAILURE_COUNT=0
SKIP_COUNT=0
ASSERTION_LOG=
NESTED_OUTPUT_DIR=
NESTED_PREFLIGHT_VALID=false
PLAN_REVIEW_VALID=false
STATE_UNCHANGED=false
APPLY_READY=false
APPLY_AUTHORIZED=false
APPLY_EXECUTED=false
NEXT_STAGE=current-rollback-reconstruction-authorized-apply-review-manual-review
TEST_MODE=${SLACK_UPDATE_TEST_MODE:-0}

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current \\
                     --confirm-hostname SHORT_HOSTNAME \\
                     --confirm-hostname-fqdn FQDN \\
                     --confirm-source-plan-evidence-sha256 SHA256 \\
                     --confirm-active-kernel VERSION \\
                     --confirm-rollback-kernel VERSION \\
                     --confirm-authorization-review-sha256 SHA256 \\
                     --source-package PATH \\
                     --source-signature PATH [options]

Perform the non-mutating authorization review for the exact optional rollback
reconstruction plan. The review reruns the accepted source-and-plan preflight,
revalidates the signed source and live boundary, audits every projected action,
and emits authorization only for the exact canonical apply contract. It does not extract
the package into the installed system, restore files, run depmod or mkinitrd,
modify GRUB, change the default boot entry, refresh repositories, or reboot.

Required options:
      --target slackware-current
      --confirm-hostname SHORT_HOSTNAME
      --confirm-hostname-fqdn FQDN
      --confirm-source-plan-evidence-sha256 SHA256
      --confirm-active-kernel VERSION
      --confirm-rollback-kernel VERSION
      --confirm-authorization-review-sha256 SHA256
      --source-package PATH
      --source-signature PATH

Optional arguments:
      --output-dir PATH         Store evidence under an absolute, new directory
  -h, --help                    Show this help and exit
EOF_USAGE
}

error() { printf 'ERROR: %s\n' "$*" >&2; }
record_pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf 'PASS: %s\n' "$1" | tee -a "$ASSERTION_LOG"; }
record_failure() { FAILURE_COUNT=$((FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" | tee -a "$ASSERTION_LOG" >&2; }
record_skip() { SKIP_COUNT=$((SKIP_COUNT + 1)); printf 'SKIP: %s\n' "$1" | tee -a "$ASSERTION_LOG"; }

is_sha256() {
    [ "${#1}" -eq 64 ] || return 1
    case "$1" in *[!0-9A-Fa-f]*) return 1 ;; esac
}

is_safe_kernel_version() {
    [ -n "$1" ] || return 1
    case "$1" in *[!0-9A-Za-z._+-]*) return 1 ;; esac
}

parse_arguments() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --target) [ "$#" -ge 2 ] || return 1; TARGET=$2; shift 2 ;;
            --confirm-hostname) [ "$#" -ge 2 ] || return 1; CONFIRM_HOSTNAME=$2; shift 2 ;;
            --confirm-hostname-fqdn) [ "$#" -ge 2 ] || return 1; CONFIRM_HOSTNAME_FQDN=$2; shift 2 ;;
            --confirm-source-plan-evidence-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_SOURCE_PLAN_EVIDENCE_SHA256=${2,,}; shift 2 ;;
            --confirm-active-kernel) [ "$#" -ge 2 ] || return 1; CONFIRM_ACTIVE_KERNEL=$2; shift 2 ;;
            --confirm-rollback-kernel) [ "$#" -ge 2 ] || return 1; CONFIRM_ROLLBACK_KERNEL=$2; shift 2 ;;
            --confirm-authorization-review-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_AUTHORIZATION_REVIEW_SHA256=${2,,}; shift 2 ;;
            --source-package) [ "$#" -ge 2 ] || return 1; SOURCE_PACKAGE=$2; shift 2 ;;
            --source-signature) [ "$#" -ge 2 ] || return 1; SOURCE_SIGNATURE=$2; shift 2 ;;
            --output-dir) [ "$#" -ge 2 ] || return 1; OUTPUT_DIR=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done
    [ "$TARGET" = slackware-current ] || return 1
    [ -n "$CONFIRM_HOSTNAME" ] && [ -n "$CONFIRM_HOSTNAME_FQDN" ] || return 1
    case "$CONFIRM_HOSTNAME$CONFIRM_HOSTNAME_FQDN" in *[[:space:]]*) return 1 ;; esac
    is_sha256 "$CONFIRM_SOURCE_PLAN_EVIDENCE_SHA256" || return 1
    is_sha256 "$CONFIRM_AUTHORIZATION_REVIEW_SHA256" || return 1
    is_safe_kernel_version "$CONFIRM_ACTIVE_KERNEL" || return 1
    is_safe_kernel_version "$CONFIRM_ROLLBACK_KERNEL" || return 1
    [ "$CONFIRM_ACTIVE_KERNEL" != "$CONFIRM_ROLLBACK_KERNEL" ] || return 1
    case "$SOURCE_PACKAGE" in /*) ;; *) return 1 ;; esac
    case "$SOURCE_SIGNATURE" in /*) ;; *) return 1 ;; esac
    if [ -n "$OUTPUT_DIR" ]; then case "$OUTPUT_DIR" in /*) ;; *) return 1 ;; esac; fi
}

rooted() { printf '%s%s\n' "$ROOT_PREFIX" "$1"; }
require_regular_file() { [ -f "$1" ] && [ ! -L "$1" ] && [ -r "$1" ]; }
file_sha256() { sha256sum -- "$1" | awk '{print $1}'; }
file_size() { stat -Lc '%s' -- "$1"; }

json_value() {
    python3 - "$1" "$2" <<'PY'
import json, sys
value=json.load(open(sys.argv[1], encoding='utf-8'))
for part in sys.argv[2].split('.'):
    value=value[part]
if isinstance(value, bool): print(str(value).lower())
elif isinstance(value, (dict, list)): print(json.dumps(value, separators=(',', ':'), sort_keys=True))
else: print(value)
PY
}

validate_review_boundary() {
    python3 - "$REVIEW_POLICY" "$REVIEW_SCRIPT" "$ACCEPTED_SOURCE_PLAN" "$SOURCE_PLAN_SCRIPT" "$SOURCE_PLAN_POLICY" \
        "$CONFIRM_HOSTNAME" "$CONFIRM_HOSTNAME_FQDN" "$CONFIRM_SOURCE_PLAN_EVIDENCE_SHA256" \
        "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$CONFIRM_AUTHORIZATION_REVIEW_SHA256" \
        "$SOURCE_PACKAGE" "$SOURCE_SIGNATURE" <<'PY'
import hashlib, json, pathlib, sys
(policy_path, review_script_path, accepted_path, source_script_path, source_policy_path,
 host, fqdn, evidence_sha, active, rollback, confirmed_scope, source_package, source_signature)=sys.argv[1:]
def regular(path):
    p=pathlib.Path(path)
    if not p.is_file() or p.is_symlink(): raise SystemExit(1)
    return p
def sha(path): return hashlib.sha256(regular(path).read_bytes()).hexdigest()
policy=json.loads(regular(policy_path).read_text(encoding='utf-8'))
accepted=json.loads(regular(accepted_path).read_text(encoding='utf-8'))
review_script_sha=sha(review_script_path)
accepted_sha=sha(accepted_path)
source_script_sha=sha(source_script_path)
source_policy_sha=sha(source_policy_path)
contract={
    'operation':'current-rollback-reconstruction-authorized-apply',
    'target':'slackware-current',
    'hostname_short':accepted['hostname_short'],
    'hostname_fqdn':accepted['hostname_fqdn'],
    'active_kernel':accepted['active_kernel'],
    'rollback_kernel':accepted['rollback_kernel'],
    'root_source':accepted['root_source'],
    'root_uuid':accepted['root_uuid'],
    'source':accepted['source'],
    'payload':accepted['payload'],
    'initrd':accepted['initrd'],
    'grub':accepted['grub'],
    'backup_root':policy.get('backup_root'),
    'stage_root':policy.get('stage_root'),
    'ordered_actions':accepted['ordered_actions'],
    'rollback_limits':accepted['rollback_limits'],
}
contract_sha=hashlib.sha256((json.dumps(contract, separators=(',', ':'), sort_keys=True)+'\n').encode()).hexdigest()
checks=[
    policy.get('schema') == 1,
    policy.get('scenario') == 'current-rollback-reconstruction-authorized-apply-review',
    policy.get('apply_contract_sha256') == contract_sha,
    policy.get('expected_review_script_sha256') == review_script_sha,
    policy.get('accepted_source_plan_record_sha256') == accepted_sha,
    policy.get('accepted_source_plan_archive_sha256') == evidence_sha,
    accepted.get('accepted') is True,
    accepted.get('archive_sha256') == evidence_sha,
    accepted.get('hostname_short') == host == policy.get('hostname_short'),
    accepted.get('hostname_fqdn') == fqdn == policy.get('hostname_fqdn'),
    accepted.get('active_kernel') == active == policy.get('active_kernel'),
    accepted.get('rollback_kernel') == rollback == policy.get('rollback_kernel'),
    accepted.get('source_plan_script_sha256') == source_script_sha == policy.get('source_plan_script_sha256'),
    accepted.get('source_plan_policy_sha256') == source_policy_sha == policy.get('source_plan_policy_sha256'),
    accepted.get('source', {}).get('package_path') == source_package,
    accepted.get('source', {}).get('signature_path') == source_signature,
]
scope=(
    'operation=current-rollback-reconstruction-authorized-apply-review\n'
    'target=slackware-current\n'
    f'hostname_short={host}\n'
    f'hostname_fqdn={fqdn}\n'
    f'active_kernel={active}\n'
    f'rollback_kernel={rollback}\n'
    f'source_plan_evidence_sha256={evidence_sha}\n'
    f'accepted_source_plan_record_sha256={accepted_sha}\n'
    f'source_plan_script_sha256={source_script_sha}\n'
    f'source_plan_policy_sha256={source_policy_sha}\n'
    f'review_script_sha256={review_script_sha}\n'
    f'source_package_sha256={accepted["source"]["package_sha256"]}\n'
    f'source_signature_sha256={accepted["source"]["signature_sha256"]}\n'
    f'kernel_sha256={accepted["payload"]["kernel_sha256"]}\n'
    f'module_manifest_sha256={accepted["payload"]["module_manifest_sha256"]}\n'
    f'source_plan_scope_sha256={accepted["source_plan_scope_sha256"]}\n'
    f'apply_contract_sha256={contract_sha}\n'
)
scope_sha=hashlib.sha256(scope.encode()).hexdigest()
checks += [scope_sha == confirmed_scope, scope_sha == policy.get('confirmation_scope_sha256')]
if not all(checks): raise SystemExit(1)
PY
}

capture_package_database() {
    local output=$1 record
    : > "$output" || return 1
    while IFS= read -r record; do
        [ -f "$record" ] && [ ! -L "$record" ] || return 1
        printf '%s|%s|%s\n' "$(basename -- "$record")" "$(stat -Lc '%s|%a|%u|%g' -- "$record")" "$(file_sha256 "$record")" >> "$output" || return 1
    done < <(find "$PACKAGE_DATABASE" -mindepth 1 -maxdepth 1 -type f -print | LC_ALL=C sort)
}

capture_sensitive_state() {
    local output=$1 path type metadata target digest
    : > "$output" || return 1
    while IFS= read -r path; do
        if [ -L "$path" ]; then
            target=$(readlink -- "$path") || return 1
            metadata=$(stat -Lc '%a|%u|%g' -- "$path") || return 1
            printf '%s|symlink|%s|%s|\n' "${path#$ROOT_PREFIX}" "$target" "$metadata" >> "$output" || return 1
        elif [ -f "$path" ]; then
            metadata=$(stat -Lc '%s|%a|%u|%g' -- "$path") || return 1
            digest=$(file_sha256 "$path") || return 1
            printf '%s|regular||%s|%s\n' "${path#$ROOT_PREFIX}" "$metadata" "$digest" >> "$output" || return 1
        elif [ -d "$path" ]; then
            metadata=$(stat -Lc '%a|%u|%g' -- "$path") || return 1
            printf '%s|directory||%s|\n' "${path#$ROOT_PREFIX}" "$metadata" >> "$output" || return 1
            find "$path" -mindepth 1 -maxdepth 2 -printf '%P|%y|%m|%u|%g|%s\n' 2>/dev/null | LC_ALL=C sort | sed "s#^#${path#$ROOT_PREFIX}/#" >> "$output" || return 1
        else
            printf '%s|missing||||\n' "${path#$ROOT_PREFIX}" >> "$output" || return 1
        fi
    done <<EOF_PATHS
$(rooted /boot/vmlinuz-generic)
$(rooted /boot/vmlinuz-6.18.42)
$(rooted /boot/vmlinuz-6.18.40)
$(rooted /boot/initrd-generic.img)
$(rooted /boot/initrd-6.18.42.img)
$(rooted /boot/initrd-6.18.40.img)
$(rooted /boot/grub/grub.cfg)
$(rooted /etc/grub.d/41_slackware_rollback_6_18_40)
$(rooted /lib/modules/6.18.40)
$(rooted /etc/default/geninitrd)
$(rooted /usr/sbin/geninitrd)
$(rooted /usr/share/mkinitrd/mkinitrd_command_generator.sh)
$(rooted /var/lib/pkgtools/setup/setup.01.mkinitrd)
$(rooted /var/lib/slack-update/rollback-backups/6.18.40)
$(rooted /var/tmp/slack-update-rollback-apply/6.18.40)
EOF_PATHS
}

invoke_fresh_source_plan_preflight() {
    local inventory failed revision1 revision2 revision3 revision4 revision5 source_scope
    inventory=$(json_value "$SOURCE_PLAN_POLICY" inventory_archive_sha256) || return 1
    failed=$(json_value "$SOURCE_PLAN_POLICY" failed_preflight_archive_sha256) || return 1
    revision1=$(json_value "$SOURCE_PLAN_POLICY" revision_1_failed_preflight_archive_sha256) || return 1
    revision2=$(json_value "$SOURCE_PLAN_POLICY" revision_2_failed_preflight_archive_sha256) || return 1
    revision3=$(json_value "$SOURCE_PLAN_POLICY" revision_3_failed_preflight_archive_sha256) || return 1
    revision4=$(json_value "$SOURCE_PLAN_POLICY" revision_4_rejected_plan_archive_sha256) || return 1
    revision5=$(json_value "$SOURCE_PLAN_POLICY" revision_5_failed_preflight_archive_sha256) || return 1
    source_scope=$(json_value "$SOURCE_PLAN_POLICY" source_plan_scope_sha256) || return 1
    NESTED_OUTPUT_DIR=$OUTPUT_DIR/nested-source-and-plan-preflight
    if [ "$TEST_MODE" = 1 ] && [ -n "${SLACK_UPDATE_TEST_NESTED_SOURCE:-}" ]; then
        [ -d "$SLACK_UPDATE_TEST_NESTED_SOURCE" ] || return 1
        cp -a -- "$SLACK_UPDATE_TEST_NESTED_SOURCE" "$NESTED_OUTPUT_DIR" || return 1
        return 0
    fi
    bash "$SOURCE_PLAN_SCRIPT" \
        --target slackware-current \
        --confirm-hostname "$CONFIRM_HOSTNAME" \
        --confirm-hostname-fqdn "$CONFIRM_HOSTNAME_FQDN" \
        --confirm-inventory-evidence-sha256 "$inventory" \
        --confirm-failed-preflight-evidence-sha256 "$failed" \
        --confirm-revision-1-failed-preflight-evidence-sha256 "$revision1" \
        --confirm-revision-2-failed-preflight-evidence-sha256 "$revision2" \
        --confirm-revision-3-failed-preflight-evidence-sha256 "$revision3" \
        --confirm-revision-4-rejected-plan-evidence-sha256 "$revision4" \
        --confirm-revision-5-failed-preflight-evidence-sha256 "$revision5" \
        --confirm-active-kernel "$CONFIRM_ACTIVE_KERNEL" \
        --confirm-rollback-kernel "$CONFIRM_ROLLBACK_KERNEL" \
        --confirm-source-plan-sha256 "$source_scope" \
        --source-package "$SOURCE_PACKAGE" \
        --source-signature "$SOURCE_SIGNATURE" \
        --output-dir "$NESTED_OUTPUT_DIR" \
        > "$OUTPUT_DIR/nested-source-and-plan-preflight.log" 2>&1
}

validate_fresh_source_plan() {
    python3 - "$ACCEPTED_SOURCE_PLAN" "$REVIEW_POLICY" "$NESTED_OUTPUT_DIR" "$SOURCE_PACKAGE" "$SOURCE_SIGNATURE" "$OUTPUT_DIR/reviewed-plan.json" <<'PY'
import hashlib, json, pathlib, shlex, sys
accepted_path, policy_path, nested_path, source_package, source_signature, output_path=sys.argv[1:]
accepted=json.load(open(accepted_path, encoding='utf-8'))
policy=json.load(open(policy_path, encoding='utf-8'))
nested=pathlib.Path(nested_path)
required=[
 'summary.txt','source-and-plan-analysis.json','reconstruction-plan.json','projected-apply-commands.txt',
 'projected-grub-menuentry.cfg','projected-41_slackware_rollback_6_18_40','projected-grub-entry.json',
 'projected-mkinitrd-command.sh','projected-mkinitrd-command.json','space-budget.json','live-boundary.json',
 'source-package.json','source-module-manifest.txt','packages.before.txt','packages.after.txt',
 'package-names.before.txt','package-names.after.txt','sensitive.before.txt','sensitive.after.txt'
]
for name in required:
    p=nested/name
    if not p.is_file() or p.is_symlink(): raise SystemExit(1)
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def parse_summary(path):
    result={}
    for line in path.read_text(encoding='utf-8').splitlines():
        if '=' in line:
            k,v=line.split('=',1); result[k]=v
    return result
summary=parse_summary(nested/'summary.txt')
analysis=json.load(open(nested/'source-and-plan-analysis.json', encoding='utf-8'))
plan=json.load(open(nested/'reconstruction-plan.json', encoding='utf-8'))
mkinitrd=json.load(open(nested/'projected-mkinitrd-command.json', encoding='utf-8'))
grub=json.load(open(nested/'projected-grub-entry.json', encoding='utf-8'))
space=json.load(open(nested/'space-budget.json', encoding='utf-8'))
live=json.load(open(nested/'live-boundary.json', encoding='utf-8'))
package=json.load(open(nested/'source-package.json', encoding='utf-8'))
actions=[item['id'] for item in sorted(plan['ordered_actions'], key=lambda item:item['order'])]
checks=[
 summary.get('result') == 'PASS', summary.get('failures') == '0', summary.get('skips') == '0',
 summary.get('apply_ready') == 'true', summary.get('apply_authorized') == 'false',
 analysis.get('apply_ready') is True, analysis.get('apply_authorized') is False,
 analysis.get('system_state_mutated') is False,
 live.get('validated') is True,
 all(item.get('ok') is True for item in live.get('checks', [])),
 source_package == accepted['source']['package_path'],
 source_signature == accepted['source']['signature_path'],
 analysis['source_package']['sha256'] == accepted['source']['package_sha256'],
 analysis['source_signature']['sha256'] == accepted['source']['signature_sha256'],
 plan['source']['package_sha256'] == accepted['source']['package_sha256'],
 plan['source']['signature_sha256'] == accepted['source']['signature_sha256'],
 plan['payload']['kernel_sha256'] == accepted['payload']['kernel_sha256'],
 plan['payload']['module_manifest_sha256'] == accepted['payload']['module_manifest_sha256'],
 package['kernel']['sha256'] == accepted['payload']['kernel_sha256'],
 package['module_member_count'] == accepted['payload']['module_member_count'],
 package['module_object_count'] == accepted['payload']['module_object_count'],
 sha(nested/'source-module-manifest.txt') == accepted['payload']['module_manifest_sha256'],
 mkinitrd['command_vector'] == accepted['initrd']['command_vector'],
 grub['source_initrd_vector'] == accepted['grub']['source_initrd_vector'],
 grub['projected_initrd_vector'] == accepted['grub']['projected_initrd_vector'],
 grub['active_initrd_retained'] is False,
 plan['grub']['default_must_remain'] == accepted['grub']['default_must_remain'],
 plan['grub']['fragment_destination'] == accepted['grub']['fragment_destination'],
 actions == accepted['ordered_actions'],
 plan['rollback_limits'] == accepted['rollback_limits'],
 space['state'] == 'sufficient',
 space['minimum_available_bytes'] >= space['aggregate_required_bytes'],
 (nested/'packages.before.txt').read_bytes() == (nested/'packages.after.txt').read_bytes(),
 (nested/'package-names.before.txt').read_bytes() == (nested/'package-names.after.txt').read_bytes(),
 (nested/'sensitive.before.txt').read_bytes() == (nested/'sensitive.after.txt').read_bytes(),
]
menu=(nested/'projected-grub-menuentry.cfg').read_text(encoding='utf-8')
checks += [
 menu.count('\n\tlinux ') == 1,
 menu.count('\n\tinitrd ') == 1,
 '/boot/vmlinuz-6.18.40' in menu,
 'initrd /boot/intel-ucode.img /boot/amd-ucode.img /boot/initrd-6.18.40.img' in menu,
 '/boot/initrd-generic.img' not in menu,
 '/boot/initrd-6.18.42.img' not in menu,
]
commands=(nested/'projected-apply-commands.txt').read_text(encoding='utf-8')
for forbidden in policy['forbidden_projected_tokens']:
    if forbidden in commands: checks.append(False)
required_fragments=policy['required_projected_command_fragments']
checks += [fragment in commands for fragment in required_fragments]
commands_without_comments='\n'.join(line for line in commands.splitlines() if not line.lstrip().startswith('#'))
checks += [
 'slackpkg ' not in commands_without_comments,
 'installpkg ' not in commands_without_comments,
 'upgradepkg ' not in commands_without_comments,
 'removepkg ' not in commands_without_comments,
 'grub-set-default' not in commands_without_comments,
 'grub-reboot' not in commands_without_comments,
]
if not all(checks): raise SystemExit(1)
review={
 'schema':1,
 'fresh_preflight_result':'PASS',
 'fresh_preflight_passes':int(summary['passes']),
 'fresh_plan_sha256':sha(nested/'reconstruction-plan.json'),
 'fresh_commands_sha256':sha(nested/'projected-apply-commands.txt'),
 'fresh_grub_fragment_sha256':sha(nested/'projected-41_slackware_rollback_6_18_40'),
 'fresh_module_manifest_sha256':sha(nested/'source-module-manifest.txt'),
 'source_package_sha256':analysis['source_package']['sha256'],
 'source_signature_sha256':analysis['source_signature']['sha256'],
 'kernel_sha256':plan['payload']['kernel_sha256'],
 'module_manifest_sha256':plan['payload']['module_manifest_sha256'],
 'projected_initrd_vector':grub['projected_initrd_vector'],
 'ordered_actions':actions,
 'system_state_mutated':False,
 'reviewed':True,
}
path=pathlib.Path(output_path)
tmp=path.with_suffix('.tmp')
tmp.write_text(json.dumps(review, indent=2, sort_keys=True)+'\n', encoding='utf-8')
tmp.replace(path)
PY
}

revalidate_source_pair() {
    local expected_package expected_signature
    require_regular_file "$SOURCE_PACKAGE" || return 1
    require_regular_file "$SOURCE_SIGNATURE" || return 1
    expected_package=$(json_value "$ACCEPTED_SOURCE_PLAN" source.package_sha256) || return 1
    expected_signature=$(json_value "$ACCEPTED_SOURCE_PLAN" source.signature_sha256) || return 1
    [ "$(file_sha256 "$SOURCE_PACKAGE")" = "$expected_package" ] || return 1
    [ "$(file_sha256 "$SOURCE_SIGNATURE")" = "$expected_signature" ] || return 1
}

write_authorization_record() {
    python3 - "$ACCEPTED_SOURCE_PLAN" "$REVIEW_POLICY" "$OUTPUT_DIR/reviewed-plan.json" "$OUTPUT_DIR/apply-authorization.json" \
        "$CONFIRM_SOURCE_PLAN_EVIDENCE_SHA256" "$CONFIRM_AUTHORIZATION_REVIEW_SHA256" "$SOURCE_PACKAGE" "$SOURCE_SIGNATURE" <<'PY'
import json, pathlib, sys
accepted_path, policy_path, review_path, output_path, evidence_sha, scope_sha, source_package, source_signature=sys.argv[1:]
accepted=json.load(open(accepted_path, encoding='utf-8'))
policy=json.load(open(policy_path, encoding='utf-8'))
review=json.load(open(review_path, encoding='utf-8'))
record={
 'schema':1,
 'scenario':'current-rollback-reconstruction-authorized-apply-review',
 'target':'slackware-current',
 'source_plan_evidence_sha256':evidence_sha,
 'authorization_review_scope_sha256':scope_sha,
 'apply_contract_sha256':policy['apply_contract_sha256'],
 'active_kernel':accepted['active_kernel'],
 'rollback_kernel':accepted['rollback_kernel'],
 'source_package':{'path':source_package,'sha256':accepted['source']['package_sha256']},
 'source_signature':{'path':source_signature,'sha256':accepted['source']['signature_sha256']},
 'payload':accepted['payload'],
 'initrd':accepted['initrd'],
 'grub':accepted['grub'],
 'ordered_actions':accepted['ordered_actions'],
 'rollback_limits':accepted['rollback_limits'],
 'fresh_review':review,
 'authorization_constraints':policy['authorization_constraints'],
 'repository_metadata_refreshed':False,
 'package_installation_performed':False,
 'package_database_mutated':False,
 'depmod_executed':False,
 'initrd_generated':False,
 'grub_mutated':False,
 'reboot_performed':False,
 'apply_ready':True,
 'apply_authorized':True,
 'apply_executed':False,
 'next_stage':'current-rollback-reconstruction-authorized-apply',
}
path=pathlib.Path(output_path)
tmp=path.with_suffix('.tmp')
tmp.write_text(json.dumps(record, indent=2, sort_keys=True)+'\n', encoding='utf-8')
tmp.replace(path)
PY
}

write_summary() {
    cat > "$OUTPUT_DIR/summary.txt" <<EOF_SUMMARY
scenario=current-rollback-reconstruction-authorized-apply-review
target=$TARGET
result=$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)
passes=$PASS_COUNT
failures=$FAILURE_COUNT
skips=$SKIP_COUNT
hostname_short=$CONFIRM_HOSTNAME
hostname_fqdn=$CONFIRM_HOSTNAME_FQDN
active_kernel=$CONFIRM_ACTIVE_KERNEL
rollback_kernel=$CONFIRM_ROLLBACK_KERNEL
source_plan_evidence_sha256=$CONFIRM_SOURCE_PLAN_EVIDENCE_SHA256
authorization_review_scope_sha256=$CONFIRM_AUTHORIZATION_REVIEW_SHA256
apply_contract_sha256=$(json_value "$REVIEW_POLICY" apply_contract_sha256)
source_package=$SOURCE_PACKAGE
source_package_sha256=$(json_value "$ACCEPTED_SOURCE_PLAN" source.package_sha256)
source_signature=$SOURCE_SIGNATURE
source_signature_sha256=$(json_value "$ACCEPTED_SOURCE_PLAN" source.signature_sha256)
repository_metadata_refreshed=false
package_installation_performed=false
package_database_mutated=false
depmod_executed=false
initrd_generated=false
grub_mutated=false
reboot_performed=false
apply_ready=$APPLY_READY
apply_authorized=$APPLY_AUTHORIZED
apply_executed=$APPLY_EXECUTED
next_stage=$NEXT_STAGE
EOF_SUMMARY
}

publish_evidence() {
    local parent base archive owner group
    parent=$(dirname -- "$OUTPUT_DIR")
    base=$(basename -- "$OUTPUT_DIR")
    archive="$parent/$base.tar.gz"
    tar -C "$parent" -czf "$archive" "$base" || return 1
    (cd "$parent" && sha256sum -- "$base.tar.gz" > "$base.tar.gz.sha256") || return 1
    owner=${SUDO_USER:-}
    if [ -z "$owner" ] || [ "$owner" = root ]; then owner=${ROLLBACK_AUTH_EVIDENCE_OWNER:-promano}; fi
    group=$(id -gn "$owner" 2>/dev/null || printf users)
    chmod 0600 "$archive" "$archive.sha256" || return 1
    printf 'Evidence archive: %s\n' "$archive"
    printf 'Evidence SHA-256: %s\n' "$(file_sha256 "$archive")"
    printf 'Copy evidence command: sudo install -o %s -g %s -m 0600 %q /home/%s/%q\n' "$owner" "$group" "$archive" "$owner" "$(basename -- "$archive")"
    printf 'Copy sidecar command: sudo install -o %s -g %s -m 0600 %q /home/%s/%q\n' "$owner" "$group" "$archive.sha256" "$owner" "$(basename -- "$archive.sha256")"
    printf 'Copy evidence pair command: sudo install -o %s -g %s -m 0600 %q /home/%s/%q && sudo install -o %s -g %s -m 0600 %q /home/%s/%q\n' \
        "$owner" "$group" "$archive" "$owner" "$(basename -- "$archive")" \
        "$owner" "$group" "$archive.sha256" "$owner" "$(basename -- "$archive.sha256")"
    printf 'Source package retained: %s\n' "$SOURCE_PACKAGE"
    printf 'Source signature retained: %s\n' "$SOURCE_SIGNATURE"
    printf 'Verify evidence command: cd /home/%s && sha256sum -c %q\n' "$owner" "$(basename -- "$archive.sha256")"
}

main() {
    local timestamp slackware_version
    parse_arguments "$@" || { print_usage >&2; return 2; }
    [ "$(id -u)" -eq 0 ] || { error 'this review must run as root'; return 2; }
    if [ "$TEST_MODE" = 1 ]; then
        ROOT_PREFIX=${SLACK_UPDATE_TEST_ROOT:-}
        PATH=${SLACK_UPDATE_TEST_PATH:-$PATH}; export PATH
    else
        ROOT_PREFIX=
    fi
    slackware_version=$(cat "$(rooted /etc/slackware-version)" 2>/dev/null || true)
    [ "$slackware_version" = 'Slackware 15.0+' ] || { error 'Slackware-current target mismatch'; return 2; }
    for command_name in awk bash chmod cmp cp date find id mkdir python3 readlink sha256sum sort stat tar tee; do
        command -v "$command_name" >/dev/null 2>&1 || { error "required command missing: $command_name"; return 2; }
    done
    for reviewed_file in "$SOURCE_PLAN_SCRIPT" "$SOURCE_PLAN_POLICY" "$ACCEPTED_SOURCE_PLAN" "$REVIEW_POLICY" "$REVIEW_SCRIPT"; do
        require_regular_file "$reviewed_file" || { error "reviewed file is missing or unsafe: $reviewed_file"; return 2; }
    done
    bash -n "$SOURCE_PLAN_SCRIPT" || { error 'source and plan preflight has invalid shell syntax'; return 2; }
    bash -n "$REVIEW_SCRIPT" || { error 'authorization review has invalid shell syntax'; return 2; }
    if [ -d "$(rooted /var/lib/pkgtools/packages)" ] && [ ! -L "$(rooted /var/lib/pkgtools/packages)" ]; then
        PACKAGE_DATABASE=$(rooted /var/lib/pkgtools/packages)
    elif [ -d "$(rooted /var/log/packages)" ] && [ ! -L "$(rooted /var/log/packages)" ]; then
        PACKAGE_DATABASE=$(rooted /var/log/packages)
    else
        error 'installed package database is unavailable'; return 2
    fi
    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    [ -n "$OUTPUT_DIR" ] || OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/${TARGET}-${timestamp}"
    [ ! -e "$OUTPUT_DIR" ] && [ ! -L "$OUTPUT_DIR" ] || { error "output exists: $OUTPUT_DIR"; return 2; }
    mkdir -m 0700 -p -- "$OUTPUT_DIR" || return 2
    ASSERTION_LOG=$OUTPUT_DIR/assertions.log
    : > "$ASSERTION_LOG"

    if validate_review_boundary; then
        record_pass 'the accepted step-87 evidence, exact source-plan code, exact review code, and explicit authorization scope are bound'
    else
        record_failure 'the accepted step-87 record, reviewed code, source identity, or explicit authorization scope is missing, changed, or mismatched'
    fi

    if capture_package_database "$OUTPUT_DIR/packages.before.txt" && capture_sensitive_state "$OUTPUT_DIR/sensitive.before.txt"; then
        record_pass 'the package database and rollback-sensitive state were captured before the authorization review'
    else
        record_failure 'the package database or rollback-sensitive state could not be captured before the authorization review'
    fi

    if revalidate_source_pair; then
        record_pass 'the pre-staged package and detached signature still match the exact accepted SHA-256 identities'
    else
        record_failure 'the pre-staged package or detached signature is missing, unsafe, or changed'
    fi

    if [ "$FAILURE_COUNT" -eq 0 ]; then
        if invoke_fresh_source_plan_preflight; then
            record_pass 'a fresh non-mutating revision-6 source-and-plan preflight completed for the exact retained source pair'
        else
            record_failure 'the fresh revision-6 source-and-plan preflight failed or could not be completed'
        fi
    else
        record_skip 'the fresh source-and-plan preflight requires the reviewed boundary and unchanged source pair'
    fi

    if [ -d "$NESTED_OUTPUT_DIR" ] && validate_fresh_source_plan; then
        NESTED_PREFLIGHT_VALID=true
        PLAN_REVIEW_VALID=true
        record_pass 'the fresh plan exactly preserves the reviewed payload, mkinitrd vector, ordered microcode, active default, backup limits, and recovery sequence'
    elif [ -d "$NESTED_OUTPUT_DIR" ]; then
        record_failure 'the fresh source-and-plan output is incomplete, changed, unsafe, or not semantically identical to the accepted plan'
    else
        record_skip 'plan review requires a completed fresh source-and-plan preflight'
    fi

    if capture_package_database "$OUTPUT_DIR/packages.after.txt" && capture_sensitive_state "$OUTPUT_DIR/sensitive.after.txt"; then
        record_pass 'the package database and rollback-sensitive state were captured after the authorization review'
    else
        record_failure 'the package database or rollback-sensitive state could not be captured after the authorization review'
    fi

    if cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" \
        && cmp -s "$OUTPUT_DIR/sensitive.before.txt" "$OUTPUT_DIR/sensitive.after.txt"; then
        STATE_UNCHANGED=true
        record_pass 'the installed package database and rollback-sensitive system state remained unchanged'
    else
        record_failure 'the installed package database or rollback-sensitive system state changed during the review'
    fi

    if [ "$NESTED_PREFLIGHT_VALID" = true ] && [ "$PLAN_REVIEW_VALID" = true ] && [ "$STATE_UNCHANGED" = true ] \
        && revalidate_source_pair && [ "$FAILURE_COUNT" -eq 0 ]; then
        if write_authorization_record; then
            APPLY_READY=true
            APPLY_AUTHORIZED=true
            NEXT_STAGE=current-rollback-reconstruction-authorized-apply
            record_pass 'the exact rollback reconstruction canonical apply contract is authorized and remains unexecuted'
        else
            record_failure 'the exact apply authorization record could not be written atomically'
        fi
    else
        record_skip 'apply authorization requires a fresh accepted plan, unchanged source, and byte-identical system boundary'
    fi

    write_summary || return 2
    publish_evidence || return 2
    if [ "$FAILURE_COUNT" -eq 0 ]; then
        printf 'Result: PASS (%d passes, %d failures, %d skips); apply_ready=%s; apply_authorized=%s; apply_executed=%s; next_stage=%s\n' \
            "$PASS_COUNT" "$FAILURE_COUNT" "$SKIP_COUNT" "$APPLY_READY" "$APPLY_AUTHORIZED" "$APPLY_EXECUTED" "$NEXT_STAGE"
        return 0
    fi
    printf 'Result: FAIL (%d passes, %d failures, %d skips); apply_ready=%s; apply_authorized=%s; apply_executed=%s; next_stage=%s\n' \
        "$PASS_COUNT" "$FAILURE_COUNT" "$SKIP_COUNT" "$APPLY_READY" "$APPLY_AUTHORIZED" "$APPLY_EXECUTED" "$NEXT_STAGE" >&2
    return 1
}

main "$@"
