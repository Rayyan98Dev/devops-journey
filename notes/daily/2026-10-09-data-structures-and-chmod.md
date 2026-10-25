# Fri 9 Oct: Data structures and chmod

*My own wording, spelling tidied. A **Check:** line is a correction we agreed on.*

## Python data structures
- A list is an array of items.
- A tuple is an unchangeable pair of data.
  - **Check:** a tuple can hold any number of items, not just two. Think of it as a list that can't be changed.
- A set is a list of unique items; I think it has no indexes.
  - **Check:** right. No repeats, no order, so `[0]` doesn't work.
- A dict is a list of key-value pairs with unique keys.
  - **Check:** the sharper version: a list finds things by *position*, a dict finds them by *name* (the key).
- `in` checks if the left-hand item exists in the right-hand collection, and returns `True` or `False`.
- `in` is faster on a set than on a list.
  - **Check:** the reason isn't duplicates. A list checks items one by one (scan); a set or dict calculates where the item would be and jumps there.

## chmod (TLCL Chapter 9)
- `chmod xyz` is really a permission setter for all three, user, group and other, in one go, with 4 = read, 2 = write, 1 = execute.
- `chmod 755` sets permissions for all three at once; `chmod u+x` only sets it for the user.
  - **Check:** `755` rewrites all nine bits; `u+x` touches one bit and leaves the other eight alone.
- `+` adds permissions and leaves the rest alone, while `=` sets the permission and removes all others that don't match.
- `./script` needs an `x` bit as well as an `r` bit to run, while `bash` already has all of these.
  - **Check:** `bash ./script` only needs `r` on the script, because `bash` is the program doing the running.
- If `x` is what lets me into a directory, I would remove the 1 permission to stop someone entering it.
  - **Check:** `chmod go-x dir`. On a directory, `r` lets you list it and `x` lets you enter it.
- Connection: Python has yes/no in the form of a boolean, and each `r`, `w`, `x` is a yes/no switch. Each octal digit packs three of them into one number.

## Teach-back, Day 5
- Today I learned about bash permissions. I rewrote my notes on `chmod xyz`, and on `chmod a+b`, where I learned about `-` remove, `+` add, and `=` set to this and remove everything else.
- I learned about catching exceptions in Python, and how `requests` exceptions look the same as Python exceptions but are not caught. I learned how to catch them.
  - **Check:** they have the *same name* but are different classes. `except ConnectionError` catches Python's own; use `requests.RequestException`.
- `requests.RequestException` catches all its child exceptions. The `requests` manual's wording is hard to use, so I should find other sources or get better at reading reference docs.
- Question I raised: could I have caught the 404 in my `except` clause instead?
  - **Check:** only with `r.raise_for_status()`, which raises `requests.HTTPError`. Catch it with `except requests.HTTPError as e:` and read `e.response.status_code`. (If `requests.get` itself fails, `r` is never assigned.)
- I learned about data structures and which ones to use. Most of it came from w3schools, the AI overview in Brave, and experimenting afterwards, like setting up my `if` statement and using `dict.get()`.
  - **Check:** reference docs say what exists, tutorials say how to use it, and an experiment confirms either.
