#!/usr/bin/env bash
# Initialize node/ git submodules in all node* packaging repos under this workspace.
#
# Usage (from dockershelf-pipeline/):
#   ./init-node-submodules.sh
#   ./init-node-submodules.sh node22

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGETS=()

if [ "$#" -gt 0 ]; then
    TARGETS=("$@")
else
    for d in "${ROOT}"/node[0-9]*; do
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
    if [ -d node/.git ]; then
        echo "    node submodule already initialized"
        continue
    fi
    # Read branch from .gitmodules (default to main if not specified)
    branch="$(git config -f .gitmodules submodule.node.branch 2>/dev/null || echo main)"
    rm -rf node
    git submodule update --init --depth 1 node 2>/dev/null || {
        echo "    submodule update failed; cloning node ${branch} branch..."
        git clone --filter=blob:none --branch "${branch}" \
            https://github.com/nodejs/node.git node
        git add node .gitmodules
        git commit -m "Add node upstream submodule" || true
    }
done

echo "Done."
