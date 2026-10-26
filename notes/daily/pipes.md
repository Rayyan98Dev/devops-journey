# Pipes and redirection (connections approach)

Rewritten 26 Oct 2026. Book: TLCL chapter 6, Redirection.

## Model

A pipe is a hose that takes the **stdout** of the last command and feeds it into the **stdin** of the next program. By default it only carries stream 1.

> Check: say "stdout", not "output". stderr is output too, and it does not go through the pipe by default.

## The three streams

| Number | Name   | Default destination |
|--------|--------|---------------------|
| 0      | stdin  | keyboard (input)    |
| 1      | stdout | screen              |
| 2      | stderr | screen              |

## Look-alike table

| Operator | Sends to | Streams | My one-line model |
|---|---|---|---|
| `>` | a file (overwrite) | 1 | deletes everything in the file and starts fresh |
| `>>` | a file (append) | 1 | goes to the end of the file to append data |
| `\|` | another program's stdin | 1 | hose from stdout to the next program's stdin, nothing touches disk |
| `2>` | a file | 2 | points stream 2's output to a file |
| `2>&1` | wherever stream 1 points right now | 2 | points stream 2 at stream 1's destination at that moment |
| `\|&` | another program's stdin | 1 and 2 | shorthand for `2>&1 \|` |
| `tee file` | a file and stdout | 1 | T-junction: copies stdin to a file and to stdout |

> Check: `>` empties the file before the command even runs. Both `>` and `>>` create the file if it does not exist.

> Check: `>` always sends to a file, `|` always sends to a program. `ls > grep` does not run grep, it creates a file called `grep`.

## Rule: redirections are read left to right

`2>&1` points stream 2 to where stream 1 is pointing now. It does not change if stream 1's destination is changed later in the command.

| Command | Screen | File |
|---|---|---|
| `cmd > out.txt 2>&1` | nothing | output and errors |
| `cmd 2>&1 > out.txt` | errors | output only |

## Worked examples

**1. The error skips the pipe**

```bash
ls /nonexistent | wc -l
```

```
ls: cannot access '/nonexistent': No such file or directory
0
```

The error is printed to the screen and not fed into `wc`. Stream 1's destination is the pipe; stream 2's is still the screen. `wc` received nothing, so it counted 0.

**2. The error joins the pipe**

```bash
ls /nonexistent 2>&1 | wc -l
```

```
1
```

Stream 2 now points where stream 1 points, which is the pipe, so `wc` counts the error line. Nothing reaches the screen except the count.

**3. Moving stream 2 to a file**

```bash
ls /nonexistent /etc 2> errors.txt | wc -l   # prints 280, error is in errors.txt
ls /nonexistent /etc |& wc -l                # prints 281, error is counted too
```

> Check: the pipe only carries stream 1 by default. Stream 2 goes to the screen unless I point it elsewhere. `2>&1` (or `|&`) is the only way to get it into the pipe. `2> f` just moves it from the screen to a file; it has nothing to do with the pipe.

## tee vs >

`tee` always passes its input on to stdout, and stdout goes wherever stdout goes:

- Mid-chain: `echo hello | tee out.txt | wc -c` gives `6` (the newline counts), and `out.txt` holds `hello`.
- End of chain: `echo hello | tee out.txt` shows `hello` on the screen and saves it.
- `echo hello > out.txt` shows nothing on screen.

Rule: use `tee` when I still need the data to go to stdout (screen or next command). Use `>` when I don't need it on stdout. Use `> file 2>&1` to store errors as well.

> Check: `tee` only copies stdout. To save errors and also see them, put `2>&1` before the pipe: `cmd 2>&1 | tee file` or `cmd |& tee file`.

## Gotchas

- `ls > grep` creates a file called `grep`; it does not run grep.
- Errors "skipping" a pipe are not a bug; that is stderr doing its job.
- To hide errors without capturing them: `cmd 2>/dev/null`.
