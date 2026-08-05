# Reference acceptance scenarios

These scripts exercise the shell reference on real Slackware installations. They
are not mock tests and must not be run on a production host merely to validate a
change.

Use a disposable virtual machine snapshot, or an equivalently recoverable test
installation, for every scenario that invokes `--apply`. Keep Slackware 15.0 and
Slackware-current evidence separate.

## Fully updated system with no package changes

The first scenario isolates the core Slackware package path. Its generated
configuration disables Flatpak, SBo, ELF, Cinnamon, and boot preparation because
those modules have dedicated acceptance cases elsewhere in the matrix.

The scenario performs these steps:

1. Verify the declared Slackware target and required commands.
2. Capture host metadata, the installed-package database, and selected boot files.
3. Run the real `--check --json` operation and require no available updates.
4. Run the real `--apply --json` workflow with `slackpkg update`, `install-new`,
   and `upgrade-all` in non-interactive mode.
5. Require stable exit code `0`, no reboot guidance, valid and equal package
   snapshots, no ABI/kernel/critical-package changes, and no structured errors.
   Raw `install-new` and `upgrade-all` statuses may be `0` or the Slackware 15.0
   no-package result `20`; `slackpkg update` must return `0`.
6. Confirm that `/var/log/packages`, `/boot/initrd.gz`, and
   `/boot/grub/grub.cfg` are unchanged.
7. Produce a private `.tar.gz` evidence archive and SHA-256 sidecar. When run through `sudo`, publish both files as the invoking user with mode `0600` while keeping the expanded evidence directory root-only.

Run on Slackware 15.0:

```bash
sudo bash tests/acceptance/reference/test-no-updates.sh \
    --target slackware-15.0 \
    --execute-apply
```

Run on Slackware-current:

```bash
sudo bash tests/acceptance/reference/test-no-updates.sh \
    --target slackware-current \
    --execute-apply
```

Slackware 15.0 passed this scenario on 2026-07-28. The reviewed run returned
stable code `0` for both check and apply, preserved 1,594 package records,
retained raw `slackpkg` no-package statuses `20`, produced empty package and
boot diffs, and created evidence archive SHA-256
`5a784cd6d830ac271cc3aad02ed89f2e00c2afd63c88f90aabb74b0a81b0b20b`.
The sanitized acceptance record is stored in
`tests/fixtures/reference/acceptance/no-updates/slackware-15.0-accepted.json`.

Slackware-current passed this scenario on 2026-07-28. The reviewed run returned
stable code `0` for both check and apply, preserved 2,035 package records,
retained raw `slackpkg` no-package statuses `20`, produced empty package and
boot diffs, and created evidence archive SHA-256
`ba0c1264d57df5acf6bee843391113327736683ede36ec3d708d58ca174a2976`.
The sanitized acceptance record is stored in
`tests/fixtures/reference/acceptance/no-updates/slackware-current-accepted.json`.

Invoke the scenario through `bash` as shown above. This avoids depending on executable bits being preserved by the ZIP extraction or shared-folder filesystem.

By default, evidence is stored below:

```text
/var/tmp/slack-update-acceptance/no-updates/
```

The default parent directory is traversable, the archive and sidecar are owned by the `sudo` caller, and the expanded timestamped directory remains accessible only to root. The harness also prints the stable result and individual Slackware command statuses when structured validation fails.

The scenario prints a single-line `Copy evidence command:` after creating the
archive. Prefer that exact line when a host, terminal, or chat copy operation may
insert invisible paragraph separators into multiline shell blocks.

For the `promano` acceptance account, the equivalent generic fallback is one
single shell line:

```bash
archive=$(sudo sh -c 'ls -1t /var/tmp/slack-update-acceptance/no-updates/*.tar.gz 2>/dev/null | head -n 1'); group=$(id -gn promano); sudo install -o promano -g "$group" -m 0600 "$archive" "/home/promano/$(basename "$archive")" && sudo install -o promano -g "$group" -m 0600 "$archive.sha256" "/home/promano/$(basename "$archive.sha256")"
```

The reference and host-metadata capture follow `/var/log/packages` when it is a
command-line compatibility symlink to the real `pkgtools` database. The reference
also preserves raw `slackpkg` no-package status `20` for `install-new` and
`upgrade-all` while normalizing it to successful action semantics. They do not
follow package-record symlinks stored inside that database. `host.txt` records
both the configured path and its resolved destination for diagnosis.

Review the evidence before publishing it. Preserve `summary.txt`,
`assertions.log`, the JSON results, diagnostics, package and boot comparisons,
the generated configuration, and `host.txt`. Remove or replace host-specific
mirror URLs or other identifying values when creating sanitized repository
fixtures.

## Normal official-package update

`test-normal-update.sh` stages the next acceptance scenario. It is suitable for
an explicitly recoverable physical host as well as a disposable VM, but apply
mode performs real package and potentially boot changes.

Always begin with the non-destructive preflight:

```bash
sudo bash tests/acceptance/reference/test-normal-update.sh \
    --target slackware-current \
    --preflight
```

Preflight first refreshes package metadata with non-interactive `slackpkg update`,
then runs `slackpkg install-new` and `slackpkg upgrade-all` with dialog output
disabled, batch mode enabled, and a negative default answer. It stores all raw
output, extracts candidate package filenames, classifies kernel and critical
packages, and proves that neither `/var/log/packages` nor the observed initrd and
GRUB configuration changed. Apply repeats this refresh-and-classify boundary
immediately before authorization, preventing stale local metadata from bypassing
the kernel safety gate.

The Slackware-current preflight captured on 2026-07-29 is accepted. It reported
ten `upgrade-all` candidates, no `install-new` candidates, no kernel candidates,
no configured critical candidates, and no package-database or boot-state changes.
The sanitized record is stored at
`tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-accepted.json`.
The confirmed physical-host apply later refreshed the same candidate digest,
returned stable code `0`, upgraded exactly those ten packages, retained 2,039
package records, detected the expected ABI change through PipeWire, and left
kernel, initrd, and GRUB state unchanged. Its archive SHA-256 is
`00679a69d9c40033db74b4a73525651a42d0d72b293ec536d1181e87e2ab7e66`, and
the reviewed record is stored at
`tests/fixtures/reference/acceptance/normal-update/slackware-current-apply-reviewed.json`.
The transaction is accepted as package and boot evidence, but the run exposed 27
`.new` files reaching slackpkg's interactive post-install menu with the generic
batch answer `y`. The reference therefore now disables post-install processing,
keeps current configurations, enumerates pending regular `/etc/*.new` files, and
requires revalidation of that hardened policy during the next available update.
The accepted candidate-set SHA-256 remains `a8a608d8aac53c0d9f027622c01df4f794e94e8dd4586764b8d2503f9b94e45d`.

