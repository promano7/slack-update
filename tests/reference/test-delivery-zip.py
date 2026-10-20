#!/usr/bin/env python3
"""Exercise the delivery ZIP checker with independently authored private archives."""

import io
import os
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import warnings
import zipfile


ROOT = Path(__file__).resolve().parents[2]
CHECKER = ROOT / "tools/reference/verify-delivery-zip.py"


def archive_bytes(records, compression=zipfile.ZIP_STORED):
    output = io.BytesIO()
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", UserWarning)
        with zipfile.ZipFile(output, "w", compression=compression) as archive:
            for name, data in records:
                archive.writestr(name, data)
    return output.getvalue()


def corrupt_payload(data):
    result = bytearray(data)
    # The first fixture member is stored, with no descriptor or extra field.
    name_length, extra_length = struct.unpack_from("<HH", result, 26)
    offset = 30 + name_length + extra_length
    result[offset] ^= 1
    return bytes(result)


def run_case(root, name, data, options, status, fragment, success_lines=0):
    path = root / (name + ".zip")
    if data is not None:
        path.write_bytes(data)
    result = subprocess.run([sys.executable, str(CHECKER), str(path), *options],
                            cwd=root, env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1", TMPDIR=str(root)),
                            capture_output=True, text=True, timeout=15)
    if result.returncode != status:
        raise AssertionError((name, "status", status, result.returncode, result.stdout, result.stderr))
    if status == 0:
        if result.stderr or not result.stdout.startswith("PASS ZIP outer:") or len(result.stdout.splitlines()) != success_lines:
            raise AssertionError((name, "success channels", result.stdout, result.stderr))
        if fragment not in result.stdout:
            raise AssertionError((name, "success message", fragment, result.stdout))
    elif result.stdout or fragment not in result.stderr:
        raise AssertionError((name, "failure channels", fragment, result.stdout, result.stderr))


def main():
    child = archive_bytes([("child.txt", b"child bytes")])
    broken_child = corrupt_payload(child)
    outer = archive_bytes([("history/child.zip", child), ("source.txt", b"source bytes")])
    duplicate_child = archive_bytes([("same", b"one"), ("same", b"two")])
    cases = [
        ("empty", archive_bytes([]), [], 0, "0 entries, 0 uncompressed bytes", 1),
        ("stored", archive_bytes([("file", b"abc")]), [], 0, "1 entries, 3 uncompressed bytes", 1),
        ("deflated", archive_bytes([("file", b"abc" * 100)], zipfile.ZIP_DEFLATED), [], 0, "300 uncompressed bytes", 1),
        ("directory-member", archive_bytes([("directory/", b"")]), [], 0, "1 entries, 0 uncompressed bytes", 1),
        ("outer-only", outer, [], 0, "2 entries", 1),
        ("nested-valid", outer, ["--member", "history/child.zip"], 0, "'history/child.zip': 1 entries, 11 uncompressed bytes", 2),
        ("not-zip", b"plain bytes", [], 1, "FAIL ZIP:", 0),
        ("missing", None, [], 1, "FAIL ZIP:", 0),
        ("truncated-end", outer[:-22], [], 1, "FAIL ZIP:", 0),
        ("truncated-member", outer[:40], [], 1, "FAIL ZIP:", 0),
        ("prepended-data", b"prefix" + child, [], 1, "does not start at byte zero", 0),
        ("prepended-empty", b"prefix" + archive_bytes([]), [], 1, "does not start at byte zero", 0),
        ("bad-outer-crc", corrupt_payload(outer), [], 1, "Bad CRC-32", 0),
        ("nested-truncated-unselected", archive_bytes([("history/child.zip", child[:-22])]), [], 0, "1 entries", 1),
        ("nested-truncated-selected", archive_bytes([("history/child.zip", child[:-22])]), ["--member", "history/child.zip"], 1, "FAIL ZIP:", 0),
        ("nested-crc-selected", archive_bytes([("history/child.zip", broken_child)]), ["--member", "history/child.zip"], 1, "Bad CRC-32", 0),
        ("nested-plain", archive_bytes([("history/child.zip", b"not ZIP")]), ["--member", "history/child.zip"], 1, "FAIL ZIP:", 0),
        ("missing-selection", outer, ["--member", "absent.zip"], 1, "selected ZIP member is missing", 0),
        ("directory-selection", archive_bytes([("directory/", b"")]), ["--member", "directory/"], 1, "selected ZIP member is a directory", 0),
        ("duplicate-outer", archive_bytes([("same", b"one"), ("same", b"two")]), [], 1, "duplicate member names", 0),
        ("duplicate-child", archive_bytes([("child.zip", duplicate_child)]), ["--member", "child.zip"], 1, "duplicate member names", 0),
        ("limit-equal", archive_bytes([("file", b"abc")]), ["--max-uncompressed-bytes", "3"], 0, "3 uncompressed bytes", 1),
        ("limit-exceeded", archive_bytes([("file", b"abc")]), ["--max-uncompressed-bytes", "2"], 1, "exceed limit 2", 0),
        ("limit-zero", outer, ["--max-uncompressed-bytes", "0"], 2, "must be a positive integer", 0),
        ("limit-negative", outer, ["--max-uncompressed-bytes", "-1"], 2, "must be a positive integer", 0),
        ("limit-nonnumeric", outer, ["--max-uncompressed-bytes", "bad"], 2, "invalid positive_integer value", 0),
        ("duplicate-selection", outer, ["--member", "history/child.zip", "--member", "history/child.zip"], 2, "--member names must be distinct", 0),
    ]
    with tempfile.TemporaryDirectory(prefix="delivery-zip-test-") as temporary:
        root = Path(temporary)
        for row in cases:
            run_case(root, *row)
        multiple = archive_bytes([("first.zip", child), ("second.zip", child)])
        run_case(root, "two-valid", multiple, ["--member", "first.zip", "--member", "second.zip"], 0, "'second.zip'", 3)
        mixed = archive_bytes([("first.zip", child), ("second.zip", child[:-22])])
        run_case(root, "second-invalid", mixed, ["--member", "first.zip", "--member", "second.zip"], 1, "FAIL ZIP:")
        large_child = archive_bytes([("large", b"x" * (9 * 1024**2))])
        run_case(root, "spilled-child", archive_bytes([("large.zip", large_child)]),
                 ["--member", "large.zip"], 0, "'large.zip': 1 entries", 2)
        compressed_child = archive_bytes([("large", b"x" * 10000)], zipfile.ZIP_DEFLATED)
        run_case(root, "child-limit", archive_bytes([("child.zip", compressed_child)]),
                 ["--member", "child.zip", "--max-uncompressed-bytes", "1000"], 1, "exceed limit 1000")
        if any(root.glob("**/child.txt")) or any(p.is_dir() for p in root.iterdir()):
            raise AssertionError("embedded paths were unexpectedly extracted")
    print(f"Delivery ZIP integrity: {len(cases) + 4} scenarios PASS")


if __name__ == "__main__":
    main()
