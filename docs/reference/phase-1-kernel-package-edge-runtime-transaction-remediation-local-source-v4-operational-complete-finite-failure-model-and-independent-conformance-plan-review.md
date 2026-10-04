# Step 326: complete declared finite failure model and independent conformance plan

325 confirmed at prefix 0c5caa7: complete ordered1004 PASS, first successful push,
clean tree and matching HEAD/origin. Full commit ID unknown. Preserve its prepared
flags and all development failures.318 remains the last confirmed strong safe pause.

This review closes the declared finite model contract across service, admission,
launch, bootstrap, worker, target, recovery and publication. It does not close the
actual transitive graph or operational proof. 31 macro-event boundaries,
23 hazard types, 8 forbidden actions and 14 prerequisite gates
produce 2938 exact declared cases: golden path, every single
known-failure/unknown boundary, every hazard/forbidden insertion at every boundary,
every single missing gate, budgets0..8 and every pair of boundary failure outcomes.
Completeness is limited to these named finite families. Arbitrary schedules, every
internal syscall/native effect and real concurrency remain outside this model.
The actual selected implementation must be refined into the model or the model
extended before any implementation freeze. A macro event never asserts atomicity.

Known failure means independently proven no additional effect at that boundary;
nonzero status alone does not establish this. Unknown claim, launch slot, spawn,
authentication, guard, clock, revocation, child or partial target state stays pending.
No replay, relaunch, repin, guard reacquire, new grant or blind restore follows.
Raw status and original failure remain separate from recovery/publication outcome,
including raw0 with an independently detected stream/effect failure. Empty install
raw0/20 requires the325 full-selector/no-effect proof; mandatory upgrade raw20 fails.

Stage0 uses only bounded read/auth/close in memory; stage1 arms traps. The324 barrier
acquires the outer native writer guard and fresh original before stage2 owned writes;
stage3 verifies backups before target changes. Successful forward execution or any
failure enters permanent forward stop before recovery. Original323 finite retained
rights/budget and known guard/identity/children are required. Every attempted recovery
action spends budget before its outcome, without refund or retry. Drain first.
A proven unchanged-target branch can verify the original without a backup that was
never created; it cannot perform restoration writes. Unknown owned binding/record
artifacts may be retained while separately known target state permits safe original
restoration. Unknown target mutation never becomes a known phase by observation.

Full original verification and target evidence precede release. No target writes or
refresh follow release. Publication uses separately controlled captured closed data,
exclusive record creation and supported durability, then separate last receipt and
handoff. No pair atomicity or self-receipt hash. Unknown/partial/occupied/lost ACK
retains artifacts and scoped pending obligations without republishing or target grant.
Intentional retained artifacts are described in the final evidence; no global host
absence/closure is inferred from a finite model terminal state.

The independent conformance plan has 52 required-not-run entries: 26
per Slackware15.0 and -current. Every actual implementation/version/boot/test-run
binding and result is null. Require fresh separately authorized tests after actual
implementation selection and full graph closure. Bind original raw observations,
independent verifier/oracle, positive/negative fault controls, native writers/locks,
time/revocation/concurrency/crash/children, exact raw selectors/effects/restoration,
and separate publication origin/durability. The same selector or cleanup logic
cannot be its own sole oracle; harness PASS, signed self-report or a synthetic
evidence index never proves conformance. One platform never proves the other.

All six325 future proofs plus six new refinement/conformance/closure proofs, seven
capabilities and ten cross obligations remain required-not-proven.325 actual graph
and successor entry are still unclosed/unselected. No reference main/oldv2/source,
service, ledger, backend, selector, package/config/boot, namespace, child, restore
or publication operation occurs.326 authorizes repository/private validation only.
327 crossclosure and328 conditional repository integration-design freeze/pause
follow accepted returns. Production/Phase2 closed; Phase1/kernel edge incomplete.
