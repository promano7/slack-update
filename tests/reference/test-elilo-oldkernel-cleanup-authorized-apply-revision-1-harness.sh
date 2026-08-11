#!/bin/bash
set -uo pipefail
IFS=$'\n\t'
LC_ALL=C
export LC_ALL

REPO=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
SCRIPT=$REPO/tests/acceptance/reference/test-elilo-oldkernel-cleanup-authorized-apply.sh
POLICY=$REPO/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-authorized-apply-policy.json
AUTH=$REPO/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-authorization-review-20260811-accepted.json
PLAN=$REPO/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-source-and-plan-preflight-20260811-accepted.json
REVISION=$REPO/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-authorized-apply-revision-review-20260811-accepted.json
COUNT=0
FAILS=0

ok(){ COUNT=$((COUNT+1)); "$@" || { printf 'FAIL: %s\n' "$*" >&2; FAILS=$((FAILS+1)); }; }

ok bash -n "$SCRIPT"
ok python3 - "$POLICY" <<'PY'
import json,sys
p=json.load(open(sys.argv[1]))
raise SystemExit(0 if p.get('schema')==2 and p.get('scenario')=='elilo-oldkernel-cleanup-authorized-apply-revision-1' and p.get('reviewed') is True else 1)
PY
ok python3 - "$REVISION" <<'PY'
import json,sys
r=json.load(open(sys.argv[1]))
raise SystemExit(0 if r.get('status')=='accepted-apply-revision-review' and r.get('retry_authorized') is True and r.get('apply_authorized') is True and r.get('apply_executed') is False else 1)
PY
ok python3 - "$REVISION" <<'PY'
import json,sys
r=json.load(open(sys.argv[1]))
raise SystemExit(0 if r.get('archive_sha256')=='4ed50105ad880742638c91426cdc3d9e9a8dcd04425f5fe74709e9ae708024e7' else 1)
PY
ok python3 - "$SCRIPT" "$POLICY" <<'PY'
import hashlib,json,sys
h=hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest(); p=json.load(open(sys.argv[2]))
raise SystemExit(0 if p.get('expected_script_sha256')==h=='680bf2e4b18f3ff9a3939c4fa947a689347ed15c4f25df343241f62fe55a21de' else 1)
PY
ok python3 - "$REVISION" "$POLICY" <<'PY'
import hashlib,json,sys
h=hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest(); p=json.load(open(sys.argv[2]))
raise SystemExit(0 if p.get('accepted_revision_record_sha256')==h else 1)
PY
ok python3 - "$AUTH" "$POLICY" <<'PY'
import hashlib,json,sys
h=hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest(); p=json.load(open(sys.argv[2]))
raise SystemExit(0 if p.get('accepted_authorization_record_sha256')==h else 1)
PY
ok python3 - "$PLAN" "$POLICY" <<'PY'
import hashlib,json,sys
h=hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest(); p=json.load(open(sys.argv[2]))
raise SystemExit(0 if p.get('accepted_source_plan_record_sha256')==h else 1)
PY
ok python3 - "$REVISION" <<'PY'
import json,sys
r=json.load(open(sys.argv[1]))
raise SystemExit(0 if r.get('base_apply_contract_sha256')=='e5b587aacb911a05428706a09c3d7a85dc35a9802e46ccf8131cb3569dd6806f' and r.get('revision_contract_sha256')=='5054c7126abf2b9d2694640318934d25fc41d60d5830802ac9f10af29fb15aea' else 1)
PY
ok python3 - "$POLICY" "$SCRIPT" "$AUTH" "$REVISION" <<'PY'
import hashlib,json,sys
pol,script,auth,revision=sys.argv[1:]
def sh(p): return hashlib.sha256(open(p,'rb').read()).hexdigest()
p=json.load(open(pol)); r=json.load(open(revision))
scope=(
'operation=elilo-oldkernel-cleanup-authorized-apply-revision-1\n'
+'target=slackware-15.0\n'
+'hostname_fqdn=vbox-slack15.vbox-slack15.org\n'
+'authorization_evidence_sha256=9ed0b6f4c989e4ea5d1742fc47d2ae5c31979e64fc3dffcc1aa7e5ed15934553\n'
+'revision_evidence_sha256=4ed50105ad880742638c91426cdc3d9e9a8dcd04425f5fe74709e9ae708024e7\n'
+'active_kernel=5.15.209\n'
+'rollback_kernel=5.15.19\n'
+'apply_contract_sha256=e5b587aacb911a05428706a09c3d7a85dc35a9802e46ccf8131cb3569dd6806f\n'
+f'accepted_authorization_record_sha256={sh(auth)}\n'
+f'accepted_revision_record_sha256={sh(revision)}\n'
+f'authorized_apply_script_sha256={sh(script)}\n').encode()
raise SystemExit(0 if p.get('confirmation_scope_sha256')==hashlib.sha256(scope).hexdigest() else 1)
PY
ok grep -Fq -- '--confirm-revision-evidence-sha256' "$SCRIPT"
ok grep -Fq -- 'verify_generated_depmod_indexes' "$SCRIPT"
ok grep -Fq -- 'module_stable_manifest' "$SCRIPT"
ok grep -Fq -- 'module_object_manifest' "$SCRIPT"

printf 'ELILO oldkernel cleanup revision-1 production-boundary harness: %d checks, %d failures\n' "$COUNT" "$FAILS"
[ "$FAILS" -eq 0 ]
