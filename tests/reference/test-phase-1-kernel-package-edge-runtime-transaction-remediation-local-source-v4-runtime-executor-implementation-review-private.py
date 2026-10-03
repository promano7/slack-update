"""Executed private filesystem tests; never invokes a host package/boot command."""
from pathlib import Path
import configparser
import importlib.util
import json
import os
import secrets
import signal
import stat
import subprocess
import sys
import tarfile
import tempfile

sys.dont_write_bytecode = True
repo = Path(sys.argv[1]).absolute()
module_path = repo / "tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-private.py"
spec = importlib.util.spec_from_file_location("private_v4_candidate", module_path)
engine = importlib.util.module_from_spec(spec)
spec.loader.exec_module(engine)
checks = 0


def check(label, value):
    global checks
    if not value:
        raise SystemExit("FAIL: private " + label)
    checks += 1
    print("PASS: private " + label, flush=True)


def fixture(root, options=None, geninitrd=True):
    root.chmod(0o700)
    token = secrets.token_hex(16)
    for rel in ["machine", "machine/packages", "machine/headers", "machine/slackpkg-state",
                "machine/boot", "source", "history", "artifacts"]:
        (root / rel).mkdir(mode=0o755)
    content = {"machine/packages/" + engine.TARGET_NAME: (engine.TARGET_NAME + "\n").encode(),
               "machine/packages/unrelated-1-x86-1": b"unrelated exact record\n",
               "machine/headers/version.h": b"private-6.18.45\n",
               "machine/slackpkg.conf": b"CHECKGPG=on\nWORKDIR=original\n",
               "machine/mirrors": b"original mirror\n", "machine/slackpkg-state/stable": b"state exact\n",
               "machine/boot/kernel": b"boot exact\n", "source/metadata": b"synthetic source, not real v4\n",
               "history/v2-evidence": b"preserved historical fixture\n",
               "artifacts/target.txz": b"synthetic target archive\n",
               "artifacts/predecessor.txz": b"synthetic predecessor archive\n"}
    if geninitrd:
        content["machine/GenInitrd"] = b"original GenInitrd\n"
    for rel, data in content.items():
        p = root / rel
        p.write_bytes(data)
        p.chmod(0o640 if rel == "machine/slackpkg.conf" else 0o644)
    boot = "private-boot-" + token
    (root / "boot-id").write_text(boot)
    opts = dict(fault=None, refresh="ok", nested="ok", cleanup_failure=False, publication_failure=None)
    opts.update(options or {})
    value = dict(schema=1, scope=engine.SCOPE, token=token, boot_id=boot, options=opts,
                 baseline=engine.inventory(root / "machine"),
                 inputs={n: engine.inventory(root / n) for n in ["source", "history", "artifacts"]})
    (root / "fixture.json").write_bytes(engine.encoded(value))
    return value


def preserved(root, f):
    return engine.inventory(root / "machine") == f["baseline"] and all(
        engine.inventory(root / n) == i for n, i in f["inputs"].items())


def drive(root, options=None, cls=engine.Transaction, geninitrd=True):
    f = fixture(root, options, geninitrd)
    tx = cls(root, repo)
    return f, tx, tx.run()


