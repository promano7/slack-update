# Phase 1 reference comment-language audit execution — step 166

Step 166 executes the contract frozen by step 165 against only
`tools/reference/slack-update-reference.sh`.

The audit is read-only with respect to the reference source. It inventories
syntactic shell comments, excludes the shebang and heredoc payload, classifies
technical directives and code-only fragments separately, and records natural
language comments as either `english-prose` or `language-defect`.

The acceptance policy is generated from the exact source present at execution
time and stores its SHA-256. The TSV record inventories every syntactic comment
considered by the audit. A non-zero `language_defects` count does not authorize
source edits; it routes the workstream to
`phase-1-reference-comment-language-remediation-design`. A zero count routes to
a closure review instead.

This step authorizes no repository or network refresh, no Slackware machine
execution, no package or boot action, and no Phase 2 work. A later
Slackware-current publication does not invalidate this repository-only audit.
