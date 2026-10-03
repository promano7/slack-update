"""Private control engine candidate; no operational backend or reference execution.

PrivateBackend is explicitly injected, sealed, file-only and never loaded from
fixture code. Its nested reference protocol is an emulator, not equivalence
proof for the immutable reference. Host command/namespace/child/lock bindings
remain unresolved. Real source identity anchors are historical oracle inputs;
private archive identities are separately verified synthetic fixtures.
"""
from pathlib import Path
import atexit
import ast
import configparser
import hashlib
import io
import json
import os
import re
import signal
import stat
import sys
import tarfile

SCOPE = "private-synthetic-control-engine-only"
REFERENCE_SHA = "1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415"
CONFIG_SHA = "4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba"
FUNCTIONS = ['verify_immediate_preflight', 'arm_cleanup_traps', 'create_owned_workspace', 'capture_and_verify_baseline', 'stage_exact_predecessor', 'configure_local_isolation', 'refresh_and_validate_pkglist', 'bind_exact_candidate', 'run_guarded_reference', 'restore_baseline', 'verify_restoration', 'finalize_stage_evidence', 'publish_evidence_and_receipt']
STAGES = ['immediate-preflight', 'arm-idempotent-traps', 'initialize-owned-workspace', 'capture-verify-backups', 'stage-exact-predecessor', 'isolate-local-configuration', 'refresh-new-pkglist', 'bind-exact-candidate', 'reference-apply', 'restore-production-baseline', 'verify-restoration-invariants', 'capture-complete-evidence', 'publish-reviewed-result']
ROLES = {'adapters': 'adapters', 'backup': 'backup', 'binding': 'evidence/candidate-binding.json', 'cleanup': 'evidence/cleanup', 'derived_config': 'payload/derived.conf', 'lock': 'slack-update.lock', 'log': 'log', 'reference': 'payload/slack-update-reference.sh', 'slackpkg_temp': 'slackpkg-cache', 'slackpkg_work': 'slackpkg-workdir', 'source_config': 'payload/source.conf', 'stages': 'evidence/stages', 'work': 'work'}
ALLOWED_ARGV = [['-batch=on', '-default_answer=y', 'update'], ['-batch=on', '-default_answer=y', '-postinst=off', 'install-new'], ['-batch=on', '-default_answer=y', '-postinst=off', 'upgrade-all']]
TARGET_NAME = 'kernel-headers-6.18.45-x86-1'
PREDECESSOR_NAME = 'kernel-headers-6.18.44-x86-1'
ROW = 'slackware64 kernel-headers 6.18.45 x86 1 kernel-headers-6.18.45-x86-1 ./slackware64/d txz\n'
ORACLE_PATH = 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-review.sh'
ORACLE_SHA = '746bfa5cbfb762ff8a95bbd0bc1e64dbc61165cf32f501dadd45390f66fba68d'
CONTRACT_PATH = 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-transaction-contract-review-contract.json'
CONTRACT_SHA = 'f341e76a83148ec8ee3a438cf8a82f469490bd8b9aed82afda97c9cddc12f291'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def encoded(value):
    return (json.dumps(value, sort_keys=True, indent=2) + "\n").encode()


class Rejected(Exception):
    def __init__(self, message, status=73):
        super().__init__(message)
        self.status = status


def safe(path, root, directory=False):
    if path.absolute() != path.resolve() or not path.is_relative_to(root):
        raise Rejected("unsafe private path")
    info = path.lstat()
    if not (stat.S_ISDIR if directory else stat.S_ISREG)(info.st_mode) or info.st_uid != os.getuid():
        raise Rejected("private object kind or owner")
    if not directory and info.st_nlink != 1:
        raise Rejected("hardlinked private file")
    return info


def inventory(root):
    safe(root, root, True)
    result = {}
    for p in sorted(root.rglob("*")):
        info = safe(p, root, p.is_dir())
        result[p.relative_to(root).as_posix()] = dict(kind="directory" if p.is_dir() else "file",
            sha256=None if p.is_dir() else sha(p.read_bytes()), mode=stat.S_IMODE(info.st_mode),
            uid=info.st_uid, gid=info.st_gid)
    return result


def exclusive(path, data, mode=0o600):
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, mode)
    os.fchmod(fd, mode)
    with os.fdopen(fd, "wb") as handle:
        handle.write(data)
        handle.flush()
        os.fsync(handle.fileno())