with tempfile.TemporaryDirectory(prefix="slack-update-v4-private-") as directory:
    r = Path(directory)
    f, tx, out = drive(r)
    check("all thirteen real private stages complete in frozen order",
          out["exit"] == 0 and [v["stage"] for v in out["records"]] == engine.STAGES
          and all(v["exit"] == 0 for v in out["records"]))
    check("traps before first filesystem write and backup before mutation",
          out["events"].index("traps-armed-before-filesystem-write") < out["events"].index("first-filesystem-write")
          and out["events"].index("verified-backups-before-mutation") < out["events"].index("private-reference-protocol-emulator-complete"))
    check("physical bytes names modes owner state GenInitrd boot restored", preserved(r, f) and out["restored"])
    check("backups retained and exact", engine.inventory(tx.roles["backup"]) == f["baseline"])
    check("accepted reference/config copied exact and never executed",
          engine.sha(tx.roles["reference"].read_bytes()) == engine.REFERENCE_SHA
          and engine.sha(tx.roles["source_config"].read_bytes()) == engine.CONFIG_SHA
          and out["reference_payload_executed"] is False)
    config = configparser.ConfigParser(interpolation=None, strict=True)
    config.read_string(tx.roles["derived_config"].read_text())
    check("derived data config disables four modules and preserves Slackware booleans",
          all(config[m]["mode"] == "disabled" for m in ["flatpak", "sbo", "elf", "cinnamon"])
          and all(config["slackware"][k] == "true" for k in ["install_new", "upgrade_all"]))
    check("derived work log lock exclusively private",
          all(Path(config["core"][k]).is_relative_to(tx.workspace) for k in ["work_dir", "log_dir", "lock_file"]))
    check("nested refresh install-new upgrade-all admitted exactly",
          [v["argv"] for v in out["nested"][1:]] == engine.ALLOWED_ARGV
          and all(v["admission"] == "accepted" for v in out["nested"]))
    check("zero unrelated or boot backend commands",
          out["backend_calls"] == ["predecessor", engine.ALLOWED_ARGV[0], *engine.ALLOWED_ARGV, "target-upgrade"])
    check("candidate binding explicit private scope never operational source proof",
          json.loads(tx.roles["binding"].read_text())["operational_source_observed"] is False)
    receipt = json.loads((r / "published.publication.json").read_text())
    check("receipt last stage matches actual success record",
          receipt["final_stage"] == {k: out["records"][-1][k] for k in ["index", "stdout", "stderr", "exit"]})
    check("publication SHA sidecar complete modes0600",
          (r / "published.tar.gz.sha256").read_text() == engine.sha((r / "published.tar.gz").read_bytes()) + "  published.tar.gz\n"
          and all(stat.S_IMODE((r / name).stat().st_mode) == 0o600 for name in ["published.tar.gz", "published.tar.gz.sha256", "published.publication.json"]))
    with tarfile.open(r / "published.tar.gz") as tar:
        names = tar.getnames()
        check("archive captures stages0 through11 and cleanup without self receipt",
              len([n for n in names if n.startswith("evidence/stages/") and n.endswith(".json")]) == 12
              and "evidence/cleanup/result.json" in names and not any("12-publish" in n or "publication.json" in n for n in names))
    check("private PASS never live success pause authority",
          receipt["operational_success"] is False and out["operational_success"] is False and not out["pending_machine"] and not out["pending_controller"])
    before = engine.inventory(r)
    tx.cleanup()
    tx.cleanup()
    check("verified repeated cleanup performs no write", engine.inventory(r) == before)
    retry = engine.Transaction(r, repo).run()
    check("same attempt replay refused without overwrite", retry["exit"] != 0 and engine.inventory(r) == before)

for kind in ["entry", "mid"]:
    for index in range(13):
        with tempfile.TemporaryDirectory(prefix="slack-update-v4-private-") as directory:
            r = Path(directory)
            f, tx, out = drive(r, {"fault": kind + ":" + str(index)})
            check("fault %s:%d latches41 and stops later stages" % (kind, index),
                  out["exit"] == 41 and out["records"][-1]["index"] == index and out["records"][-1]["exit"] == 41)
            check("fault %s:%d physical baseline and inputs preserved" % (kind, index), preserved(r, f))
            check("fault %s:%d never publishes success receipt" % (kind, index),
                  not (r / "published.publication.json").exists())
            if index < 2:
                check("fault %s:%d no workspace before trap barrier" % (kind, index), not tx.workspace.exists())

for mode in ["empty", "extra", "stderr-error", "stdout-error", "exit"]:
    with tempfile.TemporaryDirectory(prefix="slack-update-v4-private-") as directory:
        r = Path(directory)
        f, tx, out = drive(r, {"refresh": mode})
        check("initial refresh %s rejected before apply" % mode,
              out["exit"] != 0 and engine.ALLOWED_ARGV[-1] not in out["backend_calls"] and preserved(r, f))
for mode in ["drift", "empty", "extra", "stderr-error", "stdout-error", "exit"]:
    with tempfile.TemporaryDirectory(prefix="slack-update-v4-private-") as directory:
        r = Path(directory)
        f, tx, out = drive(r, {"nested": mode})
        check("nested refresh %s rejects before install/upgrade and restores" % mode,
              out["exit"] != 0 and engine.ALLOWED_ARGV[1] not in out["backend_calls"]
              and engine.ALLOWED_ARGV[2] not in out["backend_calls"] and preserved(r, f))
        check("nested refresh %s streams and actual backend exit retained" % mode,
              len(out["nested"]) == 2 and set(out["nested"][-1]) >= {"stdout", "stderr", "exit", "admission"}
              and out["nested"][-1]["admission"] == "postcheck-pending")

for name in ["SIGHUP", "SIGINT", "SIGTERM"]:
    with tempfile.TemporaryDirectory(prefix="slack-update-v4-private-") as directory:
        class Signalled(engine.Transaction):
            def configure_local_isolation(self):
                super().configure_local_isolation()
                os.kill(os.getpid(), getattr(signal, name))
        r = Path(directory)
        f, tx, out = drive(r, cls=Signalled)
        check("actual %s handler latches original signal and restores private files" % name,
              out["exit"] == 128 + getattr(signal, name) and out["signal"] == name
              and out["cleanup_exit"] == 0 and preserved(r, f))

with tempfile.TemporaryDirectory(prefix="slack-update-v4-private-") as directory:
    r = Path(directory)
    f, tx, out = drive(r, {"fault": "mid:5", "cleanup_failure": True})
    check("cleanup failure preserves original41 separately from52",
          out["exit"] == 41 and out["cleanup_exit"] == 52 and out["pending_machine"] and not out["restored"])
    check("failure retains verified backups and original source/history",
          engine.inventory(tx.roles["backup"]) == f["baseline"] and all(engine.inventory(r / n) == v for n, v in f["inputs"].items()))

