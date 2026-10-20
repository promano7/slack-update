#!/usr/bin/env python3
"""Check ZIP structure/CRC and explicitly selected embedded ZIPs without extraction."""

import argparse
from collections import Counter
import shutil
import sys
import tempfile
import zipfile
import zlib


CHUNK_SIZE = 1024 * 1024


def positive_integer(value):
    number = int(value)
    if number <= 0:
        raise argparse.ArgumentTypeError("must be a positive integer")
    return number


def check_archive(archive, label, limit):
    entries = archive.infolist()
    # zipfile permits prepended bytes and can find an embedded ZIP's end record
    # after an outer archive is truncated. Deliveries must start at byte zero.
    first_offset = min(entry.header_offset for entry in entries) if entries else archive.start_dir
    if first_offset != 0:
        raise ValueError(f"{label}: ZIP does not start at byte zero (offset {first_offset})")
    duplicates = sorted(name for name, count in Counter(e.filename for e in entries).items() if count > 1)
    if duplicates:
        raise ValueError(f"{label}: duplicate member names: {duplicates!r}")
    total = sum(entry.file_size for entry in entries)
    if total > limit:
        raise ValueError(f"{label}: declared uncompressed bytes {total} exceed limit {limit}")
    for entry in entries:
        with archive.open(entry) as stream:
            while stream.read(CHUNK_SIZE):
                pass
    return f"PASS ZIP {label}: {len(entries)} entries, {total} uncompressed bytes"


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", help="ZIP file to read")
    parser.add_argument("--member", action="append", default=[],
                        help="exact member name to additionally inspect as a ZIP; repeat as needed")
    parser.add_argument("--max-uncompressed-bytes", type=positive_integer, default=4 * 1024**3,
                        help="declared uncompressed byte limit per inspected archive (default: 4 GiB)")
    args = parser.parse_args(argv)
    if len(args.member) != len(set(args.member)):
        parser.error("--member names must be distinct")
    reports = []
    try:
        with zipfile.ZipFile(args.archive) as archive:
            reports.append(check_archive(archive, "outer", args.max_uncompressed_bytes))
            for name in args.member:
                try:
                    entry = archive.getinfo(name)
                except KeyError:
                    raise ValueError(f"selected ZIP member is missing: {name!r}") from None
                if entry.is_dir():
                    raise ValueError(f"selected ZIP member is a directory: {name!r}")
                # Spill large members to a private temporary file, never to their embedded paths.
                with tempfile.SpooledTemporaryFile(max_size=8 * CHUNK_SIZE) as temporary:
                    with archive.open(entry) as stream:
                        shutil.copyfileobj(stream, temporary, CHUNK_SIZE)
                    temporary.seek(0)
                    with zipfile.ZipFile(temporary) as nested:
                        reports.append(check_archive(nested, repr(name), args.max_uncompressed_bytes))
    except (OSError, ValueError, RuntimeError, NotImplementedError,
            zipfile.BadZipFile, zipfile.LargeZipFile, EOFError, zlib.error) as error:
        print(f"FAIL ZIP: {error}", file=sys.stderr)
        return 1
    # Do not announce a successful delivery check before every requested ZIP passes.
    print("\n".join(reports))
    return 0


if __name__ == "__main__":
    sys.exit(main())
