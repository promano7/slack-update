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

