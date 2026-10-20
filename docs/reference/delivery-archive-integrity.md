# Delivery archive integrity

The delivery checker reads ZIP structure and member CRCs without extracting
embedded paths or executing repository/native workflows:

```bash
python3 tools/reference/verify-delivery-zip.py /absolute/path/delivery.zip
python3 tools/reference/verify-delivery-zip.py /absolute/path/continuation.zip \
  --member history/slack-update-phase-1-step-491-delivery.zip
python3 tests/reference/test-delivery-zip.py
```

The first command checks the outer archive only. Each repeated `--member`
selects one exact outer member for an additional ZIP check. Selection is
explicit and one level deep: ZIPs inside that selected ZIP are ordinary bytes
unless checked separately. A passing outer CRC authenticates neither the
meaning nor the completeness of an embedded file as a ZIP. No automatic
recursive history, fixture or native harness execution is introduced.

Every selected archive must start at byte zero, have unique member names and
pass complete reads of every member. Prepended/self-extracting ZIPs are outside
this delivery format. The byte-zero check matters because Python's ZIP reader
can otherwise find an embedded end record when an outer ZIP is truncated.
The checker emits success only after all requested checks pass. Failures return
1; invalid command syntax returns 2. The default declared uncompressed byte
limit is 4 GiB per inspected archive; `--max-uncompressed-bytes` changes it.
This is a finite size gate, not a complete decompression-resource sandbox.

Large selected ZIPs spill after 8 MiB into a private temporary file. Temporary
handles close on normal completion and handled failures. Filesystem interruption,
all descriptor states, ownership/xattrs, concurrency and whole-host cleanup
are not established by these tests. No embedded filename is used as an output
path; extraction safety or package trust is not certified.

## Regression cases

The 31 standard-library Python cases create private authored fixtures and invoke
the real CLI. They cover stored/deflated and empty archives, directory records,
outer-only versus explicit nested selection, two selections, a failed second
selection, missing inputs/members, truncated end records/member bodies, outer
and nested CRC faults, duplicate names, prepended bytes, positive/equal/exceeded
byte limits, invalid limits, repeated selections and real temporary-file spill.
One case deliberately accepts an unselected malformed embedded ZIP as opaque
bytes; its paired explicit-selection case must reject it. The test checks raw
status, stdout/stderr, selected messages and private extraction-path absence.
It does not derive its expected results from the checker.

## Newly observed continuation-491 defect

The supplied continuation ZIP passes its outer CRC and all 2,466 manifest
entries. Its 2,380 source files and recorded Git modes reconstruct tree
`cdcde5a9efd939f7ecbbfca51ece0879e440c26a`, matching accepted 491. These checks
do not establish the validity of its nested historical archive.

`history/slack-update-phase-1-step-491-delivery.zip` has 482,738,176 bytes and
SHA256 `8a0593c4d38c92d109696f0abfe89a3bab365d2cc9f234ca3f8bc9b92387441d`.
That hash equals its outer manifest, but the file has no complete ZIP end
directory. Sequential local-header inspection reaches an incomplete source
fixture member whose declared end is 483,220,076. The member is
`slack-update/tests/fixtures/reference/acceptance/phase-1/phase-1-operational-readonly-source-inventory-inventory.json`.
Inspection of that finite prefix is not restoration of the missing suffix or
validation of earlier nested history. No cause or creation-time failure is
inferred. The original supplied bytes remain evidence of this observation.

A separate original 491 delivery was located with reported size 493,435,467
bytes; its retrieval failed. Its contents were not read or verified, and neither
identity nor prefix equality with the damaged copy is asserted. Replacing,
inventing or relabeling the nested history as repaired is outside this result.
The prior continuation's stronger claim that the saved nested 491 ZIP supplies
complete end-to-end history is unsupported by the supplied bytes.

The first checker draft also failed its own truncated-outer control by accepting
the embedded ZIP. The byte-zero guard corrected that observed failure; retain
the failure and correction in preparation evidence. Later success does not
erase either the authoring failure or the inherited archive defect.

Six syntax-valid private checker mutations are rejected by the regression:
omitted origin, duplicate and size guards, omitted CRC reads, omitted selected
ZIP validation and premature success output. These are focused delivery controls;
they do not rerun or expand historical runtime/native mutation evidence.

## Current status

Step 492 begins a new user-requested 8-12-step repository block. It adds this
checker, its private regression and documentation only. Reference runtime,
existing tests, frozen native contracts, fixtures and member criteria remain
unchanged. The historical 60 runtime commands were not rerun in preparation;
the new ZIP test is a separate delivery check, not native coverage.

The delivery contains the full current source and exact inherited condition,
mode and receipt records, with prior archive references and hashes. It does not
embed another recursive binary history copy or claim that missing historical
bytes were restored. The archival defect remains open pending a verified
complete original and any required historical comparison. This limit must be
retained when assessing a later pause or continuation.

Prepared 492 awaits actual application/test/commit/push/clean source/mode/tree
evidence. Zero actual steps in the new block are accepted at preparation time;
491 is the recorded predecessor pause. No new strong pause is confirmed here.
Phase 1 and kernel acceptance remain incomplete. A/R/D options remain unselected;
native evidence and live bindings remain null; host state is unobserved and
global host closure is false. Independent specification/impact, migration if
norms change, actual composition, safe whole-graph review, fresh bounded native
grant and later own-platform conformance gates remain in force. This work
introduces no native execution authority or reuse of old rights.
