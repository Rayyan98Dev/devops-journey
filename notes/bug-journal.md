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

* **Pasted a placeholder into the terminal** (17 Nov)
  - Symptom: `git clone <your repo's clone URL> /tmp/readme-test` hung and showed `>`.
  - Cause: `<` is a redirect, so the shell waited for input from a file.
  - Fix: Ctrl-C (nothing ran). Replace placeholders with real values, or use `"$(git rev-parse --show-toplevel)"`.

## Python

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

## README

* **README mistakes caught in review** (17 Nov)
  - Symptom: an SSH clone address (`git@github.com:...`) and a test folder path, `down -v` as the normal stop command, "push the image to main", the Trivy scan missing from both flows, a merge flow labelled "On a PR run", and no reason why a PR doesn't push.
  - Cause: I wrote from my own setup, not a stranger's. An SSH address needs my key. `down -v` deletes the count I claim survives. `main` is a branch; the image goes to GHCR tagged with the commit SHA. The scan is the gate.
  - Fix: an https clone address, `down` (keeps the count) and `down -v` (deletes it) as separate lines, both flows including the scan, and one line on why a PR doesn't push (only reviewed, tested, merged code is published). Every command was tested from a clean clone.
