#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-review'
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-freeze'
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-review.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-review.md"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-review-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-review.tsv"
v3="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-r1.sh"
v4="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh"
prev_helper="$repo_root/tools/reference/${prev}.sh"
prev_doc="$repo_root/docs/reference/${prev}.md"
prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"
changelog="$repo_root/CHANGELOG.md"
passes=0
failures=0

good() { printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
bad() { printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
check() { local msg=$1; shift; if "$@"; then good "$msg"; else bad "$msg"; fi; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }
regular() { [[ -f $1 && ! -L $1 ]]; }
expect_hash() { [[ $(sha "$1") == "$2" ]]; }

for spec in   "step-263 helper|$helper"   "step-263 document|$doc"   "step-263 policy|$policy"   "step-263 record|$record"   "reviewed v4 builder|$v4"   "accepted step-262 helper|$prev_helper"   "accepted step-262 document|$prev_doc"   "accepted step-262 harness|$prev_harness"   "accepted step-262 policy|$prev_policy"   "accepted step-262 record|$prev_record"   "accepted v3 builder|$v3"   "CHANGELOG|$changelog"; do
    label=${spec%%|*}; path=${spec#*|}
    check "$label exists as regular file" regular "$path"
done

check 'accepted step-262 helper SHA-256 matches' expect_hash "$prev_helper" 'a8e6e5980edcf9550bc4ab7999b4452899b45e0e29c4e62039b9045916573b2f'
check 'accepted step-262 document SHA-256 matches' expect_hash "$prev_doc" '29da67295aba1d65de381901031048691940ac8729b57846c51d20c318ac04e5'
check 'accepted step-262 harness SHA-256 matches' expect_hash "$prev_harness" 'f5da26f955ded2eec9a70eb5035f9d06fa299476aa1414ad7a82ffd40ab98961'
check 'accepted step-262 policy SHA-256 matches' expect_hash "$prev_policy" '9359949c6dfd9ac7476b1b4f3053dbd2859022feab6d90e7baafcafb5a07b425'
check 'accepted step-262 record SHA-256 matches' expect_hash "$prev_record" 'fff8563425ff16f64935e94d99d6e8709554941aac55bc7e40917a04fb39d6e3'
check 'accepted v3 builder SHA-256 remains frozen' expect_hash "$v3" '80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30'
check 'reviewed v4 builder SHA-256 matches' expect_hash "$v4" '38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7'
check 'step-263 helper SHA-256 matches policy-bound identity' expect_hash "$helper" '546cc2c6bcb50ea64dfcde09d9facdd997dc6f1c615e04c07d944596d2557445'

check 'v4 builder passes bash syntax validation' bash -n "$v4"
check 'step-263 helper passes bash syntax validation' bash -n "$helper"
check 'step-263 harness passes bash syntax validation' bash -n "${BASH_SOURCE[0]}"
check 'v4 builder exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$v4"
check 'step-263 helper exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$helper"
check 'step-263 helper rejects unknown option' bash -c '! "$1" --unknown >/dev/null 2>&1' _ "$helper"

# Prove exact mechanical derivation from the frozen v3 baseline.
expected=$(mktemp)
cleanup_paths=() 
cleanup() { rm -f -- "$expected"; if [[ ${#cleanup_paths[@]} -gt 0 ]]; then rm -rf -- "${cleanup_paths[@]}"; fi; }
trap cleanup EXIT HUP INT TERM
python3 - "$v3" "$expected" <<'PYDIFF'
import pathlib, sys
src=pathlib.Path(sys.argv[1]).read_text(encoding='utf-8')
out=src.replace('v3','v4').replace('V3','V4')
old='        (cd "$source_root" && md5sum --tag -- "$rel") >> "$output"'
new='        (cd "$source_root" && md5sum -- "$rel") >> "$output"'
assert out.count(old)==1
out=out.replace(old,new,1)
oldv='''    expected_count=$(( expected_count - 2 ))
    checksum_count=$(grep -c '^MD5 (' "$source_root/CHECKSUMS.md5" || true)
    [[ $checksum_count -eq $expected_count ]] || fail 'CHECKSUMS.md5 does not bind the required generated regular files' || return 1
    while IFS= read -r -d '' rel; do
        case "$rel" in
            ./CHECKSUMS.md5|./CHECKSUMS.md5.asc) continue ;;
        esac
        md5=$(cd "$source_root" && md5sum -- "$rel" | awk '{print $1}')
        grep -Fxq "MD5 ($rel) = $md5" "$source_root/CHECKSUMS.md5" || fail "CHECKSUMS.md5 missing binding: $rel" || return 1
    done < <(cd "$source_root" && find . -type f -print0 | LC_ALL=C sort -z)
'''
newv='''    expected_count=$(( expected_count - 2 ))
    checksum_count=$(wc -l < "$source_root/CHECKSUMS.md5")
    [[ $checksum_count -eq $expected_count ]] || fail 'CHECKSUMS.md5 does not bind exactly the required generated regular files' || return 1
    [[ $(grep -c '^MD5 (' "$source_root/CHECKSUMS.md5" || true) -eq 0 ]] || fail 'CHECKSUMS.md5 contains forbidden tagged MD5 records' || return 1
    while IFS= read -r -d '' rel; do
        case "$rel" in
            ./CHECKSUMS.md5|./CHECKSUMS.md5.asc) continue ;;
        esac
        md5=$(cd "$source_root" && md5sum -- "$rel" | awk '{print $1}')
        [[ $(grep -Fxc "$md5  $rel" "$source_root/CHECKSUMS.md5" || true) -eq 1 ]] || fail "CHECKSUMS.md5 missing, duplicate, or malformed binding: $rel" || return 1
    done < <(cd "$source_root" && find . -type f -print0 | LC_ALL=C sort -z)
'''
assert out.count(oldv)==1
out=out.replace(oldv,newv,1)
pathlib.Path(sys.argv[2]).write_text(out,encoding='utf-8')
PYDIFF
check 'v4 builder is exact allowlisted mechanical derivative of v3-r1' cmp -s "$expected" "$v4"
check 'v4 builder contains ordinary untagged checksum writer' grep -Fq 'md5sum -- "$rel"' "$v4"
check 'v4 builder contains no md5sum --tag writer' bash -c '! grep -Fq "md5sum --tag" "$1"' _ "$v4"
check 'v4 builder requires exact checksum line count' grep -Fq 'checksum_count=$(wc -l < "$source_root/CHECKSUMS.md5")' "$v4"
check 'v4 builder rejects tagged checksum records' grep -Fq "grep -c '^MD5 ('" "$v4"
check 'v4 builder requires exact one binding per eligible file' grep -Fq 'grep -Fxc "$md5  $rel"' "$v4"
check 'v4 builder exposes frozen v4 production switch' grep -Fq -- '--build-local-source-v4' "$v4"
check 'v4 builder exposes frozen library-only seam' grep -Fq 'SLACK_UPDATE_LOCAL_SOURCE_V4_BUILDER_LIBRARY_ONLY' "$v4"
check 'v4 builder uses distinct local-source-v4 root' grep -Fq "/local-source-v4'" "$v4"
check 'v4 builder preserves frozen target SHA-256' grep -Fq "TARGET_SHA256='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'" "$v4"

# Source library functions only; main must not execute.
export SLACK_UPDATE_LOCAL_SOURCE_V4_BUILDER_LIBRARY_ONLY=1
# shellcheck source=/dev/null
source "$v4"
unset SLACK_UPDATE_LOCAL_SOURCE_V4_BUILDER_LIBRARY_ONLY
function_exists() { declare -F "$1" >/dev/null; }
check 'library-only seam exposes checksum writer function' function_exists write_checksums_md5
check 'library-only seam exposes source-tree validator function' function_exists validate_source_tree

# Use a full synthetic source tree satisfying all non-checksum invariants so validate_source_tree
# exercises the production checksum contract without invoking production main.
make_synthetic_tree() {
    local root=$1 target="$1/$TARGET_RELATIVE_PATH" tree
    mkdir -p -- "${target%/*}"
    for tree in "${PRIORITY_TREES[@]}"; do mkdir -p -- "$root/$tree"; done
    printf 'synthetic package bytes\n' > "$target"
    printf 'synthetic changelog\n' > "$root/ChangeLog.txt"
    cat > "$root/PACKAGES.TXT" <<EOF
PACKAGE NAME:  $TARGET_FILENAME
PACKAGE LOCATION:  $PACKAGE_LOCATION
PACKAGE SIZE (compressed):  1 K
PACKAGE SIZE (uncompressed):  1 K
PACKAGE DESCRIPTION:
kernel-headers: synthetic

EOF
    cp -- "$root/PACKAGES.TXT" "$root/slackware64/PACKAGES.TXT"
    for tree in patches extra pasture testing; do : > "$root/$tree/PACKAGES.TXT"; done
    cat > "$root/CHECKSUMS.md5.asc" <<'EOF'
slack-update local-source-v4 Slackpkg compatibility artifact
PGP compatibility marker for Slackpkg checkchangelog only.
No cryptographic authenticity claim is made by this file.
This file is not an OpenPGP signature and MUST NOT be treated as one.
Package authenticity is bound by the frozen SHA-256 and external v4 tree manifest.
EOF
    : > "$root/CHECKSUMS.md5"
    write_filelist "$root" "$root/FILELIST.TXT"
}

# The production validator also checks the frozen target SHA. For checksum-only synthetic
# cases, invoke a wrapper that temporarily binds expected SHA to the synthetic target bytes.
validate_synthetic() {
    local root=$1 synsha
    synsha=$(sha256sum -- "$root/$TARGET_RELATIVE_PATH" | awk '{print $1}')
    validate_source_tree "$root" "$synsha" >/dev/null 2>&1
}

expect_validate_fail() {
    ! validate_synthetic "$1"
}

SYNTH_TREE=''
new_tree() {
    SYNTH_TREE=$(mktemp -d)
    cleanup_paths+=("$SYNTH_TREE")
    make_synthetic_tree "$SYNTH_TREE"
}

# Valid untagged output.
new_tree; t=$SYNTH_TREE; write_checksums_md5 "$t" "$t/CHECKSUMS.md5"
check 'synthetic valid untagged checksum bindings pass' validate_synthetic "$t"
check 'synthetic target checksum line ends in package filename' bash -c 'grep -E "  \.\/slackware64\/d\/kernel-headers-6\.18\.45-x86-1\.txz$" "$1" >/dev/null' _ "$t/CHECKSUMS.md5"

# Tagged output must fail.
new_tree; t=$SYNTH_TREE
while IFS= read -r -d '' rel; do
    case "$rel" in ./CHECKSUMS.md5|./CHECKSUMS.md5.asc) continue ;; esac
    (cd "$t" && md5sum --tag -- "$rel") >> "$t/CHECKSUMS.md5"
done < <(cd "$t" && find . -type f -print0 | LC_ALL=C sort -z)
check 'synthetic tagged checksum bindings are rejected' expect_validate_fail "$t"

# Missing binding must fail.
new_tree; t=$SYNTH_TREE; write_checksums_md5 "$t" "$t/CHECKSUMS.md5"; sed -i '$d' "$t/CHECKSUMS.md5"
check 'synthetic missing checksum binding is rejected' expect_validate_fail "$t"

# Duplicate binding must fail.
new_tree; t=$SYNTH_TREE; write_checksums_md5 "$t" "$t/CHECKSUMS.md5"; head -n 1 "$t/CHECKSUMS.md5" >> "$t/CHECKSUMS.md5"
check 'synthetic duplicate checksum binding is rejected' expect_validate_fail "$t"

# GNU binary marker uses `*path` instead of two-space text marker and must fail exact binding.
new_tree; t=$SYNTH_TREE
while IFS= read -r -d '' rel; do
    case "$rel" in ./CHECKSUMS.md5|./CHECKSUMS.md5.asc) continue ;; esac
    (cd "$t" && md5sum --binary -- "$rel") >> "$t/CHECKSUMS.md5"
done < <(cd "$t" && find . -type f -print0 | LC_ALL=C sort -z)
check 'synthetic binary-marker or malformed checksum bindings are rejected' expect_validate_fail "$t"

# Extra binding must fail by exact line count.
new_tree; t=$SYNTH_TREE; write_checksums_md5 "$t" "$t/CHECKSUMS.md5"; printf '00000000000000000000000000000000  ./ghost-file\n' >> "$t/CHECKSUMS.md5"
check 'synthetic extra checksum binding is rejected' expect_validate_fail "$t"

# Reproduce policy and record.
out=$(mktemp -d); cleanup_paths+=("$out")
if "$helper" --output-dir "$out" >/dev/null; then good 'step-263 helper executes successfully'; else bad 'step-263 helper executes successfully'; fi
check 'helper reproduces frozen policy exactly' cmp -s "$out/${base}-policy.json" "$policy"
check 'helper reproduces frozen record exactly' cmp -s "$out/${base}.tsv" "$record"

check 'policy identifies step 263' python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); assert p["step"]==263 and p["scenario"]==sys.argv[2]' "$policy" "$base"
check 'policy marks implementation reviewed not frozen' python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); assert p["reviewed_v4_builder"]["state"]=="implementation-reviewed-not-frozen"' "$policy"
check 'policy binds reviewed v4 builder SHA-256' python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); assert p["reviewed_v4_builder"]["sha256"]==sys.argv[2]' "$policy" '38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7'
check 'policy preserves narrow functional scope' python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); assert p["implementation_review"]["functional_remediation_scope"]=="CHECKSUMS.md5 record representation only"' "$policy"
check 'policy records all synthetic checksum gates passed or rejected as required' python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); r=p["implementation_review"]; assert all(r[k] for k in ["synthetic_valid_untagged_passed","synthetic_tagged_failed","synthetic_missing_failed","synthetic_duplicate_failed","synthetic_binary_marker_or_malformed_failed","synthetic_extra_failed"])' "$policy"
check 'policy keeps builder execution closed' python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); assert p["authorization"]["local_source_v4_builder_execution_authorized"] is False' "$policy"
check 'policy keeps v4 build closed' python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); assert p["authorization"]["local_source_v4_build_authorized"] is False' "$policy"
check 'policy opens only implementation freeze repository stage' python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); assert p["authorization"]["repository_only_v4_builder_implementation_freeze_authorized"] is True and p["next_stage"].endswith("local-source-v4-builder-implementation-freeze")' "$policy"
check 'policy requires no machine action' python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); assert p["machine_action_required"] is False and p["controller_action_required"] is False' "$policy"
check 'step 263 is not a strong safe pause' python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); assert p["pause_safe"] is False and p["strong_safe_pause"] is False' "$policy"

