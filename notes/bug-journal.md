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
