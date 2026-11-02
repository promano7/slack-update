#!/bin/bash
# Actual main, private captures and forbidden external boundaries. No elevation.
set -uo pipefail
ROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
TMP=$(mktemp -d)
trap 'rm -rf -- "$TMP"' EXIT
failures=0
checks=0
check() { checks=$((checks+1)); if ! "$@"; then printf 'FAIL: %s\n' "$*" >&2; failures=$((failures+1)); fi; }
case_name=${1:-all}
if [ "$case_name" = all ] || [ "$case_name" = apply-blocked-before-backend ]; then
    for uid in 0 1000; do
        (
            source "$ROOT/tests/acceptance/reference/test-normal-update.sh"
            id() { if [ "${1:-}" = -u ]; then printf '%s\n' "$uid"; else command id "$@"; fi; }
            hostname() { printf 'fixture-host\n'; }
            forbidden() { printf 'FORBIDDEN\n' >> "$TMP/trace-$uid"; return 97; }
            slackpkg() { forbidden; }
            run_metadata_refresh() { forbidden; }
            run_candidate_probe() { forbidden; }
            run_reference_apply() { forbidden; }
            capture_host_metadata() { printf 'fixture\n' > "$1"; }
            capture_package_database() { printf 'fixture\n' > "$2"; }
            capture_boot_state() { printf 'fixture\n' > "$1"; }
            publish_evidence_archive() { :; }
            print_evidence_copy_command() { :; }
            print_evidence_verification_command() { :; }
            main --target slackware-current --execute-apply --confirm-hostname fixture-host \
                --confirm-candidates-sha256 "$(printf 'a%.0s' {1..64})" \
                --allow-kernel-update --allow-critical-update --output-dir "$TMP/apply-$uid"
        ) > "$TMP/out-$uid" 2> "$TMP/err-$uid"
        status=$?
        check test "$status" -eq 2
        check grep -q 'apply-disabled-until-selection-consumption-binding' "$TMP/err-$uid"
        check test ! -e "$TMP/trace-$uid"
    done
fi

