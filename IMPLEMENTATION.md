# Implementation Guide: Fix py3.10-py3.13 CI Workflows

**Status:** Phase 3 completed locally. Phases 1, 2, and 4 require GitHub access.

---

## ✅ Phase 3: Cron Schedules Updated (COMPLETED)

All workflow schedules have been updated from daily to **weekly Tuesday** with staggered times:

| Repo | Old Schedule | New Schedule | Time (UTC) |
|------|-------------|--------------|------------|
| py3.10 | `45 9 * * *` (daily 09:45) | `0 3 * * 2` | Tue 03:00 |
| py3.11 | `50 9 * * *` (daily 09:50) | `10 3 * * 2` | Tue 03:10 |
| py3.12 | `55 9 * * *` (daily 09:55) | `20 3 * * 2` | Tue 03:20 |
| py3.13 | `0 10 * * *` (daily 10:00) | `30 3 * * 2` | Tue 03:30 |
| py3.14 | `5 10 * * *` (daily 10:05) | `40 3 * * 2` | Tue 03:40 |

**Files modified:**
- `dockershelf-pipeline/py3.10/.github/workflows/main.yml`
- `dockershelf-pipeline/py3.11/.github/workflows/main.yml`
- `dockershelf-pipeline/py3.12/.github/workflows/main.yml`
- `dockershelf-pipeline/py3.13/.github/workflows/main.yml`
- `dockershelf-pipeline/py3.14/.github/workflows/main.yml`

**Next step:** Commit and push these changes to each GitHub repository.

---

## 📋 Phase 1: Verify GitHub Actions Configuration

**Status:** ✅ Actions tab already available on all repos

### Verification Steps:

1. **Check workflow permissions (recommended):**
   - Go to `https://github.com/Dockershelf/py3.10/settings/actions`
   - Verify "Workflow permissions" is set to "Read and write permissions"
   - ✅ Ensure "Allow GitHub Actions to create and approve pull requests" is checked
   - Repeat for py3.11, py3.12, py3.13

2. **Confirm workflow files are visible:**
   - Go to each repo's Actions tab
   - Verify "packaging" workflow appears in the workflows list
   - If not visible, push the updated workflow files first

### Expected State:

- ✅ Actions tab active on py3.10, py3.11, py3.12, py3.13, py3.14
- ✅ "Run workflow" button should be available once workflow files are pushed
- ✅ Workflow permissions set to read and write

---

## 🧪 Phase 2: Prime Workflows with Test Runs (MANUAL - Sequential Execution)

**Important:** Run these **sequentially** (one at a time), starting with py3.13.

### Test Run 1: py3.13 (Start Here)

1. **Navigate to Actions:**
   - Go to `https://github.com/Dockershelf/py3.13/actions`
   - Click on "packaging" workflow

2. **Trigger manual run:**
   - Click "Run workflow" button (top right)
   - Branch: `main`
   - **Publish to APT droplet after smoke test:** `false` (UNCHECK this box)
   - Click "Run workflow"

3. **Monitor execution (~30-40 minutes):**
   - Click on the running workflow
   - Watch these jobs complete:
     - ✅ `update` - Updates cpython submodule, runs meta-gbp
     - ✅ `build` - Matrix job for trixie and unstable
     - ✅ `smoke` - Matrix smoke tests in debian:trixie-slim and debian:sid-slim
     - ⏭️ `publish` - Should skip (publish: false)

4. **Verify success:**
   - All jobs show green checkmarks
   - Artifacts uploaded: `python3.13-trixie.tar.gz`, `python3.13-unstable.tar.gz`
   - No errors in job logs (GHCR pull failures are OK, fallback to local build)

5. **If py3.13 SUCCEEDS → proceed to py3.12**
   **If py3.13 FAILS → STOP and investigate before proceeding**

### Test Run 2: py3.12 (Only After py3.13 Succeeds)

