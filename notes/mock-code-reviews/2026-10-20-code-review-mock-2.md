# Tue 20 Oct: Mock code review #2 (Mercor practice)

*From my spoken review, tidied. A **Check:** line is a correction we agreed on. Mercor Code Review Session is on Fri 23 Oct.*

## The code
A small login script using SQLite: `get_user` looks a user up by name, `list_admins` lists users with the admin role, and `login` checks a username and password.

## What went better than mock #1
- Spoke for about 9 minutes (mock #1: 4.5).
- Corrected my own first guess: it's a login script, and whoever gets in has admin rights, so it has to be secure.

## What I caught
- `DB_PASSWORD` is a password in plain text in the code. It should be in an environment variable.
  - **Check:** it's also unused. SQLite has no login, so it's dead code as well as a secret in the code.
- `range(len(users) - 1)` might skip the last user.
  - **Check:** `range` does start at 0. The `- 1` is what skips the last user. Fix: `for name, role in users:`.

## My false alarms (all from guessing about SQLite)
- "We connect to the database but never log in, so we'll get an error."
  - **Check:** SQLite is a local file. `sqlite3.connect("users.db")` just opens it, with no username or password.
- "Only admins of this database can log in, so that's a logic error."
  - **Check:** `login` never checks the role at all, so that isn't what the code does.
- "If `users` is empty, the loop will throw an exception (out of range or a negative number)."
  - **Check:** `range(-1)` is just empty. The loop doesn't run, and the function returns `[]`.
- "`list_admins` isn't called anywhere."
  - **Check:** in a module, functions are often called from other files, so this isn't a problem.
- Lesson: when I don't know how something works, **ask, don't assert**: "Does SQLite need credentials here? If not, `DB_PASSWORD` looks unused."

## What I missed (most serious first)
| # | Problem | What goes wrong | Fix |
|---|---|---|---|
| 1 | SQL injection: the username goes into the query with an f-string | a "username" like `' OR '1'='1` can log in as anyone | `cur.execute("SELECT ... WHERE name = ?", (username,))` |
| 2 | Passwords stored and compared in plain text | anyone who reads the database has every password | store a hash (`hashlib.scrypt`, `bcrypt`) and compare hashes |
| 3 | The password is printed (`print(f"... with password {password}")`) | it ends up in logs | never log secrets |
| 4 | `except Exception: pass` | hides every error; an unknown user gives `None`, and `None[2]` fails silently | `if user is None: return False`, and catch specific errors |
| 5 | Connections are never closed | leaks connections and file handles | `conn.close()`, or `contextlib.closing(sqlite3.connect(...))`. SQLite's own `with` doesn't close the connection |
| 6 | `role is "admin"` | `is` compares identity, not value, so it's unreliable | `role == "admin"` |
| 7 | Every user is filtered in Python | slow with many users | `WHERE role = 'admin'` in the SQL |

## Score
- 1 full catch, 1 half catch, 4 false alarms, out of about 9 real problems.
- My checklist would have caught #3, #4 and #5, but I didn't use it.

## Habits for next time
1. Open with what the code does, in one sentence.
2. Most serious first. For each problem: **what it is, what goes wrong, the exact fix.**
3. Unsure about a library or tool? State the assumption or ask, but don't call it a bug.
4. Before saying "that's it": **a final sweep down the checklist**, line by line.

## Checklist (updated)
- Secrets in the code (and unused ones)
- **Input put straight into a query or command (SQL injection, shell injection)**
- **Passwords stored or compared in plain text**
- **Secrets printed or logged**
- Files or connections not closed
- Network calls without a timeout
- Errors swallowed (`except: pass`, `except Exception: pass`, ignored status codes)
- Edge cases: empty input, zero, missing file, **`None` returned**
- Mutable default arguments (`=[]`, `={}`)
- **`is` used where `==` was meant**
- **Off-by-one in loops (`range(len(x) - 1)`)**
- Doing the same work twice, or filtering in code what the database could filter
- Matching that's too loose (substring checks)