The 2026-08-03 Slackware-current preflight is rejected as authorization
evidence. The raw upgrade probe contained 56 package filenames, but the
normalized file contained 55 because
`kernel-headers-6.18.41-x86-1.txz` used the exact Slackware `x86`
architecture tag that the extractor did not yet accept. The corrected
reconstruction contains one install-new candidate, 56 upgrade candidates, 57
total candidates, two configured kernel candidates, and SHA-256
`d9199fcf6c5cd8c59b87b1bde9a955df2c55d0ac84f6dab37ed8e4c1830dcaf1`.
Candidate extraction and portable evidence sidecars are fixed, but a fresh
preflight is required; never reuse the reconstructed digest for apply because
Slackware-current metadata can change. The sanitized diagnostic is
`tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-20260803-parser-diagnostic.json`.

The corrected rerun at `2026-08-03T19:49:43Z` is accepted as classification
evidence. It passed all six assertions, preserved the installed-package database
and observed initrd/GRUB state, and confirmed the exact reconstructed set: one
`install-new`, 56 upgrades, 57 total candidates, two configured kernel
candidates, no configured critical candidates, and candidate-set SHA-256
`d9199fcf6c5cd8c59b87b1bde9a955df2c55d0ac84f6dab37ed8e4c1830dcaf1`.
The portable archive SHA-256 is
`33a0d6eb20dfc777c4c5f8a0172f8344aab03a20ffd130d0fe95753ffce57cbc`.
The sanitized accepted record is
`tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-20260803-accepted.json`.
This acceptance does not authorize apply because the set contains
`kernel-generic-6.18.41-x86_64-1.txz` and
`kernel-headers-6.18.41-x86-1.txz`.

### Slackware-current kernel boot-layout preflight

Run the dedicated discovery stage on the same Slackware-current host before any
kernel apply review:

```bash
sudo bash tests/acceptance/reference/test-current-kernel-boot-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 d9199fcf6c5cd8c59b87b1bde9a955df2c55d0ac84f6dab37ed8e4c1830dcaf1 \
    --confirm-target-kernel 6.18.41
```

This preflight is non-destructive. It validates that modern Slackware-current
uses the monolithic `kernel-generic` package layout rather than the Slackware
15.0 `kernel-generic`/`kernel-huge`/`kernel-modules` split, proves that the
installed generic package owns the active module tree and running kernel image,
confirms exact repository records plus the target versioned image, and validates
the active GRUB configuration with `grub-script-check`. Package and boot
fingerprints are compared before and after inspection.

Two boot modes are supported. `mkinitrd-managed` requires a safe readable
`/etc/mkinitrd.conf`, a non-empty regular `/boot/initrd.gz`, and an explicit
kernel-version transition. `direct-generic-no-initrd` requires both artifacts
to be absent, `/boot/vmlinuz-generic` to resolve to the package-owned
`/boot/vmlinuz-VERSION`, and the running `BOOT_IMAGE` to appear in the active
GRUB configuration. Mixed or unsafe states fail closed.

The first real-system run at `2026-08-03T20:17:52Z` is diagnostic only. It
passed 16 checks and failed three because the initial implementation assumed an
initrd-managed `vmlinuz-generic-VERSION` layout. The host actually used the
coherent direct mode above; package and boot state remained unchanged. Archive
SHA-256 is
`8b7d495f8a1466ef308dcb8664e31df756940695b6ed345834fad4ab1f5f3727`,
and the sanitized rejected record is
`tests/fixtures/reference/acceptance/kernel-boot/slackware-current-direct-generic-preflight-20260803-diagnostic.json`.

The corrected real-system rerun at `2026-08-03T20:40:08Z` passed all 20
checks with no failures. It accepted `direct-generic-no-initrd`, preserved the
package database and boot state byte-for-byte, and published archive SHA-256
`ed7462e70496cf38a52c211f3d5945438e5f1bad5b8d8eaa7b90079540381967`.
The archive and portable sidecar were copied directly to `/home/promano` and
verified there. Its sanitized accepted record is
`tests/fixtures/reference/acceptance/kernel-boot/slackware-current-direct-generic-preflight-20260803-accepted.json`.

Discovery intentionally remains `apply_ready=false` and
`apply_authorized=false`. The reference engine now understands the accepted
layout: it suppresses initrd only for a validated direct generic boot, requires
the post-update package-owned `vmlinuz-VERSION` symlink target and module tree,
and validates that the staged GRUB configuration references that kernel before
atomic replacement. This code-only policy does not authorize package changes.
A separate transaction preflight must inspect the exact downloaded target
package and its install script before any fixture may mark this candidate digest
`apply_ready=true`. Until then, do not execute apply.

### Slackware-current exact kernel-package and geninitrd policy preflights

The step 37 inspection passed on `pcold-slack` with package SHA-256 `b588e9e74258baaf2d5e05a1731981cb679f5665d50a3a91d9f02219c4a8024a` and evidence SHA-256 `d4f455dafb6783dc96e8cf45c45d00ef4e54d1e9b5dc2ae8e05b8db166b50888`. Its copied `doinst.sh` was not executed and exposed one guarded `usr/sbin/geninitrd` call. The accepted package record is stored at `tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-package-preflight-20260803-accepted.json`.

The original step 37 command was:

```bash
sudo bash tests/acceptance/reference/test-current-kernel-package-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 d9199fcf6c5cd8c59b87b1bde9a955df2c55d0ac84f6dab37ed8e4c1830dcaf1 \
    --confirm-target-kernel 6.18.41
```

This stage may write only to the Slackpkg download cache and its private evidence directory. It first verifies the accepted normal-update and boot-layout records and requires the live Slackpkg metadata to expose exactly `kernel-generic-6.18.41-x86_64-1.txz`. It invokes `slackpkg download kernel-generic`, resolves exactly one regular cached package, records its SHA-256, rejects unsafe or duplicate archive members, requires `boot/vmlinuz-6.18.41` plus target module files, and rejects any embedded initrd or foreign module version.

