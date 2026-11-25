# Bug journal

Format: symptom, cause, fix.

## Bash

* **`return` outside a function** (`cd reports || return`)
  - Symptom: error instead of leaving the script.
  - Cause: `return` only works inside a function (or a sourced script).
  - Fix: `cd reports || exit 1`. `exit` leaves a script, `return` leaves a function.

* **`./hello.sh` gave "Permission denied"**
  - Symptom: `bash: ./hello.sh: Permission denied`, but `bash hello.sh` worked.
  - Cause: a new file has no `x` bit, and `./script` needs it. `bash hello.sh` only needs read permission.
  - Fix: `chmod 755 hello.sh` (or `chmod u+x hello.sh`).

* **`2>&1 > out.txt` put the error on the screen, not in the file** (got this one wrong twice)
  - Symptom: the error showed on screen even though I redirected to a file.
  - Cause: redirections run left to right, and `2>&1` copies where stdout points *at that moment*. Here stdout still pointed at the screen.
  - Fix: `> out.txt 2>&1`. Move stdout first, then copy it.

* **`sudo kind` said "command not found"** (24 Nov)
  - Symptom: predicted an authentication or key error; the real failure is `sudo: kind: command not found`. At wrap-up I still said it was about credentials, and that the working form is "piped into sudo".
  - Cause: `sudo` swaps my `PATH` for its own short list (`secure_path`), and `~/.local/bin` isn't on it. Nothing to do with keys. In `sudo "$(command -v kind)" ...` **my shell** expands `$(...)` into the full path *before* sudo starts, so root is handed `/home/.../.local/bin/kind`. Nothing is piped, and it still runs as root.
  - Fix: `sudo "$(command -v kind)" ...`. Programs from `dnf` live in `/usr/bin`, which is on both lists. Same rule as `>`: my shell does `$(...)` and redirections first, then runs the command.

* **`sudo kind get kubeconfig > ~/.kube/config`: predicted root would own the file** (24 Nov)
  - Symptom: `ls -l` showed `catto-laptop` as owner.
  - Cause: the `>` is done by my own shell, as me, before `sudo` runs. `sudo` only ran kind.
  - Fix: nothing to fix; it's what I want. `chmod 600`, because the kubeconfig holds the cluster's admin certificate and key.

* **Ctrl-Z instead of Ctrl-C** (24 Nov)
  - Symptom: a hanging `curl` turned into `[1]+  Stopped  curl http://10.244.0.5`.
  - Cause: Ctrl-Z **pauses** a program and parks it as a background job; Ctrl-C cancels it.
  - Fix: `jobs` lists it, `kill %1` ends it (or `fg` then Ctrl-C). Use `curl -m 3` so a dead address gives up by itself.

* **`~/Dev/lab` looked root-owned and unreadable after copying it to the desktop** (25 Nov)
  - Symptom: `ls -la ~/Dev/lab` listed every entry as `---------`, size `0`, owner `root`, and `ls ~/Dev/lab/k8s` said `Permission denied`. I thought the USB copy had made everything root's and ran `sudo chown -R catto: ~/Dev/lab`, which changed nothing.
  - Cause: `sudo ls -la` showed the truth: everything was already mine. The `lab` directory itself was `rw-r--r--`. On a directory, `r` = list the names, `x` = go in and look them up, `w` = create/rename/delete entries (only together with `x`). With `r` and no `x`, `ls` got the names but couldn't read anything about them, so it printed placeholders. `terraform` was the mirror image, `--x--x--x`: anyone could go in and open a file by its exact name, but nobody could list it. Probably old `chmod` experiments, not the USB (only two folders were hit). At teach-back I still said `rw-` would let me rename things inside.
  - Fix: `sudo chmod -R u+rwX,go+rX,go-w ~/Dev/lab` → directories `755`, files `644`. Capital `X` adds `x` only to directories and to files that already have it, so plain files never become executable. When `ls` output looks impossible, look with `sudo ls -la` before changing anything.

* **Pasted a placeholder into the terminal** (17 Nov)
  - Symptom: `git clone <your repo's clone URL> /tmp/readme-test` hung and showed `>`.
  - Cause: `<` is a redirect, so the shell waited for input from a file.
  - Fix: Ctrl-C (nothing ran). Replace placeholders with real values, or use `"$(git rev-parse --show-toplevel)"`.

## Python

* **Thought `boto3...Table(...)` creates a table** (23 Nov review)
  - Symptom: I said `table = ...` sits outside `handler` "so a new table isn't made with every request, or the count would always be 1".
  - Cause: `boto3.resource("dynamodb").Table(name)` makes a Python **handle** that points at a table that already exists (Terraform made it). It creates nothing in AWS.
  - Fix: it's outside `handler` so it's built once per cold start and reused by warm requests (470 ms first request vs 23 ms after). And `ADD visits :one` on a missing item **creates** it with `visits = 1`, so no setup step is needed.

* **Argument count one too high**
  - Symptom: `$#` and `len(sys.argv)` gave different numbers.
  - Cause: Python stores command-line args in a list, and the script name is the first item.
  - Fix: `$#` is `len(sys.argv) - 1`. `"$@"` matches `sys.argv[1:]`.

* **No-arguments run exited with the wrong code**
  - Symptom: `echo $?` showed `0` when no name was given.
  - Cause: forgot `sys.exit(2)` after the usage message.
  - Fix: add `sys.exit(2)` and check with `echo $?`.

* **`except ConnectionError` didn't catch the `requests` error**
  - Symptom: a traceback instead of my friendly message.
  - Cause: Python has its own `ConnectionError`, and `requests` has a different class with the same name.
  - Fix: `requests.RequestException` (the parent class that covers connection errors and timeouts).

* **`200 >= r.status_code < 400` was backwards**
  - Symptom: a `301` fell into the error branch.
  - Cause: the chain reads "200 is at least the status", so the status had to be 200 or less.
  - Fix: write the chain in ascending order: `200 <= r.status_code < 400`.

* **`sys.argv.strip()` on a list**
  - Symptom: an error as soon as an argument was passed.
  - Cause: `.strip()` belongs to strings, and `sys.argv` is a list.
  - Fix: `sys.argv[1].strip()`.

* **`"Error: " + r.status_code` mixed text with a number**
  - Symptom: an exception when the error branch ran.
  - Cause: `+` can't join a string and an integer.
  - Fix: an f-string: `f"Error: {r.status_code}"`.

* **Blank line after every line read from a file**
  - Symptom: `readfile.py` printed an empty line between each name.
  - Cause: each line from the file ends with `\n`, and `print` adds another one.
  - Fix: `print(line.strip())`, or `line = line.strip()` first. `print(repr(line))` shows the hidden `\n`.

* **`unique[0]` on a set**
  - Symptom: `TypeError: 'set' object is not subscriptable`.
  - Cause: a set has no order and no positions, so `[0]` means nothing.
  - Fix: loop over it with `for x in unique`, or use a list if the order matters.

* **`point[0] = 10` on a tuple**
  - Symptom: a `TypeError` when assigning to an item.
  - Cause: `(3, 4)` is a tuple, which can't be changed once made. I thought it was a list.
  - Fix: build a new tuple, or use a list (`[3, 4]`) if it has to change.

## Git

* **`origin/main` didn't move when I committed**
  - Symptom: I expected `git status` to say "up to date" after a local commit. It said "ahead of 'origin/main' by 1 commit".
  - Cause: `origin/main` is a local bookmark of where the remote's `main` was at the last push or fetch. It only moves then.
  - Fix: nothing is broken. `git push` updates it, `git fetch` refreshes it, and `git log origin/main..` lists unpushed commits.

* **Expected `git merge scratch` to make a new commit, but it fast-forwarded**
  - Symptom: no new commit, just `Fast-forward`.
  - Cause: `main` had nothing the other branch lacked, so Git only moved the `main` label forward.
  - Fix: a merge commit with two parents only appears when both branches have new commits. Check with `git log --oneline --graph --all`.

* **`git push` rejected with "(fetch first)"**
  - Symptom: `! [rejected] main -> main (fetch first)`.
  - Cause: the remote had a commit I didn't have. A push is only accepted if the remote's tip is already in my history.
  - Fix: `git fetch`, then `git merge origin/main` (or `git pull`), then `git push`.

