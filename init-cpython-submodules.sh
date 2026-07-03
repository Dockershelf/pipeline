#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
export GIT_PROGRESS_DELAY=0

init_cpython() {
  local repo=$1 pin=$2 branch=$3

  echo "=== $repo ==="
  cd "$ROOT/$repo"
  git submodule deinit -f cpython 2>/dev/null || true
  rm -rf .git/modules/cpython cpython

  git clone --progress --depth 1 --branch "$branch" \
    https://github.com/python/cpython cpython

  git -C cpython fetch --progress --depth 1 origin "$pin"
  git -C cpython checkout "$pin"
  test -f cpython/Include/Python.h
  echo "OK $repo"
}

init_cpython py3.10 b286d98783db0c1169f558b4c6d7512cb3264274 3.10
init_cpython py3.11 a7370a9c2d6a3f160599c37d7a8be99db021ea64 3.11
init_cpython py3.12 7c999be49dee7f12703e4b2e07e990544fabd40e 3.12
init_cpython py3.13 5810def6dd7de4c24af0a977444026a184dc7cdd 3.13
init_cpython py3.14 bbaaebd0c13bb28679e2247353515823c28dccf7 main