`install/doinst.sh` is read from the archive into evidence but never run. Its shell syntax must be valid, package mutation, direct `mkinitrd`, GRUB installation, reboot, and shutdown commands are forbidden, exactly one symlink transition from `vmlinuz-generic` to the target versioned image must be recognizable, and exactly one guarded `geninitrd` invocation must require the next host-policy stage. GRUB discovery writes a generated configuration only below the evidence directory and validates it with `grub-script-check`. Before/after package and active-boot fingerprints must match. Every archive is copied with its portable `.sha256` directly to `/home/promano`; regardless of success, the result remains `apply_ready=false` and `apply_authorized=false` pending manual review.

Step 38 passed on `pcold-slack` with evidence SHA-256 `3b807d2d00fce2b9986308f5cd252d97b483d4b8f1a397fad7d6f047b20421fd`. The accepted record is stored at `tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-policy-preflight-20260803-accepted.json`. It confirmed an enabled `mkinitrd_command_generator.sh` path, automatic GRUB update, transition `direct-to-generated-initrd`, and two executable pre-install hooks whose exact paths and SHA-256 digests must remain stable.

Step 39 passed on the same host with evidence SHA-256 `95eec7f57d4ff9d3f254830428d5382a155f890b9e57553b71fbd4f661e30ebf`. Its accepted record is `tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-dkms-hook-preflight-20260803-accepted.json`. DKMS reported zero installed rows, and both reviewed hooks were accepted as explicit no-ops for this host state.

Step 40 was executed on the same host with this command:

```bash
sudo bash tests/acceptance/reference/test-current-geninitrd-command-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 d9199fcf6c5cd8c59b87b1bde9a955df2c55d0ac84f6dab37ed8e4c1830dcaf1 \
    --confirm-target-kernel 6.18.41
```

The command preflight executes the installed generator only in command-output mode for the running kernel. It requires exactly one safe `mkinitrd` argument vector, projects that vector to the reviewed target kernel and versioned initrd, and never executes either the generated or projected command. Package and boot-sensitive state must compare byte-for-byte before and after inspection; all results retain `apply_ready=false` and `apply_authorized=false`.

Step 40 passed on `pcold-slack` with 11 assertions and evidence SHA-256 `391c56d5aa3d5e8cfa5eba2a259e0c78964d5825d10ce1cabd0124d7ef435814`. The accepted record is `tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-command-preflight-20260803-accepted.json`. It preserves the exact projected `mkinitrd` vector for `6.18.41`, the versioned output `/boot/initrd-6.18.41.img`, all 18 reviewed modules, unchanged host state, and explicit no-execution/apply denial.

The reviewed GenInitrd flow would still run `/usr/sbin/update-grub` from the package post-install path because the active `/etc/default/geninitrd` contains `AUTO_UPDATE_GRUB=true`. An environment-only override is not sufficient: the installed setup script sources the active configuration before applying shell defaults. Run step 41 to prove the safe ownership strategy without editing the host policy:

```bash
sudo bash tests/acceptance/reference/test-current-geninitrd-grub-ownership-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 d9199fcf6c5cd8c59b87b1bde9a955df2c55d0ac84f6dab37ed8e4c1830dcaf1 \
    --confirm-target-kernel 6.18.41
```

The GRUB-ownership preflight creates only an evidence-local copy of `/etc/default/geninitrd` with the single change `AUTO_UPDATE_GRUB=false`. It validates source-order and guard placement, emits a twelve-step transaction plus five recovery boundaries, and selects a future temporary atomic policy override so package post-install may generate the versioned initrd while Slack-Update remains the sole owner of validated atomic GRUB replacement. It never installs the staged policy, runs package tools, generates an initrd, or invokes either GRUB command. Every result remains `apply_ready=false` and `apply_authorized=false`.

Step 41 passed with 11 assertions and archive SHA-256 `246a54dd81c1db6ce2e7d04cb5d6e4739249e4a2f0483edcb9c7a5f1e0e93ad3`. Its accepted record is `tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-grub-ownership-preflight-20260803-accepted.json`. Step 42 implements the accepted temporary override in the reference engine: exact one-line staging, same-directory backup, atomic activation, immediate post-package restoration, cleanup restoration, concurrent-change refusal, retained recovery backup, and structured diagnostics.

Step 43 adds a synthetic, non-executable post-package contract in `slackware-current-geninitrd-post-state-synthetic.json`. It validates the target package record, versioned kernel, module tree, generated versioned initrd, named initrd link, continued absence of legacy initrd configuration, and the requirement that generated GRUB reference both the target kernel and initrd. It performs no package or boot mutation and keeps `apply_ready=false` plus `apply_authorized=false`. The next real-system action is a fresh normal-update preflight because Slackware-current candidate metadata may have changed.

This preflight requires the accepted normal-update, boot-layout, exact-package, and GenInitrd policy records. It verifies that the live executable hook set is exactly `dkms-bcachefs` and `dkms-nvidia` with the reviewed digests, rejects symlinks, unexpected executables, non-root ownership, group/world writable modes, syntax errors, and content drift, then copies the hook bodies with mode `0600` into private evidence. It records static commands, referenced paths, and shell features without shell evaluation. The only DKMS commands executed are `dkms --version` and `dkms status`; source trees, build state, running modules, and target-kernel paths are inventoried without running any build, install, remove, or autoinstall action. Package and DKMS-sensitive state must compare byte-for-byte before and after. The result always remains `apply_ready=false` and `apply_authorized=false` pending manual review.


Slackware 15.0 passed the non-boot-kernel branch on 2026-08-01. An initial
preflight reported 199 candidates, including `kernel-generic`, `kernel-huge`,
and `kernel-modules`. Those three boot-kernel packages were deliberately
deferred through the Slackpkg blacklist for a later dedicated kernel scenario.
The reviewed preflight then reported 12 `install-new` candidates, 184
`upgrade-all` candidates, five configured critical candidates, zero boot-kernel
candidates, and candidate-set SHA-256
`baaf89bb3e61662d7bbb10223e2c26b9adc98c443eacdf8273319a6818951410`.
Its archive SHA-256 is
`4774070e7a9173f6486d560e54d7efce8580b76a92449e1698e7449d8557e73c`.

