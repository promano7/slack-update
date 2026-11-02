# Diagnostic regression inputs

These fixtures exercise real main/validators in private filesystems without sudo,
network, native backend, installation, boot generation or reboot. The shell driver
uses explicit doubles; the Python composition test uses the real policy, catalog,
parser and boot code through a test-only bridge. The main startup still requires
this Slackware host's readable version/package-directory presence gates; no new
native contract acceptance is inferred from that read-only dependency.

`PROVENANCE.json` records exact public900/920 sources and hashes. Count/prompt
captures are historical900 outputs, not a newly acquired backend protocol.
The metadata gzip files contain the full public signed catalog and FILELIST920;
slackware.gpg is a public-only dearmored key, not a secret keyring. Tests run gpgv
against that retained material in private homes with no keyserver or agent.
They do not establish independent provenance of the signing key. The pkglist.awk
fixture preserves the observed backend transformation; reusing it is not an
independent complete selection oracle. Original accepted fixtures remain intact.

The policy example is deliberately invalid/non-operational. Completing hashes or
host fields does not itself authorize a native case. P1 remains unresolved: main's
apply entry point is blocked until a separate selection/consumption design is
implemented and accepted.
