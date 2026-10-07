#!/usr/bin/env bash
#netcheck.sh to check one connection layer at a time. Note: HTTP 2xx and 3xx are considered passes for this script

#--- Global Variables ---
quiet_flag=0

#--- Flags ---
while true; do
	case "$1" in
		-h) echo "usage: $(basename "$0") [-h] [-q] [target]"; 
			echo "-q will only show checks that failed."; 
			echo "Note: HTTP 2xx and 3xx are considered passes.";
			echo "exit: 0 all passed, 1 a check failed, 2 bad flag" 
			exit 0;;
		-q) quiet_flag=1; shift;; # only prints failures
		-*) echo "ERROR: Unknown flag" >&2; exit 2;;
		*) break;;
	esac
done

#--- Helper Functions ---
check_function () {

	if [[ $# -lt 2 ]]; then
		echo "check_function: needs a label and a command" >&2
		exit 2 
	fi

	label=$1
	shift

	if "$@" >/dev/null 2>&1; then
		if [[ $quiet_flag -eq 0 ]]; then
			echo "$label: OK"
		fi
		((count_pass++))
		return 0
	else
		echo "$label: FAIL"
		return 1
	fi 
}
#--- Defaults ---
target=${1:-github.com}

#--- Checks ---
count_pass=0
gateway=$(ip -4 route show default | head -n 1 | cut -d " " -f 3)

check_function "checking gateway" test -n "$gateway"
check_function "checking gateway ping" ping -c 3 -W 2 "$gateway"
check_function "checking internet ping" ping -c 3 -W 2 1.1.1.1
check_function "checking dns lookup" ping -c 3 -W 2 "$target"
check_function "checking curl" curl -f -s -o /dev/null --max-time 10 "https://$target"

#--- Report ---
echo "Result: $count_pass/5 passed"

if [[ $count_pass -lt 5 ]]; then
	exit 1
else
	exit 0
fi