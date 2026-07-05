# Dockershelf pipeline — open gaps

**Last verified:** 2026-07-04

Living tracker for remaining work across `dockershelf-pipeline` and related Dockershelf repos (`Dockershelf/Dockershelf` image build scripts, GitHub Actions on `py3.*` / `node*` / `go*` repos, and the APT droplet at `apt.luisalejandro.org`).

**Priority key:** 🔴 blocking · 🟠 important · 🟡 nice-to-have · ⚪ cosmetic / hygiene

---

## Summary

| Area | Open items | Notes |
|------|------------|-------|
| Node CI / APT | 🟠 APT index | no `nodejs` packages in APT index |
| Go pipeline | � local smoke | no `make smoke` target |
| CI / ops hygiene | 🟡 several | `publish.yml`, `pr.yml`, action versions, maintainer branding |
| Workspace tooling | 🟡 Python | no maintained `init-cpython-submodules.sh` (Node has one; Go uses tarballs) |

---

## Python pipeline

###  No `init-cpython-submodules.sh` (asymmetric with Node)

**What:** Node has a maintained workspace helper, `init-node-submodules.sh` — documented in `README.md`, referenced by `seed-node-repo.sh`, accepts a single repo or all `node*` dirs, and skips already-initialized submodules. Python has no equivalent for `cpython/`: `seed-py-repo.sh` and `docs/operations.md` only document plain `git submodule update --init cpython`. Go does not need one: upstream is a vendored tarball in `go/`, fetched by `seed-go-repo.sh`.

**Impact:** Inconsistent developer experience across pipelines. No workspace-level, idempotent helper for on-demand `cpython/` init after shallow clones.

**Evidence:**

- `README.md` — documents `init-node-submodules.sh` only
- `seed-py-repo.sh` — ends with `git submodule update --init cpython` only

**Next steps:**

1. Add `init-cpython-submodules.sh` modeled on the node script (parameterized `py3.14` or all `py3.*`, idempotent, branch from `.gitmodules`).
2. Document in `README.md` and `seed-py-repo.sh` like node.

---

### 🟡 `publish.yml` escape hatch is weak (python-pipeline)

**What:** Standalone `python-pipeline/.github/workflows/publish.yml` expects `dist/*.deb` in the python-pipeline checkout. It does not download artifacts from a packaging workflow run.

**Impact:** Cannot republish from a failed publish step without manually placing `.deb` files in `dist/`.

**Next steps:** Wire to workflow artifacts / manual upload input, or document deprecation in favor of re-dispatching packaging with `publish: true`.

---

### 🟡 Consumer smoke test does not use the public APT repo

**What:** `scripts/debian-smoke-test.sh` installs from a local `file:/debs` source inside a container. CI smoke jobs use this path. No automated test adds the documented client `sources.list` + GPG key and runs `apt install` from `apt.luisalejandro.org`.

**Impact:** TLS, nginx, reprepro, and signing are not verified the way end users consume packages.

**Next steps:** Add `scripts/apt-consumer-smoke-test.sh` (or extend existing script with `--from-apt`) and optionally a scheduled/manual workflow.

---

### 🟡 reprepro first-attempt errors (retry masks failures)

**What:** Publish logs sometimes show `cannot be included` on first `reprepro includedeb`. `import-incoming.sh` removes and retries once; job stays green.

**Impact:** Transient conflicts may be hidden; logs look alarming on success.

**Next steps:** Determine which errors are fatal vs benign. Fail fast on unrecoverable cases; summarize retried packages in the job summary.

---

### 🟡 `pr.yml` never exercised (python-pipeline)

**What:** `python-pipeline/.github/workflows/pr.yml` runs pre-commit on pull requests. No PR workflow runs exist in GitHub history.

**Next steps:** Open a trivial PR to verify, or add pre-commit to a push workflow on `main`.

---

### ⚪ `DEBFULLNAME` / `DEBEMAIL` not customized

**What:** CI defaults to `Dockershelf Maintainer` and `github-actions[bot]@users.noreply.github.com` for changelog attribution.

**Next steps:** Set org- or repo-level `DEBFULLNAME` / `DEBEMAIL` variables if human maintainer branding is desired.

---

## Node pipeline

### 🟠 Node packages not visible in APT index

**What:** `curl` of trixie and unstable `Packages` indices shows **no `nodejs` packages**, while Go and Python packages are present.

**Impact:** Either Node publish path is broken, packages use unexpected names, or publish has never succeeded to production.

**Next steps:** Verify `node-pipeline` publish job on a green run; inspect droplet `incoming/` and reprepro logs.

---

### 🟡 `publish.yml` escape hatch is weak (node-pipeline)

Same limitation as Python — expects `dist/*.deb` in the node-pipeline checkout.

---

## Go pipeline

###  No local Debian smoke test in `make`

**What:** `scripts/debian-smoke-test.sh` exists and runs in CI, but `go-pipeline/Makefile` has no `make smoke` target (same for `python-pipeline/Makefile`).

**Next steps:** Add `smoke` targets wrapping the existing scripts for local dev parity with CI.

---

### 🟡 `publish.yml` escape hatch is weak (go-pipeline)

Same limitation as Python and Node.

---

## Cross-cutting infrastructure

### 🟡 GitHub Actions — Node 20 deprecation warnings

**What:** Workflows use `actions/checkout@v4`, `actions/setup-python@v5`, `docker/login-action@v3`, `actions/download-artifact@v4`, etc. Runners log Node 20 deprecation warnings.

**Next steps:** Bump action versions when Node 24–compatible releases are available; test on a PR per pipeline.

---

### 🟡 GHCR builder image pull — remove local build fallback

**What:** CI and local workflows must always pull builder images from GHCR; unauthenticated public pulls succeed. The script previously fell back to building images locally on pull failure.

**Change:** Remove the possibility of building the image locally. If the pull fails, fail the workflow and instruct users to resolve access issues with GHCR rather than attempt a local build.

**Next steps:** Update `ci-pull-builder-images.sh` to eliminate the local build fallback logic. Ensure all usages only pull images, never build locally.

---

### 🟡 `deploy-status` summary job

**What:** `update-meta-gbp.yml` in each pipeline includes a `deploy-status` job that posts a summary when publish is skipped due to missing `DEPLOY_HOST`.

**Next steps:** Keep for forks, or remove once all repos have deploy vars configured.

---

## Success criteria (not yet met)

- [ ] Node packages visible and installable from the public APT repo
- [ ] Consumer smoke test passes from a clean Debian container using the documented apt source (not local `file:/debs`)
- [x] Multi-arch (amd64 + arm64) packages available for Python, Node, and Go
- [ ] `pr.yml` verified on at least one pull request per pipeline

---

## Suggested order of work

1. **Investigate Node APT publish** — confirm node packages reach the index.
2. **Add public APT consumer smoke test** — catches deploy/TLS/signing issues CI currently misses.
3. **Hygiene pass** — action version bumps.

---

## References

- Operations: `*/docs/operations.md`
- CI setup: `*/docs/ci.md`
- Deploy wiring: `*/docs/deploy-setup.md`
- APT repo: `https://apt.luisalejandro.org/dockershelf`