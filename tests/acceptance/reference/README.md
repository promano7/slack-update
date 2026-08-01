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
additional `--allow-kernel-update` option is supplied. Configured critical
packages are independently blocked unless `--allow-critical-update` is supplied.
The refreshed `all.candidates.txt` must also match the explicitly supplied
`--confirm-candidates-sha256`; any candidate-set change blocks apply before package
installation. `install-new` and `upgrade-all` run with `-postinst=off`, so the
active configuration files remain in place and pending regular `/etc/*.new` files
are listed in human and structured output for a later explicit `slackpkg new-config`
review. Flatpak, SBo, ELF, and Cinnamon are disabled for this scenario. Boot preparation stays in `auto` mode;
a detected kernel change must produce validated initrd and GRUB updates and the
stable reboot-required status.

Every run prints a one-line `Copy evidence command:`. For the `promano` account,
the generic fallback for this scenario is:

```bash
archive=$(sudo sh -c 'ls -1t /var/tmp/slack-update-acceptance/normal-update/*.tar.gz 2>/dev/null | head -n 1'); sudo install -o promano -g "$(id -gn promano)" -m 0600 "$archive" "/home/promano/$(basename "$archive")" && sudo install -o promano -g "$(id -gn promano)" -m 0600 "$archive.sha256" "/home/promano/$(basename "$archive.sha256")"
```
