#!/usr/bin/env python3
"""Exercise real instance-lock helpers using only private files/process groups."""

from pathlib import Path
import errno
import fcntl
import os
import select
import shutil
import signal
import subprocess
import tempfile
import time


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
FLOCK = shutil.which("flock")
BUSY = "Otra instancia de slack-update ya esta ejecutandose\n".encode()
DRIVER = r'''
source "$1"
LOCKFILE=$2
REAL_FLOCK=$3
mode=$4
initial_state=$5
initial_descriptor=$6
UNLOCK_FAILURES=0
if [[ $initial_state == unset ]]; then unset INSTANCE_LOCK_HELD; else INSTANCE_LOCK_HELD=0; fi
exec 9>&-
if [[ $initial_descriptor == open ]]; then exec 9>"$LOCKFILE"; fi
if [[ $mode == missing ]]; then
    command() {
        if [[ $# == 2 && $1 == -v && $2 == flock ]]; then return 1; fi
        builtin command "$@"
    }
elif [[ $mode == unlock-failure ]]; then
    flock() {
        if [[ $1 == -u ]]; then UNLOCK_FAILURES=$((UNLOCK_FAILURES + 1)); return 23; fi
        "$REAL_FLOCK" "$@"
    }
fi
forbidden() { printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
main() { forbidden main; }
install_runtime_traps() { forbidden install_runtime_traps; }
initialize_runtime() { forbidden initialize_runtime; }
initialize_dry_run_runtime() { forbidden initialize_dry_run_runtime; }
load_configuration() { forbidden load_configuration; }
require_root() { forbidden require_root; }
cleanup() { forbidden cleanup; }
run_check_workflow() { forbidden run_check_workflow; }
run_apply_workflow() { forbidden run_apply_workflow; }
run_dry_run_workflow() { forbidden run_dry_run_workflow; }
while IFS= read -r action; do
    case "$action" in
        acquire) acquire_instance_lock; status=$? ;;
        release) release_instance_lock; status=$? ;;
        exit17) exit 17 ;;
        *) forbidden "$action" ;;
    esac
    if { : >&9; } 2>/dev/null; then descriptor=open; else descriptor=closed; fi
    printf '%s\t%s\t%s\t%s\t%s\n' "$action" "$status" \
        "${INSTANCE_LOCK_HELD-unset}" "$descriptor" "$UNLOCK_FAILURES"
done
'''


