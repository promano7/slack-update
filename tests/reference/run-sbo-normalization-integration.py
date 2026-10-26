#!/usr/bin/env python3
"""Run current111 integration with complete inherited output oracles and source hashes."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def normalize56(value):
    roots = set(re.findall(r"/tmp/tmp\.[A-Za-z0-9]+", value))
    if len(roots) != 1:
        raise ValueError("position56 requires exactly one consistent private root: " + repr(roots))
    root = next(iter(roots))
    return value.replace(root, "<PRIVATE_ROOT>"), root


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", type=Path, nargs="?", default=Path(__file__).resolve().parents[2])
    parser.add_argument("--report", type=Path)
    parser.add_argument("--label", default="STEP570")
    args = parser.parse_args()
    assert re.fullmatch(r"STEP[0-9]+", args.label), "invalid output label"
    root = args.root.resolve()
    plan_path = root / "tests/reference/sbo-normalization-integration-plan.json"
    plan_bytes = plan_path.read_bytes()
    plan = json.loads(plan_bytes)
    old_path = root / "tests/reference/sbo-emission-integration-plan.json"
    old_runner = root / "tests/reference/run-sbo-emission-integration.py"
    old = json.loads(old_path.read_bytes())
    assert sha(old_path) == plan["prior106_plan_sha256"]
    assert sha(old_runner) == plan["prior106_runner_sha256"]
    assert len(plan["commands"]) == plan["command_count"] == 111
    assert old["commands"] == plan["commands"][:106]
    assert old["ordered_vectors"] == plan["ordered_vectors"][:106]
    assert plan["frozen_audits_excluded"] == old["frozen_audits_excluded"] + [564]
    assert plan["new_introduction_order"] == [565, 566, 567, 568, 569]
    assert [r["expected_origin_step"] for r in plan["commands"][106:]] == plan["new_introduction_order"]
    assert plan["normalization"] == old["normalization"]
    assert plan["runtime_sha256"] == "eb141d314b3a483285c6d65d430fdd5c56c7492cbf06a10723a33024ab58b8e4"
    assert not plan["native_acceptance"] and not plan["new_pause_confirmed"]
    assert sha(Path(__file__).resolve()) == plan["runner_sha256"]
    def verify_sources():
        assert plan_path.read_bytes() == plan_bytes, "plan changed during integration"
        assert sha(old_path) == plan["prior106_plan_sha256"]
        assert sha(old_runner) == plan["prior106_runner_sha256"]
        assert sha(root / "tools/reference/slack-update-reference.sh") == plan["runtime_sha256"]
        assert sha(Path(__file__).resolve()) == plan["runner_sha256"]
        for i, row in enumerate(plan["commands"], 1):
            assert row["position"] == i and row["command"] == plan["ordered_vectors"][i - 1]
            assert sha(root / row["command"][1]) == row["driver_sha256"]
            if "support_path" in row:
                assert sha(root / row["support_path"]) == row["support_sha256"]
            for support in row.get("declared_supports", []):
                assert sha(root / support["path"]) == support["sha256"]
    verify_sources()
    rows = []
    def save():
        if args.report:
            args.report.write_text(json.dumps(rows, sort_keys=True, indent=2) + "\n")
    for expected in plan["commands"]:
        i, command = expected["position"], expected["command"]
        print("BEGIN " + args.label + " COMMAND " + str(i) + ": " + " ".join(command), flush=True)
        start = time.monotonic()
        try:
            result = subprocess.run(command, cwd=root, capture_output=True, timeout=240,
                env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"))
            got = dict(expected, status=result.returncode, stdout=result.stdout.decode(), stderr=result.stderr.decode(), timed_out=False)
        except subprocess.TimeoutExpired as error:
            got = dict(expected, status=None, stdout=(error.stdout or b"").decode(), stderr=(error.stderr or b"").decode(), timed_out=True)
        got.update(fresh=True, runtime_sha256=plan["runtime_sha256"], execution_label=args.label,
            plan_sha256=hashlib.sha256(plan_bytes).hexdigest(), elapsed_seconds=round(time.monotonic() - start, 3))
        rows.append(got)
        sys.stdout.write(got["stdout"]); sys.stdout.flush()
        sys.stderr.write(got["stderr"]); sys.stderr.flush()
        actual, oracle = got["stdout"], expected["expected_stdout"]
        if i == 56:
            try:
                actual, actual_root = normalize56(actual)
                oracle, oracle_root = normalize56(oracle)
                got.update(normalized_stdout=actual, expected_normalized_stdout=oracle,
                    actual_private_root=actual_root, expected_private_root=oracle_root,
                    normalization=plan["normalization"]["rule"])
            except ValueError as error:
                got["normalization_error"] = str(error)
        matched = "normalization_error" not in got and (got["status"], actual, got["stderr"]) == (
            expected["expected_status"], oracle, expected["expected_stderr"])
        got["expected_output_matches"] = matched
        save()
        print("END " + args.label + " COMMAND " + str(i) + ": status=" + str(got["status"]) + "; exact_output=" + str(matched), flush=True)
        if not matched:
            print("FAIL " + args.label + " INTEGRATION: complete failed row retained", file=sys.stderr)
            return 1
    verify_sources()
    print("PASS " + args.label + " INTEGRATION: 111 fresh ordered commands; original106 entire rows/vectors/oracles/supports unchanged; five565-569 additions; only position56 private-root normalization; frozen audits excluded; no native acceptance", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
