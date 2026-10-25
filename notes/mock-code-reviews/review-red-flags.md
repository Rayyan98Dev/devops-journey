# Code review red flags: functions to know on sight

*Scan for these **first**, before reading for logic. If data I didn't write (arguments, user input, API responses, files, environment) can reach one, it's the top finding.*

## Python

### Runs code (the worst kind: "remote code execution")
| Function | What it does | Why it's dangerous | Safe alternative |
|---|---|---|---|
| `eval(s)` | evaluates `s` as a Python expression | any code in `s` runs: `__import__('os').system('...')` | `int()`, `float()`, `Decimal()`; `ast.literal_eval()` for literals like lists and dicts |
| `exec(s)` | runs `s` as Python statements | same as `eval`, for whole programs | don't. Use a dict of allowed functions instead |
| `pickle.load(f)` / `pickle.loads(b)` | turns saved bytes back into Python objects | a crafted pickle runs code while loading | `json.load` / `json.dump` |
| `yaml.load(s)` (PyYAML, old style) | parses YAML and can build any object | crafted YAML can run code | `yaml.safe_load(s)` |
| `marshal.loads`, `shelve.open` | other save/load formats | `shelve` uses pickle underneath | JSON |
| `__import__(name)`, `importlib.import_module(name)` with outside input | imports a module by name | attacker picks what gets loaded | a fixed list of allowed names |

### Runs shell commands
| Function | Why it's dangerous | Safe alternative |
|---|---|---|
| `os.system(cmd)` | always goes through the shell, so `; rm -rf ~` in input runs | `subprocess.run([...])` with a list |
| `os.popen(cmd)` | same as `os.system`, returns the output | `subprocess.run([...], capture_output=True, text=True)` |
| `subprocess.run(cmd, shell=True)` with an f-string | shell injection | a list of arguments and no `shell=True` |
| `subprocess.*` without `check=True` or a `returncode` check | failures look like success | `check=True` |
| `subprocess.*` without `timeout=` | can hang forever | `timeout=...` |

### Builds queries
| Pattern | Why it's dangerous | Safe alternative |
|---|---|---|
| `cur.execute(f"... WHERE name = '{name}'")` (also `%` or `+`) | SQL injection | `cur.execute("... WHERE name = ?", (name,))` |

### Touches files
| Pattern | Why it's dangerous | Safe alternative |
|---|---|---|
| `open(base + "/" + user_input)` | path traversal (`../../etc/passwd`) | `os.path.basename()`, or check the resolved path stays inside the folder |
| `tarfile.extractall()` / `zipfile.extractall()` on downloaded archives | files inside can be named `../../x` and land anywhere | `tarfile.extractall(filter="data")` (Python 3.12+), or check each name |
| `os.remove`, `shutil.rmtree` with a built path or a wildcard | deletes more than intended | check the path and the file type first |
| `open(...)` without `with` | file never closed | `with open(...) as f:` |
| `tempfile.mktemp()` | another program can grab the name first | `tempfile.mkstemp()` or `NamedTemporaryFile` |

### Network
| Pattern | Why it's dangerous | Safe alternative |
|---|---|---|
| `requests.get(url)` without `timeout=` | hangs forever | `timeout=10` |
| `verify=False` | turns off HTTPS checking, so anyone in the middle can read and change traffic | leave the default (`verify=True`) |
| no `raise_for_status()` or status check | errors treated as data | `r.raise_for_status()` |
| `requests.get(user_url)` | the server can be made to fetch internal addresses (SSRF) | an allowlist of hosts |

### Secrets and randomness
| Pattern | Why it's dangerous | Safe alternative |
|---|---|---|
| `TOKEN = "..."`, `PASSWORD = "..."` in code | anyone with the code has it | `os.environ["TOKEN"]` |
| secrets in `print`, logs or error messages | ends up in logs | never log them |
| `random.random()`, `random.choice()` for tokens, passwords, IDs | predictable | `secrets.token_hex()`, `secrets.choice()` |
| `hashlib.md5` / `sha1` / plain `sha256` for passwords | too fast to crack | `hashlib.scrypt`, `bcrypt`, `argon2` |
| `password == stored` | plain text, and the timing leaks | compare hashes with `hmac.compare_digest` |

