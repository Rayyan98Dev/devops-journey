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
