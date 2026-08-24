# Phase 1 step 137 revision 2 — revision-1 document assertion fix

Step 137 revision 1 established that the authorized direct-generic source
relocation is correct and that the original step-137 implementation harness
passes with the classifier-local reconstruction helper. Its final assertion
failed only because the revision-1 harness searched for a prose fragment with
`grep -F` even though the Markdown source wrapped that fragment across a line
boundary.

## Verification defect

The revision-1 document already states that the failure belonged to the
verification code, not to the authorized source relocation. The assertion
looked for the shorter literal fragment `verification code, not to the` on one
physical line. Markdown line wrapping placed `authorized source relocation` on
the next line, so the content was semantically correct while the line-oriented
assertion failed.

## Revision 2 correction

Revision 2 changes only the revision-1 verification harness. It normalizes
Markdown whitespace before checking the complete sentence fragment
`verification code, not to the authorized source relocation`, together with
the classifier-local reconstruction statement, the authorized pre-edit source
SHA-256 `c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c`,
and the explicit Slackware-current execution hold.

The accepted post-edit source remains exactly
`aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7`.
The corrected step-137 implementation helper, implementation TSV, policy, and
revision-1 document remain unchanged.

## Authorization and machine boundary

The step-136 source authorization remains consumed and non-reusable. Revision
2 authorizes no source change and no machine execution. No Slackware-current
rerun, Slackware 15.0 execution, package action, boot mutation, reboot, or
repository refresh is authorized or required.

A successful revision-2 harness restores the intended repository-only step-137
implementation checkpoint and advances to the repository-local regression
review.