Repeat same steps as py3.13:
- `https://github.com/Dockershelf/py3.12/actions`
- Run workflow with `publish: false`
- Monitor completion
- Verify artifacts

**Wait ~1 hour between test runs to avoid overwhelming GitHub Actions runners.**

### Test Run 3: py3.11 (Only After py3.12 Succeeds)

Same process as above.

### Test Run 4: py3.10 (Only After py3.11 Succeeds)

Same process as above.

### Common Issues to Watch For:

**Issue:** "Workflow not found" or Actions tab disabled
- **Fix:** Complete Phase 1 first (enable Actions)

**Issue:** GHCR pull denied errors in logs
- **Expected:** This is gap #4, known issue. Workflow should fallback to local build.
- **Impact:** +2 minutes per job (acceptable for now)

**Issue:** Build failures, compilation errors
- **Action:** Check job logs, may indicate packaging repo issues
- **Stop:** Don't proceed to next version until resolved

**Issue:** Smoke test failures
- **Action:** Package installation or import failed
- **Stop:** Critical issue, investigate before proceeding

---

## 🚀 Phase 4: Enable Publishing (MANUAL - After All Tests Pass)

**Only proceed when ALL test runs (py3.10-py3.13) have completed successfully.**

### Publish Run 1: py3.13

1. **Navigate to Actions:**
   - Go to `https://github.com/Dockershelf/py3.13/actions/workflows/main.yml`

2. **Trigger publish run:**
   - Click "Run workflow"
   - Branch: `main`
   - **Publish to APT droplet after smoke test:** `true` (CHECK this box)
   - Click "Run workflow"

3. **Monitor execution:**
   - Wait for update → build → smoke jobs to complete
   - Watch `publish` job execute (should no longer skip)

4. **Verify APT repository update:**
   ```bash
   # Check packages are published
   curl -s https://apt.luisalejandro.org/dockershelf/dists/trixie/main/binary-amd64/Packages | grep "^Package: python3.13"
   curl -s https://apt.luisalejandro.org/dockershelf/dists/unstable/main/binary-amd64/Packages | grep "^Package: python3.13"
   ```

5. **Consumer smoke test:**
   ```bash
   docker run --rm debian:trixie-slim bash -c '
     curl -fsSL https://apt.luisalejandro.org/debian/dists/trixie/Release.gpg | \
       gpg --dearmor -o /usr/share/keyrings/dockershelf.gpg
     echo "deb [signed-by=/usr/share/keyrings/dockershelf.gpg] https://apt.luisalejandro.org/dockershelf trixie main" \
       > /etc/apt/sources.list.d/dockershelf.list
     apt-get update -qq
     apt-get install -y python3.13
     python3.13 --version
   '
   ```

### Publish Runs 2-4: py3.12, py3.11, py3.10

Repeat same process for each version:
- Run with `publish: true`
- Verify APT repo updated
- Run consumer smoke test

**Can run these in parallel or sequentially (parallel faster but harder to debug).**

---

## 📊 Verification Checklist

### After Phase 2 (Test Runs)
- [ ] py3.13 test run succeeded
- [ ] py3.12 test run succeeded
- [ ] py3.11 test run succeeded
- [ ] py3.10 test run succeeded
- [ ] All runs show artifacts uploaded
- [ ] No critical errors in logs (GHCR pull failures OK)

### Before Starting (Prerequisites)
- [x] Actions tab available on all py3.XX repos
- [ ] Updated workflow files pushed to GitHub
- [ ] Workflow permissions verified (read and write)
- [ ] "packaging" workflow visible in Actions tab

