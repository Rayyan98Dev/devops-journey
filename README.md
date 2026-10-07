# devops-notes

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

## Notes
Daily study notes are in `notes/`.