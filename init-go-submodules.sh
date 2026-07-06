#!/usr/bin/env bash
# Initialize go/ git submodules in all go1.* packaging repos under this workspace.
#
# Usage (from dockershelf-pipeline/):
#   ./init-go-submodules.sh
#   ./init-go-submodules.sh go1.25

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGETS=()

if [ "$#" -gt 0 ]; then
    TARGETS=("$@")
else
    for d in "${ROOT}"/go1.*; do
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
    if [ -d go/.git ]; then
        echo "    go submodule already initialized"
        continue
    fi
    # Read branch from .gitmodules (default to master if not specified)
    branch="$(git config -f .gitmodules submodule.go.branch 2>/dev/null || echo master)"
    rm -rf go
    git submodule update --init --depth 1 go 2>/dev/null || {
        echo "    submodule update failed; cloning go ${branch} branch..."
        git clone --filter=blob:none --branch "${branch}" \
            https://github.com/golang/go.git go
        git add go .gitmodules
        git commit -m "Add go upstream submodule" || true
    }
done

echo "Done."