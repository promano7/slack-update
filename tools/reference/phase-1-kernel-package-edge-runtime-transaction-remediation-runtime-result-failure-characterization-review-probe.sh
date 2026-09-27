#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

readonly EXPECTED_FQDN='vbox-slackcurrent.vbox-slackcurrent.org'
readonly EXPECTED_KERNEL='6.18.45'
readonly EXPECTED_BOOT_ID='fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9'
readonly EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256='726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'
readonly EXPECTED_SLACKPKG_CONF_SHA256='f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4'
readonly EXPECTED_SLACKPKG_MIRRORS_SHA256='71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12'
readonly EXPECTED_TARGET_RECORD='kernel-headers-6.18.45-x86-1'
readonly EXPECTED_GENERIC_RECORD='kernel-generic-6.18.45-x86_64-1'
readonly EXPECTED_PREDECESSOR_RECORD='kernel-headers-6.18.44-x86-1'
readonly EXPECTED_TREE_MANIFEST_SHA256='e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945'
readonly EXPECTED_EXECUTOR_SHA256='9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c'
readonly EVIDENCE_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction-remediation'
readonly PUBLISHED_ARCHIVE='/home/promano/slack-update-phase-1-kernel-package-edge-runtime-remediation-evidence.tar.gz'
readonly PUBLISHED_SHA256='/home/promano/slack-update-phase-1-kernel-package-edge-runtime-remediation-evidence.tar.gz.sha256'
readonly LOCAL_SOURCE_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2'
readonly TREE_MANIFEST='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2.tree.sha256'
readonly COMPAT_ASC="$LOCAL_SOURCE_ROOT/CHECKSUMS.md5.asc"
readonly EXECUTOR='/home/promano/Descargas/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh'
readonly SLACKPKG_CORE='/usr/libexec/slackpkg/core-functions.sh'
readonly SLACKPKG_CONF='/etc/slackpkg/slackpkg.conf'
readonly SLACKPKG_MIRRORS='/etc/slackpkg/mirrors'
readonly SLACKPKG_STATE='/var/lib/slackpkg'
readonly PACKAGE_DB='/var/lib/pkgtools/packages'
readonly GENINITRD_POLICY='/etc/default/geninitrd'