* **`git log --online` and `git HEAD`**
  - Symptom: `fatal: unrecognized argument: --online`, and `'HEAD' is not a git command`.
  - Cause: a typo (`--oneline`), and `HEAD` is a pointer, not a command.
  - Fix: `git log --oneline`, and `cat .git/HEAD` (or `git rev-parse HEAD`) to look at it.

* **Thought `git fetch --prune` cleans up after a merge** (19 Nov)
  - Symptom: I gave `git fetch --prune` as the whole cleanup after merging a PR.
  - Cause: `--prune` only removes `origin/<branch>` copies of branches deleted on GitHub. It doesn't update my local `main` or delete my local branch.
  - Fix: `git switch main`, `git pull`, `git fetch --prune`, `git branch -d <branch>`. Check with `git branch -a`.

* **Branch name typos: `add-odic` and a PR compare on `fix-regionremote`** (20 Nov)
  - Symptom: a branch called `add-odic`, and GitHub's compare page said "There isn't anything to compare".
  - Cause: typing slips. The compare box had two words stuck together, so it named a branch that doesn't exist.
  - Fix: `git branch -m add-oidc` before pushing; on the compare page pick the branch from the list instead of typing it.

* **Edited `lambda.tf` on an old branch** (21 Nov)
  - Symptom: the prompt still said `(oidc-workflow)` while I made the next change.
  - Cause: I didn't switch after pushing; the earlier PR wasn't merged yet.
  - Fix: merge the old PR, then `git stash`, `git switch main && git pull`, `git switch -c <new>`, `git stash pop`. Read the branch in the prompt before editing.

## Docker

* **Phone reached a container port I never opened**
  - Symptom: `-p 8080:80` nginx loaded on my phone, but 8080 isn't open in my firewall zone.
  - Cause: Docker writes its own firewall rules that run before firewalld's zones, and `-p 8080:80` listens on `0.0.0.0` (every connection).
  - Fix: `-p 127.0.0.1:8080:80` to listen only on the laptop; check the `PORTS` column in `docker ps`.

* **"file with no instructions" on docker build**
  - Symptom: build failed straight away, showing only empty lines.
  - Cause: the Dockerfile on disk was empty lines; the text in VSCodium was never saved.
  - Fix: write it with a flush-left heredoc, check with `cat -A Dockerfile`.

* **"The slow stop (bug)"**
  - Symptom: `docker compose down` took 10.2 s for `app` but 0.1 s for Redis.
  - Cause: `app` was PID 1 in its container, and PID 1 ignores `SIGTERM` unless it has a handler for it. Docker sends `SIGTERM`, waits 10 s, then sends `SIGKILL`.
  - Fix: `init: true` in `compose.yaml` makes a tiny init program PID 1.
    - **Check:** the init program (Docker uses `tini`) receives `SIGTERM` and forwards it to my app. My app is no longer PID 1, so it stops normally. After the fix: 0.2 s.
  - The `up -d` after the change still took 10.6 s, because Compose first stopped the old container, the one without `init`.

* **`invalid reference format` when tagging for GHCR**
  - Symptom: `docker tag web:0.1.1 ghcr.io/Rayyan98Dev/web:0.1.1` failed with `repository name must be lowercase`.
  - Cause: image references must be all lowercase, and my GitHub username has capitals.
  - Fix: `ghcr.io/rayyan98dev/web:0.1.1`. GitHub isn't case sensitive, so it still points at my account.

* **`redis-cli` wasn't in the `docker image inspect` output**
  - Symptom: I looked for a healthcheck tool in the `inspect` output and it wasn't there.
  - Cause: `inspect` shows how an image *runs* (CMD, env, ports), not the files inside it.
  - Fix: `sudo docker run --rm redis:7 ls /usr/local/bin` lists the programs; `docker history --no-trunc` shows how it was built.

* **First `docker push` to GHCR ended in `denied` after uploading the layers**
  - Symptom: every layer showed `Pushed`, then `error from registry: denied`. Pushing a second tag worked, and so did a retry of the first.
  - Cause: not confirmed. Probably a one-time failure while GHCR created the package on its first push.
  - Fix: push again. Check with `docker pull` of each tag that the registry has the manifest. Layers alone can't be pulled.

* **New route returned 404 after I added it to `app.py`**
  - Symptom: `curl /sec` gave 404 even though the route was in my file.
  - Cause: `app.py` is copied into the image at build time. `docker compose up -d` reused the old image, which had no such route.
  - Fix: `docker compose up -d --build`. Check with `docker compose exec app grep -n sec /app/app.py`.

* **`FileNotFoundError: 'run/secrets/api_key'`**
  - Symptom: a 500 and a traceback when the code opened the secret.
  - Cause: the path had no leading `/`, so Python looked inside the working directory (`/app/run/secrets/...`).
  - Fix: `/run/secrets/api_key`. A path that means "from the root of the container" starts with `/`.

* **`docker build` failed: `FROM requires either one or three arguments`**
  - Symptom: a parse error on the second `FROM`, before any step ran.
  - Cause: `FROM pyhon-3.12 slim` had two words and a typo. An image is `name:tag`, so the tag follows a colon, not a dash or a space.
  - Fix: `FROM python:3.12-slim`. Stage names are lowercase (`AS builder`), or BuildKit warns.

* **`WORKDIR dev/` put the app in `/dev`**
  - Symptom: none at first, only wrong when I read it.
  - Cause: a relative `WORKDIR` starts from `/`, so `dev/` means `/dev`, the device directory.
  - Fix: an absolute path: `WORKDIR /app`.

* **`CMD app.py` printed `/bin/sh: 1: app.py: not found`**
  - Symptom: the container exited at once; `COPY app.py .` had worked.
  - Cause: shell form runs `sh -c "app.py"`, which looks for a program called `app.py`. I also thought it failed because the file was missing from my scratch folder, but the build context was `projects/visit-counter`, so the copy had worked. `RUN` is for build time, `CMD` for start time.
  - Fix: `CMD ["python", "app.py"]`. The exec form also lets the app receive `SIGTERM` (no slow stop).

* **Wrong `pip` and `COPY --from` forms in a multi-stage build**
  - Symptom: wrote `pip install flask -r /install` and `COPY --from=/install`.
  - Cause: `-r` takes a requirements **file**, `--prefix` takes the destination, and `--from` takes the **stage name**, not a path.
  - Fix: `pip install --no-cache-dir --prefix=/install -r requirements.txt`, then `COPY --from=builder /install /usr/local`.

* **My image ran as uid 1001, not 10001**
  - Symptom: `docker run --rm vc-attempt id` printed `uid=1001(appuser)`.
  - Cause: `useradd --uid` was left out, so the default number was used. My notes and the real image use 10001.
  - Fix: `useradd --create-home --uid 10001 appuser`, then `USER appuser`.

* **Expected a missing secret file to make the container "unhealthy"** (17 Nov)
  - Symptom: fresh clone, `docker compose up`: `invalid mount config for type "bind": bind source path does not exist: .../secrets/api_key.txt`.
  - Cause: unhealthy means the container runs and fails its healthcheck. Here Docker couldn't create the container at all, so there is no health status. A fresh clone lacks `.env` and `secrets/api_key.txt` (`app.env` is committed).
  - Fix: README steps that create `.env` and `secrets/api_key.txt` with a dummy key. `ls -a` in the clone shows what is missing.

* **Fresh-clone test reused my real project's Redis** (17 Nov)
  - Symptom: `visit-counter-redis-1` was "created 2 weeks ago" and the page said "visited 10 times".
  - Cause: Compose names a project after its folder. The clone's folder was also `visit-counter`, so it matched my real containers and volume (`visit-counter_redis-data`). The tutor's `down -v` would have deleted that real volume (caught before it ran).
  - Fix: `docker compose -p readme-test up -d --build` isolates the test (new network, volume and containers; first visit is 1), and `-p readme-test down -v` is safe. Without `-p`, never use `-v`.

* **Thought `.env` beats `app.env`** (17 Nov)
  - Symptom: my comment in `app.env` said ".env always beats it".
  - Cause: two steps. First `.env` (or the shell) fills in `${...}` inside `compose.yaml`. Then the container gets `environment:` over `env_file:` (`app.env`) over Dockerfile `ENV`. `.env` never feeds the container directly.
  - Fix: the comment says `environment:` in `compose.yaml` overrides this file, and its value comes from `.env`. Still shaky: hands-on test in the parking lot.

