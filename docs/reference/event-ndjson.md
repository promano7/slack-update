# Supplied-event NDJSON regression

Run `python3 tests/reference/test-event-ndjson.py` without root. It sources the
reference and directly calls event wrappers with supplied state and arguments.
It never calls `main`, initializes runtime, loads configuration, calculates an
operation result or executes a workflow. Event timestamps come from a fixed
local `date` function, not the host clock.

## Covered output

Fourteen scenarios compare every field of each provisional schema 0 record:

- Nine supplied lifecycles exercise operation/module/action start and completion,
  warning/error records and all stable final codes 0 through 8. Raw action and
  module codes include 100, 20, -1 and 126 and remain distinct from final codes.
- Warning/error text retains escaping, duplicate warnings and order. All warnings
  precede all errors, then exactly one supplied final completion follows.
- Integer sequences advance per record, including a supplied nonzero starting
  sequence. Absent optional fields serialize as null; explicit exit code 0 is
  an integer, distinct from null. Each record occupies one newline-terminated line.
- Two disabled-output cases close descriptor 3, make clock access fail and verify
  no output or sequence change. One leaves operation/sequence unset; the other
  exercises every wrapper and final warning/error emission.
- A descriptor-routing case sends events to a private file while supplied human
  progress/diagnostic text stays on stdout/stderr. It checks emitter routing,
  not logging setup or routing through `main`.

Expected objects and final-code descriptions are authored independently of the
reference's mapping helpers. Eight negative controls reject reordered/duplicate
sequences, wrong scalar types/state/timestamp, a missing field and a blank frame.
Expected output: `Event NDJSON tests: 14 scenarios, 8 negative controls, 0 failures`,
test status 0. Assertion failures return 1. Imported bytecode is disabled and the
private descriptor-routing file is automatically removed.

## Meaning and limits

These are supplied emitter calls, not observed operation traces. In particular,
the code 6/7/8 cases do not establish that startup failures reach event setup or
that `main` emits the illustrated lifecycle before returning those codes.
Final event state follows supplied success/partial/boot flags; this test does
not prove coherence of those flags or repeat the separate result-calculation
tests. Raw numbers are arguments, not classifications of package effects.

Fixed timestamps and incrementing integers demonstrate formatting/local state
only, not real clock integrity, durable once-only recording, native delivery,
drain, cancellation, independent custody or a whole operational trace. Disabled
output checks cover these selected calls; they do not prove general absence of
effects. The normal reference workload is never entered.

The source, executable mode and existing result tests are unchanged. Schema 0
remains provisional; no schema 1 freeze, native scenario closure, authority or
phase entry is introduced. Original raw-20 requirements and all operational
findings remain binding and unresolved in their original scopes.
