# Deadsnakes Pipeline Status Report

**Report Date:** 2026-07-02

## Overview

The dockershelf-pipeline is a local packaging workspace for building custom Debian packages for Dockershelf. It manages three language pipelines for creating `.deb` packages that are published to a self-hosted APT repository at `apt.luisalejandro.org/dockershelf`.

## Architecture

```text
dockershelf-pipeline/
├── python-pipeline/   # CPython packaging orchestration
├── node-pipeline/     # Node.js packaging orchestration
├── go-pipeline/       # Go repackaging orchestration
├── py3.10/ … py3.14/  # Python 3.10-3.14 packaging repos
├── node16/ … node24/  # Node.js 16-24 packaging repos
└── go1.20/ … go1.25/  # Go 1.20-1.25 repackaging repos
```

### Pipeline Capabilities

Each pipeline:
- Clones upstream source repositories as Git submodules
- Builds Debian packages for multiple distributions (trixie, sid/unstable)
- Uses Docker builder images with packaging tools (gbp, dch, dpkg)
- Publishes to self-hosted APT repository via reprepro
- Has GitHub Actions CI with scheduled builds

## Python Pipeline

**Status:** Partially functional - py3.14 working, py3.10-py3.13 broken

### Working Features
- ✅ Build orchestration and Makefile infrastructure
- ✅ Docker builder images on GHCR (`ghcr.io/dockershelf/dockershelf-python-builder/*`)
- ✅ GitHub Actions workflows for CI/CD
- ✅ py3.14 builds successfully on weekly schedule
- ✅ APT repository publish mechanism (reprepro)
- ✅ Debian split packaging (python3.X, libpython3.X-stdlib, python3.X-dev, etc.)

### Known Issues

#### High Priority (Blocking)

**1. py3.10-py3.13 Never Run in CI**
- **Impact:** Only Python 3.14 packages exist in APT repo
- **Status:** ⚙️ **IN PROGRESS** - Cron schedules updated to weekly Tuesday, awaiting GitHub Actions enablement
- **Action Required:** 
  1. ✅ Cron schedules updated to weekly Tuesday (03:00-03:30 UTC) - **COMPLETED**
  2. Enable GitHub Actions on py3.10-py3.13 repos (Settings → Actions)
  3. Manually dispatch test runs with `publish: false` (py3.13 → py3.12 → py3.11 → py3.10)
  4. After test success, re-run with `publish: true`
- **Implementation Guide:** See [IMPLEMENTATION.md](IMPLEMENTATION.md) for detailed steps

**2. Dockershelf Python Images Don't Use This APT Repo**
- **Impact:** Pipeline output not consumed by published Docker images
- **Status:** `python/build-image.sh` still uses deadsnakes PPA (Ubuntu)
- **Action Required:** 
  - Rewrite `build-image.sh` to use `apt.luisalejandro.org/dockershelf`
  - Add GPG key `0F6CBFE94AA83A5E`
  - Remove Ubuntu/PPA logic, mime-support-dummy, UBUNTU_RELEASE code

**3. Scheduled Crons Failed**
- **Impact:** Automated builds not working
- **Status:** Crons ran but failed (root cause TBD)
- **Action Required:** Investigate failure logs and fix root cause
- **Previous Fix:** `mk-build-deps` on read-only `/code` mount fixed via `/tmp/build-deps`

**4. GHCR Pull Access Denied**
- **Impact:** CI rebuilds builder images locally (+2 min per job)
- **Status:** `docker pull ghcr.io/dockershelf/dockershelf-python-builder/*` fails
- **Action Required:**
  - Make builder packages public or grant read access to py3.* repos
  - Verify builder images correctly named `dockershelf-python-builder` (not just `dockershelf-builder`)

#### Medium Priority (Inefficiencies)

**5. reprepro First-Attempt Errors**
- **Impact:** Transient publish errors, retry logic masks real failures
- **Status:** `cannot be included` errors on first attempt, succeeds on retry
- **Action Required:** Determine if errors are fatal or warnings; fix if feasible

**6. No Seed Script for New Python Versions**
- **Impact:** Manual error-prone process to add py3.15+
- **Status:** Node has `seed-node-repo.sh`, Python doesn't
- **Action Required:** Create `scripts/seed-py-repo.sh` script
- **Resolution:** Added after Gap 6 implementation (status unclear)

**7. Weak publish.yml Escape Hatch**
- **Impact:** Cannot republish from failed runs
- **Status:** Expects `dist/*.deb` in python-pipeline checkout, doesn't download artifacts
- **Action Required:** Wire to workflow artifacts or document deprecation

#### Lower Priority (Hygiene)

**8. pr.yml Never Exercised**
- **Impact:** Pre-commit hooks untested
- **Status:** No PR workflow runs in history
- **Action Required:** Open test PR or run pre-commit on push to main

**9. DEBFULLNAME/DEBEMAIL Not Customized**
- **Impact:** Bot identity in changelogs instead of human maintainer
- **Status:** Uses `Dockershelf Maintainer` and bot email
- **Action Required:** Set org/repo variables if branding desired

