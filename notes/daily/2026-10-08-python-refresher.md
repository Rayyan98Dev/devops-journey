# Thu 8 Oct: Python refresher

*My own wording, spelling tidied. A **Check:** line is a correction we agreed on.*

## Python functions and scripts
- When calling `greet("Catto", "Hi")`, "Hi" replaces "Hello" because it's passed as the second argument. The default only applies when you leave the argument out.
- `return` can hand back a status, numbers, booleans, strings and so on.
  - **Check:** right, and that's the big difference from bash, where `return` can only give a number from 0 to 255. But `return` exits the *function*, not the script. To end the script with an exit code, use `sys.exit(1)` (after `import sys`).
- In `add(a, b)` with `total = a + b` and no `return`, `total` is never sent back, so the caller gets nothing useful.
  - **Check:** Python quietly returns `None`. And `+` concatenates strings but adds numbers: the same operator does different jobs depending on the type.
- `sys.argv` stores the command-line arguments as a list, and it includes the script name. If I'd remembered it was a list, I'd have said `len()` is the length of the list: 3 for `args.py hello world`.
  - **Check:** `sys.argv[0]` is like `$0`, `sys.argv[1]` like `$1`, and `$#` is `len(sys.argv) - 1`. `"$@"` matches `sys.argv[1:]` (it does *not* include the script name).
- A blank name can sneak through as `" "`. Either strip the spaces and check if the length is zero, or there's a single method for it.
  - **Check:** `.strip()` removes whitespace from both ends, so `"   ".strip()` gives `""`.
- To read an optional `sys.argv[2]`, I need an `if` on the length: one branch for fewer than 3 items, one for 3 or more.
  - **Check:** reading a missing item raises `IndexError`, so check the length first. Use `> 2`, not `== 3`, so a stray extra argument doesn't fall through. The one-line form is `x if condition else y`.
- I forgot `sys.exit(2)` after the usage check, so the no-arguments run exited with 0. Fixed it and confirmed with `echo $?`.

## Python lists and loops
- A `for` loop over a list prints the items line by line, from the first (index 0) to the last.
- `names[-1]` printed the last item.
- Python's `for name in names:` and bash's `for name in "$@"` work the same way: for every item in the list, do this.
  - **Check:** neither loop uses indexes; both just walk the items in order. The difference is how the body is marked: Python uses the colon and *indentation*, bash uses `do` and `done`.
- So a Python list really is a bash array.
  - **Check:** close. Both are ordered and indexed from 0, but a bash array holds only strings, while a Python list can hold anything (numbers, text, other lists).

## Python files
- `with` handles opening a file, assigning it to a variable, and then closing it.
  - **Check:** right, and it closes the file even if an error happens partway through.
- `for line in f` reminds me of `for name in names`: one goes over every line in a file, the other over every item in a list. You can think of `for line in f` as a list of lines taken from `f`.
  - **Check:** good model. Technically `f` hands you one line at a time and never loads the whole file, which matters for big files. `f.readlines()` gives a real list.
- There was an extra blank line after each entry, and I got rid of it with `strip()`. Both `line = line.strip()` before the `print`, and `print(line.strip())`, work.
  - **Check:** each line from the file ends with an invisible `\n`, and `print` adds another one. `print(repr(line))` shows the hidden `\n`.
- If the file had no newlines, everything would print on one line.
  - **Check:** right. The newline is what makes lines exist in a file; to Python a file with no newlines is one line.
- I understand the quirk of Python and its handling of the invisible `\n` when reading a file.

## Python and JSON
- The type of the loaded data is a dict, not a "JSON object". (I guessed wrong here.)
  - **Check:** JSON object `{}` = Python `dict`, JSON array `[]` = `list`, `true`/`false` = `True`/`False`, `null` = `None`.
- `"tools"` became a list, like the ones from the morning.
- A dict has a key-value pair that associates a value with a key, which lists don't have.
  - **Check:** the sharper version: a list finds things by *position*, a dict by *name*. Adding a key never shifts the others.
- `json.dump` with `indent=2` spread the output over several lines, indented. (I didn't predict that part.)
- `data.json` didn't change because we wrote to a new file. `w` is the write flag, equivalent to `>`.
  - **Check:** right on `w` = `>`. `w` empties a file the moment it's opened, so writing to a new file is the safe habit. `a` (append) matches `>>`, and `r` is the default.
- In `addtool.py`, each run starts from the unchanged `data.json`, so the new tool always lands at index 2 and `out.json` only holds the latest run. Adding `bash` gives two `bash`es, because there's no duplicate check.
  - Fixed with `if not (tool in data["tools"]):`. (Tidier: `if tool not in data["tools"]:`.)

## Python APIs and errors
- `r.status_code` shows 2xx if it succeeds.
  - **Check:** a successful GET is `200`. `requests` follows 3xx redirects itself, and it does *not* treat 4xx or 5xx as failures unless you call `r.raise_for_status()`.
- The response's JSON is a dict.
- `timeout=10` is the equivalent of `curl --max-time`.
- A dropped connection isn't a bug in my code.
  - **Check:** right, but it wouldn't give a 4xx. A status code only exists if the server answered. If no answer arrives (packet loss, DNS failure, timeout), `requests` raises an *exception* instead.
- A user that doesn't exist gives a 404. A host that doesn't exist gives an exception, because it's treated as no answer reaching me.
- `try`/`except` is roughly like `||`: the `try` is the left side and the `except` is the right side. `if` and `try`/`except` are more similar to each other, because they can do a lot more than `||`, which only decides what command runs next.
  - **Check:** good mapping. Differences: `except` can pick which error *type* to catch, an unhandled exception stops the script (bash just carries on), and a `try` block can guard several statements at once.

## Teach-back, Day 4
- Today we learned file handling in Python, all of which can be done with `with`. `w` erases everything if it points at an existing file and then writes from the start; you'd use `a` to append; and `r`, read, is the default.
  - **Check:** `with` doesn't do the reading or writing itself. It opens and closes the file; `open(name, mode)` decides what you can do.
- We learned how to handle JSON files, and how to append JSON objects from a JSON file. We didn't append to the file, since we used `w` and put our new output in a new file, which is best practice. What about using `a`?
  - **Check:** we loaded the file into a dict, appended one item to a list inside it, and dumped the whole thing back out. Appending (`a`) a second `{...}` to a JSON file makes it invalid JSON; JSON has to be rewritten whole.
- We learned how to handle errors using try/catch blocks, but before that we learned how to use APIs in Python. I feel we'd need to go deeper, but that might be for things like making my own APIs, so maybe not a today thing. It was pretty straightforward.
  - **Check:** in Python it's `try`/`except`, not `catch`.
- I learned about Python dicts. I feel we need to go over Python's data structures. (Done on Friday.)
