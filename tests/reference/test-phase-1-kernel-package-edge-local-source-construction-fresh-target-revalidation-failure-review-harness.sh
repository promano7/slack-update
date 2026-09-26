#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-failure-review-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-failure-review.tsv"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-failure-review.sh"
probe="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-package-database-drift-characterization-probe.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-failure-review.md"
passes=0; failures=0
pass(){ printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail(){ printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
for f in "$policy" "$record" "$helper" "$probe" "$doc"; do [[ -f $f && ! -L $f ]] && pass "${f#$repo_root/} is a regular file" || fail "${f#$repo_root/} missing or unsafe"; done
bash -n "$helper" && pass 'failure-review helper passes shell syntax validation' || fail 'failure-review helper shell syntax'
bash -n "$probe" && pass 'characterization probe passes shell syntax validation' || fail 'characterization probe shell syntax'
python3 - "$policy" <<'PY' && pass 'policy freezes fail-closed drift and read-only characterization only' || fail 'policy contract mismatch'
import json,sys
p=json.load(open(sys.argv[1]))
assert p['scenario'].endswith('fresh-target-revalidation-failure-review')
assert p['revision']=='r1-package-database-drift-characterization'
assert p['observed_failure']['expected_manifest_sha256']=='3aeaf9f193f5bc5c92f10ee3c5063be0b17a0e3001eccbc57bc4037c4343e910'
assert p['observed_failure']['actual_manifest_sha256']=='726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'
assert p['observed_failure']['step_201_failed_closed'] is True
assert p['authorization']['package_database_drift_characterization_authorized'] is True
for k,v in p['authorization'].items():
    if k!='package_database_drift_characterization_authorized': assert v is False
assert p['pause_safe'] is False
PY

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
bash "$helper" --output-dir "$tmp" >/dev/null
cmp -s "$policy" "$tmp/${policy##*/}" && cmp -s "$record" "$tmp/${record##*/}" && pass 'helper reproduces policy and record deterministically' || fail 'helper output is not deterministic'
probe_sha=$(sha256sum "$probe"|awk '{print $1}')
grep -Fqx "characterization_probe_sha256	$probe_sha" "$record" && pass 'record binds exact characterization probe SHA-256' || fail 'record probe SHA-256 mismatch'
grep -Fq "readonly EXPECTED_DRIFT_MANIFEST_SHA256='726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'" "$probe" && pass 'probe binds exact failed manifest' || fail 'probe does not bind failed manifest'
grep -Fq "readonly BASELINE_OBSERVED_UTC='2026-09-24 16:18:07 UTC'" "$probe" && pass 'probe binds accepted baseline observation time' || fail 'probe baseline time mismatch'
grep -Fq "recent_installed_record" "$probe" && grep -Fq "recent_removed_record" "$probe" && pass 'probe reports recent installed and removed pkgtools records' || fail 'probe missing drift detail reporting'
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|wget|curl|reboot|shutdown|poweroff)([[:space:]]|$)' "$probe"; then fail 'probe contains mutation or network command'; else pass 'probe contains no executable network/package/boot/reboot command'; fi
grep -Fq 'step 201 correctly failed closed' <(tr '[:upper:]' '[:lower:]' < "$doc") && pass 'document records fail-closed result' || fail 'document does not record failure semantics'
grep -Fq 'Phase 1 step 201-r1' "$repo_root/CHANGELOG.md" && pass 'CHANGELOG records step 201-r1' || fail 'CHANGELOG missing step 201-r1'
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && echo PASS || echo FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