with tempfile.TemporaryDirectory(prefix="slack-update-v4-private-") as directory:
    class BadBackup(engine.Transaction):
        def capture_and_verify_baseline(self):
            super().capture_and_verify_baseline()
            self.backup_ready = False
            raise engine.Rejected("unverified backup", 44)
    r = Path(directory)
    f, tx, out = drive(r, cls=BadBackup)
    check("failed backup prevents every package/config mutation", out["exit"] == 44 and not out["backend_calls"] and preserved(r, f))

with tempfile.TemporaryDirectory(prefix="slack-update-v4-private-") as directory:
    class UnknownArgv(engine.Transaction):
        def run_guarded_reference(self):
            self.guarded_slackpkg(["update", "--unreviewed"])
    r = Path(directory)
    f, tx, out = drive(r, cls=UnknownArgv)
    check("unknown adapter argv refused without backend call", out["exit"] != 0 and len(out["backend_calls"]) == 2 and preserved(r, f))

for changed in [engine.ORACLE_PATH, engine.CONTRACT_PATH]:
    with tempfile.TemporaryDirectory(prefix="slack-update-v4-private-") as directory:
        r = Path(directory)
        clone = r / "repository-copy"
        for rel in [engine.ORACLE_PATH, engine.CONTRACT_PATH]:
            p = clone / rel
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_bytes((repo / rel).read_bytes())
        class InputDrift(engine.Transaction):
            def run_guarded_reference(self):
                self.repository = clone
                p = clone / changed
                p.write_bytes(p.read_bytes() + b"\n")
                super().run_guarded_reference()
        f, tx, out = drive(r, cls=InputDrift)
        check("use-time immutable hash drift refuses " + Path(changed).name,
              out["exit"] != 0 and len(out["backend_calls"]) == 2 and preserved(r, f))

for fault in ["sidecar", "receipt"]:
    with tempfile.TemporaryDirectory(prefix="slack-update-v4-private-") as directory:
        r = Path(directory)
        f, tx, out = drive(r, {"publication_failure": fault})
        check("partial %s publication leaves controller pending no success" % fault,
              out["exit"] != 0 and out["pending_controller"] and not out["pending_machine"]
              and preserved(r, f) and not (r / "published.publication.json").exists())
        check("partial %s attempt preserves exclusive artifact" % fault, (r / "published.tar.gz").is_file())

with tempfile.TemporaryDirectory(prefix="slack-update-v4-private-") as directory:
    r = Path(directory)
    f, tx, out = drive(r, geninitrd=False)
    check("absent GenInitrd remains absent after success", out["exit"] == 0 and not (r / "machine/GenInitrd").exists() and preserved(r, f))

for bad in ["symlink", "hardlink", "occupied", "schema", "unknown-option"]:
    with tempfile.TemporaryDirectory(prefix="slack-update-v4-private-") as directory:
        r = Path(directory)
        fixture(r)
        p = r / "machine/slackpkg-state/stable"
        if bad == "symlink":
            p.unlink()
            p.symlink_to(r / "history/v2-evidence")
        elif bad == "hardlink":
            (r / "machine/slackpkg-state/alias").hardlink_to(p)
        elif bad == "occupied":
            (r / "transaction").mkdir()
        else:
            f = json.loads((r / "fixture.json").read_text())
            if bad == "schema":
                f["schema"] = True
            else:
                f["options"]["command"] = "slackpkg"
            (r / "fixture.json").write_bytes(engine.encoded(f))
        call = subprocess.run(["bash", str(repo / "tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor.sh"), "--private-test", str(r)], capture_output=True, text=True)
        check("CLI rejects %s fixture before production mutation" % bad, call.returncode != 0)
        check("CLI %s fixture creates no new evidence/publication" % bad,
              not (r / "published.tar.gz").exists() and (bad == "occupied" or not (r / "transaction").exists()))

with tempfile.TemporaryDirectory(prefix="slack-update-v4-private-") as directory:
    r = Path(directory)
    f = fixture(r)
    before = engine.inventory(r)
    wrapper = repo / "tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor.sh"
    for number, args in enumerate([[], ["--apply"], ["--grant", "old"], ["--private-test"], ["--private-test", str(r), "extra"]]):
        call = subprocess.run(["bash", str(wrapper), *args], capture_output=True, text=True)
        check("production/invalid CLI case%d closed before writes" % number, call.returncode == 2 and engine.inventory(r) == before)
    call = subprocess.run(["bash", str(wrapper), "--private-test", str(r)], capture_output=True, text=True)
    check("actual wrapper executes isolated Python private candidate", call.returncode == 0 and json.loads(call.stdout)["scope"] == engine.SCOPE and preserved(r, f))

print("Private result: PASS (%d checks, 0 failures)" % checks)
