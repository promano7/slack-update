# F1-F3 Offline Repair Execution Addendum

Goal: fulfill the already approved package-case design's known-conflict rules.
Spec: docs/superpowers/specs/2026-11-01-json-v1-package-case-design.md in the
isolated repository; original implementation plan and approval remain binding.
Method: owner-selected direct execution, TDD, one fresh-context final review.
Base:4971a197546579b643bb16caeddac892db07d3b9. No new design or execution choice.

## Tasks and expected evidence

1. Add KnownConflictRepair regressions to the existing package-case test. F1
   catches admission short-circuiting known forbidden effects behind raw/criterion
   unknown; F2 catches required raw=-1 behind criterion unknown; F3 catches known
   profile/expected identity, configuration identity and pin contradictions hidden
   by unknown observations. Expected RED: named assertions fail on unchanged
   production, not imports or binding controls. Preserve exact historical tests,
   fixtures and full expected assessment objects. Missing criterion remains pending.
2. Change only admission ordering, known required-absence ordering and conditional
   known declaration-conflict checks in the assessor. Expected GREEN: named
   regressions and all old full assessment expectations pass without rewriting
   those expectations. Run the same eight authorized offline groups after binding
   integration; no native or blanket acceptance dispatcher.
3. Preserve complete preimages of every changed existing input under history/pre801;
   document fix scope in guide, CHANGELOG and roadmap; refresh acyclic current
   input/inventory/migration/dossier bindings with explicit scope/provenance.
4. One fresh-context whole-change review, then a single grouped correction pass
   for material findings with RED/GREEN evidence. No re-review or native claims.
5. Guarded PC delivery based on exact published base, reviewed changed-path-only
   application, retained backups and results. Rehearse in disposable local clones.
   Owner commits/pushes. New pause stays pending until actual return/publication
   and full applicable conditions/effects review. Last qualified pause is800.

## Review Focus

- Known conflict plus unknown raw/criterion/config must preserve both sets.
- No fabricated mismatch for merely unknown or valid disabled/blocked actions.
- Shared-case profile/expectation inconsistencies are data conflicts, not authority.
- Existing authored P01-P28 assessments and all original v0/native inputs stay exact.
- Binding preimages, output collisions and partial-application logs stay truthful.

## Interfaces and verification

Same assess_package_case(result_bytes, profile, expectations, observations) API;
no public schema, dependency, producer, collector or wire-format change.
Use audit791/venv/bin/python with existing jsonschema4.26.0.
Task1/2 share the same frozen records and assessment collections. Task3 consumes
final source/test bytes, so binding refresh follows behavior verification. Task5
consumes the final reviewed finite change list and candidate tree.
