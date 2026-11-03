# devops-journey

Notes and automation scripts from my DevOps study plan (Linux, Bash, Git, networking, Docker, CI/CD, AWS, Kubernetes).

## Scripts

### sysinfo.sh
Writes a system report (user, uptime, disk, memory, processes, service status) to `reports/`, and warns when disk usage passes a threshold.

```bash
./scripts/sysinfo.sh                 # report, checks NetworkManager as the default
./scripts/sysinfo.sh sshd cups       # check specific services
./scripts/sysinfo.sh -q              # save the report without printing it
./scripts/sysinfo.sh -h              # help for usage instructions
```

Exit codes: `0` OK, `1` disk above threshold, `2` invalid flag.


Note: reports are saved as reports/sysinfo-YYYY-MM-DD.txt and are not committed

### netcheck.sh
Check one connection layer at a time to identify where the network is failing.

```bash
./scripts/netcheck.sh                           # report, checks with github.com as the default
./scripts/netcheck.sh no-such-host.ivalid       # check specific address
./scripts/netcheck.sh -q                        # will only print the checks that fail
./scripts/netcheck.sh -h                        # help for usage instructions
```

Exit codes: `0` all checks passed, `1` a check has failed, `2` bad flag.


Note: HTTP 2xx and 3xx count as a pass.

### ghuser.py
Looks up a GitHub user by username and prints their login name and number of public repositories

```bash
python3 ./scripts/ghuser.py <username>                           # prints user's login name and number of public repos
```
#### Example

```
$ python3 ./scripts/ghuser.py octocat
Connection success
octocat
8
```
(count may differ)

Exit codes: `0` user found and details printed, `1` user not found (404), another HTTP error, or a network failure, `2` missing or blank username.


Note: GitHub allows 60 unauthenticated requests per hour per IP address. If you hit the limit, the API answers with an error (usually 403 or 429), and the script exits with 1.


## Notes
Daily study notes are in `notes/`.