### After Phase 4 (Publishing)
- [ ] py3.13 packages in APT repo (trixie + unstable)
- [ ] py3.12 packages in APT repo (trixie + unstable)
- [ ] py3.11 packages in APT repo (trixie + unstable)
- [ ] py3.10 packages in APT repo (trixie + unstable)
- [ ] Consumer smoke tests pass for all versions
- [ ] APT index shows all Python versions:
  ```bash
  curl -s https://apt.luisalejandro.org/dockershelf/dists/trixie/main/binary-amd64/Packages | \
    grep "^Package: python3\." | sort
  # Expected output:
  # Package: python3.10
  # Package: python3.11
  # Package: python3.12
  # Package: python3.13
  # Package: python3.14
  ```

### After First Weekly Cron (Next Tuesday)
- [ ] All 5 repos triggered automatically on Tuesday 03:00-03:40 UTC
- [ ] All cron runs completed successfully
- [ ] APT repo updated with latest upstream Python versions
- [ ] No manual intervention required

---

## 🔧 Troubleshooting

### Workflows Don't Appear After Enabling Actions

**Symptom:** Actions tab enabled but "packaging" workflow not listed

**Cause:** Workflow files not yet on GitHub (only local)

**Fix:** 
```bash
cd dockershelf-pipeline/py3.13
git add .github/workflows/main.yml
git commit -m "Update cron schedule to weekly Tuesday 03:30 UTC"
git push origin main
```

Repeat for py3.10, py3.11, py3.12, py3.14.

### "Workflow not found" When Trying to Run

**Cause:** Workflow file syntax error or not in `.github/workflows/` directory

**Fix:** Verify workflow file exists and is valid YAML:
```bash
cd dockershelf-pipeline/py3.13
cat .github/workflows/main.yml
```

### Build Job Fails with "Permission denied"

**Symptom:** Build logs show permission errors

**Cause:** Workflow permissions not set to "Read and write"

**Fix:** Return to Phase 1, ensure workflow permissions are set correctly

### Publish Job Runs But Packages Don't Appear in APT Repo

**Symptom:** Publish job succeeds but packages not in Packages index

**Cause:** SSH key or deploy variables not configured

**Fix:** Verify repository variables/secrets:
```bash
cd dockershelf-pipeline/python-pipeline
./scripts/ci-check-config.sh --strict
```

Required secrets: `DEPLOY_SSH_KEY`
Required variables: `DEPLOY_USER`, `DEPLOY_HOST`, `DEPLOY_PATH`, `DOCKERSHELF_SUITES`

---

## 📝 Commit Messages

When pushing updated workflow files:

```bash
# For each py3.XX repo:
cd dockershelf-pipeline/py3.13
git add .github/workflows/main.yml
git commit -m "ci: change schedule from daily to weekly Tuesday 03:30 UTC

Reduces CI runner cost and aligns with Dockershelf image build frequency.
Weekly Tuesday schedule matches documentation in python-pipeline/docs/ci.md.

Part of gap #1 resolution: enable py3.10-py3.13 CI workflows."

git push origin main
```

Adjust commit time for each repo:
- py3.10: `03:00 UTC`
- py3.11: `03:10 UTC`
- py3.12: `03:20 UTC`
- py3.13: `03:30 UTC`
- py3.14: `03:40 UTC`

---
GitHub Actions enabled on py3.10-py3.13 repos (already available)
3. ⏳ Workflow files committed and pushed to GitHub

This implementation is **complete** when:

1. ✅ All 5 workflow files updated to weekly Tuesday schedule (DONE)
2. ✅ Workflow files committed and pushed to GitHub
3. ✅ GitHub Actions enabled on py3.10-py3.13 repos
4. ✅ All test runs (publish: false) suActions already enabled. Ready to push workflow files and begin Phase 2 (test runs
5. ✅ All publish runs (publish: true) succeeded
6. ✅ APT repo contains packages for py3.10, py3.11, py3.12, py3.13, py3.14
7. ✅ Consumer smoke tests pass for all versions
8. ✅ First weekly cron (next Tuesday) executes successfully

**Current Status:** Phase 3 complete. Ready for Phase 1 (GitHub UI configuration).
