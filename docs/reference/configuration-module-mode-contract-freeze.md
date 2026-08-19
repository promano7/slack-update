# Phase 1 optional-module mode contract freeze

Step 122 freezes the optional-module activation contract reviewed at the fresh
step-121 boundary. It does not change the shell reference or the shipped
configuration template. Instead, it records the existing behavior as an
explicit compatibility surface that later conformance work must satisfy.

## Frozen contract

The contract contains a complete 15-row matrix: five optional modules multiplied
by the three supported activation modes.

The five optional modules are Flatpak, SBo, ELF, boot, and Cinnamon. Their
configuration keys remain `flatpak.mode`, `sbo.mode`, `elf.mode`, `boot.mode`,
and `cinnamon.mode`, and every shipped default remains `auto`.

For every reviewed module:

- `enabled` keeps strict requirement probing. If mandatory requirements needed
  by an applicable module are unavailable, the module reports an error.
- `disabled` bypasses requirement probing and never executes the module.
- `auto` probes conditionally and executes only when the existing availability
  and applicability conditions are satisfied. Unavailable or irrelevant
  optional software remains non-fatal.

The contract does not force an otherwise irrelevant module to execute in
`enabled` mode. Existing module applicability rules remain part of the frozen
reference behavior; `enabled` makes requirements strict once that module is
applicable.

## Boot specialization

The boot module retains the stricter safety specialization already reviewed in
step 121. In `auto`, only validated supported preparation paths may be selected.
In `disabled`, boot preparation is bypassed. In `enabled`, an applicable boot
preparation that lacks its mandatory supported path is an error. No existing
initrd, ELILO, or GRUB safety gate is weakened or made configurable by this
freeze.

## Compatibility boundary

The freeze is bound to:

- the exact step-121 mode-boundary policy;
- the unchanged reference implementation accepted at steps 120 and 121;
- the unchanged shipped configuration template;
- the exact TSV mode contract stored with this step.

Slackware 15.0 and Slackware-current remain mandatory targets. The step is
repository-only, has no Slackware package-repository-state dependency, performs
no machine action, and authorizes no source or configuration-template change.

A successful step 122 advances only to
`phase-1-configuration-module-mode-conformance-review`. That next stage may test
the frozen contract against the existing implementation, but it must not silently
reinterpret or expand the contract frozen here.