* **Said 1001 and "rootless" again at the README review** (19 Nov)
  - Symptom: listing Project 1's security decisions, I said the app runs as uid 1001 and that `sudo docker` is rootless.
  - Cause: the same uid slip as before, and I mixed up the two Docker modes. `sudo docker` talks to the root daemon, so it's **rootful**. Rootless was dropped on 26 Oct.
  - Fix: uid **10001**; rootful Docker plus hardened containers. Both are now written in the README's "Security decisions".

* **Docker on the desktop: iptables couldn't create the `nat` chain** (24 Nov, desktop)
  - Symptom: after `desktop-setup.sh`, Docker failed to start. iptables couldn't make the `nat` `PREROUTING` chain.
  - Cause: the update installed new kernels and removed the module folder of the kernel that was **still running** (7.2.2). `/usr/lib/modules` only had `6.18.60-3-cachyos-lts` and `7.3.5-2-cachyos`. Each kernel version has its own folder, and the running kernel can only load modules from `/usr/lib/modules/$(uname -r)`, so the netfilter/NAT modules Docker needs couldn't load.
  - Fix: reboot into the new kernel. Before Docker or kind work after an update: `uname -r` must appear in `ls /usr/lib/modules` (25 Nov: `7.3.5-2-cachyos`, OK). Add that check to `desktop-setup.sh` (parking lot).

## CI (GitHub Actions)

* **`name` and `run` written as two list items**
  - Symptom: the workflow had a step with a name and no command, and another with a command and no name.
  - Cause: in a YAML list each `-` starts a new item, so `- name:` and `- run:` became two separate steps.
  - Fix: one item, one dash: `- name: ...` then `  run: ...` indented under it.

* **Plain `pytest` found no tests (`collected 0 items`)**
  - Symptom: `no tests ran`; I ran `pytest test.py` by name and it worked.
  - Cause: pytest only collects files named `test_*.py` or `*_test.py`. `test.py` matches neither.
  - Fix: rename to `test_app.py`.

* **CI failed with exit code 5 after I pushed the workflow**
  - Symptom: `collected 0 items`, `Error: Process completed with exit code 5`, though the test passed on my laptop.
  - Cause: I pushed `ci.yml` but not `test_app.py`. The runner had only what I pushed.
  - Fix: add the file and push. Read `git status` before adding, and add by name.

* **`source .venv/bin/activate` in its own step did nothing**
  - Symptom: no error, but the next step didn't use the venv.
  - Cause: each `run:` step is a new shell, so the activation is forgotten. A runner is already throwaway, so a venv isn't needed.
  - Fix: delete the venv steps, and use `setup-python` to pin the version.

* **`with:` under the job and `python-version:3.12`**
  - Symptom: invalid workflow, and no `setup-python` step existed.
  - Cause: `with:` is the input of one `uses:` step, not a job setting, and `key:value` needs a space after the colon.
  - Fix: a `- uses: actions/setup-python@...` step with `with:` under it, `python-version: "3.12"`.

* **A PR started no CI run, and the check said `(push)`**
  - Symptom: the first PR showed no pull-request checks, and the check name ended in `(push)`.
  - Cause: I had added `pull_request:` to `ci.yml` on my laptop but never pushed it. GitHub reads the workflow from the pushed commit.
  - Fix: push the file. Read the word in brackets after the check name: it says which trigger ran.

* **Ruleset created, but the merge button still worked**
  - Symptom: a required `simple-job` check was failing, and PR #2 could still be merged.
  - Cause: **Enforcement status** was `Disabled`. A new ruleset isn't active until I switch it.
  - Fix: set it to `Active` and save. A rule doesn't protect anything until it is switched on, and a greyed-out button proves it is.

* **`git push` to `main` rejected: `Required status check "simple-job" is expected`**
  - Symptom: `GH013: Repository rule violations found for refs/heads/main`, `push declined due to repository rule violations`.
  - Cause: the ruleset needs the check to pass before a commit lands on `main`. A commit pushed straight to `main` has never been tested, however good the tests are.
  - Fix: `git reset --soft HEAD~1`, `git switch -c <branch>`, commit, `git push -u origin <branch>`, open a PR, merge when green.

* **My prediction: renaming the job "errors or just passes"**
  - Symptom: wrong guess about what a renamed job does to a required check.
  - Cause: the rule finds the check by the job name. A check that never reports isn't passed and isn't an error: it stays "expected" and blocks the merge.
  - Fix: rename the job and update the ruleset in the same PR.

