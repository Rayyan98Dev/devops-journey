# Thu 22 Oct: Mock code review #4 (Mercor practice)

*From my spoken review, tidied. A **Check:** line is a correction. Mercor Code Review Session is on Fri 23 Oct at 10:10.*

## The code
A report cache: `fetch_report` gets a sales report from an API, `load_cached` and `save_cached` keep copies on disk with `pickle`, `get_report` uses the cache first, and `total_sales` adds up the sales amounts for a region.

## Progress
| Mock | Time spoken | Catches | False alarms | Missed security issues |
|---|---|---|---|---|
| #1 (Fri 16) | 4.5 min | 1.5 | 3 | |
| #2 (Tue 20) | 9 min | 1.5 | 4 | SQL injection |
| #3 (Wed 21) | 14 min | 5 | 2 minor | shell injection, path traversal |
| #4 (Thu 22) | 14 min | 5.5 | 1 | **`eval`, `pickle`, path traversal** |

- Good: I said "I have not used pickle before" instead of asserting, and I corrected myself on the `if cached: return` (a `return` already ends the function, so no `else` is needed).
- Weak: the opening took 2 minutes of reading lines out loud, and the three most serious problems were all missed.

## What I caught
- `API_TOKEN` is hard-coded. Fix: an environment variable.
- The token is printed in `total_sales`.
  - **Check:** say it firmly (not "not sure how wise"): secrets must never be printed or logged. Fix: remove it from the `print`.
- No timeout on `requests.get`, so it can hang. Fix: `timeout=10`.
- `load_cached` opens a file and never closes it. Fix: `with open(path, "rb") as f:`.
- Non-200 responses aren't handled.
  - **Check:** add *what goes wrong*. `fetch_report` returns `None`, `get_report` caches that `None`, and `total_sales` crashes on `None["rows"]`. Fix: `r.raise_for_status()`, and don't cache failures.
- `params={}` is a mutable default.
  - **Check:** add what goes wrong and the fix. The same dict is shared by every call, so values left by one call leak into the next. Fix: `params=None`, then `params = dict(params or {})`.
- No check that `report_id` or `region` is empty (minor).
- `CACHE_DIR` is hard-coded, so it fails where `/var/cache/reports` doesn't exist. A fair config point, but minor, and it took a lot of time.

## My false alarm
- "`save_cached` never closes the file / opens it twice."
  - **Check:** `with open(...) as f:` closes the file automatically, even on errors. `pickle.dump(data, f)` writes to the file that's already open. Only `load_cached` leaks.
- Wrong assumption: "pickle returns JSON."
  - **Check:** `pickle` saves and restores any Python object, here the dict from `r.json()`. Stating the uncertainty was right.

## What I missed (most serious first)
| # | Problem | What goes wrong | Fix |
|---|---|---|---|
| 1 | `eval(row["amount"])` on data from the API | `eval` runs any Python code. An amount like `__import__('os').system('rm -rf ~')` runs it | `float(row["amount"])` or `Decimal(...)` |
| 2 | `pickle.load` on files from disk | loading a pickle can run code. Anyone who can write into the cache folder (or a crafted file) can run code | store JSON instead (`json.dump` / `json.load`) |
| 3 | Path traversal: `report_id` builds the path | `report_id = "../../etc/x"` reads or writes outside the cache folder (and with #2, loads a planted pickle) | check the ID against a pattern (for example digits only), or `os.path.basename` |
| 4 | Failures are cached (`save_cached(None)`) | one bad response is saved and reused | only save when the fetch succeeded |
| 5 | `if cached:` treats an empty report as missing | an empty report is refetched every time | `if cached is not None:` |
| 6 | `region in row["region"]` is a substring match | "North" also matches "North-East" | `==` |
| 7 | The cache never expires | old sales numbers are returned forever | store a timestamp and refetch after a set age |
| 8 | Paths built with `+` | easy to get slashes wrong | `os.path.join` |

## Rules to take into Friday
- **Code execution first.** Before anything else, scan for the dangerous functions: `eval`, `exec`, `pickle.load`, `yaml.load`, `subprocess(..., shell=True)`, `os.system`, and f-strings in SQL. Any of these fed by data I didn't write is the top finding.
- **Then trace every outside value** (arguments, API data, files) to where it's used: a query, a command, a path, `eval`.
- **Opening: one sentence**, then straight to the most serious problem. Don't read the code aloud line by line.
- Each finding: what it is, what goes wrong, the exact fix. Then the checklist sweep.

## Checklist (updated)
**Security**
- **Code execution: `eval`, `exec`, `pickle.load`, `yaml.load` on outside data**
- Input put straight into a query or command (SQL injection, shell injection: `shell=True`, `os.system`)
- User input used in a file path (path traversal: `../`)
- Secrets in the code (and unused ones)
- Secrets printed or logged
- Passwords stored or compared in plain text

**Reliability**
- Files or connections not closed (`with` closes them)
- Network calls or subprocesses without a timeout
- Errors swallowed (`except: pass`, ignored status codes or return codes, `None` returned silently)
- **Failures saved or cached as if they were results**
- Edge cases: empty input, zero, missing file, `None` returned
- Deleting more than intended (wildcards, whole folders)

**Logic**
- Mutable default arguments (`=[]`, `={}`)
- `is` used where `==` was meant
- **Truthiness checks (`if x:`) where `is not None` was meant**
- Off-by-one in loops (`range(len(x) - 1)`)
- Loops that never end (a counter that's never changed)
- Files overwritten by name
- **Caches that never expire**

**Efficiency and style**
- Doing the same work twice, or filtering in code what the database could filter
- Matching that's too loose (substring checks)
- Global state that grows forever
- Paths built with `+` instead of `os.path.join`
