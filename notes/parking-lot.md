# Parking lot

One line per tangent. Friday slot: explore the best two.

## Open

- Writing JSON safely: write to a temporary file, then rename, so a crash can't leave a half-written original. Why not append (`a`) to JSON?
- `requests` in more depth: headers, authentication, POST, retries, paging. Building my own API is a separate topic for later.
- Setting permissions from Python: `os.chmod(path, 0o755)`. Why the `0o` prefix? (Plain `755` would be read as decimal.) Try it on `hello.sh`.
- Getting better at reading technical docs: the `requests` reference page was hard to use. Reference docs say what exists, tutorials say how to use it. Find good sources for each, and test any answer by experiment.
- `git.autofetch` in VSCodium: is it on, and what does it change? (It updates `origin/main` in the background, but doesn't fix a divergence.)
- Packet can't run in the background or start at login on Sway (no background portal for Flatpaks). Try starting it from the Sway config with an `exec` line; check the right command first.
- Ideas from the old `sysinfo.sh` (retired `devops-journey-old` repo): a "top 3 memory users" section (`ps -eo pid,comm,%mem --sort=-%mem | head -n 4`) and a small `section()` helper for printing headings.
- Rootless Docker: daemon runs as me, so containers can only touch my own files. Set up Fri 23 Oct; check how it affects kind (Weeks 8-9).
- Limiting *who* can reach a published port (not just which address): Docker's rules skip the firewalld zones, so look at the `DOCKER-USER` chain, binding to a VPN address, and nginx `allow`/`deny`.
- Safe remote access: SSH from a library, or Jellyfin from another house, without opening ports to everyone. Look at a private VPN (WireGuard or Tailscale), SSH keys only (no passwords, no root login), and a reverse proxy with HTTPS and a login.
- Shallow vs deep healthchecks (27 Oct): shallow = "is the process alive and answering?"; deep = "can it do its real job, including its dependencies?" A deep `/health` would ping Redis and fail when Redis is down. Tradeoff: one Redis outage turns web `unhealthy` too.
- `/health` must not count visits (27 Oct): the web healthcheck hits its own route, because `/` increments the counter every time Docker checks.
- Friendlier 404 page in Flask (28 Oct): `@app.errorhandler(404)` can return a custom page, but it must still send status 404 so checks and clients see the real error.
- Redis client timeout (29 Oct): `redis.Redis(..., socket_connect_timeout=2)` so a wrong host fails in 2 seconds instead of retrying slowly.
- `.env.example` (29 Oct): commit one with the same keys and safe values, so a fresh clone works while the real `.env` stays ignored.
- `sec()` (29 Oct): rename to `load_api_key`. It only runs under `if __name__ == "__main__"`, so a production server (Week 5) would skip it and never load the key.
- Redis password (29 Oct): `requirepass` from a Compose secret, and a healthcheck that uses it (needs `CMD-SHELL`). Skipped as the stretch goal.
- Secret file permissions (29 Oct): `chmod 600` on the host vs the container user (uid 10001) reading it. See Kubernetes secrets in Week 8.
- `start_interval` (30 Oct): check the Compose docs for a faster check rate during `start_period`, so a slow starter goes healthy sooner. Then add a README to `pg-health` and decide whether it stays in `projects/` or moves to `docker-labs`.
- Make a step run even after a failure (2 Nov): `if: always()`, and what `continue-on-error: true` does.
- Cache pip in the workflow (2 Nov): `setup-python` has a `cache: pip` option, so the install step is faster.
- Better names (2 Nov): rename `simple-job` and `devops-journey-workflow` to what they do, and clean the `ls` and Python-version steps out of the workflow once I don't need them.
- Test on more than one Python (2 Nov): a matrix, for example 3.12 and 3.14.
- Renaming the job (3 Nov): when I give `simple-job` a better name, the ruleset must change in the same PR, or `main` gets stuck waiting for a check that never reports.
- `push.autoSetupRemote` (3 Nov): a Git setting that makes plain `git push` create and link a new branch, so no `-u` is needed. Is it worth it, or is `-u` a better habit while I learn?
- Other ruleset options (3 Nov): "require branches to be up to date before merging", requiring approvals (pointless alone), and "require linear history". What does each change, and which would a team turn on?
- Merge button choices (3 Nov): merge commit vs squash vs rebase. How do they change the history `git log --graph` shows?
- `paths:` filter for a workflow (3 Nov): run CI only when code changes, not for a notes-only PR. But a skipped required check can block the merge, so check how GitHub treats it. (5 Nov: now there's a reason, since every notes PR that merges to `main` rebuilds and pushes an image.)
- Does a skipped required check count as passing? (5 Nov) When `simple-job` fails, `build-image` is skipped. The PR is blocked by `simple-job` anyway, but test what GitHub does with a skipped required check on its own.
- Build cache for the image (5 Nov): each runner starts empty, so pip reinstalls every time (about 40 s). Look at `cache-from` and `cache-to` with `type=gha` on the build action.
- Link the package to the repo (5 Nov): I used **Manage Actions access**. The other ways are the **Connect Repository** button and `LABEL org.opencontainers.image.source` in the Dockerfile. What does each one change?
- Pin actions by commit SHA (5 Nov): a tag like `@v7` can be moved by whoever owns the action. Pinning to a full SHA is safer. Look at what that does to updates.
- Where did `COPY --from=builder /install /usr` land? (5 Nov) I expected Python not to find the packages there (`/usr/local` is where Python looks), but I fixed it before testing. Rebuild with `/usr` and read `sys.path` to see.
- Did auto-delete of merged branches work on PR #5? (5 Nov) After the merge, run `git fetch --prune` and `git branch -a`.
- After Week 4: "build your own container" from the `build-your-own-x` repo (Docker section), to see what containers really are underneath.
- January CKA prep: use Class Central to pick one free Kubernetes course (for example a Linux Foundation intro).
- "Close account" button (10 Nov): why is it visible to my IAM admin `Learning` on a standalone account, when AWS docs say only root can close it? Never click it; look only.
- Delete the deactivated root access key (10 Nov): Mon 16 Nov, ClickUp task exists.
- "1 notice" in the Annotations of CI run #20 (10 Nov): what does it say?
- Remote state backends (11 Nov): where do teams keep state so it isn't on one laptop and isn't in Git?
- `terraform plan -out` (11 Nov): save a plan and apply exactly that plan (needed in CI).
- `local_sensitive_file` (11 Nov): what exactly does it hide, given the state still stores the content in clear text?
- Why does `local_file` plan a *create* (not an update) after I edit the file by hand? (11 Nov) Its `id` is the SHA1 of the content; check the provider docs.
- Least-privilege IAM policy (12 Nov): write one for Project 2 instead of using `AdministratorAccess` for everything.
- Variable `validation` blocks (12 Nov): reject a bad value before the plan.
- `*.auto.tfvars` and `-var-file` (12 Nov): when to use each instead of `terraform.tfvars`.
- `terraform providers lock` (12 Nov): lock hashes for other platforms, so CI on a different OS accepts the same lock file.
- `aws_iam_policy_document` (12 Nov): build policy JSON in Terraform (it makes no AWS call).
- Roles and assuming a role (12 Nov): how a person or service takes on a role temporarily, and what `sts:AssumeRole` does.
- `.gitignore` for Terraform (12 Nov): `~/dev/lab/terraform` isn't a Git repo, so state can't be committed by accident. When Project 2 becomes a repo, create `.gitignore` (`.terraform/`, `*.tfstate`, `*.tfstate.backup`, `*.tfvars`) before the first commit, and commit `.terraform.lock.hcl`.
- Cross-zone traffic in AWS (12 Nov): what it costs and when it matters (zone IDs vs names).
- `aws login` with Terraform (12 Nov): it worked directly with provider v6.73.0 and no fallback command. Record the version if it ever stops working.

## Answered

- Why `string = string.strip()` but `data["tools"].append(tool)` with no assignment? (Fri 9 Oct) Strings can't change in place, so `strip()` returns a new one. `append` changes the list in place and returns `None`, so `data = data["tools"].append(tool)` leaves `data` as `None`.
- How do sets and dicts jump straight to an item? (Sat 10 Oct) The slot is calculated from the item (its hash) every time, and nothing stores where it lives. The cost is spare memory, so they're bigger than a list. Keys must be unchangeable types so the hash stays the same.
- When is a dict the right tool? (Sat 10 Oct) Counting, "have I seen this before?" (two-sum) and lookup by key. It's not for sorting, and searching by *value* is still a scan.
- Uses of the `2>&1 >file` order? (Mon 12 Oct) With a pipe, `cmd 2>&1 >/dev/null | wc -l` counts only the error lines: stdout is thrown away, and stderr copies the pipe.
- Would 15 branches of 1 GB take 15 GB? (Mon 12 Oct) No. A branch is a tiny file holding one hash, and Git stores each file version once. Big binary files are what make a repo grow.
- What is `origin/main` for? (Mon 12 Oct) A local bookmark of the remote's `main`, updated only on push or fetch. It's used to compare with `git status` ("ahead", "behind", "diverged") and `git log origin/main..`, and it makes `pull` safe to split into a fetch and a merge.
- Why does `git push` need a fetch first, and why not auto-fetch? (Mon 12 Oct) The remote refuses a push that would lose commits, since its tip must already be in my history. A fetch alone wouldn't fix it, because someone still has to combine the two histories.
- Detached `HEAD`? (Tue 13 Oct) `HEAD` points straight at a commit instead of a branch. Git does this during a rebase while it replays commits one at a time, then moves the branch label and re-attaches `HEAD` at the end. `git branch` shows `(no branch, rebasing ...)`.
- What happens to commits no branch points to? (Tue 13 Oct) They stay in Git's storage for weeks (roughly 30-90 days by default). `git reflog` lists where my labels used to point (local only), and `git branch <name> <hash>` rescues one.
- Could a 404 be caught in the `except` instead of an `if`? (Fri 23 Oct) Yes: `requests.get` only raises when it can't talk to the server; `r.raise_for_status()` turns a 4xx or 5xx answer into `requests.HTTPError`, with the response in `e.response.status_code`. If `requests.get` itself fails, `r` is never assigned (`UnboundLocalError`), so `return` in the `except` or use `else:`. Redirects are followed by default, so a redirect to a home page shows as 200.
- What does `-p 127.0.0.1:8081:80` change, and what does `EXPOSE` do? (Fri 23 Oct) The host IP picks which of the laptop's addresses accept connections: `127.0.0.1` only the laptop itself, none at all means every address (so the Wi-Fi can connect). `EXPOSE` is only a note in the image (`80/tcp`); it opens nothing, and `-p` works without it. Only `-P` uses it, publishing each exposed port to a random high host port (`0.0.0.0:32768`).
- Is `ssh` in the `public` zone a risk? (Thu 15 Oct) Not right now: `sshd` is `disabled` and `inactive (dead)`, so nothing listens on port 22. Being allowed and listening are two separate checks.
- What do `terraform fmt` and `terraform validate` do? (Thu 12 Nov) `fmt` rewrites the files into the standard layout and prints the names it changed (mine: `variables.tf`, tabs to spaces). `validate` checks syntax and references only, without touching state or real infrastructure, so passing it doesn't mean `apply` will work. Habit: `fmt`, `validate`, `plan`.