flow_case() {
    local fixture=$1 expected_trace=$2 reason=$3
    (
        source "$ROOT/tests/acceptance/reference/test-normal-update.sh"
        CASE_MAIN_PID=$BASHPID
        id() { if [ "${1:-}" = -u ]; then printf '0\n'; else command id "$@"; fi; }
        hostname() { printf 'fixture-host\n'; }
        slackpkg() { printf 'FORBIDDEN real backend\n' >> "$TMP/$fixture.trace"; return 97; }
        run_metadata_refresh() { slackpkg; }
        run_candidate_probe() { slackpkg; }
        extract_slackpkg_candidates() { slackpkg; }
        run_reference_apply() { slackpkg; }
        validate_diagnostic_policy() { printf '{}\n' > "$2"; }
        capture_host_metadata() { printf 'fixture\n' > "$1"; }
        capture_package_database() {
            if [ "$fixture" = final-package-drift ] && [[ "$2" = *after-preflight* ]]; then
                printf 'changed\n' > "$2"
            else printf 'fixture\n' > "$2"; fi
        }
        capture_selection_state() { printf 'fixture\n' > "$2"; }
        establish_diagnostic_baseline() { printf 'fixture\n' > "$3"; }
        capture_boot_state() { printf 'fixture\n' > "$1"; }
        capture_diagnostic_boot() {
            [ "$fixture" != capture-failure ] || return 81
            if [ "$fixture" = signal-final-capture ] && [[ "$2" = *after-preflight* ]]; then kill -TERM "$CASE_MAIN_PID"; fi
            printf 'fixture\n' > "$2"
        }
        validate_diagnostic_catalog() { printf '{}\n' > "$3/catalog.json"; }
        validate_diagnostic_probe() { printf 'fixture-app-1.0-x86_64-1.txz\n' > "$4.candidates.txt"; }
        run_diagnostic_command() {
            printf '%s\n' "$1" >> "$TMP/$fixture.trace"
            local raw=0
            case "$fixture:$1" in refresh30-stops:update|refresh-and-archive-failure:update|refresh-signal-archive:update) raw=30 ;;
                install42-stops:install-new|upgrade42-no-digest:upgrade-all) raw=42 ;;
                signal-stops:update) kill -TERM "$BASHPID" ;; esac
            printf '%s\n' "$raw" > "$2.exit"
            : > "$2.stdout"; : > "$2.stderr"
            return "$raw"
        }
        publish_evidence_archive() { :; }
        print_evidence_copy_command() { :; }
        print_evidence_verification_command() { :; }
        if [ "$fixture" = archive-failure ] || [ "$fixture" = refresh-and-archive-failure ]; then
            create_evidence_archive() { return 80; }
        fi
        if [ "$fixture" = signal-archive ] || [ "$fixture" = refresh-signal-archive ]; then
            create_evidence_archive() {
                printf 'unpublished archive\n' > "$OUTPUT_DIR.tar.gz"
                printf 'unpublished sidecar\n' > "$OUTPUT_DIR.tar.gz.sha256"
                kill -TERM "$CASE_MAIN_PID"
                return 80
            }
        fi
        if [ "$fixture" = archive-collision ]; then printf 'prior evidence\n' > "$TMP/$fixture.tar.gz"; fi
        # Supply globals also on the unchanged base to isolate the flow defect.
        DIAGNOSTIC_POLICY="$TMP/policy.json"
        main --target slackware-current --preflight --output-dir "$TMP/$fixture"
    ) > "$TMP/$fixture.out" 2> "$TMP/$fixture.err"
    local raw=$?
    check test "$raw" -ne 0
    printf '%s' "$expected_trace" > "$TMP/expected-trace"
    [ -e "$TMP/$fixture.trace" ] || : > "$TMP/$fixture.trace"
    check cmp -s "$TMP/expected-trace" "$TMP/$fixture.trace"
    check grep -q "failure_reason=$reason" "$TMP/$fixture/summary.txt"
    check grep -q 'candidate_set_sha256=not-calculated' "$TMP/$fixture/summary.txt"
    if [ "$fixture" = signal-archive ] || [ "$fixture" = refresh-signal-archive ]; then
        check test ! -e "$TMP/$fixture.tar.gz"
        check test -e "$TMP/$fixture/interrupted-publication/$fixture.tar.gz"
        check test ! -e "$TMP/$fixture.tar.gz.sha256"
    fi
    if [ "$fixture" = archive-collision ]; then check grep -q 'prior evidence' "$TMP/$fixture.tar.gz"; fi
}
for c in refresh30-stops install42-stops upgrade42-no-digest capture-failure archive-failure refresh-and-archive-failure signal-stops final-package-drift signal-final-capture signal-archive refresh-signal-archive archive-collision; do
    if [ "$case_name" = all ] || [ "$case_name" = "$c" ]; then
        case "$c" in
            refresh30-stops|refresh-and-archive-failure) flow_case "$c" $'update\n' refresh-failed ;;
            install42-stops) flow_case "$c" $'update\ninstall-new\n' install-new-failed ;;
            upgrade42-no-digest) flow_case "$c" $'update\ninstall-new\nupgrade-all\n' upgrade-all-failed ;;
            capture-failure) flow_case "$c" '' boot-before-failed ;;
            archive-failure) flow_case "$c" $'update\ninstall-new\nupgrade-all\n' archive-failed ;;
            final-package-drift) flow_case "$c" $'update\ninstall-new\nupgrade-all\n' package-state-drift ;;
            signal-final-capture|signal-archive) flow_case "$c" $'update\ninstall-new\nupgrade-all\n' signal-TERM ;;
            refresh-signal-archive) flow_case "$c" $'update\n' refresh-failed ;;
            archive-collision) flow_case "$c" $'update\ninstall-new\nupgrade-all\n' archive-output-exists ;;
            signal-stops) flow_case "$c" $'update\n' signal-TERM ;;
        esac
    fi
done

printf 'Diagnostic flow: %d checks, %d failures\n' "$checks" "$failures"
[ "$checks" -gt 0 ] && [ "$failures" -eq 0 ]