**10. No End-User Verification**
- **Impact:** Can't verify `apt install python3.14` works from clean container
- **Status:** Only metadata verified via curl
- **Action Required:** Add consumer smoke test with actual apt install

**11. CI Cost at Scale**
- **Impact:** ~33 min per suite × 5 repos × 2 suites × daily = substantial runner hours
- **Status:** Concern for when all py3.10-3.14 are active
- **Action Required:** Consider shared build cache or reduced frequency

### Recent Resolutions (Gaps 1-6)
- ✅ Weekly Tuesday crons configured (staggered 0-40 3 * * 2 UTC)
- ✅ `python/build-image.sh` rewrite started (incomplete - still uses PPA)
- ✅ Cron root cause identified: `mk-build-deps` read-only mount issue
- ✅ Builder images renamed to `ghcr.io/dockershelf/dockershelf-python-builder/*`
- ✅ `import-incoming.sh` fixes: `$?` capture, proactive remove, import summary
- ✅ `seed-py-repo.sh` script added

## Node Pipeline

**Status:** More complete than Python, fewer documented gaps

### Working Features
- ✅ Build orchestration for Node.js 16, 18, 20, 22, 24
- ✅ GitHub Actions CI workflows
- ✅ Docker builder images on GHCR
- ✅ Monolithic package approach (single `nodejs` package)
- ✅ Integration with main Dockershelf images appears functional

### Known Issues
- No dedicated gaps document found
- Mirrors Python pipeline architecture, likely shares some common issues (GHCR access, cron reliability)
- Large upstream `node/` submodules require on-demand initialization via `init-node-submodules.sh`

## Go Pipeline

**Status:** Functional but missing features

### Working Features
- ✅ Repackages official precompiled Go toolchains from go.dev
- ✅ Builds Debian packages `golang-<minor>-go`
- ✅ GitHub Actions CI workflows
- ✅ Docker builder images

### Known Limitations (Future Work)

**1. Multi-arch Not Implemented**
- **Status:** CI runs on `ubuntu-latest` with `GO_CI_ARCH=amd64` only
- **Impact:** Published packages contain only amd64 Go toolchains
- **Action Required:** Add arm64 builds via separate matrix jobs

**2. No Local Debian Smoke Test**
- **Status:** Tests not integrated into `make` targets
- **Impact:** Manual testing required
- **Action Required:** Add local smoke test targets

**3. Not Integrated with Dockershelf Images**
- **Status:** Published packages not used by `go/build-image.sh`
- **Impact:** Docker images don't consume pipeline output
- **Action Required:** Update build scripts to use apt.luisalejandro.org

## Common Infrastructure

### APT Repository
- **Location:** `https://apt.luisalejandro.org/dockershelf`
- **GPG Key:** `0F6CBFE94AA83A5E`
- **Suites:** trixie, unstable (sid)
- **Tool:** reprepro for repository management

### CI/CD
- **Platform:** GitHub Actions
- **Builder Images:** GHCR (ghcr.io/dockershelf/dockershelf-*-builder/*)
- **Schedule:** Weekly builds (staggered to avoid overload)
- **Secrets Required:** `DEPLOY_SSH_KEY`, `GH_PACKAGES_TOKEN`
- **Variables Required:** `DEPLOY_USER`, `DEPLOY_HOST`, `DEPLOY_PATH`, `DOCKERSHELF_SUITES`

### Documentation Structure
Each pipeline has:
- `README.md` - Quick start and overview
- `docs/operations.md` - Add versions, bump patches, add suites
- `docs/ci.md` - GitHub Actions setup and workflows
- `docs/deploy-setup.md` - Droplet and repository configuration

## Priority Action Items

### Immediate (Blocking Python)
1. **Fix py3.10-py3.13 CI runs** - Investigate why workflows don't execute
2. **Fix scheduled cron failures** - Determine root cause of failed runs
3. **Fix GHCR access** - Make builder images pullable in CI
4. **Integrate Python APT repo** - Rewrite `python/build-image.sh` to use custom packages

### Short Term
5. **Adjust cron schedules** - Reduce frequency to match image build cadence
6. **Add consumer smoke tests** - Verify `apt install` from clean containers
7. **Integrate Go packages** - Update `go/build-image.sh` to use custom APT repo

### Medium Term
8. **Multi-arch Go builds** - Add arm64 support
9. **Fix reprepro errors** - Investigate publish retry issues
10. **Cost optimization** - Review CI runner usage at scale

## Success Metrics

- [ ] All Python versions (3.10-3.14) building and publishing weekly
- [ ] Dockershelf Python images installing from custom APT repo
- [ ] Dockershelf Go images installing from custom APT repo
- [ ] GHCR builder images pulling successfully in CI
- [ ] Scheduled crons running reliably
- [ ] Consumer smoke tests passing
- [ ] Multi-arch Go packages available

## References

- Python gaps: `dockershelf-pipeline/python-pipeline/docs/gaps.md`
- CI documentation: `*/docs/ci.md` in each pipeline
- Operations manual: `*/docs/operations.md` in each pipeline
