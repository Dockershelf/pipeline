#!/usr/bin/env bash
# Initialize cpython/ git submodules in all py3.* packaging repos under this workspace.
#
# Usage (from dockershelf-pipeline/):
#   ./init-cpython-submodules.sh
#   ./init-cpython-submodules.sh py3.14

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGETS=()

if [ "$#" -gt 0 ]; then
    TARGETS=("$@")
else
    for d in "${ROOT}"/py3.[0-9]*; do
        [ -d "${d}/.git" ] && TARGETS+=("$(basename "${d}")")
    done
fi

for name in "${TARGETS[@]}"; do
    repo="${ROOT}/${name}"
    if [ ! -d "${repo}/.git" ]; then
        echo "SKIP ${name}: not a git repo"
        continue
    fi
    echo "==> ${name}"
    cd "${repo}"
    if [ -d cpython/.git ]; then
        echo "    cpython submodule already initialized"
        continue
    fi
    # Read branch from .gitmodules (default to main if not specified)
    branch="$(git config -f .gitmodules submodule.cpython.branch 2>/dev/null || echo main)"
    rm -rf cpython
    git submodule update --init --depth 1 cpython 2>/dev/null || {
        echo "    submodule update failed; cloning cpython ${branch} branch..."
        git clone --filter=blob:none --branch "${branch}" \
            https://github.com/python/cpython.git cpython
        git add cpython .gitmodules
        git commit -m "Add cpython upstream submodule" || true
    }
done

echo "Done."