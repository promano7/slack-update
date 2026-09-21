# Phase 1 reference comment-language remediation design — step 167

Step 167 freezes a narrowly scoped remediation boundary from the accepted
step-166 audit. The exact step-166 policy and record hashes are captured at
execution time, together with the unchanged SHA-256 of
`tools/reference/slack-update-reference.sh`.

Only rows classified `language-defect` by the accepted audit are eligible for
step-168 source changes. Each eligible change is a one-for-one translation of
the syntactic shell-comment payload to natural English. The source text before
and including the comment delimiter remains semantically untouched; line count
must not change; non-defect comments, runtime strings, heredoc payloads,
technical directives, and executable shell code are out of scope.

This design grants source-change authorization only for those frozen defect
rows. It grants no repository or network refresh, no Slackware machine
execution, no package or boot action, and no Phase 2 work. Step 168 must run
`bash -n` and rerun the same language audit, with zero language defects required
before closure may be considered.
