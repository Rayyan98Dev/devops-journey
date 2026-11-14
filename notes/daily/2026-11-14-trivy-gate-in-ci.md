# 2026-11-14: Trivy as a gate in CI

Week 5 block, finished late. Branch `trivy-scan`, PR #9, runs #26 (red) and the merge run (green).

## What I built

In `build-image` the one step that built and pushed is now three steps, in one job:

```yaml
- name: build the image (no push yet)
  uses: docker/build-push-action@v7.4.0
  with:
    context: projects/visit-counter
    load: true
    push: false
    tags: ghcr.io/rayyan98dev/visit-counter:${{ github.sha }}
- name: scan the image
  uses: aquasecurity/trivy-action@ed142fd0673e97e23eac54620cfb913e5ce36c25   # v0.36.0
  with:
    image-ref: ghcr.io/rayyan98dev/visit-counter:${{ github.sha }}
    severity: 'HIGH,CRITICAL'
    ignore-unfixed: true
    exit-code: '1'
- name: push the image
  if: github.event_name == 'push'
  run: docker push ghcr.io/rayyan98dev/visit-counter:${{ github.sha }}
```

The login step, before them, still has `if: github.event_name == 'push'`.

## Why the scan goes where it does

- **Between build and push.** Before the build there is nothing to scan. After the push, the bad image is already published.
- **In the same job.** A locally built image exists only on the runner that built it, and each job starts on a fresh runner. A second job would have to push the image first and pull it back, which is the publishing I wanted to avoid. Rebuilding in a second job works, but the scanned image could differ from the pushed one (a rebuild pulls the newest base layers). One job guarantees the scanned image is the pushed image.
- `load: true` puts the built image into the runner's local Docker store, so the scan can see it. `push: false` keeps it off the registry.

> Check: I first said the same job was "the most efficient use of resources". That is a side effect. The reason is that the image lives only on that runner.

## The three settings

- `severity: 'HIGH,CRITICAL'`: which levels count. No space after the comma, and quoted.
- `ignore-unfixed: true`: skip findings that have no patched version yet.
- `exit-code: '1'`: make the scan step fail when it finds something. `'0'` only reports and never blocks. The action's inputs are strings, so it is quoted.

## Pinning the action by commit SHA

- A tag is a movable name that points at a commit. A **commit SHA is computed from the content**, so it can't be pointed elsewhere.
- In March 2026, attackers with stolen credentials moved 76 of the 77 `trivy-action` tags to credential-stealing code. Workflows pinned to a full commit SHA did not run it.
- Pin the full **40 characters**, and keep the version as a comment: `@ed142fd0673e97e23eac54620cfb913e5ce36c25   # v0.36.0`. The comment is so a person can read it. I first gave only the 7-character start (`ed142fd`), and GitHub requires the full length.
- A name on a release is not a trust signal (it was my own question about who published it). Pinning the SHA is. I also read the release page, clicked the commit link and compared the hash.

> Check: I said the SHA "points to a specific image". It points to a specific **commit of the action's code**. The Docker equivalent is an image digest.

## What happens when the scan fails

- A step after a failed step is **skipped**, because every `if:` without a status function (`always()`, `failure()`) has an implicit `success() &&` in front. My own `if: github.event_name == 'push'` was all the push step needed. The `if: ${{ exit-code == 0 }}` I first wrote was invented: a workflow can't read `exit-code` like that.
- On a **PR**: `build-image` goes red, the merge button is disabled because it is a required check, and the login and push steps are skipped anyway (they only run on a push event).
- On a **merge run** (a push to `main`): the code is already merged, so nothing is blocked. The run goes red, the push is skipped, and no image is published for that commit.

> Check: I explained the skipped push on a merge run by "the merge button is disabled". That is the PR case. On a merge run it is the implicit `success()`.

## Reading the two runs

- **PR run #26, red.** `simple-job` green. `log in to GHCR` skipped. `build the image` green (8s). `scan the image` red (12s): Report Summary showed the Debian 13.7 row with 2 vulnerabilities and all 9 Python packages at 0. `push the image` skipped. Annotations: 1 error (exit code 1) and 1 notice (a Trivy version notice, see below).
- **Merge run, green.** All steps ran: login (0s), build (8s), scan (12s), push (4s). The same scan passed, then the image was published.
- **The version notice.** `Version 0.76.2 of Trivy is now available, current version is 0.70.0`. It is a notice and does not fail a job. The vulnerability database was downloaded fresh in the run, and my laptop scan on 0.76.2 had found the same kind of result. Updating the scanner is its own deliberate change (parking lot).

## Reading a Trivy table

Columns: Library, Vulnerability, Severity, Status, Installed Version, Fixed Version, Title.

- Library `zlib1g`, installed `1:1.3.dfsg+really1.3.1-1+b1`, fixed in `1:1.3.dfsg+really1.3.1-1+deb13u1`.
- **CVE-2026-76844**: HIGH, fixed. **CVE-2026-85091**: zlib heap buffer overflow in `gz_vacate()`. (The second row's severity was not visible in my screenshot; it passed the HIGH,CRITICAL filter and has a fix.)
- One advisory's title mentioned `webpack-dev-middleware` for a zlib finding. Titles can be wrong; trust the library name and the versions, and check the advisory link.

> Check: I expected the old `apt` CVE from my 6 Nov local scan. It was gone and zlib had two new ones. New CVEs appear between runs, which is what the gate is for.
> Check: I thought the red scan might be because Trivy was outdated. It wasn't: the notice and the failure were two different things.

## Three ways to get to green

1. **Loosen the gate** (`exit-code: '0'`, drop HIGH). Cheating: the hole stays in the image.
2. **Fix the image.** What I did.
3. **Accept the risk in writing** with a `.trivyignore` file: the CVE ID, a reason, and a review date. Only when the finding truly can't be reached or fixed.

## The fix

Final stage of `projects/visit-counter/Dockerfile`:

```dockerfile
FROM python:3.12-slim
RUN useradd --create-home --uid 10001 appuser
WORKDIR /app
COPY --from=builder /install /usr/local
COPY app.py .
RUN apt-get update \
    && apt-get install -y --only-upgrade zlib1g \
    && rm -rf /var/lib/apt/lists/*
USER appuser
CMD ["python", "app.py"]
```

- The `RUN` goes **above** `USER appuser`. Installing packages needs root, and every instruction after `USER` runs as `appuser`. Do the root work first and drop privileges last.
- `--only-upgrade` upgrades a package only if it is already installed and never installs anything new. The last line deletes apt's package lists to keep the image small.
- **Trade-off:** the same Dockerfile now builds a **different image on a different day**, because it pulls the newest patched `zlib1g`. Builds are less reproducible. A security patch is worth that here.
- Optional: moving the `apt` line above `COPY app.py .` keeps Docker's cache working when only `app.py` changes (CI starts with an empty cache, so it makes no difference there).

> Check: I first said the `apt` line goes below `USER appuser` "so it runs as appuser". It must be above, because it needs root.

## Habit

A gate is not trusted until it has been seen failing. This one rang on its first run, for a real finding.
