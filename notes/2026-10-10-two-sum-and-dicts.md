# Sat 10 Oct: Two-sum and dicts

*My own wording, spelling tidied. A **Check:** line is a correction we agreed on.*

## Two-sum and dicts
- For two-sum: add a number as the key, then work out `target - number` and see if it's in the dict.
- If you store the number before you check, you'll find its own complement in the dict and get an answer where both indices are the same. So check first, then store.
