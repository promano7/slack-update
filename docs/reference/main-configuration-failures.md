# Main configuration-loading boundaries

Run from the repository root with Python 3 and Bash:

```bash
python3 tests/reference/test-main-configuration-failures.py
```

The 456 scenarios source the reference and run the real `main`, argument parser,
`load_configuration`, explicit-path resolver, state initializer, configuration
text parser and validator. All file selections are nonempty explicit private
paths or a deliberately rejected relative override. No installed configuration
or source-tree fallback is selected by this harness.

Eighteen failing configuration cases are combined with four operations (including
legacy default apply), three output choices and closed/open descriptor 3. These
432 cases must return stable code 7, leave stdout empty, emit the exact diagnostic
without usage text on stderr and reach none of the guarded later boundaries.
Neither JSON nor NDJSON is emitted when loading fails, even with a format flag.

Cases include absent/directory/relative paths, empty/malformed files, unknown or
duplicate keys, unsupported schema, missing values and invalid boolean, module,
path, kernel-package, builder, remote or ELF settings. Input bytes remain unchanged.
Every subprocess has a ten-second timeout. Private trace/channel/configuration
files are removed with the temporary directory.

Twenty-four positive controls use an authored valid configuration. They must
reach the application callback and then the privilege callback, which deliberately
returns code 8 to stop before locking. This is a modeled stop, not an observed
native privilege failure or successful configuration-to-runtime assignment.
It detects a loader that rejects everything or skips its application stage.

## Mock boundaries and limits

Environment initialization is replaced by a one-call trace callback. Configuration
application is a guarded callback, permitted only in positive controls. Privilege
checking is another guarded callback, permitted only there. Sixteen later functions
covering locking, traps, runtime, logging, workflows and completion output/time are
replaced with callbacks that abort on invocation. The trace must match exactly;
descriptor 3 receives no bytes, and stdout/stderr are checked separately.

Eight private source mutations were rejected: wrong main status, ignored resolver/
parser/validation error, application before parsing, privileges before loading,
skipped successful application stage and missing environment callback. The actual
reference passed without a source change. Real assignments are checked separately
by the configuration-application suite.

These replacements are not an OS sandbox or proof of all possible effects. Review
future calls before running the test against changed code. The harness performs
real parsing/validation of supplied private files, not a native Slackware update.
Original acceptance criteria, operational findings/decisions/grants and phase
gates remain unchanged. Phase 1 and later release gates remain incomplete.
