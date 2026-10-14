# Parking lot

One line per tangent. Friday slot: explore the best two.

## Open

- Could a 404 be caught in the `except` instead of an `if`? `r.raise_for_status()` raises `requests.HTTPError` for 4xx and 5xx, so try `except requests.HTTPError as e:` and read `e.response.status_code`. Note: if `requests.get(...)` itself fails, `r` is never assigned.
- Writing JSON safely: write to a temporary file, then rename, so a crash can't leave a half-written original. Why not append (`a`) to JSON?
- `requests` in more depth: headers, authentication, POST, retries, paging. Building my own API is a separate topic for later.
- Setting permissions from Python: `os.chmod(path, 0o755)`. Why the `0o` prefix? (Plain `755` would be read as decimal.) Try it on `hello.sh`.
- Getting better at reading technical docs: the `requests` reference page was hard to use. Reference docs say what exists, tutorials say how to use it. Find good sources for each, and test any answer by experiment.
- `git.autofetch` in VSCodium: is it on, and what does it change? (It updates `origin/main` in the background, but doesn't fix a divergence.)
- Packet can't run in the background or start at login on Sway (no background portal for Flatpaks). Try starting it from the Sway config with an `exec` line; check the right command first.
- `ssh` is allowed in the `public` firewall zone. Is `sshd` actually running? If not needed, remove `ssh` from `public`. (Fits the systemd day.)

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