The corresponding real apply returned stable code `4`, with
`success=true`, `partial=false`, `reboot=recommended`, and `boot_safe=true`.
It installed all 12 new packages, changed all 184 upgrade candidates, moved the
package database from 1,554 to 1,566 records, and left the observed initrd and
GRUB state unchanged. The hardened `-postinst=off` policy was exercised on the
real system: no interactive post-install menu was opened, active configurations
were preserved, and 45 regular `/etc/*.new` files were reported for later
review. The broad `kernel_changes=true` field reflected updates to
`kernel-firmware` and `kernel-source`; the explicit `initrd_required` and
`grub_required` fields remained false, so boot preparation and stable code `5`
were not applicable. The original acceptance validator incorrectly conflated
those two concepts and produced one false-negative assertion; the corrected
validator keys boot requirements from the explicit boot fields and accepts the
reviewed run. The apply archive SHA-256 is
`c670a5077f9efb5d64470b46b537754634913c0f1deccd4fcef707c9385339ed`.

The sanitized records are stored at:

```text
tests/fixtures/reference/acceptance/normal-update/slackware-15.0-preflight-accepted.json
tests/fixtures/reference/acceptance/normal-update/slackware-15.0-apply-accepted.json
```

Do not run apply mode until the preflight archive has been reviewed. Apply mode
requires the exact current hostname:

```bash
sudo bash tests/acceptance/reference/test-normal-update.sh \
    --target slackware-current \
    --execute-apply \
    --confirm-hostname "$(hostname)" \
    --confirm-candidates-sha256 a8a608d8aac53c0d9f027622c01df4f794e94e8dd4586764b8d2503f9b94e45d
```

When preflight reports kernel candidates, apply remains blocked unless the
additional `--allow-kernel-update` option is supplied. On Slackware-current, a
matching accepted boot-layout record with `apply_ready=true` is also mandatory;
its archive digest must be supplied through
`--confirm-kernel-boot-preflight-sha256`. Configured critical packages are
independently blocked unless `--allow-critical-update` is supplied.
The refreshed `all.candidates.txt` must also match the explicitly supplied
`--confirm-candidates-sha256`; any candidate-set change blocks apply before package
installation. `install-new` and `upgrade-all` run with `-postinst=off`, so the
active configuration files remain in place and pending regular `/etc/*.new` files
are listed in human and structured output for a later explicit `slackpkg new-config`
review. Flatpak, SBo, ELF, and Cinnamon are disabled for this scenario. Boot preparation stays in `auto` mode;
a detected kernel change must produce validated initrd and GRUB updates and the
stable reboot-required status.

Every run prints a one-line `Copy evidence command:` and a destination-side `Verify evidence command:`. Sidecars contain only the archive basename. For the `promano` account,
the generic fallback for this scenario is:

```bash
archive=$(sudo sh -c 'ls -1t /var/tmp/slack-update-acceptance/normal-update/*.tar.gz 2>/dev/null | head -n 1'); sudo install -o promano -g "$(id -gn promano)" -m 0600 "$archive" "/home/promano/$(basename "$archive")" && sudo install -o promano -g "$(id -gn promano)" -m 0600 "$archive.sha256" "/home/promano/$(basename "$archive.sha256")"
```

## Deferred Slackware 15.0 boot-kernel preflight

`test-kernel-boot-preflight.sh` is the first stage of the dedicated kernel-update
scenario for the temporarily blacklisted `kernel-generic`, `kernel-huge`, and
`kernel-modules` packages. Run it only while those three package names remain in
`/etc/slackpkg/blacklist`:

```bash
sudo bash tests/acceptance/reference/test-kernel-boot-preflight.sh \
    --target slackware-15.0
```

The preflight is non-destructive. It captures the package database and selected
boot artifacts before and after inspection, classifies BIOS versus UEFI,
identifies probable LILO, ELILO, GRUB, ambiguous, or unknown boot-loader state,
records relevant command availability and configuration directives, summarizes
safe scalar values from `/etc/mkinitrd.conf` or records availability of the
official Slackware command generator, and preserves installed plus
repository kernel records from Slackpkg metadata. It never removes blacklist
entries, invokes `slackpkg upgrade`, runs `mkinitrd`, installs LILO, copies ELILO
images, or regenerates GRUB.

The current shell reference supports automatic mkinitrd plus GRUB preparation.
A reported `reference-unsupported` LILO or ELILO path is an expected discovery,
not permission to proceed: review the evidence and design the applicable safe
adapter or manual acceptance boundary before removing the kernel blacklist.
Every run publishes a private archive and SHA-256 sidecar under
`/var/tmp/slack-update-acceptance/kernel-boot-preflight/` and prints a one-line
copy command for the invoking user.

### ELILO generator preflight

Real Slackware 15.0 evidence classified the deferred kernel path as UEFI plus
ELILO. The active `elilo.conf` uses the relative `vmlinuz` and `initrd.gz`
files in `/boot/efi/EFI/Slackware/`. The initrd copy matches `/boot/initrd.gz`.
The generic `/boot/vmlinuz` alias resolves to `vmlinuz-huge-5.15.19` and does
not match the EFI kernel copy, so that alias is not treated as the authoritative
ELILO source. `/etc/mkinitrd.conf` is absent, and kernel apply remains blocked.

Run the second non-destructive stage while all three boot-kernel packages remain
blacklisted:

```bash
sudo bash tests/acceptance/reference/test-elilo-generator-preflight.sh \
    --target slackware-15.0
```

This stage runs `/usr/share/mkinitrd/mkinitrd_command_generator.sh -k` for the
currently running kernel only to capture stdout. It also inventories every
top-level `/boot/vmlinuz*` regular file and symlink, compares their resolved
content with the EFI `vmlinuz` copy, collapses aliases resolving to the same
file, and requires one unique versioned source whose filename identifies the
running generic or huge kernel. It never evaluates the generator output, never
invokes `mkinitrd`, never runs `eliloconfig`, and never changes packages,
blacklist entries, `/boot`, or the EFI system partition. A successful result is
still evidence for adapter design, not authorization to remove the kernel
blacklist.

The accepted third run mapped the EFI image uniquely to
`/boot/vmlinuz-generic-5.15.19`, matched the running release, matched the active
initrd copy, and passed all 20 assertions. Its archive SHA-256 is
`0eb55c3bda5a4167f4ef9fc19aede6e2029985d5dd325416e78e00ba85d57480`.

### ELILO kernel transaction preflight

Run the third stage while the same three kernel packages remain blacklisted:

