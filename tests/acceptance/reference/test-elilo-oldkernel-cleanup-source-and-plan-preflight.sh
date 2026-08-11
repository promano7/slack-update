#!/bin/bash
set -uo pipefail
IFS=$'\n\t'
umask 077
LC_ALL=C
export LC_ALL
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../../.." && pwd -P)
SELF=$SCRIPT_DIR/test-elilo-oldkernel-cleanup-source-and-plan-preflight.sh
POLICY=${ELILO_CLEANUP_SOURCE_POLICY_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-source-and-plan-policy.json}
ACCEPTED_RETENTION=${ELILO_CLEANUP_ACCEPTED_RETENTION_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-retention-preflight-20260811-accepted.json}
PLANNER=$REPOSITORY_ROOT/tools/reference/kernel-cleanup-plan-reference.sh
DRY_RUNNER=$REPOSITORY_ROOT/tools/reference/kernel-cleanup-dry-run-reference.sh
SIGNING_KEY=$REPOSITORY_ROOT/tests/fixtures/reference/keys/slackware-security.gpg.asc

TARGET=
CONFIRM_HOSTNAME_FQDN=
CONFIRM_RETENTION_EVIDENCE_SHA256=
CONFIRM_ACTIVE_KERNEL=
CONFIRM_ROLLBACK_KERNEL=
CONFIRM_REVIEW_SHA256=
OUTPUT_DIR=
PASS_COUNT=0
FAILURE_COUNT=0
SKIP_COUNT=0
SOURCE_READY=false
PLAN_READY=false
CLEANUP_READY=false
CLEANUP_AUTHORIZED=false
NEXT_STAGE=elilo-oldkernel-cleanup-source-and-plan-manual-review
PACKAGE_DATABASE=
TEST_MODE=${SLACK_UPDATE_TEST_MODE:-0}
ROOT_PREFIX=${SLACK_UPDATE_TEST_ROOT:-}
CACHE_ROOT=${ELILO_CLEANUP_CACHE_ROOT:-${ROOT_PREFIX}/var/cache/packages}
CHECKSUMS_FILE=${ELILO_CLEANUP_CHECKSUMS_FILE:-${ROOT_PREFIX}/var/lib/slackpkg/CHECKSUMS.md5}
CHECKSUMS_SIGNATURE=${ELILO_CLEANUP_CHECKSUMS_SIGNATURE:-${ROOT_PREFIX}/var/lib/slackpkg/CHECKSUMS.md5.asc}

