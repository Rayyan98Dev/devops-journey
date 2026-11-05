# Building and pushing an image from CI

Wed 4 Nov and Thu 5 Nov 2026 (Week 5). Repo: `devops-journey`. Lab: `projects/visit-counter`.

## One-line models

- **A runner is a throwaway computer.** An image built on it is lost with it, unless it is pushed to a registry before the job ends.
- **Pushing needs two locks open.** The workflow's `permissions: packages: write` says what this job's token may do. The package's **Manage Actions access** says whether this repo may write to this package.
- **A SHA tag is a fingerprint, and `latest` is a sticky note that moves.** The tag on `main` is the merge commit's SHA.
- **`needs:` orders jobs. A required check blocks merges.** Two different settings with different owners.

## What a runner keeps

- Steps in the **same job** share one machine: a file or an image built in step 1 is there in step 2. Each step gets a fresh **shell**, so `cd`, variables and an activated venv are forgotten. It is like opening a new terminal on the same computer.
- A **second job** runs on a different machine, so an image built in job A doesn't exist in job B.
- A fresh runner has no saved login. `docker push` with no login says `denied`.

## Logging in from CI

| Option | Verdict |
|---|---|
| built-in `GITHUB_TOKEN` | best: managed by GitHub, valid only for the run, never stored by me |
| PAT stored as a repo secret | OK but worse: long-lived, usually more rights than one job needs, someone has to rotate it |
| PAT pasted in the workflow file | worst: plain text in the repo, and git history keeps it |

> Check: a repo secret is not stored in the repo. It is stored encrypted in GitHub's settings and hidden in logs (`***`). Its weaknesses are its long life, its wide rights, and that anyone who can edit the workflow could make it print.

## Tags, and when to push

- Tag every image with the commit SHA (`${{ github.sha }}`). With only `latest`, a bad push takes the name and the good image loses its label (it is "orphaned"). With a SHA tag I can point back at the exact commit.
- **Build on every PR, push only after the merge to `main`.** A PR build proves "this still builds". Only reviewed, tested code should become a published image.
- The tag on `main` is the **merge commit**, not the PR branch's last commit. A `push` run is triggered by the commit that arrived on `main`. My merge run tagged `8902e82...`, and the branch's last commit was `71fecc2`.

> Check: pushing every PR is not mainly about "duplicate images wasting space". A registry stores each layer once, so identical layers cost almost nothing. The real costs are unreviewed images, PRs overwriting each other's tag, and clutter.

## The job

```yaml
    build-image:
        needs: simple-job
        runs-on: ubuntu-latest
        permissions:
            contents: read
            packages: write
        steps:
            - uses: actions/checkout@v7.0.1
            - name: log in to GHCR
              if: github.event_name == 'push'
              uses: docker/login-action@<tag from its Releases page>
              with:
                registry: ghcr.io
                username: ${{ github.actor }}
                password: ${{ secrets.GITHUB_TOKEN }}
            - name: build, and push only when allowed
              uses: docker/build-push-action@v7.4.0
              with:
                context: projects/visit-counter
                push: ${{ github.event_name == 'push' }}
                tags: ghcr.io/rayyan98dev/visit-counter:${{ github.sha }}
```

- It goes **inside** the existing `ci.yml`, at the same level as `simple-job`. `needs:` only works between jobs in the same file.
- Two separate switches stop a push on a PR: the login step's `if:` skips the login, and `push:` is `false`, so the image is built but not uploaded.
- Expressions: text goes in **single quotes** (`'push'`), and `${{ }}` wraps only the expression, with no keywords inside. `packages:` takes `read`, `write` or `none`. `push:` takes true or false, and the image name belongs in `tags:`.
- `context:` is relative to the repo root (`projects/visit-counter`), never a laptop path like `~/dev/...`. It is the folder whose files `COPY` can see.
- Pin each action to a tag that exists on its Releases page, `v`-prefixed.

## `needs:` against a required check

| Case on a PR | Does `build-image` run? | Can the PR be merged? |
|---|---|---|
| `simple-job` fails | no, it is **skipped** | no, `simple-job` is required |
| both pass | yes | yes |
| `build-image` fails, only `simple-job` required | yes | **yes**, with a red ✗ |
| `build-image` fails and it is also required | yes | no |

- If a needed job fails, the job that needs it is **skipped**, not run anyway. Running regardless takes `if: always()`.
- A check can only be added to the ruleset after it has reported once. I ran the PR first, then added `build-image` to `protect-main`.

## The 403

```
failed to push ghcr.io/rayyan98dev/visit-counter:<sha>: unexpected status from HEAD request to .../blobs/sha256:...: 403 Forbidden
```

- **401** means "who are you?" (no or bad credentials). **403** means "I know who you are, and no".
- Cause: the package was made by my laptop's PAT, so it wasn't connected to the repo. Fix: Packages, `visit-counter`, Package settings, **Manage Actions access**, add `devops-journey` with **Write**, then re-run the failed jobs.
- A re-run uses the same commit, so the tag is the same.

## Dockerfile written from memory (and the fixes)

| Mine | Fix |
|---|---|
| `FROM python-3.12` | `FROM python:3.12-slim AS builder` (`name:tag`, lowercase stage name) |
| `WORKDIR dev/` | `WORKDIR /app` (a relative path from `/` means `/dev`) |
| `RUN pip install flask` | `RUN pip install --no-cache-dir --prefix=/install -r requirements.txt` (`-r` takes the file, `--prefix` is the destination) |
| `COPY from Builder /usr /usr/bin` | `COPY --from=builder /install /usr/local` (`--from` takes the **stage name**) |
| `USER 1001` with no user created | `useradd --create-home --uid 10001 appuser`, then `USER appuser` |
| `RUN app.y` and later `CMD app.py` | `CMD ["python", "app.py"]` |

> Check: `RUN` happens at **build** time, `CMD` at **start** time. The shell form `CMD app.py` tried to execute a program named `app.py` (`not found`). The exec form (JSON array) is also what avoids the slow-stop bug: with shell form, `sh` is PID 1 and doesn't pass `SIGTERM` on.

> Check: `docker build -f <path> ... <folder>`: `-f` picks the Dockerfile, and the last argument picks the **context**. That's why `COPY app.py .` worked even though my scratch folder had no `app.py`.

> Check: the app calls `sec()` at startup, so `docker run` without the mounted secret crashes with `FileNotFoundError: /run/secrets/api_key`, even with a perfect Dockerfile.

## Result

PR #5 passed both checks, with the image built but not pushed. After the merge, run #19 built and pushed `ghcr.io/rayyan98dev/visit-counter:8902e82de6148f81c45d5f29598dca227816ccfc`. `protect-main` now requires both `simple-job` and `build-image`.

> Check: `SHA256 digest of uploaded artifact` in the Post step is the digest of the build-summary file, not of the image. The image's digest is on the package's version page.

## Still to do

- Thu: scan the image for vulnerabilities.
- Fri: review, and the Project 1 README.