```bash
sudo bash tests/acceptance/reference/test-elilo-kernel-transaction-preflight.sh \
    --target slackware-15.0
```

This stage refreshes Slackpkg metadata and reads `/var/lib/slackpkg/pkglist` to
resolve complete common repository records for `kernel-generic`, `kernel-huge`,
and `kernel-modules`. Slackpkg may retain more than one historical patch kernel,
so the selector prefers the `patches` repository and chooses the newest complete
version and build using version ordering. It rejects missing members, duplicate
records, mixed package sets, unsafe values, or an ambiguous newest candidate. It
records the exact selected three-record SHA-256, verifies that the running
generic kernel and EFI copies still match the accepted source, checks
conservative free space on `/boot` and the EFI system partition through portable
`df -Pk` output, and writes a planned `elilo.conf` that selects versioned kernel
and initrd basenames.

The plan keeps the current EFI `vmlinuz`, `initrd.gz`, and original `elilo.conf`
as rollback artifacts. Future activation is defined as an atomic configuration
switch only after new versioned files have been generated and verified. The
preflight never removes blacklist entries, upgrades packages, runs `mkinitrd`,
runs `eliloconfig`, changes firmware variables, or replaces active boot files.
Every result remains `apply_authorized=false` until its evidence is reviewed.

The first real run observed complete `patches` sets for `5.15.208` and
`5.15.209` and exposed the former one-candidate assumption plus an incompatible
`df -PB1 --output=avail` invocation. It passed 22 assertions, failed five
planning assertions, changed no system state, and did not authorize apply. Its
reviewed archive SHA-256 is
`3780c922fffab042ae265b5a54286d7ce22379f4774f174326cec81fed406259`.
The corrected real-system run selected `5.15.209-1` from `patches`, produced
candidate digest `10ea616935d628a97ba2bc9cec0d5e57fdebeefe54d2768800ef3a30c3a4c5db`,
passed all 27 assertions, and changed no system state. Its accepted evidence
archive SHA-256 is
`d951cd9eb24b54b1b8c20262ac12c59b00a042c7426c883dd4af246076d482bb`.



### ELILO kernel transaction apply

Run only after the corrected transaction preflight has been reviewed, while the
VM snapshot and the three exact blacklist deferrals remain available:

```bash
sudo bash tests/acceptance/reference/test-elilo-kernel-transaction-apply.sh \
    --target slackware-15.0 \
    --execute-apply \
    --confirm-hostname vbox-slack15.vbox-slack15.org \
    --confirm-candidate-sha256 10ea616935d628a97ba2bc9cec0d5e57fdebeefe54d2768800ef3a30c3a4c5db \
    --confirm-target-kernel 5.15.209
```

The apply stage refreshes metadata and fails before modification unless the
hostname, target version, and exact three-record digest still match. It removes
only one exact active blacklist line for each of `kernel-generic`,
`kernel-huge`, and `kernel-modules`, uses `slackpkg download` to populate the
verified package cache, restores the blacklist byte-for-byte, and installs the
new packages with `installpkg` so version `5.15.19` remains installed. It then
captures but never evaluates the official generator output, builds a versioned
initrd, verifies versioned copies in the EFI partition, and atomically replaces
only `elilo.conf` after all staged files are complete.

The resulting configuration sets label `vmlinuz` as the explicit default for
the new versioned kernel and retains the current EFI `vmlinuz` plus `initrd.gz`
under label `oldkernel`. It does not run `eliloconfig`, does not replace
`elilo.efi`, and does not modify EFI firmware variables. Package installation is
not automatically reversible; failures after package installation retain the
old active boot files and require evidence review before any retry. A successful
run requires a reboot test and separate post-reboot evidence before old packages
or rollback files may be removed.

The first real apply attempt stopped safely at the download boundary. Slackpkg
returned `20` because the former argument `^kernel-(generic|huge|modules)$` was
processed as one unmatched pattern. No package was downloaded or installed, the
blacklist was restored byte-for-byte, and neither initrd nor ELILO was changed.
The reviewed archive SHA-256 is
`e3a854a2ed5479e9906ff3dd72592bf39439e55e20d1cc992a42eadf05f14996`.
The corrected transaction performs three exact package-name downloads, records
one raw status per name, stops at the first failure, and resolves only the
approved version/build/path from `/var/cache/packages` before `installpkg` can
run.

The corrected real transaction completed on 2026-08-01 with 31 passing
assertions and no failures. It installed `5.15.209` alongside `5.15.19`, built
and verified the versioned generic initrd, atomically activated the versioned
ELILO entry, retained `oldkernel`, and preserved the original blacklist. The
reviewed archive SHA-256 is
`93c58c1508085f3dffaa182eac52fb49c72e6222d75b49c79af4309713f0ac95`.
After reboot, `uname -r` reported `5.15.209`, `/proc/cmdline` identified
`\EFI\Slackware\vmlinuz-generic-5.15.209`, and the active configuration
still selected label `vmlinuz` while retaining label `oldkernel`. The
transaction is accepted; cleanup of the previous packages and rollback files
remains a separate, explicitly gated operation.

### ELILO oldkernel retention preflight

Phase 1 step 30 defines the retention boundary without authorizing cleanup. The
accepted transaction reboot counts as the first successful boot. The rollback
packages, `oldkernel` entry, and legacy EFI files must remain available for at
least seven days after the accepted reboot review, and one later boot must start
after that review with kernel `5.15.209` still active.

Run the non-destructive preflight as root:

```bash
sudo bash tests/acceptance/reference/test-elilo-oldkernel-retention-preflight.sh \
    --target slackware-15.0
```

The script loads the accepted transaction record, captures the current boot ID
and boot start epoch, verifies that the active ELILO entry uses the versioned
`5.15.209` kernel and initrd, verifies that `oldkernel` still maps the preserved
`5.15.19` files, and requires exactly three active plus three rollback package
records. It also compares package logs to inventory paths shared by old and new
kernel packages. Those shared paths require the later cleanup apply to reinstall
the exact active package set after removing the old records. The configured
`/var/log/packages` path may be Slackware's compatibility symlink; the preflight
resolves it canonically, records the resolved destination, and rejects broken or
non-directory destinations plus package-record symlinks inside the database.
Before/after immutability is reported only when all four state files were
captured as readable regular files. Cleanup eligibility is calculated only
after those final comparisons, so any capture or comparison failure forces the
result to remain ineligible.

