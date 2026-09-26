# Phase 1 step 201 kernel-package-edge fresh target revalidation review

Step 201 consumes the accepted step-200 resume-planning boundary and opens the
first post-pause machine gate. The gate is intentionally limited to a
standalone read-only observation of `vbox-slackcurrent.vbox-slackcurrent.org`.
No package/source staging, network access, repository refresh, package action,
boot action, persistent configuration change, reboot, or runtime scenario
execution is authorized.

## Expired binding versus historical baseline

The step-194 runtime target binding remains expired and is not reusable. Its
accepted package/configuration state is used only as a historical compatibility
baseline for the frozen 6.18.44 to 6.18.45 `kernel-headers` artifact pair.

The new probe therefore does not require the old step-194 boot ID. It records a
fresh boot ID and explicitly reports that the prior binding was not reused. A
successful observation must still match the pre-staging state that makes the
frozen pair usable:

- FQDN `vbox-slackcurrent.vbox-slackcurrent.org`;
- architecture `x86_64` and running kernel `6.18.45`;
- Slackware release string `Slackware 15.0+`;
- pkgtools compatibility path `/var/log/packages` resolving exactly to
  `/var/lib/pkgtools/packages`;
- package-database manifest SHA-256
  `3aeaf9f193f5bc5c92f10ee3c5063be0b17a0e3001eccbc57bc4037c4343e910`;
- exactly `kernel-headers-6.18.45-x86-1` for the configured header package;
- `kernel-generic-6.18.45-x86_64-1` installed, with `kernel-huge` and
  `kernel-modules` absent;
- the accepted `slackpkg.conf` and `mirrors` fingerprints from step 194.

Any drift fails closed and must be reviewed before package staging can be
designed or authorized.

## Standalone revalidation probe

The probe at
`tools/reference/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-probe.sh`
is self-contained and does not require the repository on the VM. It embeds the
accepted controller reference/configuration identities and the frozen artifact
pair:

- predecessor `kernel-headers-6.18.44-x86-1.txz`, SHA-256
  `3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d`;
- target `kernel-headers-6.18.45-x86-1.txz`, SHA-256
  `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`.

The external controller evidence root remains
`/home/promano/slack-update-phase-1-step-196-kernel-package-edge-artifacts` and
must remain unchanged. The probe neither reads nor reacquires those controller
artifacts from the VM.

A successful observation starts with `revalidation_status<TAB>PASS`. The full
output must be returned for the next freeze gate. A later Slackware-current
publication does not invalidate this review because the VM does not consume
live mirror metadata or a candidate set.

## Authorization boundary

Step 201 authorizes only this read-only target revalidation and, after a
successful returned observation, the repository-only fresh-target revalidation
freeze. The local-source builder remains unimplemented, the local-source tree
remains unbuilt, no candidate set is bound, and no artifact copy or package
mutation is authorized.

`machine_action_required=true`, with action type
`read-only-fresh-target-revalidation-observation`. This remains an active chain,
so `pause_safe=false`.

The next stage is
`phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-freeze`.