### Logic traps (not security, but common in reviews)
| Pattern | What goes wrong | Fix |
|---|---|---|
| `def f(x=[])` / `={}` | one shared list or dict for every call | `x=None`, then create it inside |
| `if x:` where `x` can be `0`, `""`, `[]` | valid empty values treated as missing | `if x is not None:` |
| `x is "text"` / `x is 5` | compares identity, not value | `==` |
| `except:` / `except Exception: pass` | hides every error | catch specific errors, log or re-raise |
| `assert` for checks | removed when Python runs with `-O` | `if ...: raise ValueError(...)` |
| `range(len(x) - 1)` | skips the last item | `for item in x:` |
| `if a in b` on strings | substring match is too loose | `==`, or split first |
| changing a list while looping over it | items skipped | loop over a copy, or build a new list |

## JavaScript
| Pattern | Why it's dangerous | Safe alternative |
|---|---|---|
| `eval(s)`, `new Function(s)`, `setTimeout("string")` | runs any code | `JSON.parse`, `Number()`, pass a function |
| `el.innerHTML = userText`, `document.write` | cross-site scripting (XSS): user text becomes HTML and scripts | `el.textContent = userText` |
| `child_process.exec(\`cmd ${input}\`)` | shell injection | `execFile("cmd", [input])` |
| SQL built with template strings | SQL injection | parameterized queries (`?` or `$1`) |
| `==` | type juggling (`"0" == 0` is true) | `===` |
| `JSON.parse` without `try` | bad input crashes | `try/catch` |
| `fetch(url)` without a timeout or `res.ok` check | hangs, errors treated as data | `AbortSignal.timeout(10000)`, check `res.ok` |
| a missing `await` | the promise is used as if it were the value, and errors vanish | `await` it |
| `Math.random()` for tokens | predictable | `crypto.randomUUID()`, `crypto.getRandomValues()` |
| merging user JSON into objects (`Object.assign`, deep merge) | prototype pollution through `__proto__` | reject `__proto__` and `constructor` keys |

## Bash
| Pattern | Why it's dangerous | Safe alternative |
|---|---|---|
| `$var` unquoted | spaces split it and `*` expands: `rm $file` can delete several files | `"$var"` |
| `rm -rf "$DIR/"*` when `DIR` might be empty | becomes `rm -rf /*` | `${DIR:?}` stops if empty |
| `eval "$input"` | runs any code | don't |
| `curl ... \| bash` | runs whatever the server sends | download, read, then run |
| no `set -euo pipefail` | errors ignored, the script keeps going | put it at the top |
| `cd dir` without a check | the next commands run in the wrong folder | `cd dir \|\| exit 1` |
| temp files at fixed names (`/tmp/out.txt`) | collisions, and other users can plant files | `mktemp` |
| passwords as arguments (`mysql -pSECRET`) | visible to everyone in `ps` | an environment variable or a config file |
| `chmod 777` | anyone can change or run it | the smallest permissions that work |
| `for f in $(ls)` | breaks on spaces in names | `for f in *` |

## The 30-second scan, in order
1. **Runs code:** `eval`, `exec`, `pickle`, `yaml.load`, `new Function`, `innerHTML`.
2. **Runs commands:** `os.system`, `shell=True`, `exec(` in Node, `eval` in Bash.
3. **Builds queries or paths from input:** f-strings in SQL, `+` paths.
4. **Secrets:** hard-coded, printed, or compared in plain text.
5. **Network and subprocess:** timeouts, status checks, `verify=False`.
6. Then read for logic with the checklist.
