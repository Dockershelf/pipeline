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
    major="${name#node}"
    if [ ! -d "${repo}/.git" ]; then
        echo "SKIP ${name}: not a git repo"
        continue
    fi
    echo "==> ${name}"
    cd "${repo}"
    rm -f node/.gitkeep
    if [ -d node/.git ]; then
        echo "    node submodule already initialized"
        continue
    fi
    rm -rf node
    git submodule update --init --depth 1 node 2>/dev/null || {
        git clone --filter=blob:none --branch "v${major}.x" \
            https://github.com/nodejs/node.git node || {
            git clone --filter=blob:none https://github.com/nodejs/node.git node
            (
                cd node
                git checkout "v${major}.x" 2>/dev/null \
                    || git checkout "$(git tag -l "v${major}.*" --sort=-v:refname | head -1)"
            )
        }
        git add node .gitmodules
        git commit -m "Add node upstream submodule" || true
    }
done

echo "Done."