check 'TSV binds reviewed builder SHA-256' grep -Fxq $'reviewed_v4_builder_sha256\t38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7' "$record"
check 'TSV records authorized diff proof' grep -Fxq $'authorized_diff_only_verified\tyes' "$record"
check 'TSV records valid synthetic PASS' grep -Fxq $'valid_untagged_synthetic_test\tPASS' "$record"
check 'TSV records tagged synthetic rejection' grep -Fxq $'tagged_synthetic_test\tREJECTED' "$record"
check 'TSV records no builder execution' grep -Fxq $'v4_builder_execution_performed\tno' "$record"
check 'TSV names implementation freeze next' grep -Fxq $'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-freeze' "$record"

check 'step-263 document records exact v4 builder SHA-256' grep -Fq '38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7' "$doc"
check 'step-263 document records ordinary untagged writer' grep -Fq 'md5sum -- "$rel"' "$doc"
check 'step-263 document records repository-only synthetic cases' grep -Fq 'binary-marker/malformed bindings fail' "$doc"
check 'step-263 document keeps production execution closed' grep -Fq 'Production builder execution and the v4 build remain forbidden.' "$doc"
check 'CHANGELOG records step 263' grep -Fq '## Phase 1 step 263 kernel-package-edge runtime-transaction remediation local-source-v4 builder implementation review' "$changelog"

for path in "$v4" "$helper" "$doc" "$policy" "$record"; do
    name=${path##*/}
    if grep -n '[[:blank:]]$' "$path" >/dev/null; then bad "$name contains no trailing whitespace"; else good "$name contains no trailing whitespace"; fi
done

# Static guard: no newly introduced operational command families beyond the frozen v3 baseline.
check 'v4 builder contains no executable network downloader command' bash -c '! grep -E "^[[:space:]]*(curl|wget|ftp|rsync|scp|ssh)[[:space:]]" "$1"' _ "$v4"
check 'v4 builder contains no executable package or Slackpkg mutation command' bash -c '! grep -E "^[[:space:]]*(installpkg|upgradepkg|removepkg|slackpkg)[[:space:]]" "$1"' _ "$v4"
check 'v4 builder contains no executable boot reboot or shutdown command' bash -c '! grep -E "^[[:space:]]*(reboot|shutdown|poweroff|halt|lilo|eliloconfig|grub-install|grub-mkconfig)[[:space:]]" "$1"' _ "$v4"

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
