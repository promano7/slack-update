#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../../.." && pwd -P)
DEFAULT_ELF_REVIEW_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-userspace-elf-runtime-review-preflight.sh"
DEFAULT_NORMAL_UPDATE_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-normal-update.sh"
DEFAULT_ELF_RECORD="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-elf-runtime-review-20260805-accepted.json"
DEFAULT_REVIEW_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-apply-review-policy.json"
DEFAULT_REFERENCE_ENGINE="$REPOSITORY_ROOT/tools/reference/slack-update-reference.sh"
DEFAULT_OUTPUT_ROOT=/var/tmp/slack-update-acceptance/current-userspace-apply-review-preflight

TARGET=
CONFIRM_CANDIDATES_SHA256=
CONFIRM_TARGET_KERNEL=
ELF_REVIEW_SCRIPT=$DEFAULT_ELF_REVIEW_SCRIPT
NORMAL_UPDATE_SCRIPT=$DEFAULT_NORMAL_UPDATE_SCRIPT
ELF_RECORD=$DEFAULT_ELF_RECORD
REVIEW_POLICY=$DEFAULT_REVIEW_POLICY
REFERENCE_ENGINE=$DEFAULT_REFERENCE_ENGINE
OUTPUT_DIR=
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
CANDIDATE_COUNT=0
BASELINE_CANDIDATE_COUNT=0
ADDED_CANDIDATE_COUNT=0
INSTALL_NEW_COUNT=0
UPGRADE_ALL_COUNT=0
KERNEL_CANDIDATE_COUNT=0
KERNEL_TRANSACTION_COUNT=0
CRITICAL_CANDIDATE_COUNT=0
USPACE_APPLY_REVIEW_COMPLETE=false
NEXT_STAGE=manual-review-required

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current \\
                     --confirm-candidates-sha256 SHA256 \\
                     --confirm-target-kernel VERSION [options]

Review the exact userspace package-application boundary without installing
packages. The preflight reruns the accepted ELF/runtime review, performs a
fresh non-installing candidate probe, reconstructs the reviewed 69+68 package
union, and verifies the immutable Slack-Update package, GenInitrd, failure,
and GRUB ownership contract.

Required options:
      --target slackware-current
      --confirm-candidates-sha256 SHA256
      --confirm-target-kernel VERSION

Optional arguments:
      --elf-review-script PATH
      --normal-update-script PATH
      --elf-record PATH
      --review-policy PATH
      --reference-engine PATH
      --output-dir PATH
  -h, --help
EOF_USAGE
}

