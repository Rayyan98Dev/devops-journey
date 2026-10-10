# Parking lot

One line per tangent. Friday slot: explore the best two.

## Open

- How do sets and dicts jump straight to an item (hashing), and why must dict keys be unchangeable?
- When is a dict the right tool? (LeetCode memory: counting, "have I seen this before?", lookups by name.) Explore with examples. Related: `collections.Counter`.
- Could a 404 be caught in the `except` instead of an `if`? `r.raise_for_status()` raises `requests.HTTPError` for 4xx and 5xx, so try `except requests.HTTPError as e:` and read `e.response.status_code`. Note: if `requests.get(...)` itself fails, `r` is never assigned.
- Writing JSON safely: write to a temporary file, then rename, so a crash can't leave a half-written original. Why not append (`a`) to JSON?
- `requests` in more depth: headers, authentication, POST, retries, paging. Building my own API is a separate topic for later.
- Setting permissions from Python: `os.chmod(path, 0o755)`. Why the `0o` prefix? (Plain `755` would be read as decimal.) Try it on `hello.sh`.
- Getting better at reading technical docs: the `requests` reference page was hard to use. Reference docs say what exists, tutorials say how to use it. Find good sources for each, and test any answer by experiment.

## Answered

- Why `string = string.strip()` but `data["tools"].append(tool)` with no assignment? (Fri 9 Oct) Strings can't change in place, so `strip()` returns a new one. `append` changes the list in place and returns `None`, so `data = data["tools"].append(tool)` leaves `data` as `None`.