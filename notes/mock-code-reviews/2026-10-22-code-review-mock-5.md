# Thu 22 Oct: Mock code review "A" (Mercor practice, Flask app)

*From my spoken review, tidied. A **Check:** line is a correction. Mercor Code Review Session is on Fri 23 Oct at 10:10.*

## The code
A small Flask web app: `/signup` stores a user, `/avatar` saves an uploaded image and resizes it, `/users` lists names, and `/admin/delete` deletes a user.

## Progress
| Mock | Time spoken | Catches | False alarms | Biggest miss |
|---|---|---|---|---|
| #1 (Fri 16) | 4.5 min | 1.5 | 3 | |
| #2 (Tue 20) | 9 min | 1.5 | 4 | SQL injection |
| #3 (Wed 21) | 14 min | 5 | 2 minor | shell injection |
| #4 (Thu 22) | 14 min | 5.5 | 1 | `eval`, `pickle` |
| A (Thu 22) | 13 min | about 5 | 2 | `debug=True`, trusting the `X-Admin` header |

## What I caught
- `yaml.load(..., Loader=yaml.Loader)` can run code. Fix: `yaml.safe_load`.
  - **Check:** correct, but I found it last, at minute 12, after reading the line aloud at minute 2. It should have been the opening finding.
- `shell=True` with the filename in an f-string is shell injection. Fix: a list of arguments, with no shell.
- Path traversal through `f.filename`. Fix: `werkzeug.utils.secure_filename(f.filename)`.
  - **Check:** checking for `../` by hand misses other tricks (absolute paths, `..\`), so use the library function.
- The token from `make_token()` is never stored or tied to the user, so it's useless. A real logic finding.
- `assert` for authorization can be removed when Python runs with `-O`. Fix: explicitly return a 403 error.
- The `INSERT` is parameterized, so it's fine.

## What I missed (most serious first)
| # | Problem | What goes wrong | Fix |
|---|---|---|---|
| 1 | `app.run(host="0.0.0.0", debug=True)` | Flask's debug mode serves an interactive debugger page that lets anyone who can reach the port run code, and it's open to the whole network | `debug=False`, and `host="127.0.0.1"` unless it must be public |
| 2 | The admin check trusts a **request header** (`X-Admin: yes`) | the client chooses its own headers, so anyone can send `X-Admin: yes` and delete users | real authentication: a login or session, and a server-side role check |
| 3 | SQL injection: `f"... LIMIT {limit}"` in `/users` | `limit=1; DROP TABLE users` style input, or `limit=(SELECT ...)` leaks data | `int(limit)` with a cap, and `LIMIT ?` |
| 4 | `DELETE ... WHERE name LIKE ?` | a name of `%` matches every user and deletes them all | `=` instead of `LIKE` |
| 5 | `hashlib.md5` for passwords | too fast, with no salt, so leaked hashes crack in seconds | `hashlib.scrypt` with a salt, `bcrypt` or `argon2` |
| 6 | `random.randint` for the token | predictable (only 900,000 values) | `secrets.token_urlsafe()` |
| 7 | Upload saved under the user's filename, with no checks | overwrites existing files; no type or size limit | random file name, an allowed-extensions list, `MAX_CONTENT_LENGTH` |
| 8 | `convert` writes over the input file in place | a failed resize can corrupt the upload | write to a new file, and use `check=True` and `timeout=` |
| 9 | `/avatar` has no authentication, and `username` is unused | anyone can upload for anyone | require login |
| 10 | No unique constraint on `name` | duplicate users with the same name | `UNIQUE` on the column, and handle the error |
| 11 | `range(len(rows))` | not a bug, just style | `[r[0] for r in rows]` |

## My false alarms
- "No timeout on `requests.get` in `/users`."
  - **Check:** there is no `requests.get` anywhere in this code. Some lines in the transcript (`requests.get`, `jsonify(ok=True)`, `"deleted {name}"`) aren't in the code, so they probably came from mock #4 or from the tidy-up. If I said them, they were false alarms. Always check a claim against the code in front of me.
- "The database connection is never closed."
  - **Check:** one connection opened at start-up and kept for the life of the app is normal. The leak pattern is opening a new connection inside each request and never closing it. Mention it at most as a small note.
- "If `range` doesn't start from zero..."
  - **Check:** it does start at 0 (the same doubt as in mock #2). Stating doubt was right, but this one is settled.

## Rules to take into Friday
- **Scan for dangerous calls first** (`eval`, `exec`, `pickle`, `yaml.load`, `shell=True`, `debug=True`), then **trace every value the client controls** (form fields, filenames, query strings, **headers**, cookies) to where it's used.
- **"Who is allowed to do this, and how does the server know?"** Ask it for every route. A header, cookie or hidden field the client can edit is not proof.
- Open with one sentence, then the most serious problem. Don't narrate line by line.
- Say each finding as: what it is, what goes wrong, the exact fix.
- Finish with a sweep down the checklist.

## Checklist (updated)
**Security**
- Code execution: `eval`, `exec`, `pickle.load`, `yaml.load` on outside data
- **Debug mode left on (`debug=True`) or a server open to the whole network**
- Input put straight into a query or command (SQL injection in `LIMIT`/`ORDER BY` too, shell injection: `shell=True`, `os.system`)
- User input used in a file path or upload name (path traversal: use `secure_filename`)
- **Authorization based on something the client controls (headers, cookies, form fields)**
- **Routes with no login check where one is needed**
- Secrets in the code, or printed or logged
- Passwords stored in plain text, or hashed with `md5`/`sha1`
- **`random` used for tokens (use `secrets`)**

**Reliability**
- Files or connections not closed (per request)
- Network calls or subprocesses without a timeout, or without `check=True`
- Errors swallowed, or failures saved as results
- Edge cases: empty input, `None`, missing file
- Deleting more than intended (**`LIKE` with `%`**, wildcards, whole folders)
- **`assert` used for checks that must always run**

**Logic**
- Mutable default arguments (`=[]`, `={}`)
- `is` used where `==` was meant, and `if x:` where `is not None` was meant
- **Values created but never stored or used (a token nobody can check)**
- Files overwritten by name, caches that never expire
- Duplicates allowed where they shouldn't be (no `UNIQUE`)

**Efficiency and style**
- Filtering in code what the database could filter
- Matching that's too loose (substring checks, `LIKE`)
- Global state that grows forever, paths built with `+`

## Friday morning, 1-minute warm-up
1. Read `review-red-flags.md`'s "30-second scan" once.
2. Say the opening sentence out loud: "This code does ___. I'll go from most serious down: security first, then reliability, then logic."
3. Remember: **state doubts, check claims against the code, finish with the checklist.**