def derive_config(raw, roles):
    parser = configparser.ConfigParser(interpolation=None, strict=True)
    parser.read_string(raw.decode())
    required = [("core", k) for k in ["work_dir", "log_dir", "lock_file"]]
    required += [(m, "mode") for m in ["flatpak", "sbo", "elf", "cinnamon"]]
    if any(k not in parser[s] for s, k in required):
        raise Rejected("missing unique derived config key")
    if any(parser["slackware"][k] != "true" for k in ["install_new", "upgrade_all"]):
        raise Rejected("Slackware operations changed")
    for k, role in [("work_dir", "work"), ("log_dir", "log"), ("lock_file", "lock")]:
        parser["core"][k] = str(roles[role])
    for m in ["flatpak", "sbo", "elf", "cinnamon"]:
        parser[m]["mode"] = "disabled"
    out = io.StringIO()
    parser.write(out)
    return out.getvalue().encode()


class PrivateBackend:
    """Explicit file-only injection: no PATH lookup or host subprocess."""
    def __init__(self, root, options):
        self.root, self.options, self.calls = root, options, []

    def package(self, predecessor):
        db = self.root / "machine/packages"
        old, new = (TARGET_NAME, PREDECESSOR_NAME) if predecessor else (PREDECESSOR_NAME, TARGET_NAME)
        if not (db / old).is_file():
            raise Rejected("exact expected package predecessor absent")
        (db / old).unlink()
        exclusive(db / new, (new + "\n").encode(), 0o644)
        (self.root / "machine/headers/version.h").write_bytes(
            b"private-6.18.44\n" if predecessor else b"private-6.18.45\n")
        self.calls.append("predecessor" if predecessor else "target-upgrade")

    def slackpkg(self, argv, pkglist, nested=False):
        self.calls.append(list(argv))
        mode = self.options["nested"] if nested else self.options["refresh"]
        stdout, stderr, status = "private backend " + argv[-1] + "\n", "", 0
        if argv[-1] == "update":
            data = ROW.encode()
            if mode == "drift":
                data += b"\n"
            elif mode == "empty":
                data = b""
            elif mode == "extra":
                data += b"extra unrelated 1 x86 1 unrelated-1-x86-1 ./extra txz\n"
            pkglist.write_bytes(data)
            if mode == "stderr-error":
                stderr = "eRrOr DoWnLoAdInG FrOm private-source\n"
            elif mode == "stdout-error":
                stdout += "Error downloading from private-source\n"
            elif mode == "exit":
                status = 27
        elif argv[-1] == "upgrade-all":
            self.package(False)
        return stdout, stderr, status