The generated plan is ordered: separately review and authorize apply; download
and revalidate the exact active package archives; archive `elilo.conf` and all
rollback artifacts; remove only the exact old package records; reinstall the
active package set; verify the active module tree and versioned boot files;
atomically remove the `oldkernel` stanza; and only then delete unreferenced legacy
files. The preflight never invokes package installation or removal commands,
never edits ELILO, and never deletes files. It can report eligibility, but every
result remains `cleanup_authorized=false`.

Every run publishes a private archive plus SHA-256 sidecar and prints one command
that copies both files directly to `/home/promano` with `promano` ownership. The
sidecar records only the archive basename, and the script prints a second command
that verifies the copied pair from `/home/promano` with `sha256sum -c`.

The corrected baseline run on 2026-08-01 passed all 24 assertions with archive
SHA-256
`5afedf07c964369e19ed7ba28f89f2c92caf50a1f46bba813f5652baedc7c3b4`.
It observed a later boot starting at `2026-08-01T20:19:42Z`, preserved exactly
three active plus three rollback package records, and proved package and boot
state unchanged. It correctly remained `cleanup_eligible=false` because the
seven-day window was not met. The next eligibility run must occur no earlier
than `2026-08-08T19:51:00+02:00`; cleanup remains unauthorized regardless of
preflight eligibility.

### Kernel cleanup plan contract

Phase 1 step 31 is intentionally plan-only and has no real-system apply command.
`tools/reference/kernel-cleanup-plan-reference.sh` consumes a schema-1 inventory
and emits deterministic JSON while preserving `cleanup_authorized=false` and
`apply_permitted=false`. It validates exact active and rollback boot-package
triples, active package archive coverage, module trees, canonical package-database
metadata, and backend-specific boot state.

ELILO plans stage and atomically activate removal of the `oldkernel` stanza only
after active packages are reinstalled and the active boot chain is verified.
GRUB plans generate to a same-directory temporary file, validate with
`grub-script-check`, verify active entries plus absent rollback entries, and then
replace `grub.cfg` atomically. Neither plan can execute package commands, edit a
boot-loader configuration, or delete rollback files.

The console-observed Slackware 15.0 GRUB development VM is preserved in
`tests/fixtures/reference/kernel-cleanup/slackware-15.0-grub-single-kernel-observed.json`.
It runs `5.15.209`, defaults to the huge kernel, has no retained rollback package
triple, and therefore produces a stable `not-applicable` result with zero actions.
This fixture is a development baseline, not acceptance evidence. The retained
ELILO VM remains the only target for the scheduled mature preflight after
`2026-08-08T19:51:00+02:00`.


### Kernel cleanup dry-run contract

Phase 1 step 32 remains fixture-only and does not add a real-system acceptance
command. `tools/reference/kernel-cleanup-dry-run-reference.sh` requires
`--dry-run`, verifies the step 31 plan hash, and either emits a blocked/no-op
result or renders all proposed actions as inert JSON command vectors. It never
executes those vectors and always reports empty command and mutation lists.

A complete simulation requires a matching authorization whose scope is exactly
`dry-run-only`; it must match the plan digest, target, boot loader, active kernel,
and rollback kernel while preserving `apply_authorized=false`. Synthetic mature
ELILO and GRUB fixtures exercise the full transaction and deterministic failure
recovery, but they are not acceptance evidence and do not authorize either VM.
The retained ELILO VM remains frozen until the scheduled mature retention
preflight no earlier than `2026-08-08T19:51:00+02:00`.



### Slackware-current candidate-chain refresh preflight

Phase 1 step 44 adds `test-current-candidate-chain-refresh-preflight.sh` as a
root-only but non-installing wrapper around the established normal-update
preflight. It refreshes Slackpkg metadata, captures the resulting candidate
files and nested evidence, recomputes the deterministic candidate digest, and
compares the exact list with the accepted 2026-08-03 Slackware-current chain.

The analysis requires sorted unique safe package filenames. When one
`kernel-generic` candidate exists, exactly one matching `kernel-headers` and
`kernel-source` version must accompany it. Multiple generic targets or an
incomplete companion set are manual-review failures. An exact unchanged digest
may reuse only the existing candidate-bound records and advances to a separate
readiness dry-run. A changed kernel digest marks the previous boot, package,
GenInitrd, DKMS, command, and GRUB-ownership records stale and requires the
target-specific chain to be repeated. Changed userspace and no-update outcomes
select their own explicit review stages.

The wrapper compares the installed package database and active boot state before
and after metadata refresh. It invokes the nested acceptance script only with
`--preflight`, records that package apply, initrd generation, and GRUB updates
were not executed, and always publishes `apply_ready=false` and
`apply_authorized=false`. Its private portable evidence archive and sidecar are
copied directly to `/home/promano` with the printed command.

### Slackware-current kernel evidence-chain restart preflight (steps 45-46)

Phase 1 step 45 adds `test-current-kernel-chain-restart-preflight.sh` after the
accepted refresh selected a new kernel target. The wrapper binds the accepted
2026-08-04 chain-refresh record to the matching 69-candidate normal-update
record, reconstructs the exact candidate digest, and requires the complete
`kernel-generic`, `kernel-headers`, and `kernel-source` trio for `6.18.42`.

The wrapper invokes only `test-current-kernel-boot-preflight.sh` with the
reviewed normal-update record supplied explicitly. The complete nested evidence
directory, its archive, and its portable sidecar remain inside the outer private
evidence tree. The outer stage validates the nested summary identity, verifies
the nested sidecar, and requires unchanged package and active boot state.

The first real run on 2026-08-04 is diagnostic only. It passed 19 nested boot
checks but failed because the local Slackpkg file inventory did not expose
`boot/vmlinuz-6.18.42` before the exact package had been downloaded. The package
list still exposed one exact `kernel-generic`, `kernel-headers`, and
`kernel-source` target trio, and both package and boot state remained unchanged.
The rejected outer archive SHA-256 is
`ea7b0d7fa6ff5f9020f41ae06f5bea5c91a79d579dddf1bc25d258ca484605d1`.

Phase 1 step 46 corrects the stage boundary. Boot discovery records target image
metadata as `present` when the file inventory is available, or as
`deferred-to-exact-package-preflight` otherwise. The latter is not ownership
proof: the mandatory next exact-package preflight must download the reviewed
`kernel-generic-6.18.42` archive and validate both `boot/vmlinuz-6.18.42` and the
matching module tree before any later readiness decision.

