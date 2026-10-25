# Wed 21 Oct: Mock code review #3 (Mercor practice)

*From my spoken review, tidied. A **Check:** line is a correction we agreed on. Mercor Code Review Session is on Fri 23 Oct.*

## The code
A backup script: `backup` makes a `tar.gz` of a folder in `/backups`, `cleanup` deletes backups older than a number of days, and `upload` copies a backup to a server with `scp`, retrying on failure.

## Progress
| Mock | Time spoken | Catches | False alarms |
|---|---|---|---|
| #1 (Fri 16) | 4.5 min | 1.5 | 3 |
| #2 (Tue 20) | 9 min | 1.5 | 4 |
| #3 (Wed 21) | 14 min | 5 | 2 minor |

- Stated my assumptions out loud ("I'm assuming the age is in seconds", "if it doesn't open anything, that's fine").

## What I caught
- `upload`: `retries` is never reduced, so a failing upload loops forever. Fix: `retries -= 1` after a failed attempt (no `else` needed).
- The `tar` result is never checked, so a failed backup looks like a success. Fix: `subprocess.run(..., check=True)`, or check `returncode`.
- No timeouts on `tar` or `scp`, so either can hang. Fix: `timeout=...`.
- The server `backup@server` is hard-coded. Fix: config or an environment variable.
- No checks for empty `folder` or `name`, or for `days` being 0 or less.

## My false alarms
- "Check `name` is a string and convert it with an f-string."
  - **Check:** Python doesn't need that. Too much type checking is noise in a review.
- "`days` must be an integer to compare with a float."
  - **Check:** Python compares ints and floats fine. Only a string would break, so "validate that `days` is a number" is the better point.
- "Add try/except so the program doesn't crash."
  - **Check:** failing loudly is good. The real problem is ignoring failures (unchecked return codes). A `try/except` that hides errors would be worse.

## What I missed (most serious first)
| # | Problem | What goes wrong | Fix |
|---|---|---|---|
| 1 | Shell injection: `shell=True` with an f-string built from `folder` and `name` | a `name` like `x; rm -rf ~` runs that command | `subprocess.run(["tar", "-czf", target, folder], check=True)`, with a list and no shell |
| 2 | Path traversal: `name` like `../../etc/x` | the backup is written outside `/backups` | `os.path.basename(name)`, or reject names containing `/` |
| 3 | `cleanup` deletes everything in `/backups` | removes non-backup files; `os.remove` on a folder crashes | only touch `*.tar.gz` files, and check `os.path.isfile` |
| 4 | Global `log` list grows forever | lost on exit, uses more memory over time | the `logging` module |
| 5 | The same `name` overwrites the last backup | the old backup is lost | add a date to the filename |
| 6 | Paths built with `+` | easy to get slashes wrong | `os.path.join` |

## Rules to take into Friday
- **`shell=True` plus any input I didn't write myself is a red flag, every time.** It's SQL injection's cousin.
- **Security first**, then reliability, then input checks and style.
- Finish with a sweep down the checklist.

## Checklist (updated)
**Security**
- Secrets in the code (and unused ones)
- Input put straight into a query or command (SQL injection, shell injection: `shell=True`)
- **User input used in a file path (path traversal: `../`)**
- Passwords stored or compared in plain text
- Secrets printed or logged

**Reliability**
- Files or connections not closed
- Network calls or subprocesses without a timeout
- Errors swallowed (`except: pass`, ignored status codes or return codes)
- Edge cases: empty input, zero, missing file, `None` returned
- **Deleting more than intended (wildcards, whole folders)**

**Logic**
- Mutable default arguments (`=[]`, `={}`)
- `is` used where `==` was meant
- Off-by-one in loops (`range(len(x) - 1)`)
- Loops that never end (a counter that's never changed)
- **Files overwritten by name**

**Efficiency and style**
- Doing the same work twice, or filtering in code what the database could filter
- Matching that's too loose (substring checks)
- **Global state that grows forever**