class Transaction:
    def __init__(self, root, repository):
        self.root, self.repository = Path(root).absolute(), Path(repository).absolute()
        self.workspace = self.root / "transaction"
        self.roles = {k: self.workspace / v for k, v in ROLES.items()}
        self.pkglist = self.roles["slackpkg_work"] / "pkglist"
        self.options = self.backend = self.binding = None
        self.traps_armed = self.owned_root_created = self.backup_ready = self.mutated = self.restored = False
        self.cleanup_state = "unarmed"
        self.cleanup_exit = self.original_exit = self.original_signal = None
        self.pending_machine = self.pending_controller = False
        self.records, self.nested, self.events = [], [], []
        self.handlers, self.children = {}, {}

    def trip(self, position):
        if self.options and self.options["fault"] == position:
            raise Rejected("injected " + position, 41)

    def verify_inputs(self):
        safe(self.root / "boot-id", self.root)
        if (self.root / "boot-id").read_text() != self.boot_id:
            raise Rejected("private boot binding drift")
        for name in ["source", "history", "artifacts"]:
            if inventory(self.root / name) != self.inputs[name]:
                raise Rejected("private preserved input drift: " + name)

    def verify_immediate_preflight(self):
        r = self.root
        if not r.name.startswith("slack-update-v4-private-") or stat.S_IMODE(safe(r, r, True).st_mode) != 0o700:
            raise Rejected("explicit private fixture root0700 required")
        for name in ["fixture.json", "boot-id"]:
            safe(r / name, r)
        raw = (r / "fixture.json").read_bytes()
        if len(raw) > 65536:
            raise Rejected("bounded private fixture")
        f = json.loads(raw)
        if set(f) != {"schema", "scope", "token", "baseline", "inputs", "boot_id", "options"} or type(f["schema"]) is not int or f["schema"] != 1 or f["scope"] != SCOPE:
            raise Rejected("private fixture schema")
        if not re.fullmatch("[a-z0-9]{32}", f["token"]):
            raise Rejected("fresh private attempt token")
        self.token, self.options = f["token"], f["options"]
        if set(self.options) != {"fault", "refresh", "nested", "cleanup_failure", "publication_failure"}:
            raise Rejected("private injection fields")
        fault = self.options["fault"]
        if fault is not None and not re.fullmatch("(entry|mid):([0-9]|1[0-2])", fault):
            raise Rejected("unknown injected fault")
        modes = {"ok", "empty", "extra", "drift", "stderr-error", "stdout-error", "exit"}
        if self.options["refresh"] not in modes or self.options["nested"] not in modes or type(self.options["cleanup_failure"]) is not bool or self.options["publication_failure"] not in {None, "sidecar", "receipt"}:
            raise Rejected("typed private backend options")
        self.boot_id, self.inputs, self.baseline = f["boot_id"], f["inputs"], f["baseline"]
        if self.boot_id != "private-boot-" + self.token or set(self.inputs) != {"source", "history", "artifacts"}:
            raise Rejected("explicit synthetic boot/input labels required")
        self.verify_inputs()
        required = {"headers/version.h", "packages/" + TARGET_NAME, "packages/unrelated-1-x86-1",
                    "slackpkg.conf", "mirrors", "slackpkg-state/stable", "boot/kernel"}
        if inventory(r / "machine") != self.baseline or not required.issubset(self.baseline):
            raise Rejected("fresh complete private baseline mismatch")
        for name, digest in [("tools/reference/slack-update-reference.sh", REFERENCE_SHA),
                             ("data/config/slack-update.conf", CONFIG_SHA),
                             (ORACLE_PATH, ORACLE_SHA), (CONTRACT_PATH, CONTRACT_SHA)]:
            p = self.repository / name
            safe(p, self.repository)
            if sha(p.read_bytes()) != digest:
                raise Rejected("immutable repository input drift")
        for name in ["transaction", "published.tar.gz", "published.tar.gz.sha256", "published.publication.json"]:
            p = r / name
            if p.exists() or p.is_symlink():
                raise Rejected("private attempt destination occupied")
        self.backend = PrivateBackend(r, self.options)
        self.trip("entry:0")
        self.events.append("preflight-read-only")

    def arm_cleanup_traps(self):
        for number in [signal.SIGHUP, signal.SIGINT, signal.SIGTERM]:
            self.handlers[number] = signal.getsignal(number)
            signal.signal(number, self.on_signal)
        atexit.register(self.on_exit)
        self.traps_armed, self.cleanup_state = True, "armed"
        self.events.append("traps-armed-before-filesystem-write")

    def on_signal(self, number, frame):
        if self.original_signal is None:
            self.original_signal = signal.Signals(number).name
        if self.cleanup_state == "running":
            self.pending_machine = True
            return
        raise Rejected("caught " + self.original_signal, 128 + number)

    def on_exit(self):
        if self.traps_armed and self.cleanup_state not in {"completed", "failed"}:
            if self.original_exit is None:
                self.original_exit = 73
            self.cleanup()

    def create_owned_workspace(self):
        if not self.traps_armed:
            raise Rejected("traps required before first write")
        self.workspace.mkdir(mode=0o700)
        self.owned_root_created = True
        self.events.append("first-filesystem-write")
        for rel in ["backup", "evidence", "evidence/stages", "evidence/cleanup", "payload", "adapters",
                    "slackpkg-workdir", "slackpkg-cache", "work", "log"]:
            (self.workspace / rel).mkdir(mode=0o700)
        for dest, source in [("reference", "tools/reference/slack-update-reference.sh"), ("source_config", "data/config/slack-update.conf")]:
            exclusive(self.roles[dest], (self.repository / source).read_bytes())
        self.flush_records()

    def capture_and_verify_baseline(self):
        self.verify_inputs()
        for rel, item in self.baseline.items():
            p = self.roles["backup"] / rel
            if item["kind"] == "directory":
                p.mkdir(mode=item["mode"])
                p.chmod(item["mode"])
            else:
                exclusive(p, (self.root / "machine" / rel).read_bytes(), item["mode"])
        if inventory(self.roles["backup"]) != self.baseline:
            raise Rejected("backup bytes/metadata mismatch")
        self.backup_ready = True
        self.events.append("verified-backups-before-mutation")

    def mutation_guard(self):
        if not self.backup_ready or not self.traps_armed:
            raise Rejected("verified backups and traps required")
        self.verify_inputs()
        self.mutated = True

    def stage_exact_predecessor(self):
        self.mutation_guard()
        self.backend.package(True)

    def configure_local_isolation(self):
        self.mutation_guard()
        raw = self.roles["source_config"].read_bytes()
        if sha(raw) != CONFIG_SHA:
            raise Rejected("source config drift")
        exclusive(self.roles["derived_config"], derive_config(raw, self.roles))
        (self.root / "machine/slackpkg.conf").write_bytes(
            ("CHECKGPG=off\nWORKDIR=" + str(self.roles["slackpkg_work"]) + "\nTEMP=" + str(self.roles["slackpkg_temp"]) + "\n").encode())
        # Private fixture URI, explicitly not a live v4 mirror observation.
        (self.root / "machine/mirrors").write_bytes(((self.root / "source").as_uri() + "/\n").encode())

    def validate_refresh(self, streams):
        stdout, stderr, status = streams
        if status != 0 or re.search("Error downloading from ", stdout + stderr, re.I):
            raise Rejected("refresh exit or both-stream error guard", status or 73)
        safe(self.pkglist, self.workspace)
        if not self.pkglist.read_bytes().strip():
            raise Rejected("empty new pkglist")

    def refresh_and_validate_pkglist(self):
        self.verify_inputs()
        if self.pkglist.exists() or self.pkglist.is_symlink():
            raise Rejected("pkglist must be absent before initial refresh")
        streams = self.backend.slackpkg(ALLOWED_ARGV[0], self.pkglist)
        self.nested.append(dict(kind="initial-refresh", argv=ALLOWED_ARGV[0], stdout=streams[0],
                                stderr=streams[1], exit=streams[2], admission="postcheck-pending"))
        self.validate_refresh(streams)
        self.nested[-1]["admission"] = "accepted"

    def candidate_gate(self, digest):
        safe(self.pkglist, self.workspace)
        data = self.pkglist.read_bytes()
        if sha(data) != digest:
            raise Rejected("bound pkglist bytes changed")
        oracle = self.repository / ORACLE_PATH
        contract = self.repository / CONTRACT_PATH
        safe(oracle, self.repository)
        safe(contract, self.repository)
        oracle_raw, contract_raw = oracle.read_bytes(), contract.read_bytes()
        if sha(oracle_raw) != ORACLE_SHA or sha(contract_raw) != CONTRACT_SHA:
            raise Rejected("immutable oracle/contract use-time drift")
        text = oracle_raw.decode()
        start = text.index("def validate_runtime_boundary_fixture")
        tree = ast.parse(text[start:text.index("\nroot=", start)])
        nodes = [n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == "validate_runtime_boundary_fixture"]
        if len(nodes) != 1:
            raise Rejected("accepted pure oracle absent")
        scope = {"re": re, "hashlib": hashlib}
        exec(compile(ast.fix_missing_locations(ast.Module(body=nodes, type_ignores=[])), "<accepted-candidate-oracle>", "exec"), scope)
        boundary = json.loads(contract_raw)["frozen_source_candidate_executor"]
        source = boundary["source"]
        fixture = dict(source_manifest_sha256=source["manifest_sha256"], source_target_sha256=source["target_sha256"],
            source_checksum_format=source["checksum_representation"], source_preserved=True, fresh_transaction=True,
            pre_refresh_pkglist_absent=True, post_refresh_pkglist_regular=True, post_refresh_pkglist_non_symlink=True,
            refresh_exit=0, same_transaction_binding=True, all_unexpected_candidate_counts_zero=True,
            refresh_stdout="", refresh_stderr="", pkglist_text=data.decode(), bound_pkglist_sha256=digest)
        scope["validate_runtime_boundary_fixture"](fixture, boundary)

    def bind_exact_candidate(self):
        self.verify_inputs()
        digest = sha(self.pkglist.read_bytes())
        self.candidate_gate(digest)
        self.binding = dict(scope=SCOPE, token=self.token, boot=self.boot_id, pkglist_sha256=digest,
                            private_inputs=self.inputs, operational_source_observed=False)
        exclusive(self.roles["binding"], encoded(self.binding))

    def guarded_slackpkg(self, argv):
        if argv not in ALLOWED_ARGV or self.binding is None:
            raise Rejected("unknown argv or missing binding")
        self.verify_inputs()
        self.candidate_gate(self.binding["pkglist_sha256"])
        db = self.root / "machine/packages"
        if not (db / PREDECESSOR_NAME).is_file() or (db / TARGET_NAME).exists():
            raise Rejected("exact private predecessor required")
        streams = self.backend.slackpkg(argv, self.pkglist, nested=True)
        record = dict(kind="nested-reference-protocol-emulator", argv=argv, stdout=streams[0], stderr=streams[1],
                      exit=streams[2], admission="postcheck-pending")
        self.nested.append(record)
        if argv == ALLOWED_ARGV[0]:
            self.validate_refresh(streams)
            self.candidate_gate(self.binding["pkglist_sha256"])
        elif streams[2]:
            raise Rejected("nested backend exit", streams[2])
        record["admission"] = "accepted"

    def run_guarded_reference(self):
        # Explicit emulator injection: immutable reference copy verified, not run.
        if sha(self.roles["reference"].read_bytes()) != REFERENCE_SHA:
            raise Rejected("reference copy changed")
        for argv in ALLOWED_ARGV:
            self.guarded_slackpkg(argv)
        self.events.append("private-reference-protocol-emulator-complete")

    def cleanup(self):
        if self.cleanup_state in {"completed", "running", "failed"}:
            return
        self.cleanup_state = "running"
        try:
            if self.children:
                raise Rejected("unresolved child quiescence")
            self.verify_inputs()
            if self.mutated:
                if not self.backup_ready or inventory(self.roles["backup"]) != self.baseline:
                    raise Rejected("unverified backup restoration forbidden")
                if self.options["cleanup_failure"]:
                    raise Rejected("injected cleanup failure", 52)
                machine = self.root / "machine"
                predecessor = machine / "packages" / PREDECESSOR_NAME
                if predecessor.exists():
                    safe(predecessor, machine)
                    predecessor.unlink()
                for rel, item in self.baseline.items():
                    if item["kind"] == "file":
                        p = machine / rel
                        if p.exists():
                            safe(p, machine)
                        else:
                            if p.resolve() != p.absolute() or p.parent.resolve() != p.parent:
                                raise Rejected("unsafe restore ancestor")
                            exclusive(p, b"", item["mode"])
                        p.write_bytes((self.roles["backup"] / rel).read_bytes())
                        p.chmod(item["mode"])
                if inventory(machine) != self.baseline:
                    raise Rejected("restoration invariant mismatch")
            self.verify_inputs()
            self.restored = inventory(self.root / "machine") == self.baseline
            if not self.restored:
                raise Rejected("private baseline not restored")
            self.cleanup_exit, self.cleanup_state = 0, "completed"
        except Exception as error:
            self.cleanup_exit, self.cleanup_state = getattr(error, "status", 73), "failed"
            self.pending_machine = self.mutated or bool(self.children)
            self.events.append("cleanup-error:" + str(error))
        if self.owned_root_created and self.roles["cleanup"].is_dir():
            p = self.roles["cleanup"] / "result.json"
            if not p.exists():
                exclusive(p, encoded(dict(state=self.cleanup_state, exit=self.cleanup_exit,
                                         original_exit=self.original_exit, signal=self.original_signal)))

    def restore_baseline(self):
        self.cleanup()
        if self.cleanup_state != "completed":
            raise Rejected("private restoration failed", self.cleanup_exit or 73)

    def verify_restoration(self):
        self.verify_inputs()
        if inventory(self.root / "machine") != self.baseline or not self.restored:
            raise Rejected("private invariant verification failed")
        self.events.append("all-private-restoration-invariants-verified")

    def flush_records(self):
        if not self.owned_root_created or not self.roles["stages"].is_dir():
            return
        for record in self.records:
            if record["index"] == 12:
                continue  # Last-stage completion lives only in external receipt.
            prefix = self.roles["stages"] / ("%02d-" % record["index"] + record["stage"])
            for suffix, data in [(".json", encoded(record)), (".stdout", record["stdout"].encode()), (".stderr", record["stderr"].encode())]:
                p = prefix.with_name(prefix.name + suffix)
                if not p.exists():
                    exclusive(p, data)

    def finalize_stage_evidence(self):
        self.flush_records()
        if len(self.records) != 11 or any(r["exit"] != 0 for r in self.records):
            raise Rejected("earlier stage evidence incomplete")
        exclusive(self.workspace / "evidence/nested.json", encoded(self.nested))
        exclusive(self.workspace / "evidence/publication-preparation.json",
                  encoded(dict(scope=SCOPE, restored=self.restored, final_stage_external_receipt=True, atomic_pair_claim=False)))

    def publish_evidence_and_receipt(self):
        self.flush_records()
        if not self.restored or self.cleanup_exit != 0 or self.pending_machine or self.original_exit is not None:
            raise Rejected("private success eligibility failed")
        self.pending_controller = True
        archive = self.root / "published.tar.gz"
        fd = os.open(archive, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
        with os.fdopen(fd, "wb") as handle:
            with tarfile.open(fileobj=handle, mode="w:gz") as tar:
                for p in sorted((self.workspace / "evidence").rglob("*")):
                    if p.is_file():
                        safe(p, self.workspace)
                        tar.add(p, arcname=p.relative_to(self.workspace).as_posix(), recursive=False)
        if self.options["publication_failure"] == "sidecar":
            raise Rejected("injected partial sidecar publication", 61)
        exclusive(self.root / "published.tar.gz.sha256", (sha(archive.read_bytes()) + "  " + archive.name + "\n").encode())
        if self.options["publication_failure"] == "receipt":
            raise Rejected("injected missing completion receipt", 62)
        self.trip("mid:12")
        receipt_data = encoded(dict(scope=SCOPE, result="PASS", operational_success=False,
            archive_sha256=sha(archive.read_bytes()), final_stage=dict(index=12, stdout="private publish-reviewed-result complete\n", stderr="", exit=0),
            restored=True, cleanup_exit=0, original_exit=0, pending_machine=False, pending_controller=False,
            receipt_committed_last=True, atomic_pair_claim=False, reference_payload_executed=False))
        receipt = self.root / "published.publication.json"
        fd = os.open(receipt, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
        identity = os.fstat(fd).st_ino
        try:
            with os.fdopen(fd, "wb") as handle:
                handle.write(receipt_data)
                handle.flush()
                os.fsync(handle.fileno())
        except BaseException:
            # Only our newly created incomplete receipt; never another inode.
            if receipt.exists() and receipt.lstat().st_ino == identity:
                receipt.unlink()
            raise
        self.pending_controller = False

    def outcome(self):
        return dict(scope=SCOPE, exit=self.original_exit, signal=self.original_signal, cleanup_state=self.cleanup_state,
            cleanup_exit=self.cleanup_exit, restored=self.restored, pending_machine=self.pending_machine,
            pending_controller=self.pending_controller, records=self.records, nested=self.nested, events=self.events,
            backend_calls=[] if self.backend is None else self.backend.calls, production_entry_closed=True,
            reference_payload_executed=False, operational_success=False)

    def run(self):
        try:
            for index, name in enumerate(FUNCTIONS):
                record = dict(index=index, stage=STAGES[index], stdout="", stderr="", exit=None, signal=None)
                try:
                    self.trip("entry:" + str(index))
                    getattr(self, name)()
                    if index != 12:
                        self.trip("mid:" + str(index))
                    record["stdout"], record["exit"] = "private " + STAGES[index] + " complete\n", 0
                except Exception as error:
                    record["exit"], record["stderr"] = getattr(error, "status", 73), str(error) + "\n"
                    record["signal"] = self.original_signal
                    raise
                finally:
                    self.records.append(record)
                    self.flush_records()
            self.original_exit = 0
        except Exception as error:
            if self.original_exit is None:
                self.original_exit = getattr(error, "status", 73)
            if self.traps_armed:
                self.cleanup()
            self.pending_machine = self.pending_machine or (self.mutated and not self.restored)
        finally:
            for number, handler in self.handlers.items():
                signal.signal(number, handler)
            atexit.unregister(self.on_exit)
        return self.outcome()


def main(args):
    if len(args) != 1:
        print("ERROR: explicit private root required", file=sys.stderr)
        return 2
    tx = Transaction(args[0], Path(__file__).resolve().parents[2])
    result = tx.run()
    print(json.dumps(result, sort_keys=True))
    return result["exit"]


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