Run it as root on `pcold-slack`:

```bash
sudo bash tests/acceptance/reference/test-current-kernel-chain-restart-preflight.sh \
    --target slackware-current
```

The stage never installs packages, generates an initrd, regenerates GRUB, or
calls normal-update apply. Every result records `apply_ready=false` and
`apply_authorized=false`. A successful corrected result advances only to a new exact
`kernel-generic-6.18.42` package preflight. The outer summary preserves the
nested target-image metadata state for auditability. Copy the printed archive and sidecar
directly to `/home/promano` and verify them there with the printed
`sha256sum -c` command.



### Slackware-current restarted exact-package preflight (step 47)

The corrected step 46 run is accepted with 20 nested and 6 outer assertions,
outer archive SHA-256
`77618b808093f3e5349f5a6e076a110b56876a7ed08878d89c71a78fc594de51`,
and nested archive SHA-256
`be201626afc4b4aa2f9b59d7c10429e083094989b8c172530348aad95ab4fc32`.
It binds candidate digest
`918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9`
to running kernel `6.18.40`, target `6.18.42`, and target-image metadata state
`deferred-to-exact-package-preflight` while preserving package and boot state.

Run the exact-package preflight on the same Slackware-current host:

```bash
sudo bash tests/acceptance/reference/test-current-kernel-package-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

The preflight binds all three accepted records before download, requires the
live repository to expose exactly `kernel-generic-6.18.42-x86_64-1`, downloads
or confirms only that package in the Slackpkg cache, validates safe archive
paths plus the target versioned kernel and module tree, and reviews but never
executes `install/doinst.sh`. GRUB output is generated and syntax-checked only
inside the private evidence directory. Package installation, GenInitrd,
`update-grub`, active GRUB replacement, readiness, and authorization remain
forbidden. Copy the resulting `.tar.gz` and `.sha256` directly to
`/home/promano` with the printed command.

The real `pcold-slack` run passed all 12 assertions. It accepted package SHA-256 `e9e7a1c5c71c945ee99595868aa8fee8a644b56601ece0c3e5696d643fe84878`, 6,588 safe members, 5,490 target-module paths, the target kernel image, zero embedded initrds, the conditional GenInitrd hook, unchanged package and boot state, and portable evidence SHA-256 `44c18026052a7d7b0d5e385258389f8bc73beefe9ac35c2a2777707df17c4f57`. The sanitized accepted record is `tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-package-preflight-20260804-accepted.json`.

### Slackware-current restarted GenInitrd policy preflight (step 48)

Run only after the accepted step-47 exact-package record is present:

```bash
sudo bash tests/acceptance/reference/test-current-geninitrd-policy-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

The preflight binds the accepted normal-update, boot-layout, chain-restart, and exact-package records before inspecting the installed GenInitrd scripts, `/etc/default/geninitrd`, effective generator, cleanup policy, automatic GRUB behavior, custom scripts, and executable hooks. Configuration is parsed without sourcing it, hooks are inventoried without execution, and package plus boot-sensitive state are compared before and after. The result always remains `apply_ready=false` and `apply_authorized=false`. Copy the generated archive and sidecar directly to `/home/promano` with the printed command and verify them there with the printed `sha256sum -c` command.

The real `pcold-slack` run passed all 10 assertions. It accepted the enabled policy, effective `mkinitrd_command_generator.sh`, automatic GRUB update, direct-to-generated-initrd transition to `/boot/initrd-6.18.42.img`, unchanged reviewed hook digests, immutable package and boot-policy state, and archive SHA-256 `873c7779dcef6f16d72d809704ca732809e6d5db5b1668f6a4942662b97c54ca`. The sanitized accepted record is `tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-policy-preflight-20260804-accepted.json`.

This record is historical only after the corrected step-55 baseline proved that the host already used a GenInitrd-managed versioned initrd. It must not be reused for apply or later evidence linkage; step 58 rebuilds the policy boundary.

### Slackware-current restarted DKMS-hook preflight (step 49)

```bash
sudo bash tests/acceptance/reference/test-current-geninitrd-dkms-hook-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

This preflight binds the accepted 69-candidate, boot, chain-restart, exact-package, and GenInitrd-policy evidence before inspecting the two exact executable hooks. Hook bodies are copied with mode `0600` and analyzed statically without evaluation. The only DKMS operations are `dkms --version` and `dkms status`; source trees, build state, running modules, and target-kernel paths are inventoried without build, install, autoinstall, remove, package, initrd, or GRUB mutation. Copy the archive and portable sidecar directly to `/home/promano` and verify them there. The result remains `apply_ready=false` and `apply_authorized=false` pending evidence review.

### Slackware-current restarted GenInitrd command preflight (step 50)

Run on `pcold-slack` only after the accepted step-49 DKMS record exists:

```bash
sudo bash tests/acceptance/reference/test-current-geninitrd-command-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

The preflight binds the accepted normal-update, boot, restarted-chain, exact-package, GenInitrd-policy, and no-op DKMS records. It invokes the installed generator only in command-output mode for `6.18.40`, parses exactly one inert `mkinitrd` vector without evaluation, and projects the target to `6.18.42` with output `/boot/initrd-6.18.42.img`. It never runs `mkinitrd`, `geninitrd`, GRUB, package tools, or the generated vector. Copy the archive and portable sidecar directly to `/home/promano`; the result remains `apply_ready=false` and `apply_authorized=false`.

The first real run passed 10 assertions and failed only the cached-package assertion because executable code still contained the old `6.18.41` package SHA-256. Archive SHA-256 `8f3f32b17d735241caf7e22f2aa32b56d2d42590a46bb920979ed51e0ab6c3f6` is diagnostic only. The corrected step-51 script loads the exact package filename and digest from `slackware-current-kernel-package-preflight-20260804-accepted.json`, records expected and observed cache digests, and requires a clean rerun before this boundary is accepted.



### Slackware-current restarted GenInitrd/GRUB ownership preflight (step 52)

The corrected step-51 rerun passed all 11 assertions. Its accepted archive SHA-256 is `be239e39372ad807be01199051730dbaf2602b962ceebea68b864e5951c78682`; the command record preserves the complete `6.18.42` evidence chain, the exact cached package digest, the inert current vector, the projected 18-module vector, and output `/boot/initrd-6.18.42.img`.

