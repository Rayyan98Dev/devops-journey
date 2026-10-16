# Fri 16 Oct: Mock code review (Mercor practice)

*My own wording, spelling tidied. A **Check:** line is a correction we agreed on. Practice for the Mercor Code Review Session, moved to Fri 23 Oct.*

## The code
A Python script that counts `ERROR` lines in a log, works out the error rate as a percentage, and sends it to an API with a token.

## How to structure the review (25 minutes)
1. What the code is meant to do, in one sentence.
2. The most serious problems first: bugs and security.
3. Then reliability: what breaks in edge cases.
4. Then smaller things: readability and style.
5. For each problem: **what it is, what goes wrong, and the exact fix.**
- If I'm unsure, ask it as a question ("is this intended?") instead of calling it a bug.
- I stopped at 4.5 minutes, so there's room to go deeper on each problem.

## What I caught
- I started by explaining what the code does (reads a log, calculates an error rate, posts it to an API). Good opening.
- The API token shouldn't be hard-coded.
  - Fix: read it from an environment variable (`os.environ["API_TOKEN"]`), and since it was in the code, revoke it and make a new one.
- Something was off with `seen`.
  - **Check:** it is set up, as the default `seen=[]`, and that's the real bug. A default list is created once and shared by every call, so it keeps growing. Fix: `seen=None`, then `if seen is None: seen = []`.

## My false alarms
- "`error_rate` is called too early, it should be after the request."
  - **Check:** the rate has to be calculated before it can be sent. The order is fine.
- "The `except` won't catch the `requests` errors."
  - **Check:** a bare `except:` catches **everything**, and that's the problem. It hides every error (even my own bugs and `Ctrl+C`) and prints a message that says nothing. Fix: catch specific errors (`requests.RequestException`, `OSError`, `ZeroDivisionError`) and print what went wrong. I mixed this up with my `ghuser.py` `ConnectionError` bug.
- "`errors += 1` might cause an error."
  - **Check:** it's exactly the same as `errors = errors + 1`. No bug.

## What I missed
| # | Problem | Fix |
|---|---|---|
| 1 | The file is never closed | `with open(path) as f:` |
| 2 | The file is read twice (slow, could change in between) | count both totals in one pass |
| 3 | An empty file crashes with division by zero | `if total == 0: return 0.0` |
| 4 | `requests.post` has no timeout, so it can hang forever | `timeout=10` |
| 5 | Any non-200 response is silently ignored | `r.raise_for_status()`, or print the status |
| 6 | `"ERROR" in line` also matches `NO_ERROR` or `ERRORS` | match the exact field |

## Score
- 1 full catch and 1 half catch out of about 8, plus 3 false alarms.
- False alarms matter as much as misses.

## Checklist for next time (things to look for in any code)
- Secrets in the code
- Files or connections not closed
- Network calls without a timeout
- Errors swallowed (bare `except:`, ignored status codes)
- Edge cases: empty input, zero, missing file
- Mutable default arguments (`=[]`, `={}`)
- Doing the same work twice
- Matching that's too loose (substring checks)
