#!/bin/bash
# Repository candidate. No production backend or operational entry is installed.
set -euo pipefail
if [[ ${BASH_SOURCE[0]} != "$0" ]]; then
  printf 'ERROR: executor must not be sourced\n' >&2
  return 2
fi
if [[ $# -eq 1 && $1 == --help ]]; then
  printf 'Repository candidate: --private-test PRIVATE_FIXTURE_ROOT\nProduction entry is closed.\n'
  exit 0
fi
if [[ $# -ne 2 || $1 != --private-test || -z $2 ]]; then
  printf 'ERROR: production entry closed; only explicit private synthetic tests are supported\n' >&2
  exit 2
fi
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
exec python3 -I "$script_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-private.py" "$2"