usage() {
cat <<EOF
Usage: ${0##*/} --target slackware-15.0 \\
  --confirm-hostname-fqdn vbox-slack15.vbox-slack15.org \\
  --confirm-retention-evidence-sha256 SHA256 \\
  --confirm-active-kernel 5.15.209 \\
  --confirm-rollback-kernel 5.15.19 \\
  --confirm-cleanup-plan-review-sha256 SHA256 [--output-dir PATH]

Verify the exact locally cached active kernel package archives, authenticate the
Slackpkg checksum metadata, generate the real ELILO oldkernel cleanup plan, and
simulate it. This is a non-mutating preflight: it never refreshes repositories,
installs/removes packages, edits ELILO, deletes files, or authorizes real apply.
EOF
}
err(){ printf 'ERROR: %s\n' "$*" >&2; }
is_sha(){ [ "${#1}" -eq 64 ] && [[ $1 != *[!0-9A-Fa-f]* ]]; }
safe_ver(){ [ -n "$1" ] && [[ $1 != *[!0-9A-Za-z._+-]* ]]; }
regular(){ [ -f "$1" ] && [ ! -L "$1" ] && [ -r "$1" ]; }
sha(){ sha256sum -- "$1" | awk '{print $1}'; }
pass(){ PASS_COUNT=$((PASS_COUNT+1)); printf 'PASS: %s\n' "$1" | tee -a "$OUTPUT_DIR/assertions.log"; }
fail(){ FAILURE_COUNT=$((FAILURE_COUNT+1)); printf 'FAIL: %s\n' "$1" | tee -a "$OUTPUT_DIR/assertions.log" >&2; }
skip(){ SKIP_COUNT=$((SKIP_COUNT+1)); printf 'SKIP: %s\n' "$1" | tee -a "$OUTPUT_DIR/assertions.log"; }

parse_args(){
 while [ "$#" -gt 0 ]; do
  case "$1" in
   --target) [ "$#" -ge 2 ]||return 1; TARGET=$2; shift 2;;
   --confirm-hostname-fqdn) [ "$#" -ge 2 ]||return 1; CONFIRM_HOSTNAME_FQDN=$2; shift 2;;
   --confirm-retention-evidence-sha256) [ "$#" -ge 2 ]||return 1; CONFIRM_RETENTION_EVIDENCE_SHA256=${2,,}; shift 2;;
   --confirm-active-kernel) [ "$#" -ge 2 ]||return 1; CONFIRM_ACTIVE_KERNEL=$2; shift 2;;
   --confirm-rollback-kernel) [ "$#" -ge 2 ]||return 1; CONFIRM_ROLLBACK_KERNEL=$2; shift 2;;
   --confirm-cleanup-plan-review-sha256) [ "$#" -ge 2 ]||return 1; CONFIRM_REVIEW_SHA256=${2,,}; shift 2;;
   --output-dir) [ "$#" -ge 2 ]||return 1; OUTPUT_DIR=$2; shift 2;;
   -h|--help) usage; exit 0;;
   *) err "unknown argument: $1"; return 1;;
  esac
 done
 [ "$TARGET" = slackware-15.0 ] || return 1
 [ -n "$CONFIRM_HOSTNAME_FQDN" ] || return 1
 is_sha "$CONFIRM_RETENTION_EVIDENCE_SHA256" || return 1
 safe_ver "$CONFIRM_ACTIVE_KERNEL" && safe_ver "$CONFIRM_ROLLBACK_KERNEL" || return 1
 [ "$CONFIRM_ACTIVE_KERNEL" != "$CONFIRM_ROLLBACK_KERNEL" ] || return 1
 is_sha "$CONFIRM_REVIEW_SHA256" || return 1
 [ -z "$OUTPUT_DIR" ] || [[ $OUTPUT_DIR = /* ]]
}

json_get(){ python3 - "$1" "$2" <<'PY'
import json,sys
v=json.load(open(sys.argv[1],encoding='utf-8'))
for p in sys.argv[2].split('.'): v=v[p]
if isinstance(v,bool): print(str(v).lower())
elif isinstance(v,(dict,list)): print(json.dumps(v,sort_keys=True,separators=(',',':')))
else: print(v)
PY
}

validate_static(){
 python3 - "$POLICY" "$SELF" "$ACCEPTED_RETENTION" "$PLANNER" "$DRY_RUNNER" "$SIGNING_KEY" \
  "$CONFIRM_HOSTNAME_FQDN" "$CONFIRM_RETENTION_EVIDENCE_SHA256" "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$CONFIRM_REVIEW_SHA256" <<'PY'
import hashlib,json,pathlib,sys
pol,script,accepted,planner,dry,key,host,evidence,active,rollback,confirmed=sys.argv[1:]
def reg(p):
 p=pathlib.Path(p)
 if not p.is_file() or p.is_symlink(): raise SystemExit(1)
 return p
def sh(p): return hashlib.sha256(reg(p).read_bytes()).hexdigest()
p=json.loads(reg(pol).read_text())
a=json.loads(reg(accepted).read_text())
scope=(
"operation=elilo-oldkernel-cleanup-source-and-plan-preflight\n"
"target=slackware-15.0\n"
f"hostname_fqdn={host}\n"
f"retention_evidence_sha256={evidence}\n"
f"active_kernel={active}\n"
f"rollback_kernel={rollback}\n"
f"accepted_retention_record_sha256={sh(accepted)}\n"
f"planner_sha256={sh(planner)}\n"
f"dry_runner_sha256={sh(dry)}\n"
f"signing_key_sha256={sh(key)}\n"
f"preflight_script_sha256={sh(script)}\n").encode()
calc=hashlib.sha256(scope).hexdigest()
checks=[
 p.get("schema")==1,p.get("scenario")=="elilo-oldkernel-cleanup-source-and-plan-policy",
 p.get("reviewed") is True,p.get("target")=="slackware-15.0",
 p.get("expected_script_sha256")==sh(script),p.get("planner_sha256")==sh(planner),
 p.get("dry_runner_sha256")==sh(dry),p.get("signing_key_sha256")==sh(key),
 p.get("accepted_retention_record_sha256")==sh(accepted),
 p.get("confirmation_scope_sha256")==confirmed==calc,
 a.get("status")=="accepted-mature-retention",a.get("cleanup_eligible") is True,
 a.get("cleanup_authorized") is False,a["evidence"]["archive_sha256"]==evidence,
 a["platform"]["hostname"]==host,a["kernel"]["active"]==active,a["kernel"]["rollback"]==rollback,
 p.get("metadata_primary_fingerprint")=="EC5649DA401E22ABFA6736EF6A4463C040102233",
 p.get("cleanup_authorized") is False,p.get("apply_authorized") is False,
]
if not all(checks): raise SystemExit(1)
PY
}

init_output(){
 local stamp base
 if [ -z "$OUTPUT_DIR" ]; then
  stamp=$(date -u +%Y%m%dT%H%M%SZ) || return 1
  base=${ROOT_PREFIX}/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-source-and-plan-preflight
  install -d -m 0700 -- "$base" || return 1
  OUTPUT_DIR=$base/slackware-15.0-$stamp
 fi
 [ ! -e "$OUTPUT_DIR" ] && [ ! -L "$OUTPUT_DIR" ] || return 1
 install -d -m 0700 -- "$OUTPUT_DIR" || return 1
 : > "$OUTPUT_DIR/assertions.log"
}

resolve_pkgdb(){
 local a=${ROOT_PREFIX}/var/lib/pkgtools/packages b=${ROOT_PREFIX}/var/log/packages
 if [ -d "$a" ] && [ ! -L "$a" ]; then PACKAGE_DATABASE=$a
 elif [ -L "$b" ] && [ -d "$b" ]; then PACKAGE_DATABASE=$(readlink -f -- "$b")
 elif [ -d "$b" ] && [ ! -L "$b" ]; then PACKAGE_DATABASE=$b
 else return 1; fi
}

capture_names(){
 find "$PACKAGE_DATABASE" -mindepth 1 -maxdepth 1 -type f -printf '%f\n' | LC_ALL=C sort > "$1"
}
capture_boot(){
 python3 - "$ROOT_PREFIX" "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$1" <<'PY'
import hashlib,pathlib,sys
root=pathlib.Path(sys.argv[1] or "/"); active,old=sys.argv[2:4]; out=pathlib.Path(sys.argv[4])
paths=[
"/boot/efi/EFI/Slackware/elilo.conf",
f"/boot/vmlinuz-generic-{active}",f"/boot/initrd-generic-{active}.gz",
f"/boot/vmlinuz-generic-{old}","/boot/initrd.gz",
f"/boot/efi/EFI/Slackware/vmlinuz-generic-{active}",f"/boot/efi/EFI/Slackware/initrd-generic-{active}.gz",
"/boot/efi/EFI/Slackware/vmlinuz","/boot/efi/EFI/Slackware/initrd.gz"]
rows=[]
for logical in paths:
 p=root/logical.lstrip("/")
 if not p.is_file() or p.is_symlink(): raise SystemExit(1)
 h=hashlib.sha256(p.read_bytes()).hexdigest()
 rows.append(f"{h}  {logical}\n")
out.write_text("".join(rows))
PY
}

runtime_fqdn(){ if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ELILO_CLEANUP_TEST_HOSTNAME_FQDN:-$CONFIRM_HOSTNAME_FQDN}"; else hostname -f; fi; }
runtime_kernel(){ if [ "$TEST_MODE" = 1 ]; then printf '%s\n' "${ELILO_CLEANUP_TEST_RUNNING_KERNEL:-$CONFIRM_ACTIVE_KERNEL}"; else uname -r; fi; }

validate_live_boundary(){
 local ok=true expected_pkg_sha
 [ "$(runtime_fqdn 2>/dev/null)" = "$CONFIRM_HOSTNAME_FQDN" ] || ok=false
 [ "$(runtime_kernel 2>/dev/null)" = "$CONFIRM_ACTIVE_KERNEL" ] || ok=false
 [ -d /sys/firmware/efi ] || [ "$TEST_MODE" = 1 ] || ok=false
 resolve_pkgdb || ok=false
 capture_names "$OUTPUT_DIR/packages.before.txt" || ok=false
 expected_pkg_sha=$(json_get "$ACCEPTED_RETENTION" immutability.package_name_snapshot_sha256) || ok=false
 [ "$(sha "$OUTPUT_DIR/packages.before.txt" 2>/dev/null)" = "$expected_pkg_sha" ] || ok=false
 capture_boot "$OUTPUT_DIR/boot.before.sha256" || ok=false
 for version in "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL"; do
  module_dir=${ROOT_PREFIX}/lib/modules/$version
  [ -d "$module_dir" ] && [ ! -L "$module_dir" ] || ok=false
  [ -n "$(find "$module_dir" -type f -print -quit 2>/dev/null)" ] || ok=false
 done
 python3 - "$ACCEPTED_RETENTION" "$OUTPUT_DIR/boot.before.sha256" <<'PY' || ok=false
import json,sys
a=json.load(open(sys.argv[1]))
seen={}
for line in open(sys.argv[2]):
 h,p=line.strip().split("  ",1); seen[p]=h
e=a["elilo"]
checks={
"/boot/efi/EFI/Slackware/elilo.conf":e["config_sha256"],
f'/boot/vmlinuz-generic-{a["kernel"]["active"]}':e["active_kernel_sha256"],
f'/boot/initrd-generic-{a["kernel"]["active"]}.gz':e["active_initrd_sha256"],
f'/boot/vmlinuz-generic-{a["kernel"]["rollback"]}':e["rollback_kernel_sha256"],
"/boot/initrd.gz":e["rollback_initrd_sha256"],
f'/boot/efi/EFI/Slackware/vmlinuz-generic-{a["kernel"]["active"]}':e["active_kernel_sha256"],
f'/boot/efi/EFI/Slackware/initrd-generic-{a["kernel"]["active"]}.gz':e["active_initrd_sha256"],
"/boot/efi/EFI/Slackware/vmlinuz":e["rollback_kernel_sha256"],
"/boot/efi/EFI/Slackware/initrd.gz":e["rollback_initrd_sha256"]}
if seen!=checks: raise SystemExit(1)
PY
 [ "$ok" = true ]
}

verify_metadata_signature(){
 if [ "$TEST_MODE" = 1 ]; then [ "${ELILO_CLEANUP_TEST_METADATA_SIGNATURE_VALID:-true}" = true ]; return; fi
 regular "$CHECKSUMS_FILE" && regular "$CHECKSUMS_SIGNATURE" && regular "$SIGNING_KEY" || return 1
 local td kr status rc=0 expected
 td=$(mktemp -d /tmp/slack-update-elilo-gpgv.XXXXXX) || return 1
 kr=$td/slackware.gpg; status=$td/status
 gpg --batch --yes --dearmor --output "$kr" "$SIGNING_KEY" >/dev/null 2>&1 || rc=1
 if [ "$rc" -eq 0 ]; then
  gpgv --homedir "$td" --keyring "$kr" --status-fd 1 "$CHECKSUMS_SIGNATURE" "$CHECKSUMS_FILE" >"$status" 2>"$OUTPUT_DIR/gpgv.log" || rc=1
 fi
 expected=$(json_get "$POLICY" metadata_primary_fingerprint) || rc=1
 if [ "$rc" -eq 0 ]; then
  python3 - "$status" "$expected" <<'PY' || rc=1
import re,sys
text=open(sys.argv[1],errors='replace').read(); expected=sys.argv[2]
valid=re.findall(r'^\[GNUPG:\] VALIDSIG ([0-9A-F]+) .*? ([0-9A-F]{40})$',text,re.M)
if not valid: raise SystemExit(1)
signing,primary=valid[-1]
if primary!=expected and signing!=expected: raise SystemExit(1)
PY
 fi
 rm -rf -- "$td"
 [ "$rc" -eq 0 ]
}

locate_and_verify_archives(){
 local record name filename path expected_md5 actual_md5
 : > "$OUTPUT_DIR/active-archives.tsv"
 for name in kernel-generic kernel-huge kernel-modules; do
  record="${name}-${CONFIRM_ACTIVE_KERNEL}-x86_64-1"
  filename="$record.txz"
  mapfile -d '' -t matches < <(find "$CACHE_ROOT" -type f -name "$filename" -print0 2>/dev/null | LC_ALL=C sort -z)
  [ "${#matches[@]}" -eq 1 ] || return 1
  path=${matches[0]}
  [ -f "$path" ] && [ ! -L "$path" ] && [ -r "$path" ] || return 1
  expected_md5=$(python3 - "$CHECKSUMS_FILE" "$filename" <<'PY'
import re,sys,pathlib
p=pathlib.Path(sys.argv[1]); fn=sys.argv[2]; rows=[]
for line in p.read_text(errors='strict').splitlines():
 m=re.fullmatch(r'([0-9a-fA-F]{32})  (\./.+/'+re.escape(fn)+r')',line)
 if m: rows.append((m.group(1).lower(),m.group(2)))
if len(rows)!=1: raise SystemExit(1)
print(rows[0][0])
PY
) || return 1
  actual_md5=$(md5sum -- "$path" | awk '{print $1}') || return 1
  [ "$actual_md5" = "$expected_md5" ] || return 1
  printf '%s\t%s\t%s\t%s\n' "$record" "$path" "$(sha "$path")" "$actual_md5" >> "$OUTPUT_DIR/active-archives.tsv"
 done
}

inspect_archives(){
 python3 - "$OUTPUT_DIR/active-archives.tsv" "$CONFIRM_ACTIVE_KERNEL" "$OUTPUT_DIR/archive-inspection.json" <<'PY'
import json,pathlib,tarfile,sys
rows=[]; version=sys.argv[2]
for raw in pathlib.Path(sys.argv[1]).read_text().splitlines():
 record,path,sha,md5=raw.split("\t")
 with tarfile.open(path,"r:*") as t:
  members=t.getmembers()
  for m in members:
   q=pathlib.PurePosixPath(m.name)
   if q.is_absolute() or ".." in q.parts or m.ischr() or m.isblk() or m.isfifo():
    raise SystemExit(1)
  names={m.name.lstrip("./") for m in members}
 if record.startswith("kernel-generic-"):
  required=f"boot/vmlinuz-generic-{version}"
 elif record.startswith("kernel-huge-"):
  required=f"boot/vmlinuz-huge-{version}"
 else:
  required=f"lib/modules/{version}"
  if not any(n==required or n.startswith(required+"/") for n in names): raise SystemExit(1)
  rows.append({"record":record,"path":path,"sha256":sha,"md5":md5,"members":len(members)})
  continue
 if required not in names: raise SystemExit(1)
 rows.append({"record":record,"path":path,"sha256":sha,"md5":md5,"members":len(members)})
pathlib.Path(sys.argv[3]).write_text(json.dumps(rows,sort_keys=True,indent=2)+"\n")
PY
}

make_inventory_and_plan(){
 python3 - "$ACCEPTED_RETENTION" "$OUTPUT_DIR/active-archives.tsv" "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/cleanup-inventory.json" <<'PY'
import json,pathlib,sys
a=json.load(open(sys.argv[1])); archives=[]
for line in pathlib.Path(sys.argv[2]).read_text().splitlines():
 rec,path,sha,md5=line.split("\t")
 archives.append({"record":rec,"path":path,"sha256":sha,"available":True,"md5":md5})
all_packages=pathlib.Path(sys.argv[3]).read_text().splitlines()
active=set(a["kernel"]["active_package_records"]); rollback=set(a["kernel"]["rollback_package_records"])
other=sorted(x for x in all_packages if x.startswith("kernel-") and x not in active and x not in rollback)
d={"schema":1,"inventory_id":"slackware-15.0-elilo-mature-real-system-20260811",
"fixture_kind":"real-system-mature-preflight","target":"slackware-15.0","hostname":a["platform"]["hostname"],
"firmware":"uefi","boot_loader":"elilo","running_kernel":a["kernel"]["active"],
"active_kernel":a["kernel"]["active"],"rollback_kernel":a["kernel"]["rollback"],
"cleanup_eligible":True,"cleanup_authorized":False,
"package_database":{"configured":a["platform"]["package_database_configured"],"resolved":a["platform"]["package_database_resolved"],"resolved_is_directory":True,"internal_record_symlinks":False},
"packages":{"active":a["kernel"]["active_package_records"],"rollback":a["kernel"]["rollback_package_records"],"other_kernel_packages":other},
"active_archives":[{k:v for k,v in x.items() if k!="md5"} for x in archives],
"module_trees":{"active":True,"rollback":True},
"boot":{"config":a["elilo"]["config"],"active_entry":{"label":"vmlinuz","kernel":a["elilo"]["active_image"],"initrd":a["elilo"]["active_initrd"]},"rollback_entry":{"label":"oldkernel","kernel":"vmlinuz","initrd":"initrd.gz"}}}
pathlib.Path(sys.argv[4]).write_text(json.dumps(d,sort_keys=True,indent=2)+"\n")
PY
 "$PLANNER" --input "$OUTPUT_DIR/cleanup-inventory.json" --output "$OUTPUT_DIR/cleanup-plan.json" || return 1
 python3 - "$OUTPUT_DIR/cleanup-plan.json" <<'PY' || return 1
import json,sys
p=json.load(open(sys.argv[1]))
checks=[p["applicable"] is True,p["cleanup_eligible"] is True,p["cleanup_authorized"] is False,
p["apply_permitted"] is False,p["requires_separate_apply_stage"] is True,
p["blocked_reasons"]==["cleanup-authorization-not-granted"],len(p["active_archives"])==3,
len(p["active_packages"])==3,len(p["rollback_packages"])==3,len(p["actions"])==14]
if not all(checks): raise SystemExit(1)
PY
 python3 - "$OUTPUT_DIR/cleanup-plan.json" "$OUTPUT_DIR/dry-run-authorization.json" <<'PY'
import json,pathlib,sys
p=json.load(open(sys.argv[1]))
a={"schema":1,"scenario":"kernel-cleanup-dry-run-authorization","authorization_id":"elilo-oldkernel-cleanup-source-review",
"scope":"dry-run-only","confirmation":"authorize-kernel-cleanup-dry-run-only","dry_run_authorized":True,"apply_authorized":False,
"plan_sha256":p["plan_sha256"],"target":p["target"],"boot_loader":p["boot_loader"],"active_kernel":p["active_kernel"],"rollback_kernel":p["rollback_kernel"]}
pathlib.Path(sys.argv[2]).write_text(json.dumps(a,sort_keys=True,indent=2)+"\n")
PY
 "$DRY_RUNNER" --dry-run --plan "$OUTPUT_DIR/cleanup-plan.json" --authorization "$OUTPUT_DIR/dry-run-authorization.json" --output "$OUTPUT_DIR/cleanup-dry-run.json" || return 1
 python3 - "$OUTPUT_DIR/cleanup-dry-run.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
if d.get("status")!="simulation-complete" or d.get("simulation_complete") is not True or len(d.get("steps",[]))!=14: raise SystemExit(1)
if d.get("commands_executed")!=[] or d.get("mutations_performed")!=[] or d.get("apply_authorized") is not False: raise SystemExit(1)
PY
}

capture_final(){
 capture_names "$OUTPUT_DIR/packages.after.txt" && capture_boot "$OUTPUT_DIR/boot.after.sha256"
}
write_summary(){
 cat > "$OUTPUT_DIR/summary.txt" <<EOF
scenario=elilo-oldkernel-cleanup-source-and-plan-preflight
target=$TARGET
hostname=$CONFIRM_HOSTNAME_FQDN
active_kernel=$CONFIRM_ACTIVE_KERNEL
rollback_kernel=$CONFIRM_ROLLBACK_KERNEL
retention_evidence_sha256=$CONFIRM_RETENTION_EVIDENCE_SHA256
source_ready=$SOURCE_READY
plan_ready=$PLAN_READY
cleanup_ready=$CLEANUP_READY
cleanup_authorized=false
apply_authorized=false
passes=$PASS_COUNT
failures=$FAILURE_COUNT
skips=$SKIP_COUNT
next_stage=$NEXT_STAGE
EOF
}
publish(){
 local base archive side owner group
 base=${ROOT_PREFIX}/var/tmp/slack-update-acceptance/elilo-oldkernel-cleanup-source-and-plan-preflight
 archive=$base/slackware-15.0-elilo-oldkernel-cleanup-source-and-plan-preflight-$(date -u +%Y%m%dT%H%M%SZ).tar.gz
 side=$archive.sha256
 install -d -m 0700 -- "$base" || return 1
 tar -C "$(dirname -- "$OUTPUT_DIR")" -czf "$archive" "$(basename -- "$OUTPUT_DIR")" || return 1
 chmod 0600 "$archive"
 (cd "$(dirname "$archive")" && sha256sum "$(basename "$archive")") > "$side" || return 1
 chmod 0600 "$side"
 printf 'Evidence archive: %s\n' "$archive"
 printf 'Evidence SHA-256: %s\n' "$(awk '{print $1}' "$side")"
 owner=${SUDO_USER:-promano}; group=$(id -gn "$owner" 2>/dev/null || printf users)
 printf 'Copy evidence command: sudo install -o %q -g %q -m 0600 %q %q && sudo install -o %q -g %q -m 0600 %q %q\n' \
  "$owner" "$group" "$archive" "/home/$owner/${archive##*/}" "$owner" "$group" "$side" "/home/$owner/${side##*/}"
 printf 'Verify copied evidence command: cd %q && sha256sum -c %q\n' "/home/$owner" "${side##*/}"
}

main(){
 parse_args "$@" || { usage >&2; return 2; }
 [ "$(id -u)" -eq 0 ] || { err 'must run as root'; return 2; }
 init_output || return 2
 if validate_static; then pass 'the accepted mature retention evidence, exact code, cleanup tools, signing key, and review scope are bound'
 else fail 'the static cleanup source-and-plan boundary does not match the reviewed contract'; fi
 if validate_live_boundary; then pass 'the live 5.15.209 ELILO state exactly matches the accepted mature retention boundary'
 else fail 'the live package or ELILO state drifted from the accepted mature retention boundary'; fi
 if [ "$FAILURE_COUNT" -eq 0 ] && verify_metadata_signature; then pass 'the cached Slackpkg checksum metadata is authenticated by the reviewed Slackware signing key'
 else
  if [ "$FAILURE_COUNT" -eq 0 ]; then fail 'the Slackpkg checksum metadata could not be authenticated'; else skip 'metadata authentication requires an intact live boundary'; fi
 fi
 if [ "$FAILURE_COUNT" -eq 0 ] && locate_and_verify_archives && inspect_archives; then
  SOURCE_READY=true; pass 'the exact three active 5.15.209 package archives are locally cached, checksum-matched, and structurally safe'
 else
  if [ "$FAILURE_COUNT" -eq 0 ]; then fail 'the exact active 5.15.209 package archives are not safely available in the local verified cache'; else skip 'active archive verification requires authenticated metadata and an intact live boundary'; fi
 fi
 if [ "$FAILURE_COUNT" -eq 0 ] && make_inventory_and_plan; then
  PLAN_READY=true; pass 'the mature real-system ELILO cleanup plan and fourteen-step dry-run simulation are complete without mutation'
 else
  if [ "$FAILURE_COUNT" -eq 0 ]; then fail 'the real-system cleanup plan or dry-run simulation could not be completed'; else skip 'cleanup planning requires the exact verified active archives'; fi
 fi
 if capture_final && [ -f "$OUTPUT_DIR/packages.before.txt" ] && [ -f "$OUTPUT_DIR/boot.before.sha256" ] \
    && cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" \
    && cmp -s "$OUTPUT_DIR/boot.before.sha256" "$OUTPUT_DIR/boot.after.sha256"; then
  pass 'the package database and ELILO boot artifacts remained unchanged throughout source verification and planning'
 else fail 'the package database or ELILO boot artifacts changed during the preflight'; fi
 if [ "$FAILURE_COUNT" -eq 0 ] && [ "$SOURCE_READY" = true ] && [ "$PLAN_READY" = true ]; then
  CLEANUP_READY=true
  NEXT_STAGE=elilo-oldkernel-cleanup-authorization-review
  pass 'the exact cleanup transaction is ready for a separate authorization review while real apply remains denied'
 else
  skip 'cleanup readiness remains unavailable until every source and plan prerequisite passes'
 fi
 write_summary
 publish || return 2
 printf 'Result: %s (%d passes, %d failures, %d skips); source_ready=%s; plan_ready=%s; cleanup_ready=%s; cleanup_authorized=false; apply_authorized=false; next_stage=%s\n' \
  "$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAILURE_COUNT" "$SKIP_COUNT" "$SOURCE_READY" "$PLAN_READY" "$CLEANUP_READY" "$NEXT_STAGE"
 [ "$FAILURE_COUNT" -eq 0 ]
}
main "$@"
