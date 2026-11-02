# GitHub Actions: first workflow and first test

Mon 2 Nov 2026 (Week 5). Repo: `devops-journey`. Lab: `projects/visit-counter`.

## One-line models

- **GitHub Actions is a computer GitHub lends me.** It runs the steps in a YAML file whenever something happens in the repo.
- **A runner is a throwaway computer.** It has the standard tools but none of my project until a step brings the project. It is deleted after the job.
- **A green run proves the code works from a clean machine with only what I pushed.**

| Word | What it is |
|---|---|
| workflow | the YAML file in `.github/workflows/` |
| trigger (`on:`) | the event that starts it, such as `push` |
| job | a group of steps that runs in order on one runner (two jobs means two machines) |
| runner (`runs-on:`) | the virtual machine, such as `ubuntu-latest` |
| step | one command (`run:`) or one ready-made action (`uses:`); the name is optional |

## What happens when I push

1. The push goes to GitHub. A commit alone stays local, so only a push can trigger it.
2. GitHub reads the workflow file from the pushed commit.
3. It starts an empty Ubuntu VM and sends it the steps one at a time.
4. My code arrives only when `actions/checkout` clones it. Without checkout, `ls` runs and prints nothing.
5. The job ends and the VM is discarded, with everything on it.

> Check: the job's steps share one machine, so a file made in step 1 is there in step 2. Shell state is different: each `run:` step starts a fresh shell, so `source .venv/bin/activate` in one step is forgotten by the next. A venv isn't needed on a runner anyway, because the machine is already throwaway.

## A failing step

- The job stops at the first failing step. Later steps are **skipped** (grey crossed circle), not green.
- The cleanup steps (`Post Run actions/checkout`) still run after a failure.
- `lss` in a step: `lss: command not found`, `Error: Process completed with exit code 127`.

> Check: the same rule applies everywhere. **Non-zero exit code means failure**, to Docker's healthcheck, to a shell and to a GitHub Actions step. `127` means command not found. `5` from pytest means no tests were collected, and it still counts as a failure.

## The workflow I wrote

```yaml
name: devops-journey-workflow
on: push
jobs:
    simple-job:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v7.0.1
            - uses: actions/setup-python@v7
              with:
                python-version: "3.12"
            - name: show-files-directories
              run: ls
            - name: show-python-version
              run: python3 --version
            - name: install-required-files-programs
              working-directory: projects/visit-counter/
              run: pip install -r requirements.txt pytest
            - name: pytest
              working-directory: projects/visit-counter/
              run: pytest
```

- `ls` in the first run listed `README.md`, `notes`, `projects`, `scripts` and `systemd`. `.github` is there but hidden, since a plain `ls` skips names that start with a dot.
- The runner's default Python was `3.14.4` (my laptop has `3.14.8`, my Docker image uses `3.12`). `setup-python` pinned to `"3.12"` makes the tests run on the same version as the image. The log showed `3.12.15`.
- `working-directory:` is needed because paths are relative and each step starts in the repo root. My `requirements.txt` is in `projects/visit-counter/`.
- YAML: each `-` starts a new step, so `name` and `run` go in **one** item. `with:` belongs to a `uses:` step, not to the job. A value needs a space after the colon, and I quote versions (`"3.12"`) because an unquoted `3.10` would be read as `3.1`.

## The first test

```python
from app import app

def test_health_returns_ok():
    client = app.test_client()
    response = client.get("/health")
    assert response.status_code == 200
    assert b"Working fine" in response.data
```

- `app.test_client()` comes from Flask. Every Flask app has it. It's a fake browser that calls my routes in the same Python process, with no server and no port.
- `response.data` is bytes, so the expected text is bytes too (`b"..."`).
- The status code comes first, then the body. Counting bytes proves nothing: a 500 error page has content.
- The `/health` test needs no Redis. The Redis client is created on import but only connects on the first command, so the test passes with Redis off, on the runner too. A test of `/` would need Redis.

> Check: pytest only collects files named `test_*.py` or `*_test.py`. The underscore matters. `test.py` matches neither, so plain `pytest` collected 0 items. I fixed it by naming the file on the command line, but the workflow runs plain `pytest`, so the file is now `test_app.py`.

## What the red run caught

I pushed `ci.yml` without pushing `test_app.py`. The runner had only what I pushed:

```
collected 0 items
no tests ran in 0.00s
Error: Process completed with exit code 5.
```

After I pushed the missing file: `collected 1 item`, `1 passed in 0.47s`, whole run 12 s. The file existed only on my laptop. This is exactly the "works on my machine" gap that CI is there to catch.

> Check: read `git status` before I add anything, and add by name, not with `git add .`.

## Still to do

- Tue: run the tests on pull requests, not only on push.
- Wed: build the image and push it to GHCR from Actions.
- Thu: add a security scan of the image.
