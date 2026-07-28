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

Invoke the scenario through `bash` as shown above. This avoids depending on executable bits being preserved by the ZIP extraction or shared-folder filesystem.

By default, evidence is stored below:

```text
/var/tmp/slack-update-acceptance/no-updates/
```

The default parent directory is traversable, the archive and sidecar are owned by the `sudo` caller, and the expanded timestamped directory remains accessible only to root. The harness also prints the stable result and individual Slackware command statuses when structured validation fails.

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
