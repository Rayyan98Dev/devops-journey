# Code review checklist (final version)

*Use after the 30-second scan in `review-red-flags.md`. Go down it at the end of every review.*

## How to run the review
1. **Opening sentence:** "This code does ___. I'll go from the most serious problem down: security first, then reliability, then logic."
2. **Scan** for the dangerous calls first (see the red flags file).
3. **Trace every outside value** (arguments, form fields, query strings, headers, cookies, filenames, API data, files) to where it's used: a query, a command, a path, `eval`, `yaml.load`, `pickle`.
4. **For each finding say:** what it is, what goes wrong, the exact fix.
5. **Finish with a sweep down this checklist.**
6. **State doubts out loud** ("I'm assuming X; if not, that's fine"), and **check every claim against the code in front of me.**

## Security (most serious first)
- [ ] Code execution: `eval`, `exec`, `pickle.load`, `yaml.load` on outside data
- [ ] Debug mode left on (`debug=True`), or a server open to the whole network (`0.0.0.0`)
- [ ] Input put straight into a query or command: SQL injection (also in `LIMIT` and `ORDER BY`), shell injection (`shell=True`, `os.system`)
- [ ] User input used in a file path or upload name (path traversal: `../`; use `secure_filename` or `basename`)
- [ ] Authorization based on something the client controls (headers, cookies, form fields)
- [ ] Routes with no login check where one is needed
- [ ] Secrets in the code, or printed or logged
- [ ] Passwords stored in plain text, or hashed with `md5` / `sha1`
- [ ] `random` used for tokens or codes (use `secrets`)
- [ ] `verify=False` on HTTPS requests

## Reliability
- [ ] Files or connections not closed (per request; `with` closes them)
- [ ] Network calls or subprocesses without a `timeout=`
- [ ] Status codes or return codes ignored (`raise_for_status()`, `check=True`)
- [ ] Errors swallowed (`except: pass`), or failures saved or cached as if they were results
- [ ] Edge cases: empty input, zero, `None`, missing file
- [ ] Deleting more than intended (`LIKE` with `%`, wildcards, whole folders)
- [ ] `assert` used for checks that must always run (it's removed with `-O`)

## Logic
- [ ] Mutable default arguments (`=[]`, `={}`)
- [ ] `is` used where `==` was meant
- [ ] `if x:` where `if x is not None:` was meant (0, `""` and `[]` count as false)
- [ ] Off-by-one: `range(len(x) - 1)`
- [ ] Loops that never end (a counter never changed)
- [ ] Values created but never stored or used (a token nobody can check)
- [ ] Files overwritten by name; caches that never expire
- [ ] Duplicates allowed where they shouldn't be (no `UNIQUE`)

## Efficiency and style (last, and keep it short)
- [ ] Work done in code that the database could do
- [ ] Loose matching (substring checks, `LIKE`)
- [ ] Global state that grows forever
- [ ] Paths built with `+` instead of `os.path.join`

## Settled facts (don't doubt these in the interview)
- `range` starts at 0.
- `with open(...)` closes the file, even on errors.
- A `return` ends the function, so no `else` is needed after it.
- SQLite has no username or password. A module-level connection opened once is normal.
- `==` compares values and `is` compares identity.
- Python compares ints and floats fine. Only strings break.
- `subprocess.run([...])` with a list and no `shell=True` is the safe form.
- `cur.execute("... ?", (value,))` is safe against SQL injection. An f-string is not.

## Phrases that work
- "The most serious issue is ___, because ___. The fix is ___."
- "I'm assuming ___; if that's not the case, this is fine."
- "Anything that comes from `request.` is controlled by the client."
- "This is a minor point, but ___."
- "That covers security. Moving on to reliability."
