# Phase 1 reference comment-language audit contract freeze

Step 165 freezes the audit contract for the repository-only workstream selected
by accepted step 164. The target is exactly
`tools/reference/slack-update-reference.sh`.

## Lexical scope

The future audit must evaluate **actual shell comments**, not every textual `#`
character. The shebang is excluded. A `#` inside quoted text, shell syntax such
as parameter expansion, or a here-document payload is not automatically a shell
comment. The execution step must preserve enough line-level evidence to show
that comment extraction covered the complete target.

Natural-language comment prose must be English. Technical directives such as
ShellCheck or SPDX annotations are classified as non-prose directives. A
comment that consists solely of a command or code fragment may be classified
as non-prose code, but mixed prose plus code remains natural-language prose and
must satisfy the English requirement.

The audit result is conformant only when the complete inventory contains zero
`language-defect` classifications. Step 165 itself does **not** assert that any
defect exists and does not authorize remediation.

## Drift and authorization boundary

The audit execution must bind its evidence to the exact SHA-256 of
`tools/reference/slack-update-reference.sh` observed at execution time. A later
change to that target invalidates that audit evidence and requires a fresh
repository-only audit. A Slackware-current publication does not invalidate this
contract because no package or runtime state is involved.

No source change, repository refresh, network refresh, machine execution,
package action, boot action, or Phase 2 start is authorized. Any source edit
needed after the audit requires a separate explicit authorization boundary.

The next stage is `phase-1-reference-comment-language-audit-execution`.
Step 165 is not the requested end-of-session strong safe pause, so
`pause_safe=false`.
