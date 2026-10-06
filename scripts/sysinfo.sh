#!/usr/bin/env bash
# sysinfo.sh: system report with service check and disk check
set -o pipefail

## --- Global variables ---
quiet_flag=0
disk_threshold=80

# --- Functions ---
# --- Report Function ---
report_function () {

  echo "Current-user: $(whoami), Hostname: $(hostname), Date: $current_date, Time: $(date +%T)" #Printing out the hostname, username, date and time

  echo "Uptime: $(uptime -p)" #Printing out the computer's uptime

  echo "Disk Usage:" 
  df -h / #printing disk usage
  echo "Memory Usage:"
  free -h #printing memory usage

  echo "Processes: $(ps aux --no-headers | wc -l)"    #Printing out the number processes the no headers flag to stop ps aux from printing the header line and stop wc -l from counting an extra line that is not a process.

  for service in "$@"; do
  echo "$service: $(systemctl is-active "$service")"
  done

  # --- Disk check ---
  disk_used=$(df --output=pcent / | tail -n 1 | tr -dc '0-9')
  if [[ $disk_used -gt $disk_threshold ]]; then
    if [[ $quiet_flag -eq 1 ]]; then
      echo "Disk check: $disk_used% used (WARNING: above $disk_threshold% )" >&2;
    fi
    echo "Disk check: $disk_used% used (WARNING: above $disk_threshold% )";
    return 1
  else
    echo "Disk check: $disk_used% used (OK: threshold $disk_threshold% )"
  fi
  
  return
}

# --- Flags ---
while true; do
	case "$1" in
		-h) echo "usage: $(basename "$0") [-h] [-q] [service...]"; exit 0;;
		-q) quiet_flag=1; shift;;
		-*) echo "ERROR: Unknown flag" >&2; exit 2;;
		*) break;;
	esac
done

# --- Default service ---
if [[ $# -eq 0 ]]; then
	set -- NetworkManager
fi

# --- Setup ---
mkdir -p reports
current_date=$(date +%F)

# --- Report ---
status=0
if [[ $quiet_flag -eq 0 ]]; then
  report_function "$@" | tee "reports/sysinfo-$current_date.txt"
  status=$?
else
  report_function "$@" > "reports/sysinfo-$current_date.txt"
  status=$?
fi

echo "Report saved to reports/sysinfo-$current_date.txt"
exit "$status"