Run the ownership preflight on the same Slackware-current host:

```bash
sudo bash tests/acceptance/reference/test-current-geninitrd-grub-ownership-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

The preflight binds seven accepted records, verifies the installed GenInitrd control flow, and creates an evidence-local staged policy whose only active change is `AUTO_UPDATE_GRUB=true` to `AUTO_UPDATE_GRUB=false`. It emits the reviewed twelve-stage transaction and five recovery boundaries, but never edits the active policy, installs packages, generates an initrd, or invokes GRUB tools. The result must remain `apply_ready=false` and `apply_authorized=false`. Copy the archive and portable sidecar directly to `/home/promano` and verify them there.


### Slackware-current final kernel transaction readiness preflight (step 53)

After the accepted step-52 ownership archive SHA-256 `f906211517c8887e52b2842ff8756973bf9ef5fa4af378a6c830226befe1d522` is recorded, run:

```bash
sudo bash tests/acceptance/reference/test-current-kernel-transaction-readiness-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

The preflight runs only the embedded normal-update `--preflight`, requires exact equality with the accepted 69-candidate set, verifies the portable nested archive, and rechecks the exact cached package, current direct-generic boot, active GenInitrd policy, reviewed scripts and hooks, zero-row DKMS state, and syntax-valid GRUB configuration. It captures package and transaction-sensitive state before and after. A clean result reports `apply_ready=true` and `apply_authorized=false`; it does not run package installation, `mkinitrd`, `geninitrd`, DKMS build/install, `update-grub`, or `grub-mkconfig`. Copy the final archive and `.sha256` directly to `/home/promano` with the printed command and verify them there.


### Slackware-current corrected GenInitrd-managed boot baseline (step 54)

The step-53 readiness evidence revalidated the exact 69-candidate set but found a pre-existing `/boot/initrd-generic.img -> initrd-6.18.40.img` pair. The artifacts predate the accepted target chain, so the former `direct-generic-no-initrd` classification is revoked. Run:

```bash
sudo bash tests/acceptance/reference/test-current-kernel-boot-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

The corrected preflight recognizes `geninitrd-managed-versioned-initrd`, captures `/boot/initrd-generic.img` and `/boot/initrd-6.18.40.img`, verifies the active GenInitrd policy and safe file metadata, and proves that GRUB pairs the generic kernel and named initrd in one menuentry. It never runs package tools, `mkinitrd`, `geninitrd`, or GRUB generation. Copy the archive and portable sidecar directly to `/home/promano`; apply remains denied and all dependent evidence must be rebuilt afterward.

### Slackware-current GenInitrd metadata-parser correction (step 55)

The first step-54 real-system run classified the host correctly but rejected safe initrd metadata because the script-wide newline/tab-only `IFS` did not split the helper's space-separated `stat` output. The verified diagnostic archive is `slackware-current-current-kernel-boot-preflight-20260805T092755Z.tar.gz`, SHA-256 `16ebd14b3dd3447c6663fb25796c603738ce58f99bff56334813f72d5b4fd2bb`; it recorded 19 passes, one parser failure, unchanged package/boot state, and permanent apply denial.

Run the corrected preflight:

```bash
sudo bash tests/acceptance/reference/test-current-kernel-boot-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

The safe-file helper now uses colon-delimited metadata and a local `IFS`, validates mode/UID/GID fields before octal arithmetic, and must accept the existing root-owned non-writable versioned initrd. Expect 20 passes, zero failures, `boot-mode=geninitrd-managed-versioned-initrd`, `geninitrd-transition=true`, `apply-ready=false`, and `apply-authorized=false`. Copy both evidence files directly to `/home/promano` and verify the portable sidecar there.



### Slackware-current corrected chain restart (step 56)

The accepted step-55 baseline archive is `slackware-current-current-kernel-boot-preflight-20260805T094536Z.tar.gz`, SHA-256 `6429fd626973b0c3fc498642e1cd9230bc0eceb0291e232b515fef625467c6ac`. Run:

```bash
sudo bash tests/acceptance/reference/test-current-kernel-chain-restart-preflight.sh \
    --target slackware-current
```

The wrapper validates the accepted candidate, normal-update, and corrected boot records, reruns the boot preflight, requires `geninitrd-managed-versioned-initrd` and the accepted versioned-initrd SHA-256, verifies the nested portable archive, and proves package plus boot state remain unchanged. It never installs packages or runs initrd or GRUB generation. Copy the final outer `.tar.gz` and `.sha256` directly to `/home/promano` and verify them there.

### Slackware-current rebuilt exact-package preflight (step 57)

The accepted corrected chain restart is recorded in `tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-chain-restart-20260805-accepted.json`. Run:

```bash
sudo bash tests/acceptance/reference/test-current-kernel-package-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

The stage binds the accepted 69-candidate record, corrected GenInitrd boot record, and corrected chain-restart record. Before download it requires the live `geninitrd-managed-versioned-initrd` baseline, exact current kernel and initrd hashes, safe root-owned versioned initrd, enabled named-symlink policy, and an active GRUB menuentry pairing `/boot/vmlinuz-generic` with `/boot/initrd-generic.img`. It then inspects only the exact cached target package and evidence-local GRUB output. The expected result is 13 passes, zero failures, `apply_ready=false`, and `apply_authorized=false`.

The real run passed all 13 assertions and produced accepted archive SHA-256 `9f702e85a8ff3eb6155b834ed11cfe494ec60f04082914d80bae2a13d02e016f`. The sanitized accepted record is `tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-package-preflight-20260805-accepted.json`.

### Slackware-current rebuilt GenInitrd policy preflight (step 58)

```bash
sudo bash tests/acceptance/reference/test-current-geninitrd-policy-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

The stage binds the corrected boot, chain-restart, and exact-package records, then revalidates the live generic kernel, named initrd, versioned initrd, scalar GenInitrd policy, and same-menuentry GRUB pairing. It parses installed policy and scripts without sourcing or executing them, inventories hooks, predicts `/boot/initrd-6.18.42.img`, and reports `versioned-to-versioned-initrd`. A safe result has 11 passes, zero failures, `apply_ready=false`, and `apply_authorized=false`. Copy the `.tar.gz` and `.sha256` directly to `/home/promano` and verify the sidecar there.

The rebuilt policy harness has 61 checks. The complete step-58 matrix contains 37 suites and 2,465 checks, all executed with zero failures.

