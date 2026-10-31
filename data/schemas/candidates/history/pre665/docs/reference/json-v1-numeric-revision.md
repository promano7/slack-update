# Exact numerical decoding candidate revision, steps630–637

This is an unaccepted development candidate. The runtime producer still emits
schema0/provisional. No J01–J12 disposition, external-consumer statement, A/R/D
selection, independent semantic acceptance, native grant or schema freeze follows.

## Observed defect and correction

The complete original validator accepted three authored invalid inputs: a result
with version1.0000000000000001, a result whose raw check code1e-400 became zero,
and an offset fragment repeating sequence1e20. The original source, strict JSON
functions and schemas were retained exactly. The earlier decoder-only findings
are now confirmed through real Draft202012Validator execution, not a stub.

The revised offline reader parses decimal/exponent tokens with Decimal. It retains
ordinary Python integers for integer lexical tokens. Duplicate keys, non-JSON
constants, invalid UTF-8, multiple documents and malformed JSON remain rejected.
This is numeric representation preservation, not an adapter from v0 to v1.

The candidate's separate JSON Schema type checker recognizes finite mathematical
integers, including Decimal1.0 and1e400, while excluding booleans and fractional or
nonfinite values. The explicit version gate uses that same check and still
requires exactly1. Already-created Python float inputs are assessed as the values
supplied; the reader cannot reconstruct digits lost before its API was called.

Raw integer domains are not narrowed: e.g.1e400 can remain a failed raw check code
instead of becoming infinity. Final codes retain their original bounded domains.
All schema bytes, fields, null rules, ordered arrays, raw20 native criteria,
timestamp/path rules and original v0 payload expectations remain unchanged.

Sequence offsets use decimal subtraction in an explicit private context with
inexact arithmetic trapped. Precision depends on the supplied coefficients and
the small expected offset, not zero padding out to the initial exponent. A valid
difference equal to that offset is exact in that precision; a nonexact subtraction
cannot pass as a rounded matching difference. Caller Decimal precision does not
control this comparison. Complete streams still start at1; only the explicit
fragment profile permits an offset. No additional numeric bound is introduced.
Existing interpreter/input representation and memory limits still apply; there
is no new resource-containment or unlimited-input guarantee.

## Reproducibility and tests

The private development environment used unmodified official jsonschema4.17.3
source (`dbc398245a583cb2366795dc529ae042d10c1577`) and pure-Python pyrsistent0.19.3
source (`cc90f3e2b339653fde0df422aaf3ccdb3fc1225d`), with the runtime's attrs.
All47 selected upstream package/schema files were checked against their Git blob
identities before use. No substituted validator, host package installation or
native workflow was used. This is a source-based development environment, not
a claim to have tested every jsonschema4.x release or the user's PC environment.

The new numeric driver has15 named test methods and600 deterministic integer-oracle
comparisons, plus explicit subcases for near-integer fractions, underflow,
overflow, large integral values, boolean/null/nonfinite refusal, strict decoding,
complete/fragment profiles and low caller precision. Valid integral spellings
1/1.0/1e0 and exact large successors remain accepted. Repeated large sequences
and all three complete adversarial inputs are rejected.

The focused regression selection also includes the unchanged original candidate,
policy, consumer-inventory and serializer-compatibility drivers. Their old scopes
and v0/projection provenance remain distinct from numeric candidate testing. Raw
stdout, stderr and statuses are supplied outside the repository. Previously
accepted605 setup/repository results are not reopened by old pending checkboxes.

Local results are deliberately incomplete: the numeric driver and inventory
driver pass. The original candidate, policy and serializer-compatibility drivers
stop on jsonschema4.17.3's internal-reference resolution error with these URN
schemas. The unchanged original candidate driver fails the same way on the
original published source in this environment. Initial isolated-mode launches
also failed to import sibling test support; their separate channels are retained.
The three full regressions must pass in the user's capable development environment
before this prepared patch is proposed for application/commit. No old test,
schema ID or upstream resolver was changed to turn those failures into a PASS.

## Source identities and stopping boundary

Eighteen exact pre630 inputs, including the complete previous dossier, migration
plan and decision narrative, are retained below
`data/schemas/candidates/history/pre630/` at their original relative paths. The
current inventory and dossier bind the revised reader and added numeric driver;
the current migration plan reflects those identities. Historical bytes and their
unaccepted decisions are preserved, not retroactively certified.

The literal discovery inventory still covers .py/.sh under tools/ and tests/;
the new test is included there. Historical source copies under data/ are inert
reference material outside that explicit discovery scope. New source identity
requires a new exact semantic review; an old binding must never be reused as
acceptance of the revised candidate. Both schemas remain unchanged.

PC application, tests, commit/publication acceptance and a separate whole-condition
pause review remain pending for this prepared change. Last confirmed qualified
STATIC pause remains621; no STATIC637 is certified by local test success. All
prior binary-history/custody/trust/IO/containment/mode/link/cleanup qualifications
remain. Phase1/kernel incomplete, P0D unresolved,13 operational findings and16
native gaps open, four native repairs inactive, C/Phase2/production closed.
STOP after this bounded preparation; no automatic next implementation or native run.
