# SBo queue constraint and graph regression scope

Run from the repository root:

```bash
python3 tests/reference/test-sbo-queue-graph.py
bash tests/reference/test-sbo-dependency-order.sh
bash tests/reference/test-sbo-target-selection.sh
bash tests/reference/test-sbo-options.sh
```

The new Python standard-library driver sources the current Bash reference without
calling `main()`. It calls the real queue record parser, build-option normalizer,
constraint appender and AWK graph sorter. It requires Bash and an AWK supporting
the reference's existing program. It uses real private files and child processes;
the source's environment initializer and installed updater commands are not run.
Guards name prohibited workflow, discovery and package/network entries. These
guards are not OS containment; review the source before extending their scope.

## Graph model and exact outputs

The independently authored Python model uses sets and the predecessor relation,
without translating the reference's heap. At each position it chooses the first
C-order name whose remaining predecessors are absent. It predicts both the exact
emitted prefix and raw status, including partial output followed by cycle status 2.
It compares stdout bytes, stderr bytes and raw return status. It does not use
reference output to construct expected results.

- All 512 directed graphs on three fixed ASCII names, including self edges.
- All 64 subsets of six forward edges in a four-node acyclic family. The declared
  direction deliberately differs from alphabetical order.
- Empty input, edge-only implicit nodes and a cycle with an unrelated free prefix.
- Each of these 579 cases runs with original, reversed and duplicated records:
  1,737 graph entries. Duplicate edges must not increase indegree twice.
- Eight authored record cases check unknown tags, wrong field counts, a blank
  line, leading tag whitespace and a carriage return retained inside a node name.

The last record is accepted by the current raw graph sorter. It is not a valid
native target-name claim. Direct graph records bypass the queue parser's target
validation. Malformed input returns 1 before emitting any graph output; a cyclic
input can emit its free prefix before returning 2. This helper's raw outputs do
not establish that callers install a partial queue.

## Constraint appending

Twenty authored streams run against empty and preseeded private graph files.
They check CRLF handling, comments, skipped controls, options, unterminated last
lines, adjacency across controls, adjacent duplicate nodes, nonadjacent repeated
nodes, invalid names and invalid options. Compare exact appended bytes and raw
status; check the caller's IFS and an unrelated scalar remain unchanged.

Invalid later input leaves previously appended constraints in the private file;
this helper is not a transaction. Controls can skip invalid-looking options,
but the multiple-pipe check precedes control recognition. Repeated adjacent nodes
produce repeated node records without a self edge. An earlier target followed by
a later repeat can create a real cycle. These are current observed semantics.

A 41st entry supplies a failure only for the graph-writing `printf` formats.
It checks return 1 and the shell-created empty redirection file. This is a supplied
writer failure, not a native permission or storage-failure test. No source command
substitution in an option is evaluated by the parser.

## Related checks and limits

The existing dependency-order and target-selection regressions additionally use
private queue directories, package records and supplied `sbopkg` callbacks. They
exercise collectors, final merging and selected workflow/JSON propagation that
the graph driver deliberately does not call. Run the dry-run workflow,
apply-secondary workflow and SBo option JSON checks for their separate boundaries.
Their separate passes do not prove actual native composition.

Eight syntax-valid private reference mutations check sensitivity to heap order,
edge deduplication, successor release, cycle status, malformed-record status,
adjacent duplicate handling, skipped-control continuation and graph-writer status.
These are focused source controls retained in delivery validation, not normal
user executions or exhaustive mutation coverage. The first test-authoring run
normalized CR during text capture; byte capture corrected that oracle issue.
The first writer callback also intercepted parser trimming, so it was narrowed to
graph formats before the final checks. Reference behavior was not changed.

No queue directory collector, installed package database, SBo synchronization,
builder, network action, ELF scanner or boot operation is executed by the new
driver. Its private work products do not demonstrate whole-host absence, global
cleanup, installed AWK behavior on either Slackware platform, native acceptance,
or semantic compatibility. Native install-new status 20 still requires empty AND
no effect; upgrade status 20 remains failure. Phase 1/kernel remain incomplete;
A/R/D unselected, schema 1/reference-v1/C/Phase 2/production closed. Original
specification, migration, composition, independent safe whole review, fresh bounded
native grant and own-platform conformance gates remain unchanged.