usage(){ cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-failure-characterization-review-probe.sh --observe-runtime-failure-characterization
       phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-failure-characterization-review-probe.sh --help

Read only the preserved failed remediation evidence and current runtime baseline.
No package, Slackpkg, network, boot, reboot, cleanup, or configuration mutation is performed.
USAGE
}
fail(){ printf 'ERROR: %s\n' "$*" >&2; exit 1; }
record(){ printf '%s\t%s\n' "$1" "$2"; }
package_records(){ local n=$1 f b; local a=(); shopt -s nullglob; for f in "$PACKAGE_DB/$n-"*; do [[ -f $f && ! -L $f ]] || continue; b=${f##*/}; a+=("$b"); done; shopt -u nullglob; ((${#a[@]})) && printf '%s\n' "${a[@]}" | LC_ALL=C sort || true; }
package_db_hash(){ find "$PACKAGE_DB" -maxdepth 1 -type f -printf '%f\n' | LC_ALL=C sort | sha256sum | awk '{print $1}'; }
path_fingerprint(){ local p=$1 metadata digest target; if [[ ! -e $p && ! -L $p ]]; then printf 'absent\n'; return; fi; if [[ -L $p ]]; then metadata=$(stat -c '%a:%u:%g:%s:%Y' -- "$p"); target=$(readlink -- "$p"); printf 'symlink|%s|%s\n' "$metadata" "$target" | sha256sum | awk '{print $1}'; return; fi; [[ -f $p ]] || fail "unsupported fingerprint path: $p"; metadata=$(stat -c '%a:%u:%g:%s:%Y' -- "$p"); digest=$(sha256sum -- "$p"|awk '{print $1}'); printf 'file|%s|%s\n' "$metadata" "$digest" | sha256sum | awk '{print $1}'; }
tree_fingerprint(){ local root=$1; [[ -d $root && ! -L $root ]] || fail "tree fingerprint root missing or unsafe: $root"; ( cd "$root"; find . -xdev -mindepth 1 -printf '%P\0' | LC_ALL=C sort -z | while IFS= read -r -d '' rel; do if [[ -L $rel ]]; then printf 'L\t%s\t%s\t%s\n' "$rel" "$(stat -c '%a:%u:%g:%s:%Y' -- "$rel")" "$(readlink -- "$rel")"; elif [[ -f $rel ]]; then printf 'F\t%s\t%s\t%s\n' "$rel" "$(stat -c '%a:%u:%g:%s:%Y' -- "$rel")" "$(sha256sum -- "$rel"|awk '{print $1}')"; elif [[ -d $rel ]]; then printf 'D\t%s\t%s\n' "$rel" "$(stat -c '%a:%u:%g:%s:%Y' -- "$rel")"; else printf 'O\t%s\t%s\n' "$rel" "$(stat -c '%F:%a:%u:%g:%s:%Y' -- "$rel")"; fi; done ) | sha256sum | awk '{print $1}'; }
tsv_value(){ local file=$1 key=$2; awk -F '\t' -v k="$key" '$1==k {print $2; exit}' "$file"; }

ack=0
while (($#)); do case "$1" in --observe-runtime-failure-characterization) [[ $ack -eq 0 ]] || fail 'duplicate observation acknowledgement'; ack=1; shift;; --help|-h) usage; exit 0;; *) printf 'ERROR: unknown option: %s\n' "$1" >&2; usage >&2; exit 2;; esac; done
[[ $ack -eq 1 ]] || { usage >&2; exit 2; }
[[ ${EUID:-$(id -u)} -eq 0 ]] || fail 'run this probe through sudo/root'
for c in awk cat find grep hostname paste readlink sed sha256sum sort stat tr uname wc; do command -v "$c" >/dev/null 2>&1 || fail "required command missing: $c"; done
for p in "$EVIDENCE_ROOT" "$EVIDENCE_ROOT/backup" "$EVIDENCE_ROOT/slackpkg-workdir"; do [[ -d $p && ! -L $p ]] || fail "required preserved evidence directory missing or unsafe: $p"; done
for p in "$EVIDENCE_ROOT/preflight.tsv" "$EVIDENCE_ROOT/cleanup.tsv" "$EVIDENCE_ROOT/slackpkg-update.exit-code" "$EVIDENCE_ROOT/slackpkg-update.stdout" "$EVIDENCE_ROOT/slackpkg-update.stderr" "$EVIDENCE_ROOT/backup/slackpkg.conf" "$EVIDENCE_ROOT/backup/mirrors" "$COMPAT_ASC" "$TREE_MANIFEST" "$EXECUTOR" "$SLACKPKG_CORE"; do [[ -f $p && ! -L $p ]] || fail "required preserved evidence file missing or unsafe: $p"; done
[[ ! -e $PUBLISHED_ARCHIVE && ! -L $PUBLISHED_ARCHIVE ]] || fail 'published success archive unexpectedly exists'
[[ ! -e $PUBLISHED_SHA256 && ! -L $PUBLISHED_SHA256 ]] || fail 'published success SHA-256 unexpectedly exists'
[[ ! -e $EVIDENCE_ROOT/result.tsv && ! -L $EVIDENCE_ROOT/result.tsv ]] || fail 'success result.tsv unexpectedly exists'

fqdn=$(hostname -f 2>/dev/null || true); kernel=$(uname -r); boot_id=$(cat /proc/sys/kernel/random/boot_id)
header=$(package_records kernel-headers); generic=$(package_records kernel-generic); huge=$(package_records kernel-huge); modules=$(package_records kernel-modules)
pkgdb=$(package_db_hash)
conf_sha=$(sha256sum -- "$SLACKPKG_CONF"|awk '{print $1}'); mirrors_sha=$(sha256sum -- "$SLACKPKG_MIRRORS"|awk '{print $1}')
pre_boot_fp=$(tsv_value "$EVIDENCE_ROOT/preflight.tsv" boot_fingerprint)
pre_state_fp=$(tsv_value "$EVIDENCE_ROOT/preflight.tsv" slackpkg_state_fingerprint)
pre_gen_fp=$(tsv_value "$EVIDENCE_ROOT/preflight.tsv" geninitrd_policy_fingerprint)
cur_boot_fp=$(tree_fingerprint /boot); cur_state_fp=$(tree_fingerprint "$SLACKPKG_STATE"); cur_gen_fp=$(path_fingerprint "$GENINITRD_POLICY")
update_rc=$(tr -d '[:space:]' < "$EVIDENCE_ROOT/slackpkg-update.exit-code")
cleanup_triggered=$(tsv_value "$EVIDENCE_ROOT/cleanup.tsv" cleanup_triggered)
rollback_from=$(tsv_value "$EVIDENCE_ROOT/cleanup.tsv" rollback_header_from)
work_pkglist="$EVIDENCE_ROOT/slackpkg-workdir/pkglist"
work_entries=$(find "$EVIDENCE_ROOT/slackpkg-workdir" -mindepth 1 -maxdepth 1 -printf '%f\n' | LC_ALL=C sort | paste -sd, -)
error_line=$(grep -Fi 'Error downloading from ' "$EVIDENCE_ROOT/slackpkg-update.stdout" "$EVIDENCE_ROOT/slackpkg-update.stderr" | head -n1 | sed 's/^[^:]*://' || true)

[[ $fqdn == "$EXPECTED_FQDN" ]] || fail "FQDN drift after rollback: $fqdn"
[[ $kernel == "$EXPECTED_KERNEL" ]] || fail "running kernel drift after rollback: $kernel"
[[ $boot_id == "$EXPECTED_BOOT_ID" ]] || fail "boot ID drift after rollback: $boot_id"
[[ $header == "$EXPECTED_TARGET_RECORD" ]] || fail "kernel-headers not restored: ${header:-<none>}"
[[ $generic == "$EXPECTED_GENERIC_RECORD" ]] || fail "kernel-generic drift: ${generic:-<none>}"
[[ -z $huge && -z $modules ]] || fail 'unexpected kernel-huge/kernel-modules records after rollback'
[[ $pkgdb == "$EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256" ]] || fail 'package database manifest not restored'
[[ $conf_sha == "$EXPECTED_SLACKPKG_CONF_SHA256" ]] || fail 'slackpkg.conf not restored'
[[ $mirrors_sha == "$EXPECTED_SLACKPKG_MIRRORS_SHA256" ]] || fail 'slackpkg mirrors not restored'
[[ $cur_boot_fp == "$pre_boot_fp" ]] || fail '/boot fingerprint differs from preflight'
[[ $cur_state_fp == "$pre_state_fp" ]] || fail 'Slackpkg state fingerprint differs from preflight'
[[ $cur_gen_fp == "$pre_gen_fp" ]] || fail 'GenInitrd policy fingerprint differs from preflight'
[[ $cleanup_triggered == yes ]] || fail 'cleanup evidence does not record cleanup_triggered=yes'
[[ $rollback_from == "$EXPECTED_PREDECESSOR_RECORD" ]] || fail "cleanup rollback source is unexpected: ${rollback_from:-<none>}"
[[ $update_rc == 0 ]] || fail "captured Slackpkg update exit code is not zero: $update_rc"
[[ ! -e $work_pkglist && ! -L $work_pkglist ]] || fail 'transaction-owned pkglist unexpectedly exists'
[[ -n $error_line ]] || fail 'captured Slackpkg output does not contain human-form Error downloading from signal'
[[ $(sha256sum -- "$TREE_MANIFEST"|awk '{print $1}') == "$EXPECTED_TREE_MANIFEST_SHA256" ]] || fail 'local-source-v2 manifest drift'
[[ $(sha256sum -- "$EXECUTOR"|awk '{print $1}') == "$EXPECTED_EXECUTOR_SHA256" ]] || fail 'transported executor drift'
if grep -q 'PGP' "$COMPAT_ASC"; then fail 'compatibility asc unexpectedly contains PGP marker'; fi
grep -Fq 'grep -q "PGP"' "$SLACKPKG_CORE" || fail 'installed Slackpkg source does not expose expected PGP marker check'
grep -Fq 'Error downloading from $SOURCE.' "$SLACKPKG_CORE" || fail 'installed Slackpkg source does not expose expected human-form download error'
grep -Fq "grep -Fqi 'error-downloading-from-local-source'" "$EXECUTOR" || fail 'executor does not expose the characterized hyphenated error guard'

record runtime_failure_characterization_status PASS
record single_use_runtime_authority_consumed yes
record second_execution_forbidden yes
record current_header_record "$header"
record package_database_manifest_sha256 "$pkgdb"
record slackpkg_conf_restored yes
record slackpkg_mirrors_restored yes
record slackpkg_state_restored yes
record geninitrd_policy_restored yes
record boot_artifacts_unchanged yes
record boot_id "$boot_id"
record cleanup_triggered yes
record rollback_header_from "$rollback_from"
record slackpkg_update_exit_code "$update_rc"
record slackpkg_update_error_signal_form human-spaced-error-downloading-from
record slackpkg_update_error_line "$error_line"
record transaction_pkglist_present no
record transaction_workdir_entries "${work_entries:-<empty>}"
record compatibility_asc_contains_PGP no
record installed_slackpkg_requires_PGP_marker yes
record installed_slackpkg_error_message_form human-spaced
record executor_error_signal_guard_form hyphenated-literal
record failure_mechanism_confirmed compatibility-asc-pgp-marker-rejection-plus-error-signal-guard-mismatch
record published_success_evidence_absent yes
record result_tsv_absent yes
record runtime_rerun_authorized no
record package_action_authorized no
record slackpkg_mutation_authorized no
record network_access_authorized no
record boot_action_authorized no
record reboot_authorized no
record evidence_cleanup_authorized no