* **The first run of PR #5 failed, and the next commit was called "fixing docker version"**
  - Symptom: a red ✗ on the first commit of the PR, green after the second.
  - Cause: a wrong action version tag (the exact error wasn't saved, so this is the likely cause). An unresolvable tag fails the job at "Set up job", before any step.
  - Fix: use a tag that exists on the action's Releases page, `v`-prefixed. Save the error text next time.

* **Workflow expression mistakes caught in review (before running)**
  - Symptom: `packages: docker`, `if: github.event_name == "push"`, `push: ${{ if: ... }}` and `push: ghcr.io/...:0.1.2`.
  - Cause: `packages:` takes `read`, `write` or `none`. Expression text needs **single** quotes. `${{ }}` wraps only the expression, with no keyword inside. `push:` takes true or false, and the image name belongs in `tags:`.
  - Fix: `packages: write`, `if: github.event_name == 'push'`, `push: ${{ github.event_name == 'push' }}`, name in `tags:`.

* **Push to GHCR from Actions: `403 Forbidden` on `HEAD .../blobs/sha256:...`**
  - Symptom: the login step was green, then the push failed.
  - Cause: the package was created by my laptop's PAT and wasn't connected to the repo, so the repo's `GITHUB_TOKEN` had no write access. (401 is "who are you", 403 is "I know you, and no".)
  - Fix: Package settings, **Manage Actions access**, add the repo with **Write**, re-run the failed jobs. The workflow's `permissions: packages: write` is a second, separate lock and still needed.

* **Pinned `trivy-action` by tag, then by a 7-character SHA**
  - Symptom: my first draft had `@v0.36.0` with the comment `# v?.??.?`, and later I gave only `ed142fd`.
  - Cause: a tag is a movable name (the March 2026 attack moved tags), and GitHub needs the **full 40-character** commit SHA in a `uses:` line, so a short one fails with "unable to resolve action".
  - Fix: `aquasecurity/trivy-action@ed142fd0673e97e23eac54620cfb913e5ce36c25   # v0.36.0`. Copy the full hash from the commit link on the release page.

* **Invented `if: ${{ exit-code == 0 }}` for the push step**
  - Symptom: a condition that can't work.
  - Cause: a workflow can't read `exit-code` like that, and it isn't needed. A step after a failed step is skipped anyway, because every `if:` without a status function has an implicit `success() &&` in front.
  - Fix: `if: github.event_name == 'push'`.

* **Wrong formats in the `trivy-action` inputs**
  - Symptom: `severity: HIGH, CRITICAL`, `ignore-unfixed: TRUE` and `exit-code: 1`, plus `image-ref: ???` left in.
  - Cause: the inputs are strings, a space after the comma is part of the value, and `image-ref` must name the image I just built.
  - Fix: `severity: 'HIGH,CRITICAL'`, `ignore-unfixed: true`, `exit-code: '1'`, and `image-ref` equal to the build step's `tags:`.

* **Thought a separate scan job could use the image**
  - Symptom: I said a second job could "download the image".
  - Cause: each job starts on a fresh runner, and an image built with `load: true` exists only on the runner that built it. The only way to share it is to push it first (the thing the gate is meant to stop), or to pass it as an artifact.
  - Fix: one job with three steps: build (`load: true`, `push: false`), scan, push.

* **Trivy scan went red: two HIGH CVEs in `zlib1g`** (the gate working)
  - Symptom: run #26: `scan the image` failed with exit code 1, the push step was skipped. The Debian 13.7 row showed 2 vulnerabilities, the 9 Python packages showed 0.
  - Cause: `zlib1g 1:1.3.dfsg+really1.3.1-1+b1` in the `python:3.12-slim` base, with the fix in `...+deb13u1`. New CVEs were published since my 6 Nov local scan (which had shown an `apt` CVE).
  - Fix: `RUN apt-get update && apt-get install -y --only-upgrade zlib1g && rm -rf /var/lib/apt/lists/*` in the final stage. CI went green.
    - **Check:** I expected the old `apt` CVE and blamed the outdated Trivy version. Neither was right: the version notice was only a notice, and the finding was new. One advisory title mentioned `webpack-dev-middleware` for a zlib finding, so trust the library and versions, not the title.

* **Put the root-only `apt` line below `USER appuser`**
  - Symptom: my first answer was "underneath, so it runs as appuser".
  - Cause: every instruction after `USER` runs as that user, and installing packages needs root. (Caught in review, before it ran.)
  - Fix: root work first, then `USER appuser` as the last step before `CMD`.

* **Bootstrap check placed after Trivy** (18 Nov)
  - Symptom: in `aws-serverless-visit-counter`'s `ci.yml`, the bootstrap `init` + `validate` step came after the Trivy scan, so a Trivy failure would skip it.
  - Cause: a failed step skips every step after it (the implicit `success() &&`). A red scan would hide whether bootstrap still validates.
  - Fix: move the bootstrap step **above** Trivy, so all the checks that can't break anything run first.

* **Wrong version in a SHA comment** (18 Nov)
  - Symptom: an action pinned by SHA had a comment with `6.73.0`.
  - Cause: I copied the AWS provider's version from the lock file, not the action's release tag.
  - Fix: the comment must be that action's tag. Verify the pair with `git ls-remote https://github.com/<owner>/<action> | grep <sha>`, which prints the tag the SHA belongs to.

* **Read Trivy's `0` as "nothing found"** (20 Nov)
  - Symptom: the CI report table showed `0` for every file, and I took it as a clean bill of health.
  - Cause: the step runs with `severity: HIGH,CRITICAL`, so the table only counts those two levels. MEDIUM and LOW findings are filtered out before it's printed, and they never fail CI.
  - Fix: read `0` as "0 HIGH/CRITICAL". To see the rest, scan without the filter (Trivy isn't installed on the laptop yet: parking lot).

* **Thought the OIDC job needs `contents: write`** (21 Nov)
  - Symptom: my answer for the permission that gets an OIDC token.
  - Cause: `contents: write` lets a job push code. The token comes from `id-token: write`.
  - Fix: `permissions: { id-token: write, contents: read }`, nothing more.

* **Thought CI would fall back to the `default` profile** (21 Nov)
  - Symptom: I said `terraform init` in the OIDC job would use `default` and hit an access denied.
  - Cause: when a profile is named, nothing falls back. The runner has no `~/.aws`, so `profile = "lab"` stops `init` with "failed to get shared config profile, lab", before credentials or region matter.
  - Fix: before switching OIDC on, remove `profile` from the code and use `AWS_PROFILE=lab` on the laptop.
  - **Again 23 Nov** (recall quiz Q4): same "falls back to default" answer. Third time, so it's on the cheat sheet: **a named profile that doesn't exist = stop, never fallback.**

* **Wrong names: `token-id` and `vars.ENABLED`** (23 Nov review)
  - Symptom: I said the OIDC permission is `token-id: write` and the switch is `vars.ENABLED`.
  - Cause: remembering the idea, not the spelling. YAML and GitHub don't guess: a wrong key is ignored or invalid, and a wrong variable name is simply empty, so the `if:` is false and the job is skipped with no error.
  - Fix: `id-token: write` and `vars.ENABLE_OIDC`. Copy names from the file, don't retype them.

* **Thought turning OIDC on means removing `-backend=false`** (23 Nov review)
  - Symptom: my steps to switch OIDC on were "set the variable, set the repo variable, remove `-backend=false`".
  - Cause: `-backend=false` belongs to `terraform-checks`, the job that has **no credentials** (it's what lets `init` succeed without them). The OIDC job already runs a plain `init`. I also had cause and effect backwards: no login → so `-backend=false`, not the other way round.
  - Fix: the real order is (1) remove `profile = "lab"`, (2) apply `enable_github_oidc = true` **by hand** (CI can't create its own way in), (3) set repo variables `AWS_ACCOUNT_ID` and `ENABLE_OIDC=true`, (4) open a PR and watch the job.

* **Thought the OIDC job plans only because AWS would apply by itself** (23 Nov review)
  - Symptom: I asked whether there's no `apply` step because AWS would run it from its end.
  - Cause: AWS never runs anything on its own. The CI role is read-only plus the state lock, so it *can't* apply.
  - Fix: no apply in CI by design here. A real pipeline would apply on merge with a separate, stronger role, usually behind an approval gate.

## Terraform

* **`plan` showed `0777` permissions for a `local_file`**
  - Symptom: `file_permission = "0777"` and `directory_permission = "0777"` in the plan.
  - Cause: that is the provider's default, so anyone can read, write and execute the file.
  - Fix: `file_permission = "0600"` and `directory_permission = "0700"`. I only saw it because I read the plan before typing `yes`.

* **Typed `1` at the `apply` prompt**
  - Symptom: `Apply cancelled.`
  - Cause: Terraform accepts only the full word `yes`.
  - Fix: type `yes`. Nothing had been created, so there was nothing to undo.

* **Expected a replace to show `0 to change`** (wrong twice)
  - Symptom: after changing `content`, the plan showed `-/+` and `1 to add, 0 to change, 1 to destroy`.
  - Cause: `content` on `local_file` forces replacement (`# forces replacement`). A replace counts as one add plus one destroy, never as a change. The provider decides per attribute whether an edit is in place or a replace.
  - Fix: look for `-/+`, "must be replaced" and `# forces replacement` before typing `yes`.
    - **Check:** the hashes changing is a side effect, not the danger. On real infrastructure a replace deletes the old thing first (a database with its data, or a server that comes back with a new IP address).

* **A line I added by hand to `hello.bar` vanished after `apply`**
  - Symptom: my `hacked` line was gone.
  - Cause: drift. Reality changed behind Terraform's back, and the config is the source of truth, so `apply` made reality match it.
  - Fix: change the `.tf` files, then `plan`, then `apply`. Never edit the resource by hand.

* **Thought `terraform destroy` deletes `terraform.tfstate`**
  - Symptom: the state file was still there after `destroy`.
  - Cause: state is Terraform's memory, not a resource it manages. It now holds no resources, and a `.backup` copy appeared.
  - Fix: none needed. State is plain JSON and can hold secrets, so it never goes into Git.

* **Typed `yes` at a variable prompt**
  - Symptom: `Enter a value:` for `var.greeting`, and the plan showed `content = yes`.
  - Cause: the prompt was for the variable, not a confirmation. `yes` is for the `apply` and `destroy` confirmation only.
  - Fix: read each prompt before answering. Only a plan, so nothing was created.

* **`local.fullpath` instead of `local.full_path`**
  - Symptom: `terraform validate` failed on the reference.
  - Cause: the local is called `full_path` and I left out the underscore.
  - Fix: `local.full_path`. The block is `locals` (plural), the reference is `local.` (singular).

* **`-var 'full_path=/tmp/x'` was refused**
  - Symptom: an error saying a value was given for an undeclared variable.
  - Cause: `full_path` is a local, and locals can't be set from outside. Only variables can.
  - Fix: none needed. A variable is an input; a local is a named value inside the config.

* **Wrong precedence guess: environment variable vs `terraform.tfvars`**
  - Symptom: I predicted `TF_VAR_greeting` would beat `terraform.tfvars`, and the plan showed the `tfvars` value.
  - Cause: guessed instead of knowing the order.
  - Fix: lowest to highest: `default`, `TF_VAR_name`, `terraform.tfvars` (and `*.auto.tfvars`), then `-var` and `-var-file`.

* **Output `content_sha256` printed the file's text**
  - Symptom: the output showed the content, not a hash.
  - Cause: I used `local_file.hello.content` instead of `local_file.hello.content_sha256`. The hash is an attribute the provider computes, listed under "Attributes Reference" in its docs.
  - Fix: `local_file.hello.content_sha256`. `sha256sum hello.bar` gave the same hash.

* **Misspelled names in a data block**
  - Symptom: `aws_availabilty_zones` with the label `availabe`, plus an output named `caller_arm`.
  - Cause: typing slips. The block type is a name the provider knows, and the label is what later references use, so a slip in either breaks the config.
  - Fix: `aws_availability_zones` and `available` and `caller_arn`. I fixed them before running, so `validate` passed. Run `validate` before the first plan.

* **Predicted "three resources" for a plan with only data blocks**
  - Symptom: I said the plan would add three, and it said it would add none.
  - Cause: I counted blocks in the file instead of reading what Terraform said. A `data` block only reads, so it is not a resource.
  - Fix: a data-only plan has no `Plan: N to add` line, only `Changes to Outputs`. Read the output before predicting a number.

* **Pasted my full AWS account number into chat**
  - Symptom: a plan with the 12-digit number in the ARN went into the chat after I had been asked to write `<account>`.
  - Cause: I didn't scan the paste before sending it.
  - Fix: look for the account number and the ARN before pasting. It isn't a password, but it stays out of chat and screenshots.
  - Happened again on 17 Nov, in an `AccessDenied` error message that names the account twice. Read error pastes too, and swap the number for `<account>`.
  - Again 21 Nov, in `aws login` output (`Updated profile lab to use arn:aws:sts::<account>:...`), with the sign-in URL. Pipe it through `sed -E 's/[0-9]{12}/<account>/g'` and never paste the URL.

* **Predicted a warning for a sensitive value in an output** (17 Nov)
  - Symptom: I guessed `plan` would warn. It stopped with an error (`Output refers to sensitive values`).
  - Cause: a warning would let the secret print anyway, so Terraform treats the leak as a hard error.
  - Fix: `sensitive = true` on the output.

* **Thought `sensitive = true` hides the value everywhere** (17 Nov) (all three predictions wrong)
  - Symptom: `terraform output secret_echo` printed `"banana-123"`, `-raw` printed it plain, and `grep banana terraform.tfstate` found it twice (the output value and the file's `content`).
  - Cause: `sensitive` hides values in plan, apply and the bare `terraform output` list only. A named output, `-raw` and the state file aren't covered.
  - Fix: nothing to fix; know the limit. State never goes in Git. After `destroy`, `terraform.tfstate.backup` still holds the secret (my prediction was right), and an S3 bucket with versioning keeps old copies too, so no secrets go into Terraform at all.

* **Expected `arn` to show a real ARN in a plan** (17 Nov)
  - Symptom: I predicted my brother's ARN; the plan showed `arn = (known after apply)`.
  - Cause: AWS generates the ARN, `id` and `unique_id` when the group is created. Terraform only knows what it was given or has read.
  - Fix: read `(known after apply)` as "AWS decides this".

* **Expected an error after deleting a resource block that was never applied** (17 Nov)
  - Symptom: `plan` said `No changes. Your infrastructure matches the configuration.`
  - Cause: plan compares the config with the state. Nothing was applied, so both were empty. If the group had been applied, the state remembers it and deleting the block plans a destroy (`0 to add, 0 to change, 1 to destroy`). At wrap-up I still answered "no changes" for the applied case.
  - Fix: before typing `yes`, read every `-` line. Re-test tomorrow.

* **`tfplan` missing from `.gitignore`** (18 Nov)
  - Symptom: the first `.gitignore` covered `.terraform/`, state and `*.tfvars`, but not the saved plan file.
  - Cause: I listed what I knew from the 12 Nov parking-lot line, before using `plan -out=tfplan`. A saved plan holds the full config and values, sensitive ones included.
  - Fix: add `tfplan` to `.gitignore`. Check with `git status` after the first `plan -out`.

* **Thought renaming a resource label only breaks references** (19 Nov teach-back)
  - Symptom: I said renaming `aws_s3_bucket.state` would just give "reference not found" errors, avoided by picking easy names.
  - Cause: the label is the resource's address in state. Once references are fixed, the old address is gone and a new one appears, so `plan` shows **destroy + create**: the state bucket itself. `plan` shows that; it doesn't stop it.
  - Fix: a `moved { from = aws_s3_bucket.state  to = aws_s3_bucket.<new> }` block, so the plan says `0 to destroy`.

* **Thought the backend can't take a variable because the name wouldn't match** (19 Nov teach-back)
  - Symptom: I said a variable's value wouldn't match the real bucket name.
  - Cause: it's about timing, not the value. The backend is read **during** `init`, before any variable or resource is evaluated.
  - Fix: literal values only in the `backend` block; anything that changes goes in `-backend-config`.

* **Gave "locals" as a variable source** (19 Nov quiz)
  - Symptom: my precedence order was `-var`, local, `terraform.tfvars`, ?, default.
  - Cause: locals can't be set from outside the config at all (12 Nov entry above), and I forgot two real sources.
  - Fix: strongest first: `-var`/`-var-file`, `*.auto.tfvars`, `terraform.tfvars`, `TF_VAR_name`, `default`.

* **Mixed up `.terraform.lock.hcl` with the state lock** (19 Nov quiz)
  - Symptom: I said the lock file stops two runs at once.
  - Cause: same word, two things. `.terraform.lock.hcl` pins **provider versions + hashes** and is committed. `.tflock` locks the **state** and lives in the S3 bucket only during plan/apply.
  - Fix: lock file = which providers; `.tflock` = who is writing state.

* **A second `terraform {}` block in `dynamodb.tf`** (19 Nov)
  - Symptom: I copied an example's `terraform { required_providers { aws = ... } }` into my new file.
  - Cause: Terraform reads every `.tf` file in the folder as one config, and `main.tf` already declares the AWS provider. Several `terraform {}` blocks are allowed; declaring the same provider twice isn't.
  - Fix: delete it. Settings live once, in `main.tf`; new files hold only resources.

* **IAM file full of type mistakes** (19 Nov)
  - Symptom: `actions = "sts:AssumeRole"`, `resources = "aws_dynamodb_table.visits.arn"`, `assume_role_policy = "assume"`, `role = aws_iam_role.lambda`, `policy = data...permissions`, `effect = "allow"`, and no `principals` block.
  - Cause: three patterns. `actions`/`resources` always take a **list**. Quotes turn a reference into **plain text** (only `"${...}:*"` builds a string). Some references need an **attribute** (`.json`, `.id`, `.arn`). Also `"Allow"` is case sensitive, and a trust policy with no `principals` says nobody may use the role.
  - Fix: `["..."]`, no quotes around references, `.json`/`.id`, `"Allow"`, and `principals { type = "Service" identifiers = ["lambda.amazonaws.com"] }`.

* **Function name typo: `visit-coutner`** (19 Nov, caught in review)
  - Symptom: `function_name = "visit-coutner"`, while the log group is `/aws/lambda/visit-counter`.
  - Cause: Lambda logs to `/aws/lambda/<function name>`, so it would look for a group that doesn't exist, and it has no `logs:CreateLogGroup` permission to make one. Result: **no logs at all**, while the function still works, so nothing looks wrong.
  - Fix: one name in one place. Better: a `local.function_name` used by both the function and the log group.

* **Output read `function_url` from the wrong resource** (19 Nov)
  - Symptom: `value = aws_lambda_function.counter.function_url`.
  - Cause: the URL is its own resource, `aws_lambda_function_url`, so the attribute lives there.
  - Fix: `aws_lambda_function_url.counter.function_url`. Check the "Attributes Reference" of the resource I think owns it.

* **`plan` failed: `could not archive missing file: ./src/app.py`** (19 Nov)
  - Symptom: `Error: Archive creation error` on `data.archive_file.lambda`.
  - Cause: the handler code was in chat, never saved to disk (same lesson as the empty Dockerfile).
  - Fix: `mkdir -p src`, save `src/app.py`, `cat src/app.py` before `plan`.

* **Predicted `plan` would add 2** (19 Nov)
  - Symptom: it said `Plan: 8 to add`.
  - Cause: I counted only the file I'd just written and half-thought `init` resets things. Nothing in the root had been applied (Wednesday's apply was empty), and `init` never touches state.
  - Fix: count every `resource` block in the folder that isn't in state yet: table, log group, role, role policy, function, URL and 2 permissions = 8. Data blocks don't count.

* **First apply went to Frankfurt and hit an SCP deny** (20 Nov)
  - Symptom: `AccessDeniedException ... dynamodb:CreateTable on ... eu-central-1 ... explicit deny in a service control policy`, same for `logs:CreateLogGroup`. The IAM role was created.
  - Cause: the root config had **no `provider "aws"` block**. The `region` and `profile` inside `backend "s3"` only say where state lives; the provider fell back to the `default` profile's region (`eu-central-1`). The account's guardrails deny Frankfurt. IAM is global, so the role went through.
  - Fix: `provider "aws" { region = "eu-north-1"  profile = "lab" }` in `main.tf`. The ARNs in an error show the region, so read them.

* **Partial apply, then a stale plan** (20 Nov)
  - Symptom: after the failed apply, the saved `tfplan` couldn't be used again.
  - Cause: a saved plan is tied to the state it was made from. The failed apply still created the role, so the state changed and the plan was stale. It happened again after the 409 below.
  - Fix: after any apply that fails part-way, `terraform plan -out=tfplan` again and read what's left.

* **409 `ResourceConflictException`: concurrent update on the function** (20 Nov)
  - Symptom: `adding Lambda Function URL (visit-counter) permission ... StatusCode: 409 ... concurrent update operation`.
  - Cause: Lambda allows one change at a time per function, and Terraform creates up to 10 resources in parallel. The URL resource (which adds its own public permission for `NONE`) and my two `aws_lambda_permission` resources changed the function's policy at the same moment. The URL was left **tainted**.
  - Fix: re-plan (it showed the URL as destroy + create), then `terraform apply -parallelism=1 tfplan`. Saturday: check `aws lambda get-policy` for duplicate statements.

* **Predicted `apply tfplan` would ask for `yes`** (20 Nov)
  - Symptom: it ran straight away.
  - Cause: a saved plan is already the reviewed decision; reviewing it in the PR is the "yes".
  - Fix: read the plan *before* saving it, because nothing asks again.

* **Thought merging would make `tfplan` stale** (20 Nov)
  - Symptom: I said I'd have to re-plan after merging `fix-region`.
  - Cause: the plan was made from the same code that was merged, and the state hadn't changed. Code moving onto `main` doesn't touch state.
  - Fix: re-plan only if `main` gained *other* changes, or the state changed since the plan.

* **Thought adding tags replaces resources** (20 Nov)
  - Symptom: I predicted `-/+`; the plan showed `~ update in-place` for all of them.
  - Cause: tags are labels, and changing a label never rebuilds the thing. The plan also said 5 to change, but apply did 4: the role policy's data source was "read during apply", so Terraform showed a cautious maybe, which turned out to be no change.
  - Fix: look for `~` vs `-/+` and `# forces replacement`. A "will be read during apply" data source can make a plan overcount.

* **Trust-policy draft for OIDC** (20 Nov)
  - Symptom: no `statement { }`, `prinicpals`, commas inside a block (`type = "Federated",`), the audience value in `variable`, `sts.amazon.com`, an unquoted `sub` key, and `github_trust.id[0].json`.
  - Cause: a `condition` has three parts (`test`, `variable` = which claim as a string, `values` = allowed list); blocks take one setting per line; with `count` the index goes right after the name.
  - Fix: `data.aws_iam_policy_document.github_trust[0].json`, and conditions on `token.actions.githubusercontent.com:aud` and `:sub`.

* **`epo:` instead of `repo:` in the `sub` values** (20 Nov, caught in review)
  - Symptom: `"epo:Rayyan98Dev/aws-serverless-visit-counter:pull_request"`.
  - Cause: a typo inside a value. `validate` only checks it's a string, and AWS would accept it, but no token would ever match: PR runs would be refused with a vague "not authorized".
  - Fix: `repo:`. Typos inside values are the ones no tool catches; read them.

* **Said a `count` resource is referenced "as a normal block"** (20 Nov)
  - Symptom: wrong prediction for how to get the OIDC provider's ARN.
  - Cause: `count` turns a resource into a list, even with one item.
  - Fix: `aws_iam_openid_connect_provider.github[0].arn`, and give anything that uses `[0]` the same `count`, so it never indexes an empty list.

* **New OIDC blocks without `count`** (21 Nov)
  - Symptom: `Error: Unexpected resource instance key ... github_ci_state[0] ... does not have "count" or "for_each" set`.
  - Cause: I referenced `[0]` on a data block that wasn't a list, and the new resources pointed at `github_ci[0]`, an empty list while the switch is off.
  - Fix: `count = var.enable_github_oidc ? 1 : 0` on every block that uses `[0]`. Terraform's error names the symptom ("remove the index"), not my real fix.

* **Thought `plan` needs no write access** (21 Nov)
  - Symptom: I said only `apply` writes, so a CI plan role needs read-only S3.
  - Cause: `plan` takes the state lock too (`Acquiring state lock` / `Releasing state lock`), which writes and deletes the `.tflock` object.
  - Fix: the CI role gets `GetObject` on the state key, plus `GetObject`/`PutObject`/`DeleteObject` on the `.tflock` key.

* **Duplicate public permissions on the function** (21 Nov)
  - Symptom: `aws lambda get-policy` showed 4 statements in two identical pairs: mine (`terraform-…`) and `FunctionURLAllowPublicAccess` / `FunctionURLAllowInvokeAction`.
  - Cause: `aws_lambda_function_url` with `authorization_type = "NONE"` adds both public permissions itself. My two `aws_lambda_permission` resources repeated them (and raced them: the 409 on 20 Nov).
  - Fix: removed my two resources (plan `2 to destroy`), left a comment saying the URL resource adds them. Risk if missed: deleting my resources would *not* close public access.

* **Destroy rehearsal predictions** (21 Nov)
  - Symptom: I predicted 8 to destroy, and that a re-apply would continue the count "because destroy only affects the laptop".
  - Cause: two permissions were already removed (6 left). `destroy` deletes things **in AWS**: the table and its count go, and the function URL is random, so a rebuild gets a new URL. Root `destroy` never touches the state bucket (bootstrap's).
  - Fix: `terraform state list` shows what Terraform manages (not the `.tf` files, which include `count = 0` blocks). After the destroy, the old URL answers `403` and `state list` is empty.

* **Mixed up code, state and real infrastructure** (23 Nov review, the root of most mistakes below)
  - Symptom: I described drift as "the code no longer matches state", and mixed up what destroying bootstrap does with what losing the laptop does.
  - Cause: Terraform has **three places**: **code** (`.tf` in Git, what I want), **state** (S3 for root, local file for bootstrap, what Terraform remembers), **real infrastructure** (AWS, what exists). `plan` compares all three.
  - Fix: stale plan = **state** moved since the plan. Drift = **reality** moved (someone edited it in the console). Changed code = just my next change. Losing the laptop loses bootstrap's state only (import it back); destroying bootstrap deletes the **bucket** holding root's state, which orphans everything still running.

* **Label vs real name, again** (23 Nov review)
  - Symptom: I described `aws_s3_bucket.state` as "Terraform's state", and said `visits` in `aws_dynamodb_table.visits.arn` is the table's name.
  - Cause: the label after the type is only Terraform's address. The bucket *resource* is called `state` but it's a bucket (real infrastructure) that *holds* state. The table's AWS name comes from `name = "visits"`; the label just happens to match.
  - Fix: label = Terraform's name for the block; `name`/`bucket` argument = the real name in AWS. Same lesson as the 19 Nov rename entry.

* **Read the public-access-block settings backwards** (23 Nov review)
  - Symptom: I said all four rules were set to `false`.
  - Cause: each setting reads "block this = yes". They're all `true`, which means locked down. Reading it backwards turns "nobody can make this public" into "anyone can".
  - Fix: read the attribute name as a question ("block public ACLs?") and the value as the answer.

* **Predicted `terraform destroy` in `bootstrap/` would succeed** (23 Nov review)
  - Symptom: I said it would just delete the bucket.
  - Cause: the bucket isn't empty (root's state file is still there after a root `destroy`, plus every old version), and there's no `force_destroy`, so AWS refuses with `BucketNotEmpty`. Destroy runs in **reverse dependency order**, so versioning, the public-access block and encryption go first and the bucket fails last.
  - Fix: don't run it. Result would be a half-destroyed bucket, still there but less protected. `lifecycle { prevent_destroy = true }` makes the *plan* fail before anything is touched.

* **Read `~> 6.0` as "6 and above"** (23 Nov review)
  - Symptom: my answer for the provider version constraint.
  - Cause: `~>` is the pessimistic operator: only the last number given may grow.
  - Fix: `~> 6.0` = ≥ 6.0 and < 7.0, so a breaking 7.0 can't arrive by itself. `>= 1.10` on Terraform is because `use_lockfile` arrived in 1.10.

* **Mixed up what `backend` and `provider` control** (23 Nov review)
  - Symptom: I said bootstrap's backend works on a local file, and that the provider affects "resources in the S3 bucket".
  - Cause: bootstrap has **no backend block at all** (local state is the default). Resources aren't in the bucket; only state is.
  - Fix: `backend` = where **state** is read and written. `provider` = where and as whom **real resources** are created. Frankfurt on 20 Nov was a provider problem.

* **Mapped the IAM blocks wrongly** (23 Nov review)
  - Symptom: I said the two resources in `iam.tf` are the trust policies and the two data blocks are the permissions policies.
  - Cause: data blocks only **write** JSON (no AWS call); resources **create** things in AWS and attach the JSON.
  - Fix: `data.assume` = trust (attached by `aws_iam_role` via `assume_role_policy`); `data.permissions` = permissions (attached by `aws_iam_role_policy`). One-line model: **data writes the letter, resource posts it.** Same in `oidc.tf`: only `github_trust` is a trust policy; `github_ci_state` is permissions.

* **Thought `main.tf` governs the other files** (23 Nov voice review)
  - Symptom: I described `main.tf` as the file that controls the rest.
  - Cause: Terraform reads **every** `.tf` file in the folder as one config; file names are only for tidiness. It never reads subfolders, which is why `bootstrap/` is a separate config.
  - Fix: `main.tf` just holds settings for the whole folder (terraform block, backend, provider). And `iam.tf` only holds IAM: it **points at** the table and log group by ARN, it doesn't create them.

## AWS

* **Expected the classic root sign-up on the new account** (16 Nov)
  - Symptom: the sign-up and console screens didn't match the steps I expected (root email, root password, root MFA).
  - Cause: accounts created after 15 Jul 2025 use a new sign-up flow: you choose a Free or Paid plan, sign in through another identity, and (as reported) there is no root user until the account is upgraded.
  - Fix: read the screen in front of me, not the steps I remember. Check the account's creation date and plan first.

* **Predicted an access key would be needed for S3** (16 Nov)
  - Symptom: I said the CLI or Terraform would need an access key before it could touch S3.
  - Cause: I mixed up two separate things. **Credentials** say who I am; **policies** say what I'm allowed to do. An access key is only one way to get credentials, and the most dangerous one because it lasts until deleted.
  - Fix: `aws login` gives short-lived credentials that expire by themselves. Permissions come from the policies on the identity.

* **Expected the IAM user wizard to offer console access** (16 Nov)
  - Symptom: IAM user `learning` has no Console sign-in section and no MFA section; Security credentials starts at Access keys.
  - Cause: in the new Free-plan account type, IAM users can't get a console password (reported by Wiz; matches what I saw). Console sign-in is a session of `AccountFullAccessRole`.
  - Fix: nothing to fix. `learning` has no credentials, so it's harmless; decide whether to keep or delete it. Still no access keys.

* **Expected the CLI to ask which profile to use** (16 Nov)
  - Symptom: `aws sts get-caller-identity` with no `--profile` failed and said I had to sign in again.
  - Cause: with no `--profile` (and no `AWS_PROFILE`), the CLI always uses `default`, which is my own account. That login session had expired. It never asks or guesses.
  - Fix: `--profile lab` for the lab account. The error showed that `aws login --profile lab` left `default` untouched.
    - **Check:** `get-caller-identity --profile lab` printed `assumed-role/AccountFullAccessRole/...`. That's a **role session**, not root and not `learning`. My prediction said "my brother's account" without saying which identity.

* **Assumed GitHub Actions could log in to the new account with OIDC** (17 Nov)
  - Symptom: `aws iam list-open-id-connect-providers --profile lab` returned `AccessDenied ... with an explicit deny in a service control policy`. I ran it before predicting.
  - Cause: AWS puts a guardrail SCP on new-experience accounts. Its Deny on `iam:*Provider*` also blocks creating the OIDC provider. An explicit Deny above the account beats any Allow inside it, even full access.
  - Fix: the "A+" workflow: CI runs `fmt -check`, `init -backend=false`, `validate` and `trivy config` without AWS; `plan` and `apply` run by hand with `aws login --profile lab`; the OIDC code is written but off (`enable_github_oidc = false`).
    - **Check:** the error says who said no ("service control policy"), so I know the block is above my role.

* **Thought `aws login` credentials last 15 minutes** (17 Nov)
  - Symptom: I predicted `terraform plan` would fail with "no valid credentials" because 15 minutes had passed.
  - Cause: the login session lasts up to 12 hours. The temporary credentials inside it refresh about every 15 minutes.
  - Fix: if the CLI or Terraform can't find credentials, run `aws login --profile lab` again.

* **Predicted `ConcurrentExecutions` would be 1** (19 Nov)
  - Symptom: `get-account-settings` showed `400`.
  - Cause: I mixed up DynamoDB's 1 RCU/1 WCU (table capacity) with Lambda concurrency (how many copies of functions run at the same moment), then with the 1M free requests a month.
  - Fix: three different numbers from two services. Reserved concurrency is limited to the unreserved amount minus 100, so up to 300 here.

* **Thought OIDC is an AWS login for the terminal** (20 Nov)
  - Symptom: I described OIDC as an AWS service that runs on my laptop.
  - Cause: that's `aws login`. OIDC is an open standard: GitHub signs a short-lived token for each workflow run ("repo X, branch main"), AWS trusts GitHub's signature through the OIDC provider, and the run swaps the token for temporary credentials (`sts:AssumeRoleWithWebIdentity`). Nothing stored in GitHub secrets.
  - Fix: one-line model: "GitHub vouches for the run, AWS trusts GitHub."
    - **Check:** `"Service"` principal = an AWS service (Lambda). `"Federated"` = an identity from outside AWS that AWS trusts (GitHub).
  - **23 Nov voice review:** I said the OIDC provider is what fetches the token and `client_id_list` is where the token is sent. GitHub issues the token on its own; the provider is AWS writing down "I trust tokens signed by GitHub". `client_id_list` is the **audience** AWS accepts (`sts.amazonaws.com`).

* **Thought there's a separate "app" between the URL and Lambda** (23 Nov review)
  - Symptom: my request path was "AWS routes it to the app, the app goes to Lambda, Lambda asks the app to print, the app stores the count".
  - Cause: the Lambda function **is** the app; `app.py` is the code inside it.
  - Fix: curl → function URL (resource policy: `InvokeFunctionUrl` + `InvokeFunction`) → Lambda runs `handler` (reserved concurrency 2) → takes on its role (trust policy) → `UpdateItem` on `visits` (permissions policy) → logs (permissions policy). Three checks: who may call the function, who may become the role, what the role may do.

* **Thought ReadOnlyAccess risk = secrets printed in logs** (23 Nov review)
  - Symptom: my answer for what `ReadOnlyAccess` means for the state file.
  - Cause: nothing prints by itself. The risk is that **any run the trust policy accepts** (including `pull_request` runs) gets a role that can read every object in every bucket, state included.
  - Fix: tighter = only the read actions `plan` needs for these resource types, plus the state key. In the README's known gaps.

## Kubernetes

* **Thought the control plane is a separate thing from the node** (24 Nov, twice: prediction and teach-back)
  - Symptom: I predicted a separate control plane, then `kubectl get nodes` showed one node with role `control-plane`, and `kubectl get pods -A` showed 9 pods before I'd made any.
  - Cause: in a single-node kind cluster the one node **is** the control plane, and it also runs my pods. The control plane itself runs **as pods** in `kube-system`: `kube-apiserver`, `etcd`, `kube-scheduler`, `kube-controller-manager`; plus `coredns` ×2, `kube-proxy`, `kindnet` (CNI) and `local-path-provisioner`.
  - Fix: "control plane" is a role. In production it's usually on its own machines; here it shares the node. `-A` = all namespaces.

* **Expected `docker ps` to show my nginx pod** (24 Nov)
  - Symptom: only `lab-control-plane` was listed.
  - Cause: three layers: Docker → node container → **containerd** → pod containers (`CONTAINER-RUNTIME: containerd://...`). Docker can't see inside the node.
  - Fix: `sudo docker exec lab-control-plane crictl ps` lists the pod containers.

* **Expected the pod IP to be reachable from the laptop** (24 Nov)
  - Symptom: `curl -m 3 http://10.244.0.5` timed out. I'd predicted the same range as the node (`172.18.x`) and that it would work "because 127.0.0.1 is self".
  - Cause: two networks. Docker gives the node `172.18.0.2`; the CNI (kindnet) gives pods `10.244.x.x`, and routes to them exist only **inside the node**. `127.0.0.1` is just the laptop talking to itself.
  - Fix: from outside, use `kubectl port-forward` (listens on `127.0.0.1`) or a Service. From inside, `sudo docker exec lab-control-plane curl ...` works. Building picture: the node is the street address, pods are internal extensions.

* **Said deleting a pod vs stopping its container differ "because a Deployment restarts it"** (24 Nov)
  - Symptom: my teach-back answer; there was no Deployment today.
  - Cause: stopping nginx kills the **container**; the **kubelet** on the node restarts it inside the same pod (default `restartPolicy: Always`), so same pod, same IP, `RESTARTS 1`. Deleting the **pod** removes the wrapper, and a bare pod has no controller watching it, so nothing recreates it.
  - Fix: container restarts = kubelet. Pod recreation = a controller (Deployment, tomorrow).

* **`pod.yaml` first draft** (24 Nov)
  - Symptom: `error parsing pod.yaml: ... line 9: did not find expected '-' indicator`, then `Error from server (BadRequest): ... unknown field "metadata.label"`, then also `"spec.container"` (a new slip while fixing).
  - Cause: `image:` and `ports:` were indented under the dash instead of under `name:` (my CI dash lesson again); `label` must be `labels`; `containers` is plural. Two separate checks: **kubectl** parses YAML on the laptop first ("error parsing", nothing sent), then the **API server** rejects unknown fields ("Error from server", all at once).
  - Fix: keys of one list item line up under the first key after the dash; `kubectl apply --dry-run=server -f` after each single fix. It never complained about `name: web` vs the requested `app: web`: label values are free text, so only a review catches them.

* **Thought `pod.yaml` made the cluster** (25 Nov)
  - Symptom: asked whether `pod.yaml` must change to run on the desktop cluster, I said it would have to say it's a cluster (and be renamed `cluster.yaml`). My first `deployment.yaml` had `cluster: lab` as the selector.
  - Cause: `kind create cluster` makes the cluster. A manifest describes one **object inside** a cluster and never names the cluster. Which cluster it goes to is decided by kubectl: `current-context` in `~/.kube/config` (`kind-lab`).
  - Fix: the same `pod.yaml` works on any cluster, unchanged. A selector is a **query over pod labels**, so it must match `template.metadata.labels`.

* **Thought `replicas: 3` makes 3 ReplicaSets** (25 Nov)
  - Symptom: predicted 3 ReplicaSets.
  - Cause: `replicas` = how many **pods** the ReplicaSet keeps alive. A Deployment makes one ReplicaSet per **version of the pod template**.
  - Fix: 1 Deployment `web` → 1 ReplicaSet `web-55fbf6bc44` → 3 pods `web-55fbf6bc44-<5 random>`.

* **First `deployment.yaml` still said `apiVersion: v1` and `kind: Pod`** (25 Nov)
  - Symptom: `Error from server (BadRequest): ... Pod in version "v1" cannot be handled as a Pod: strict decoding error: unknown field "spec.replicas", unknown field "spec.selector", unknown field "spec.template"` (I predicted this one right).
  - Cause: the top two lines decide the type, so the API server checked my fields against a Pod.
  - Fix: `apiVersion: apps/v1`, `kind: Deployment`. `apiVersion` = which shelf (API group/version), `kind` = which item on it. Together they name a **type**, never an object.

* **Said kubectl only catches syntax errors** (25 Nov teach-back)
  - Symptom: "server error = no syntax error but the wrong format; kubectl = syntax error".
  - Cause: there are **three gates**. (1) kubectl parses the YAML: `error parsing ... line N`. (2) kubectl looks up the type (apiVersion + kind) in the list the API server offers: `Deployment` in `v1` gives `no matches for kind "Deployment" in version "v1"`, nothing sent, even though the YAML is valid. (3) The API server checks the fields for that type (`Error from server ... unknown field`, all at once) and a few values (selector vs template labels). Typos in kubectl itself (`unknown shorthand flag: 'a'`, `unknown command "deployment"`) are also local: nothing sent.
  - Fix: before fixing, read which gate spoke.

* **Thought a replacement pod keeps the old name and IP** (25 Nov)
  - Symptom: predicted the same name, same IP and `RESTARTS 1` after deleting one of the Deployment's pods.
  - Cause: I mixed it up with yesterday's container restart. The ReplicaSet makes a **brand-new pod**: new name ending (`48v27` → `s5h84`), new IP (`.8` → `.9`), `RESTARTS 0`, young `AGE`. An IP belongs to one pod; "shared" means shared by the containers inside it.
  - Fix: container dies → kubelet restarts it **in the same pod**. Pod dies → ReplicaSet makes a **new pod**.

* **Said "kubectl" restarts containers, and missed the scheduler again** (25 Nov teach-back; control-plane names wrong 3 times now)
  - Symptom: control plane = etcd, kube-api, "kubectrl (controls the restarting)" and "the two DNS services"; in the next answer, containers are "restarted by kubectl".
  - Cause: three look-alike names. **kubectl** = my client on the desktop. **kubelet** = the agent on each node that starts and restarts containers. **kube-controller-manager** = control plane, runs controllers such as the ReplicaSet controller that replaces pods. CoreDNS lets pods find Services by name; it's a cluster add-on, not control plane.
  - Fix: control plane = **kube-apiserver** (the only door), **etcd** (desired state), **kube-scheduler** (picks the node for a new pod), **kube-controller-manager** (the controllers). On the cheat sheet.

* **Said nothing happens when a pod loses its label** (25 Nov teach-back)
  - Symptom: "unowned pod: nothing is done for it". True for that pod, but I left out the other half.
  - Cause: `kubectl label pod web-55fbf6bc44-qhg8w app-` took it out of the ReplicaSet's selector (`app=web,pod-template-hash=55fbf6bc44` needs **both**). The ReplicaSet released it (empty `ownerReferences`, now bare, still running), counted 2 and **made a new pod** (`7k4px`) to get back to 3.
  - Fix: ownership follows the selector. Changing a label can take a pod out of a controller's count, and the controller fills the gap.

* **Thought `kubectl scale` doesn't change the Deployment** (25 Nov)
  - Symptom: "it changes the replica only since nothing about the deploy changes".
  - Cause: `scale` writes `spec.replicas` **on the Deployment**, and the Deployment controller then sets the ReplicaSet's `DESIRED`. The **template** didn't change, so it's the same hash and the same ReplicaSet.
  - Fix: `kubectl apply -f deployment.yaml` afterwards said `configured` and went back to 3 (it removed the two newest pods): drift, fixed from the file. Change `replicas` in the YAML, not by hand.

* **Cleanup deleted the wrong pod** (25 Nov)
  - Symptom: I deleted `web-55fbf6bc44-s5h84` (owned) instead of the bare `web-55fbf6bc44-qhg8w`. `kclrj` replaced it within seconds, and `qhg8w` kept running.
  - Cause: generated names look alike, and the bare pod keeps its old name.
  - Fix: `kubectl get pods --show-labels` first; the bare one is the one without `app=web`. Copy names, don't retype them.

## README

* **README says the plan goes into every PR** (24 Nov read-through)
  - Symptom: reading the Workflow section aloud, I realised the plan summary was pasted into a PR only once (`add-counter`, 20 Nov).
  - Cause: wrote the process as intended, not as done. A one-line summary (`8 to add`) also doesn't show *what* changes.
  - Fix: later, change the README line to match what happened; from the next Terraform PR on, paste the full plan, masked with `sed`, in a collapsible block.

* **README mistakes caught in review** (17 Nov)
  - Symptom: an SSH clone address (`git@github.com:...`) and a test folder path, `down -v` as the normal stop command, "push the image to main", the Trivy scan missing from both flows, a merge flow labelled "On a PR run", and no reason why a PR doesn't push.
  - Cause: I wrote from my own setup, not a stranger's. An SSH address needs my key. `down -v` deletes the count I claim survives. `main` is a branch; the image goes to GHCR tagged with the commit SHA. The scan is the gate.
  - Fix: an https clone address, `down` (keeps the count) and `down -v` (deletes it) as separate lines, both flows including the scan, and one line on why a PR doesn't push (only reviewed, tested, merged code is published). Every command was tested from a clean clone.

* **Project 2 had no README, and `docs/design.md` was empty** (23 Nov)
  - Symptom: the repo zip had no `README.md`, and `docs/design.md` was 0 bytes.
  - Cause: the design only lived in the tutor's project notes; the empty file was committed and never filled.
  - Fix: README drafted 23 Nov from my own answers in the review; in the `add-readme` PR, fill `docs/design.md` or delete it. Check with `wc -c` that a "done" file actually has content.
