#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
LC_ALL=C
export LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-current-userspace-elf-runtime-review-preflight.sh"
# shellcheck source=../acceptance/reference/test-current-userspace-elf-runtime-review-preflight.sh
source "$SCRIPT"

HARNESS_TEST_COUNT=0
HARNESS_FAILURE_COUNT=0
pass() { HARNESS_TEST_COUNT=$((HARNESS_TEST_COUNT + 1)); printf 'PASS: %s\n' "$1"; }
fail() { HARNESS_TEST_COUNT=$((HARNESS_TEST_COUNT + 1)); HARNESS_FAILURE_COUNT=$((HARNESS_FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" >&2; }
assert_success() { local message=$1; shift; if "$@"; then pass "$message"; else fail "$message"; fi; }
assert_failure() { local message=$1; shift; if "$@"; then fail "$message"; else pass "$message"; fi; }
assert_equal() { local expected=$1 actual=$2 message=$3; [ "$expected" = "$actual" ] && pass "$message" || { printf '  expected: %s\n  actual:   %s\n' "$expected" "$actual" >&2; fail "$message"; }; }
assert_contains() { local needle=$1 file=$2 message=$3; grep -Fq -- "$needle" "$file" && pass "$message" || fail "$message"; }
assert_not_matches() { local pattern=$1 file=$2 message=$3; grep -Eq -- "$pattern" "$file" && fail "$message" || pass "$message"; }
json_value() { python3 - "$1" "$2" <<'PY'
import json,sys
d=json.load(open(sys.argv[1])); print(eval(sys.argv[2],{'d':d}))
PY
}
copy_json_mutation() { local src=$1 dst=$2 code=$3; python3 - "$src" "$dst" "$code" <<'PY'
import json,sys
d=json.load(open(sys.argv[1])); exec(sys.argv[3]); open(sys.argv[2],'w').write(json.dumps(d,indent=2,sort_keys=True)+'\n')
PY
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
cat > "$TMP/bin/ldconfig" <<'EOF_LDCONFIG'
#!/bin/sh
cat <<'EOF_CACHE'
1 libs found in cache `/etc/ld.so.cache'
	libhost.so.1 (libc6,x86-64) => /lib64/libhost.so.1
EOF_CACHE
EOF_LDCONFIG
cat > "$TMP/bin/readelf" <<'EOF_READELF'
#!/bin/sh
mode=
file=
for arg in "$@"; do
    case "$arg" in -h|-d|-l) mode=$arg ;; --) ;; *) file=$arg ;; esac
done
marker=$(dd if="$file" bs=1 skip=4 2>/dev/null | head -n 1)
case "$mode" in
-h)
    machine='Advanced Micro Devices X86-64'
    [ "$marker" = WRONG_ARCH ] && machine='AArch64'
    type=DYN
    [ "$marker" = SAFE_REL ] && type=REL
    cat <<EOF_HEADER
ELF Header:
  Class:                             ELF64
  Data:                              2's complement, little endian
  Type:                              $type (Shared object file)
  Machine:                           $machine
EOF_HEADER
    ;;
-d)
    case "$marker" in
        SAFE_APP) printf ' 0x1 (NEEDED) Shared library: [libhost.so.1]\n 0x1 (NEEDED) Shared library: [libtxn.so.1]\n' ;;
        SAFE_LIB) printf ' 0xe (SONAME) Library soname: [libtxn.so.1]\n 0x1 (NEEDED) Shared library: [libhost.so.1]\n' ;;
        UNRESOLVED) printf ' 0x1 (NEEDED) Shared library: [libmissing.so.9]\n' ;;
        TEXTREL) printf ' 0x16 (TEXTREL) 0x0\n' ;;
        UNSAFE_RUNPATH) printf ' 0x1d (RUNPATH) Library runpath: [/tmp/evil]\n' ;;
        NEEDED_SLASH) printf ' 0x1 (NEEDED) Shared library: [../libevil.so]\n' ;;
        *) : ;;
    esac
    ;;
-l)
    case "$marker" in
        SAFE_APP|UNRESOLVED|TEXTREL|UNSAFE_RUNPATH|NEEDED_SLASH|EXEC_STACK|WX_LOAD|WRONG_ARCH)
            interp=/lib64/ld-linux-x86-64.so.2
            [ "$marker" = UNSAFE_INTERPRETER ] && interp=/tmp/ld.so
            printf '      [Requesting program interpreter: %s]\n' "$interp"
            ;;
        UNSAFE_INTERPRETER) printf '      [Requesting program interpreter: /tmp/ld.so]\n' ;;
    esac
    [ "$marker" = EXEC_STACK ] && printf '  GNU_STACK 0x0 0x0 0x0 0x0 0x0 RWE 0x10\n'
    [ "$marker" = WX_LOAD ] && printf '  LOAD 0x0 0x0 0x0 0x100 0x100 RWE 0x1000\n'
    ;;
*) exit 1 ;;
esac
exit 0
EOF_READELF
chmod +x "$TMP/bin/ldconfig" "$TMP/bin/readelf"
PATH="$TMP/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export PATH

make_fixture() {
    local root=$1 mutation=${2:-none}
    rm -rf "$root"
    mkdir -p "$root/tree/usr/bin" "$root/tree/usr/lib64" "$root/payload"
    printf '\177ELFSAFE_APP\n' > "$root/tree/usr/bin/app"
    printf '\177ELFSAFE_LIB\n' > "$root/tree/usr/lib64/libtxn.so.1"
    printf '\177ELFSAFE_REL\n' > "$root/tree/usr/lib64/fixture.o"
    printf 'not elf\n' > "$root/tree/usr/share.txt"
    case "$mutation" in
        wrong-arch) printf '\177ELFWRONG_ARCH\n' > "$root/tree/usr/bin/app" ;;
        unresolved) printf '\177ELFUNRESOLVED\n' > "$root/tree/usr/bin/app" ;;
        unsafe-interpreter) printf '\177ELFUNSAFE_INTERPRETER\n' > "$root/tree/usr/bin/app" ;;
        textrel) printf '\177ELFTEXTREL\n' > "$root/tree/usr/bin/app" ;;
        exec-stack) printf '\177ELFEXEC_STACK\n' > "$root/tree/usr/bin/app" ;;
        wx-load) printf '\177ELFWX_LOAD\n' > "$root/tree/usr/bin/app" ;;
        unsafe-runpath) printf '\177ELFUNSAFE_RUNPATH\n' > "$root/tree/usr/bin/app" ;;
        needed-slash) printf '\177ELFNEEDED_SLASH\n' > "$root/tree/usr/bin/app" ;;
        elf-count) printf '\177ELFSAFE_REL\n' > "$root/tree/usr/lib64/extra.o" ;;
    esac
    (cd "$root/tree" && tar -cJf "$root/fixture-1.0-x86_64-1.txz" .)
    local sha size
    sha=$(sha256sum "$root/fixture-1.0-x86_64-1.txz" | awk '{print $1}')
    size=$(stat -c '%s' "$root/fixture-1.0-x86_64-1.txz")
    printf 'fixture-1.0-x86_64-1.txz\t%s\t%s\t%s\n' "$root/fixture-1.0-x86_64-1.txz" "$sha" "$size" > "$root/payload/cached-packages.tsv"
    python3 - "$root/policy.json" "$sha" "$size" <<'PY'
import json,sys
path,sha,size=sys.argv[1],sys.argv[2],int(sys.argv[3])
policy={
 'reviewed_packages':[{'package':'fixture-1.0-x86_64-1.txz','sha256':sha,'size':size,'expected_elf_count':3}],
 'expected_elf_file_count':3,'required_identity':{'class':'ELF64','data':"2's complement, little endian",'machine':'Advanced Micro Devices X86-64'},
 'allowed_program_interpreters':['/lib64/ld-linux-x86-64.so.2'],'default_runtime_directories':['/lib64','/usr/lib64','/lib','/usr/lib'],
 'allowed_runtime_path_roots':['/lib64','/usr/lib64','/lib','/usr/lib'],'forbidden_runtime_path_roots':['/tmp','/var/tmp','/dev/shm','/run/user']}
open(path,'w').write(json.dumps(policy,indent=2,sort_keys=True)+'\n')
PY
}

TARGET=slackware-current
CONFIRM_CANDIDATES_SHA256=27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926
CONFIRM_TARGET_KERNEL=6.18.42
values=$(validate_accepted_records)
assert_equal 722 "$(printf '%s\n' "$values" | sed -n '1p')" 'the checked-in policy should bind 722 ELF objects'
assert_equal 61 "$(printf '%s\n' "$values" | sed -n '2p')" 'the checked-in policy should bind 61 ELF-contributing packages'

make_fixture "$TMP/good"
REVIEW_POLICY=$TMP/good/policy.json
values=$(analyze_elf_runtime "$TMP/good/payload" "$TMP/good/inventory.tsv" "$TMP/good/summary.json" "$TMP/good/host.tsv" "$TMP/good/work")
assert_equal 3 "$(printf '%s\n' "$values" | sed -n '1p')" 'the fixture should contain three ELF objects'
assert_equal 1 "$(printf '%s\n' "$values" | sed -n '2p')" 'one package should contribute ELF objects'
assert_equal 2 "$(printf '%s\n' "$values" | sed -n '3p')" 'two fixture objects should be ET_DYN'
assert_equal 0 "$(printf '%s\n' "$values" | sed -n '4p')" 'the fixture should contain no ET_EXEC object'
assert_equal 1 "$(printf '%s\n' "$values" | sed -n '5p')" 'one fixture object should be relocatable'
assert_equal 1 "$(printf '%s\n' "$values" | sed -n '7p')" 'one object should request the reviewed interpreter'
assert_equal 3 "$(printf '%s\n' "$values" | sed -n '8p')" 'the fixture should expose three dependency edges'
assert_equal 2 "$(printf '%s\n' "$values" | sed -n '9p')" 'the fixture should expose two unique needed names'
assert_equal 1 "$(printf '%s\n' "$values" | sed -n '10p')" 'one transaction SONAME should be indexed'
assert_equal 2 "$(printf '%s\n' "$values" | sed -n '11p')" 'two dependency edges should resolve through the host cache'
assert_equal 1 "$(printf '%s\n' "$values" | sed -n '12p')" 'one dependency edge should resolve through the transaction provider'
assert_equal 0 "$(printf '%s\n' "$values" | sed -n '13p')" 'no dependency should remain unresolved'
assert_equal true "$(json_value "$TMP/good/summary.json" 'str(d["exact_package_hashes_verified"]).lower()')" 'exact package hashes should be verified'
assert_equal true "$(json_value "$TMP/good/summary.json" 'str(d["required_elf_identity_verified"]).lower()')" 'the reviewed ELF identity should be verified'
assert_equal true "$(json_value "$TMP/good/summary.json" 'str(d["readelf_only_payload_inspection"]).lower()')" 'payload inspection should remain readelf-only'
assert_equal false "$(json_value "$TMP/good/summary.json" 'str(d["payload_objects_executed"]).lower()')" 'ELF payload must remain unexecuted'
assert_equal false "$(json_value "$TMP/good/summary.json" 'str(d["dynamic_loader_tracing_executed"]).lower()')" 'dynamic-loader tracing must remain unexecuted'
assert_equal current-userspace-apply-review-preflight "$(json_value "$TMP/good/summary.json" 'd["next_stage"]')" 'a clean result should route only to userspace apply review'
assert_contains $'fixture-1.0-x86_64-1.txz\tusr/bin/app' "$TMP/good/inventory.tsv" 'the application should be inventoried'
assert_contains $'libhost.so.1\tlibc6,x86-64\t/lib64/libhost.so.1\tavailable' "$TMP/good/host.tsv" 'the compatible host cache entry should be recorded'

for case in wrong-arch unresolved unsafe-interpreter textrel exec-stack wx-load unsafe-runpath needed-slash elf-count; do
    make_fixture "$TMP/$case" "$case"
    REVIEW_POLICY=$TMP/$case/policy.json
    assert_failure "the $case mutation should fail closed" analyze_elf_runtime "$TMP/$case/payload" "$TMP/$case/inventory.tsv" "$TMP/$case/summary.json" "$TMP/$case/host.tsv" "$TMP/$case/work"
done

make_fixture "$TMP/hash-drift"
printf 'drift' >> "$TMP/hash-drift/fixture-1.0-x86_64-1.txz"
REVIEW_POLICY=$TMP/hash-drift/policy.json
assert_failure 'archive drift should fail exact package identity verification' analyze_elf_runtime "$TMP/hash-drift/payload" "$TMP/hash-drift/inventory.tsv" "$TMP/hash-drift/summary.json" "$TMP/hash-drift/host.tsv" "$TMP/hash-drift/work"

TARGET=slackware-current
EXPECTED_ELF_FILE_COUNT=722
EXPECTED_ELF_PACKAGE_COUNT=61
ELF_FILE_COUNT=722
ELF_PACKAGE_COUNT=61
DYNAMIC_OBJECT_COUNT=700
EXECUTABLE_OBJECT_COUNT=2
RELOCATABLE_OBJECT_COUNT=20
OTHER_OBJECT_COUNT=0
INTERPRETER_COUNT=80
NEEDED_EDGE_COUNT=5000
UNIQUE_NEEDED_COUNT=180
TRANSACTION_SONAME_COUNT=90
HOST_RESOLVED_EDGE_COUNT=4800
TRANSACTION_RESOLVED_EDGE_COUNT=200
UNRESOLVED_EDGE_COUNT=0
UNSAFE_RUNTIME_OBJECT_COUNT=0
ELF_RUNTIME_REVIEW_COMPLETE=true
NEXT_STAGE=current-userspace-apply-review-preflight
PASS_COUNT=15
FAILURE_COUNT=0
write_summary "$TMP/summary.txt"
assert_contains 'result=PASS' "$TMP/summary.txt" 'a clean summary should report PASS'
assert_contains 'elf_file_count=722' "$TMP/summary.txt" 'the summary should preserve the exact ELF count'
assert_contains 'unresolved_edge_count=0' "$TMP/summary.txt" 'the summary should expose zero unresolved edges'
assert_contains 'unsafe_runtime_object_count=0' "$TMP/summary.txt" 'the summary should expose zero unsafe objects'
assert_contains 'elf_payload_executed=false' "$TMP/summary.txt" 'the summary should record payload non-execution'
assert_contains 'dynamic_loader_tracing_executed=false' "$TMP/summary.txt" 'the summary should record that ldd-style tracing was not used'
assert_contains 'elf_runtime_review_complete=true' "$TMP/summary.txt" 'the summary should complete the ELF boundary'
assert_contains 'userspace_apply_review_complete=false' "$TMP/summary.txt" 'the summary should preserve incomplete userspace apply review'
assert_contains 'next_stage=current-userspace-apply-review-preflight' "$TMP/summary.txt" 'the summary should route only to userspace apply review'
assert_contains 'apply_ready=false' "$TMP/summary.txt" 'the summary should preserve readiness denial'
assert_contains 'apply_authorized=false' "$TMP/summary.txt" 'the summary should preserve authorization denial'

assert_success 'the ELF runtime preflight should have valid Bash syntax' bash -n "$SCRIPT"
assert_success 'the ELF runtime preflight should be executable' test -x "$SCRIPT"
assert_not_matches '^[[:space:]]*(upgradepkg|installpkg|removepkg|slackpkg[[:space:]].*(install|upgrade|remove))([[:space:]]|$)' "$SCRIPT" 'the preflight must not change installed packages'
assert_not_matches '^[[:space:]]*(ldd|sotruss|strace)[[:space:]]' "$SCRIPT" 'the preflight must not execute dynamic-loader tracing'
assert_not_matches '^[[:space:]]*(systemctl|service|rc-service|start-stop-daemon)[[:space:]]' "$SCRIPT" 'the preflight must not control services'
assert_not_matches '^[[:space:]]*(mkinitrd|geninitrd|dkms|grub-mkconfig|update-grub)([[:space:]]|$)' "$SCRIPT" 'the preflight must not change boot state'
assert_contains "['readelf','-W',*args,'--',str(path)]" "$SCRIPT" 'readelf should receive payload paths only after --'
assert_contains 'payload_objects_executed' "$SCRIPT" 'the preflight should publish payload non-execution explicitly'
assert_contains 'dynamic_loader_tracing_executed' "$SCRIPT" 'the preflight should publish dynamic-loader tracing denial explicitly'
assert_contains 'elf_runtime_review_complete=$ELF_RUNTIME_REVIEW_COMPLETE' "$SCRIPT" 'the preflight should publish the ELF review state'
assert_contains 'userspace_apply_review_complete=false' "$SCRIPT" 'the preflight should preserve the next review boundary'
assert_contains 'apply_ready=false' "$SCRIPT" 'the preflight should preserve readiness denial'
assert_contains 'apply_authorized=false' "$SCRIPT" 'the preflight should preserve authorization denial'

printf 'Slackware-current ELF runtime review harness: %s checks, %s failures\n' "$HARNESS_TEST_COUNT" "$HARNESS_FAILURE_COUNT"
[ "$HARNESS_FAILURE_COUNT" -eq 0 ]