error() { printf 'ERROR: %s\n' "$*" >&2; }
record_pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf 'PASS: %s\n' "$1" | tee -a "$ASSERTION_LOG"; }
record_failure() { FAILURE_COUNT=$((FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" | tee -a "$ASSERTION_LOG" >&2; }

is_sha256() {
    [ "${#1}" -eq 64 ] || return 1
    case "$1" in *[!0-9A-Fa-f]*) return 1 ;; esac
}

is_safe_kernel_version() {
    case "$1" in ''|.|..|*/*|*[[:space:]]*|*[!A-Za-z0-9._+-]*) return 1 ;; *) return 0 ;; esac
}

parse_arguments() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --target) [ "$#" -ge 2 ] || return 1; TARGET=$2; shift 2 ;;
            --confirm-candidates-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_CANDIDATES_SHA256=$2; shift 2 ;;
            --confirm-target-kernel) [ "$#" -ge 2 ] || return 1; CONFIRM_TARGET_KERNEL=$2; shift 2 ;;
            --elf-review-script) [ "$#" -ge 2 ] || return 1; ELF_REVIEW_SCRIPT=$2; shift 2 ;;
            --normal-update-script) [ "$#" -ge 2 ] || return 1; NORMAL_UPDATE_SCRIPT=$2; shift 2 ;;
            --elf-record) [ "$#" -ge 2 ] || return 1; ELF_RECORD=$2; shift 2 ;;
            --review-policy) [ "$#" -ge 2 ] || return 1; REVIEW_POLICY=$2; shift 2 ;;
            --reference-engine) [ "$#" -ge 2 ] || return 1; REFERENCE_ENGINE=$2; shift 2 ;;
            --output-dir) [ "$#" -ge 2 ] || return 1; OUTPUT_DIR=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done
    [ "$TARGET" = slackware-current ] || { error '--target must be slackware-current'; return 1; }
    is_sha256 "$CONFIRM_CANDIDATES_SHA256" || { error '--confirm-candidates-sha256 must be a SHA-256 digest'; return 1; }
    is_safe_kernel_version "$CONFIRM_TARGET_KERNEL" || { error '--confirm-target-kernel is unsafe'; return 1; }
    local path
    for path in "$ELF_REVIEW_SCRIPT" "$NORMAL_UPDATE_SCRIPT" "$ELF_RECORD" "$REVIEW_POLICY" "$REFERENCE_ENGINE" ${OUTPUT_DIR:+"$OUTPUT_DIR"}; do
        case "$path" in /*) ;; *) error "path must be absolute: $path"; return 1 ;; esac
        case "$path" in *[[:space:]]*) error 'paths must not contain whitespace'; return 1 ;; esac
    done
}

require_command() { command -v "$1" >/dev/null 2>&1 || { error "required command is unavailable: $1"; return 1; }; }

capture_package_database() {
    local output=$1 root=/var/lib/pkgtools/packages item
    [ -d "$root" ] && [ ! -L "$root" ] || return 1
    : > "$output" || return 1
    while IFS= read -r -d '' item; do
        [ ! -L "$item" ] || return 1
        printf '%s\t%s\n' "${item##*/}" "$(sha256sum -- "$item" | awk '{print $1}')" >> "$output" || return 1
    done < <(find "$root" -maxdepth 1 -type f -print0 | LC_ALL=C sort -z)
    [ -s "$output" ]
}

capture_path_state() {
    local path=$1
    if [ -L "$path" ]; then
        printf 'symlink|%s|%s' "$(readlink -- "$path" 2>/dev/null || true)" "$(readlink -e -- "$path" 2>/dev/null || true)"
    elif [ -f "$path" ]; then
        printf 'regular|%s|%s' "$(stat -c '%a:%u:%g:%s:%Y' -- "$path")" "$(sha256sum -- "$path" | awk '{print $1}')"
    elif [ -d "$path" ]; then
        printf 'directory|%s|' "$(stat -c '%a:%u:%g:%Y' -- "$path")"
    else
        printf 'missing||'
    fi
}

capture_sensitive_state() {
    local output=$1 path
    : > "$output" || return 1
    for path in \
        /boot/vmlinuz-generic "/boot/vmlinuz-$(uname -r)" \
        /boot/initrd-generic.img "/boot/initrd-$(uname -r).img" \
        /boot/initrd.gz /boot/grub/grub.cfg /etc/default/geninitrd \
        /etc/mkinitrd.conf /usr/sbin/geninitrd \
        /usr/share/mkinitrd/mkinitrd_command_generator.sh \
        /var/lib/pkgtools/setup/setup.01.mkinitrd \
        /etc/geninitrd.d/pre-install/dkms-bcachefs \
        /etc/geninitrd.d/pre-install/dkms-nvidia /var/lib/dkms; do
        printf '%s|' "$path" >> "$output"
        capture_path_state "$path" >> "$output" || return 1
        printf '\n' >> "$output"
    done
}

validate_accepted_boundary() {
    python3 - "$ELF_RECORD" "$REVIEW_POLICY" "$CONFIRM_CANDIDATES_SHA256" "$CONFIRM_TARGET_KERNEL" "$REFERENCE_ENGINE" <<'PY'
import hashlib, json, pathlib, re, sys
record_path, policy_path, confirmed_digest, confirmed_kernel, reference_path = sys.argv[1:]
try:
    record=json.load(open(record_path,encoding='utf-8'))
    policy=json.load(open(policy_path,encoding='utf-8'))
except Exception:
    raise SystemExit(1)
def digest(v): return isinstance(v,str) and re.fullmatch(r'[0-9a-f]{64}',v) is not None
def denied(v): return v.get('apply_ready') is False and v.get('apply_authorized') is False
baseline=policy.get('baseline_candidates',[])
added=policy.get('reviewed_additions',[])
union=sorted(baseline+added)
manifest=''.join(x+'\n' for x in union).encode()
reference_sha=hashlib.sha256(pathlib.Path(reference_path).read_bytes()).hexdigest()
checks=[
 record.get('scenario')=='current-userspace-elf-runtime-review-preflight', record.get('target')=='slackware-current',
 record.get('accepted') is True, denied(record), record.get('candidate_set_sha256')==confirmed_digest,
 record.get('target_kernel')==confirmed_kernel, digest(record.get('archive_sha256')),
 record.get('elf_file_count')==722, record.get('elf_package_count')==61,
 record.get('unresolved_edge_count')==0, record.get('unsafe_runtime_object_count')==0,
 record.get('elf_runtime_review_complete') is True, record.get('userspace_apply_review_complete') is False,
 record.get('package_transaction_executed') is False, record.get('elf_payload_executed') is False,
 record.get('dynamic_loader_tracing_executed') is False, record.get('package_database_unchanged') is True,
 record.get('runtime_sensitive_state_unchanged') is True, record.get('assertions')=={'passes':15,'failures':0},
 record.get('evidence',{}).get('copied_to')=='/home/promano',
 record.get('evidence',{}).get('destination_verification')=='passed',
 record.get('next_stage')=='current-userspace-apply-review-preflight', record.get('reference_sha256')==reference_sha,
 policy.get('scenario')=='current-userspace-apply-review-policy', policy.get('target')=='slackware-current',
 policy.get('reviewed') is True, denied(policy), policy.get('candidate_set_sha256')==confirmed_digest,
 policy.get('target_kernel')==confirmed_kernel, policy.get('accepted_elf_runtime_archive_sha256')==record.get('archive_sha256'),
 policy.get('reference_engine_sha256')==reference_sha,
 len(baseline)==policy.get('expected_baseline_candidate_count')==69,
 len(added)==policy.get('expected_added_candidate_count')==68,
 len(set(baseline))==len(baseline), len(set(added))==len(added), not set(baseline)&set(added),
 len(union)==policy.get('expected_candidate_count')==137,
 hashlib.sha256(manifest).hexdigest()==policy.get('candidate_union_manifest_sha256')==confirmed_digest,
 policy.get('expected_install_new_count')==1, policy.get('expected_upgrade_all_count')==136,
 policy.get('expected_kernel_transaction_count')==len(policy.get('expected_kernel_transaction',[]))==3,
 policy.get('expected_critical_candidate_count')==0,
 policy.get('postinstall_policy')=='defer', policy.get('postinstall_processing_enabled') is False,
 policy.get('transaction',{}).get('step_count')==12,
 policy.get('transaction',{}).get('recovery_boundary_count')==5,
 policy.get('transaction',{}).get('temporary_geninitrd_policy_override_required') is True,
 policy.get('transaction',{}).get('restore_original_geninitrd_policy_required') is True,
 policy.get('transaction',{}).get('partial_package_failure_blocks_secondary_modules') is True,
 policy.get('userspace_apply_review_complete') is False,
 policy.get('normal_update_apply_executed') is False, policy.get('package_transaction_executed') is False,
 policy.get('next_stage')=='current-kernel-transaction-readiness-preflight'
]
if not all(checks): raise SystemExit(1)
print(len(baseline)); print(len(added)); print(len(union)); print(reference_sha)
PY
}

verify_archive_sidecar() {
    local archive=$1 sidecar=$2 parent base
    [ -s "$archive" ] && [ -s "$sidecar" ] || return 1
    parent=$(dirname -- "$archive")
    base=$(basename -- "$archive")
    (cd "$parent" && sha256sum -c -- "${sidecar##*/}" >/dev/null 2>&1) || return 1
    [ "$(awk '{print $2}' "$sidecar")" = "$base" ]
}

validate_nested_elf_review() {
    local directory=$1
    python3 - "$directory/summary.txt" "$CONFIRM_CANDIDATES_SHA256" "$CONFIRM_TARGET_KERNEL" <<'PY'
import pathlib,sys
p,digest,kernel=sys.argv[1:]
values={}
for line in pathlib.Path(p).read_text().splitlines():
    if '=' in line:
        k,v=line.split('=',1); values[k]=v
checks=[values.get('scenario')=='current-userspace-elf-runtime-review-preflight',values.get('result')=='PASS',
 values.get('candidate_set_sha256')==digest,values.get('target_kernel')==kernel,
 values.get('elf_file_count')=='722',values.get('elf_package_count')=='61',
 values.get('unresolved_edge_count')=='0',values.get('unsafe_runtime_object_count')=='0',
 values.get('elf_runtime_review_complete')=='true',values.get('userspace_apply_review_complete')=='false',
 values.get('package_transaction_executed')=='false',values.get('elf_payload_executed')=='false',
 values.get('dynamic_loader_tracing_executed')=='false',values.get('next_stage')=='current-userspace-apply-review-preflight',
 values.get('apply_ready')=='false',values.get('apply_authorized')=='false',values.get('passes')=='15',values.get('failures')=='0']
if not all(checks): raise SystemExit(1)
PY
}

validate_candidate_plan() {
    local normal_dir=$1 plan_json=$2 plan_tsv=$3
    python3 - "$normal_dir" "$REVIEW_POLICY" "$CONFIRM_CANDIDATES_SHA256" "$plan_json" "$plan_tsv" <<'PY'
import hashlib,json,pathlib,sys
normal=pathlib.Path(sys.argv[1]); policy=json.load(open(sys.argv[2],encoding='utf-8')); confirmed=sys.argv[3]
plan_json=pathlib.Path(sys.argv[4]); plan_tsv=pathlib.Path(sys.argv[5])
def lines(name):
    p=normal/name
    data=p.read_text(encoding='utf-8').splitlines()
    if data!=sorted(set(data)): raise SystemExit(1)
    return data
install=lines('install-new.candidates.txt'); upgrade=lines('upgrade-all.candidates.txt'); allc=lines('all.candidates.txt')
kernel=lines('kernel.candidates.txt'); critical=lines('critical.candidates.txt')
baseline=policy['baseline_candidates']; added=policy['reviewed_additions']; expected=sorted(baseline+added)
checks=[install==policy['expected_install_new'],len(install)==policy['expected_install_new_count']==1,
 len(upgrade)==policy['expected_upgrade_all_count']==136,allc==expected,len(allc)==policy['expected_candidate_count']==137,
 sorted(install+upgrade)==allc,not set(install)&set(upgrade),hashlib.sha256((''.join(x+'\n' for x in allc)).encode()).hexdigest()==confirmed,
 len(baseline)==69,len(added)==68,not set(baseline)&set(added),set(policy['expected_kernel_transaction'])<=set(upgrade),
 len(policy['expected_kernel_transaction'])==policy['expected_kernel_transaction_count']==3,
 len(kernel)==policy['expected_kernel_candidate_count']==2,len(critical)==policy['expected_critical_candidate_count']==0]
if not all(checks): raise SystemExit(1)
rows=[]
for pkg in allc:
    origin='baseline' if pkg in set(baseline) else 'reviewed-addition'
    action='install-new' if pkg in set(install) else 'upgrade-all'
    kernel_tx='true' if pkg in set(policy['expected_kernel_transaction']) else 'false'
    rows.append((pkg,origin,action,kernel_tx))
plan_tsv.write_text('package\torigin\taction\tkernel_transaction\n'+''.join('\t'.join(x)+'\n' for x in rows),encoding='utf-8')
obj={'scenario':'current-userspace-apply-review-preflight','candidate_set_sha256':confirmed,'candidate_count':len(allc),
 'baseline_candidate_count':len(baseline),'added_candidate_count':len(added),'install_new_count':len(install),
 'upgrade_all_count':len(upgrade),'kernel_candidate_count':len(kernel),'kernel_transaction_count':len(policy['expected_kernel_transaction']),
 'critical_candidate_count':len(critical),'exact_union_verified':True,'package_transaction_executed':False,
 'apply_ready':False,'apply_authorized':False,'next_stage':'current-kernel-transaction-readiness-preflight'}
plan_json.write_text(json.dumps(obj,indent=2,sort_keys=True)+'\n',encoding='utf-8')
print(len(allc));print(len(baseline));print(len(added));print(len(install));print(len(upgrade));print(len(kernel));print(len(policy['expected_kernel_transaction']));print(len(critical))
PY
}

validate_reference_contract() {
    local report=$1
    python3 - "$REFERENCE_ENGINE" "$REVIEW_POLICY" "$report" <<'PY'
import hashlib,json,pathlib,re,sys
source_path,policy_path,report_path=map(pathlib.Path,sys.argv[1:])
source=source_path.read_text(encoding='utf-8'); policy=json.loads(policy_path.read_text())
sha=hashlib.sha256(source_path.read_bytes()).hexdigest()
def pos(text):
    p=source.find(text)
    if p<0: raise SystemExit(1)
    return p
commands=policy['package_commands']
checks={
 'reference_hash_matches_policy':sha==policy['reference_engine_sha256'],
 'metadata_command_present':commands[0] in source,
 'install_new_command_present':commands[1] in source,
 'upgrade_all_command_present':commands[2] in source,
 'postinstall_policy_deferred':'postinstall_policy' in source and 'defer' in source and '-postinst=off install-new' in source and '-postinst=off upgrade-all' in source,
 'pending_new_files_captured':'capture_pending_new_config_files' in source,
 'temporary_policy_override_precedes_packages':pos('    if ! prepare_geninitrd_grub_policy_override;') < pos('    update_slackware_system\n'),
 'policy_restore_follows_packages':pos('    update_slackware_system\n') < pos('    if restore_geninitrd_grub_policy_override;'),
 'policy_override_disables_grub':'AUTO_UPDATE_GRUB=false' in source,
 'cleanup_restores_policy':'restore_geninitrd_grub_policy_override 2>/dev/null' in source,
 'package_failures_block_secondary_modules':'block_secondary_modules_after_partial_slackware_update' in source and 'if [ "$action_exit" -gt 0 ]; then' in source,
 'grub_generation_is_temporary':'GRUB_TEMP_CONFIG' in source and 'grub-mkconfig -o "$GRUB_TEMP_CONFIG"' in source,
 'generated_grub_is_validated':'validate_generated_grub_config' in source,
 'transaction_step_count_reviewed':policy['transaction']['step_count']==12,
 'recovery_boundary_count_reviewed':policy['transaction']['recovery_boundary_count']==5,
}
if not all(checks.values()): raise SystemExit(1)
report_path.write_text(json.dumps({'scenario':'current-userspace-apply-reference-contract','reference_sha256':sha,
 'checks':checks,'all_checks_passed':True,'package_transaction_executed':False},indent=2,sort_keys=True)+'\n')
PY
}

write_summary() {
    local path=$1 result=PASS
    [ "$FAILURE_COUNT" -eq 0 ] || result=FAIL
    {
        printf 'scenario=current-userspace-apply-review-preflight\n'
        printf 'result=%s\n' "$result"
        printf 'target=%s\n' "$TARGET"
        printf 'candidate_set_sha256=%s\n' "$CONFIRM_CANDIDATES_SHA256"
        printf 'target_kernel=%s\n' "$CONFIRM_TARGET_KERNEL"
        printf 'candidate_count=%d\n' "$CANDIDATE_COUNT"
        printf 'baseline_candidate_count=%d\n' "$BASELINE_CANDIDATE_COUNT"
        printf 'added_candidate_count=%d\n' "$ADDED_CANDIDATE_COUNT"
        printf 'install_new_count=%d\n' "$INSTALL_NEW_COUNT"
        printf 'upgrade_all_count=%d\n' "$UPGRADE_ALL_COUNT"
        printf 'kernel_candidate_count=%d\n' "$KERNEL_CANDIDATE_COUNT"
        printf 'kernel_transaction_count=%d\n' "$KERNEL_TRANSACTION_COUNT"
        printf 'critical_candidate_count=%d\n' "$CRITICAL_CANDIDATE_COUNT"
        printf 'transaction_step_count=12\n'
        printf 'recovery_boundary_count=5\n'
        printf 'elf_runtime_review_complete=true\n'
        printf 'userspace_apply_review_complete=%s\n' "$USPACE_APPLY_REVIEW_COMPLETE"
        printf 'normal_update_apply_executed=false\n'
        printf 'package_transaction_executed=false\n'
        printf 'maintainer_script_executed=false\n'
        printf 'mkinitrd_executed=false\n'
        printf 'geninitrd_executed=false\n'
        printf 'dkms_action_executed=false\n'
        printf 'grub_update_executed=false\n'
        printf 'next_stage=%s\n' "$NEXT_STAGE"
        printf 'apply_ready=false\n'
        printf 'apply_authorized=false\n'
        printf 'passes=%d\n' "$PASS_COUNT"
        printf 'failures=%d\n' "$FAILURE_COUNT"
    } > "$path"
}

publish_archive() {
    local archive=$1 owner_uid=${SUDO_UID:-} owner_gid=${SUDO_GID:-}
    chmod 0600 -- "$archive" "$archive.sha256" || return 1
    if [[ "$owner_uid" =~ ^[0-9]+$ && "$owner_gid" =~ ^[0-9]+$ ]]; then chown -- "$owner_uid:$owner_gid" "$archive" "$archive.sha256" || return 1; fi
}

create_evidence_archive() {
    local parent base archive
    parent=$(dirname -- "$OUTPUT_DIR"); base=$(basename -- "$OUTPUT_DIR"); archive="$OUTPUT_DIR.tar.gz"
    tar -C "$parent" -czf "$archive" "$base" || return 1
    (cd "$parent" && sha256sum -- "${archive##*/}") > "$archive.sha256" || return 1
    publish_archive "$archive" || return 1
    printf '%s\n' "$archive"
}

print_evidence_commands() {
    local archive=$1 owner=${SUDO_USER:-promano} home
    [ -n "$owner" ] && [ "$owner" != root ] || owner=promano
    home=$(awk -F: -v owner="$owner" '$1==owner{print $6;exit}' /etc/passwd); [ -n "$home" ] || home="/home/$owner"
    printf 'Evidence archive: %s\n' "$archive"
    printf 'Evidence SHA-256: %s\n' "$(awk '{print $1}' "$archive.sha256")"
    printf 'Copy evidence command: sudo install -o %s -g users -m 0600 %q %q && sudo install -o %s -g users -m 0600 %q %q\n' \
        "$owner" "$archive" "$home/${archive##*/}" "$owner" "$archive.sha256" "$home/${archive##*/}.sha256"
    printf 'Verify evidence command: cd %q && sha256sum -c %q\n' "$home" "${archive##*/}.sha256"
}

main() {
    local timestamp archive status values
    parse_arguments "$@" || { print_usage >&2; return 2; }
    [ "$(id -u)" -eq 0 ] || { error 'this real-system acceptance scenario requires root'; return 2; }
    local cmd
    for cmd in awk bash cmp date find grep hostname python3 readlink sed sha256sum sort stat tar; do require_command "$cmd" || return 2; done
    for cmd in "$ELF_REVIEW_SCRIPT" "$NORMAL_UPDATE_SCRIPT" "$ELF_RECORD" "$REVIEW_POLICY" "$REFERENCE_ENGINE"; do [ -r "$cmd" ] || { error "required file is unreadable: $cmd"; return 2; }; done
    bash -n "$ELF_REVIEW_SCRIPT" && bash -n "$NORMAL_UPDATE_SCRIPT" && bash -n "$REFERENCE_ENGINE" || { error 'a reviewed shell source fails syntax validation'; return 2; }
    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    if [ -z "$OUTPUT_DIR" ]; then mkdir -p -- "$DEFAULT_OUTPUT_ROOT" || return 2; OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/slackware-current-$timestamp"; fi
    [ ! -e "$OUTPUT_DIR" ] || { error "output directory already exists: $OUTPUT_DIR"; return 2; }
    mkdir -p -- "$OUTPUT_DIR/nested" || return 2; chmod 0700 -- "$OUTPUT_DIR" "$OUTPUT_DIR/nested" || return 2
    ASSERTION_LOG="$OUTPUT_DIR/assertions.log"; : > "$ASSERTION_LOG"

    values=$(validate_accepted_boundary) || { record_failure 'the accepted ELF review and apply policy do not bind the requested transaction'; write_summary "$OUTPUT_DIR/summary.txt"; return 1; }
    BASELINE_CANDIDATE_COUNT=$(printf '%s\n' "$values"|sed -n '1p'); ADDED_CANDIDATE_COUNT=$(printf '%s\n' "$values"|sed -n '2p'); CANDIDATE_COUNT=$(printf '%s\n' "$values"|sed -n '3p')
    record_pass 'the accepted ELF review and apply policy bind the exact 137-package transaction'
    record_pass 'the explicit candidate digest and target kernel match the reviewed application boundary'

    capture_package_database "$OUTPUT_DIR/packages.before.txt" && capture_sensitive_state "$OUTPUT_DIR/sensitive.before.txt" || { record_failure 'the package database and apply-sensitive state could not be captured before review'; return 1; }
    record_pass 'the package database and apply-sensitive state were captured before non-installing review'

    printf 'Running a fresh non-installing ELF/runtime review before application planning...\n'
    status=0
    bash "$ELF_REVIEW_SCRIPT" --target "$TARGET" --confirm-candidates-sha256 "$CONFIRM_CANDIDATES_SHA256" --confirm-target-kernel "$CONFIRM_TARGET_KERNEL" --output-dir "$OUTPUT_DIR/nested/elf-review" >"$OUTPUT_DIR/elf-review.stdout.log" 2>"$OUTPUT_DIR/elf-review.stderr.log" || status=$?
    printf '%d\n' "$status" > "$OUTPUT_DIR/elf-review.exit"
    if [ "$status" -eq 0 ] && validate_nested_elf_review "$OUTPUT_DIR/nested/elf-review"; then record_pass 'the embedded ELF/runtime review completed without installing or executing payload'; else record_failure 'the embedded ELF/runtime review did not reproduce the accepted boundary'; fi
    if verify_archive_sidecar "$OUTPUT_DIR/nested/elf-review.tar.gz" "$OUTPUT_DIR/nested/elf-review.tar.gz.sha256"; then record_pass 'the nested ELF/runtime archive and portable sidecar verify inside the apply-review evidence'; else record_failure 'the nested ELF/runtime evidence failed verification'; fi

    printf 'Running a fresh non-installing normal-update preflight for final candidate reconstruction...\n'
    status=0
    bash "$NORMAL_UPDATE_SCRIPT" --target "$TARGET" --preflight --output-dir "$OUTPUT_DIR/nested/normal-update" --reference-script "$REFERENCE_ENGINE" >"$OUTPUT_DIR/normal-update.stdout.log" 2>"$OUTPUT_DIR/normal-update.stderr.log" || status=$?
    printf '%d\n' "$status" > "$OUTPUT_DIR/normal-update.exit"
    if [ "$status" -eq 0 ]; then record_pass 'the embedded normal-update preflight completed without authorizing package installation'; else record_failure 'the embedded normal-update preflight failed'; fi
    if verify_archive_sidecar "$OUTPUT_DIR/nested/normal-update.tar.gz" "$OUTPUT_DIR/nested/normal-update.tar.gz.sha256"; then record_pass 'the nested normal-update archive and portable sidecar verify inside the apply-review evidence'; else record_failure 'the nested normal-update evidence failed verification'; fi

    values=$(validate_candidate_plan "$OUTPUT_DIR/nested/normal-update" "$OUTPUT_DIR/apply-plan.json" "$OUTPUT_DIR/apply-plan.tsv") || values=
    if [ -n "$values" ]; then
        CANDIDATE_COUNT=$(printf '%s\n' "$values"|sed -n '1p'); BASELINE_CANDIDATE_COUNT=$(printf '%s\n' "$values"|sed -n '2p'); ADDED_CANDIDATE_COUNT=$(printf '%s\n' "$values"|sed -n '3p'); INSTALL_NEW_COUNT=$(printf '%s\n' "$values"|sed -n '4p'); UPGRADE_ALL_COUNT=$(printf '%s\n' "$values"|sed -n '5p'); KERNEL_CANDIDATE_COUNT=$(printf '%s\n' "$values"|sed -n '6p'); KERNEL_TRANSACTION_COUNT=$(printf '%s\n' "$values"|sed -n '7p'); CRITICAL_CANDIDATE_COUNT=$(printf '%s\n' "$values"|sed -n '8p')
        record_pass 'the fresh candidate set is the exact reviewed 69-package baseline plus 68 additions'
        record_pass 'the install-new, upgrade-all, kernel, and critical classifications match the reviewed plan'
    else
        record_failure 'the fresh candidate transaction differs from the reviewed package union'
        record_failure 'candidate action or kernel classification could not be accepted'
    fi

    if validate_reference_contract "$OUTPUT_DIR/reference-apply-contract.json"; then
        record_pass 'the reference engine retains the exact noninteractive slackpkg and deferred post-install contract'
        record_pass 'the temporary GenInitrd policy override is restored around package actions and Slack-Update retains GRUB ownership'
        record_pass 'partial package failures block secondary modules while pending .new files remain evidence only'
    else
        record_failure 'the reference engine package command contract changed'
        record_failure 'the GenInitrd and GRUB ownership contract changed'
        record_failure 'the package-failure or pending-configuration boundary changed'
    fi

    capture_package_database "$OUTPUT_DIR/packages.after.txt" && capture_sensitive_state "$OUTPUT_DIR/sensitive.after.txt" || { record_failure 'post-review state capture failed'; return 1; }
    if cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt"; then record_pass 'the installed package database remained unchanged during apply review'; else record_failure 'the installed package database changed during apply review'; fi
    if cmp -s "$OUTPUT_DIR/sensitive.before.txt" "$OUTPUT_DIR/sensitive.after.txt"; then record_pass 'the active kernel, initrd, GenInitrd, DKMS, and GRUB state remained unchanged during apply review'; else record_failure 'apply-sensitive state changed during review'; fi

    if [ "$FAILURE_COUNT" -eq 0 ]; then USPACE_APPLY_REVIEW_COMPLETE=true; NEXT_STAGE=current-kernel-transaction-readiness-preflight; record_pass 'the userspace application review is complete while readiness and explicit apply authorization remain pending'; fi
    write_summary "$OUTPUT_DIR/summary.txt"
    printf 'Slackware-current userspace apply review result: candidates=%s, baseline=%s, additions=%s, install-new=%s, upgrade-all=%s, kernel-transaction=%s, critical=%s, userspace-apply-review-complete=%s, next-stage=%s, apply-ready=false, apply-authorized=false\n' "$CANDIDATE_COUNT" "$BASELINE_CANDIDATE_COUNT" "$ADDED_CANDIDATE_COUNT" "$INSTALL_NEW_COUNT" "$UPGRADE_ALL_COUNT" "$KERNEL_TRANSACTION_COUNT" "$CRITICAL_CANDIDATE_COUNT" "$USPACE_APPLY_REVIEW_COMPLETE" "$NEXT_STAGE"
    archive=$(create_evidence_archive) || { error 'failed to create evidence archive'; return 2; }
    print_evidence_commands "$archive"
    [ "$FAILURE_COUNT" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then main "$@"; fi