class Shell:
    calls = 0

    def __init__(self, work, lock, mode="normal", state="zero", descriptor="closed"):
        self.pending = b""
        environment = dict(os.environ, LC_ALL="C")
        environment.pop("BASH_ENV", None)
        for name in list(environment):
            if name.startswith("BASH_FUNC_"):
                environment.pop(name)
        self.process = subprocess.Popen(
            ["bash", "--noprofile", "--norc", "-c", DRIVER, "instance-lock-test",
             str(REFERENCE), str(lock), str(FLOCK), mode, state, descriptor],
            cwd=work, env=environment, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, start_new_session=True)

    def expect(self, action, status, state, descriptor, failures=0):
        process = self.process
        process.stdin.write((action + "\n").encode())
        process.stdin.flush()
        deadline = time.monotonic() + 5
        while b"\n" not in self.pending:
            ready, _, _ = select.select([process.stdout], [], [], max(0, deadline - time.monotonic()))
            assert ready, (action, "private lock helper did not respond promptly")
            chunk = os.read(process.stdout.fileno(), 4096)
            assert chunk, (action, "private child exited before its reply")
            self.pending += chunk
        line, self.pending = self.pending.split(b"\n", 1)
        actual = line + b"\n"
        expected = f"{action}\t{status}\t{state}\t{descriptor}\t{failures}\n".encode()
        assert actual == expected, (action, actual, expected)
        Shell.calls += 1

    def finish(self, status=0):
        process = self.process
        if status == 17:
            process.stdin.write(b"exit17\n")
            process.stdin.flush()
        process.stdin.close()
        process.wait(timeout=5)
        remaining, errors = self.pending + process.stdout.read(), process.stderr.read()
        assert process.returncode == status and remaining == b"", (process.returncode, remaining, errors)
        return errors

    def stop(self):
        # A failed assertion must not leave a private child or inherited lock alive.
        if self.process.poll() is None:
            try:
                os.killpg(self.process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
        self.process.wait(timeout=5)
        for stream in (self.process.stdin, self.process.stdout, self.process.stderr):
            stream.close()


def available(path):
    descriptor = os.open(path, os.O_RDWR | os.O_CREAT, 0o600)
    try:
        try:
            fcntl.flock(descriptor, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError as error:
            assert error.errno in (errno.EACCES, errno.EAGAIN), error
            return False
        fcntl.flock(descriptor, fcntl.LOCK_UN)
        return True
    finally:
        os.close(descriptor)


def run_cases():
    assert FLOCK, "flock is required for private real-lock regression tests"
    shells = []
    count = 0
    with tempfile.TemporaryDirectory(prefix="slack-update-instance-lock-") as directory:
        work = Path(directory)
        unrelated = work / "unrelated"
        unrelated.write_bytes(b"preserve\n")

        def child(lock, **options):
            shell = Shell(work, lock, **options)
            shells.append(shell)
            return shell

        try:
            for existing in (False, True):
                for exit_status in (0, 17):
                    lock = work / f"lifecycle {existing} {exit_status}.lock"
                    if existing:
                        lock.write_bytes(b"old lock contents\n")
                    old_inode = lock.stat().st_ino if existing else None
                    shell = child(lock)
                    shell.expect("acquire", 0, 1, "open")
                    inode = lock.stat().st_ino
                    assert not existing or inode == old_inode
                    assert lock.read_bytes() == b"" and not available(lock)
                    shell.expect("release", 0, 0, "closed")
                    assert available(lock)
                    shell.expect("release", 0, 0, "closed")
                    shell.expect("acquire", 0, 1, "open")
                    assert not available(lock) and lock.stat().st_ino == inode
                    assert shell.finish(exit_status) == b""
                    assert available(lock) and lock.is_file() and lock.stat().st_ino == inode
                    count += 1

            lock = work / "shared instance.lock"
            holder, contender = child(lock), child(lock)
            holder.expect("acquire", 0, 1, "open")
            assert not available(lock)
            contender.expect("acquire", 6, 0, "closed")
            assert not available(lock)
            holder.expect("release", 0, 0, "closed")
            assert available(lock)
            contender.expect("acquire", 0, 1, "open")
            holder.expect("release", 0, 0, "closed")
            assert not available(lock)
            contender.expect("release", 0, 0, "closed")
            assert available(lock)
            assert holder.finish() == b"" and contender.finish() == BUSY
            count += 1

            directory_lock = work / "directory lock"
            directory_lock.mkdir()
            parent_file = work / "parent-file"
            parent_file.write_bytes(b"parent bytes\n")
            for lock, diagnostic in ((work / "missing-parent/lock", b"No such file or directory"),
                                     (directory_lock, b"Is a directory"),
                                     (parent_file / "lock", b"Not a directory")):
                shell = child(lock)
                shell.expect("acquire", 1, 0, "closed")
                shell.expect("release", 0, 0, "closed")
                errors = shell.finish()
                tail = f"Error: cannot open instance lock: {lock}\n".encode()
                assert errors.endswith(tail) and diagnostic in errors[:-len(tail)], errors
                count += 1
            assert parent_file.read_bytes() == b"parent bytes\n"

            lock = work / "missing flock.lock"
            lock.write_bytes(b"not opened\n")
            shell = child(lock, mode="missing")
            shell.expect("acquire", 1, 0, "closed")
            shell.expect("release", 0, 0, "closed")
            assert shell.finish() == b"Error: flock is required to acquire the instance lock\n"
            assert lock.read_bytes() == b"not opened\n"
            count += 1

            lock = work / "unlock failure.lock"
            shell = child(lock, mode="unlock-failure")
            shell.expect("acquire", 0, 1, "open")
            assert not available(lock)
            shell.expect("release", 0, 0, "closed", 1)
            assert available(lock)
            shell.expect("release", 0, 0, "closed", 1)
            assert shell.finish() == b""
            count += 1

            for state in ("zero", "unset"):
                for descriptor in ("closed", "open"):
                    lock = work / f"unowned {state} {descriptor}.lock"
                    shell = child(lock, state=state, descriptor=descriptor)
                    expected_state = 0 if state == "zero" else "unset"
                    shell.expect("release", 0, expected_state, "closed")
                    shell.expect("release", 0, expected_state, "closed")
                    assert shell.finish() == b""
                    assert lock.exists() == (descriptor == "open")
                    count += 1
            assert unrelated.read_bytes() == b"preserve\n"
        finally:
            for shell in shells:
                shell.stop()
    return count


def main():
    count = run_cases()
    print(f"Instance lock helpers: {count} scenarios, {Shell.calls} helper calls, 0 failures")


if __name__ == "__main__":
    main()
