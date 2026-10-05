#!/usr/bin/env bash
# First line: run this file with bash. Shebang (#!): tells Linux to run this file with bash
#This script is an introduction to bash scripting on linux. It is supposed to:
# * The date and time, hostname, and current user
# * Uptime
# * Disk usage of /
# * Memory usage
# * Number of running processes
# * Whether NetworkManager is active
# * A saved copy of the report in reports/sysinfo-YYYY-MM-DD.txt

mkdir -p reports    #Creating folder for the report to be stored
current_date=$(date +%F)    #Storing date in a variable +%F is the format for the date to printed in.
{

    echo "Current-user: $(whoami), Hostname: $(hostname), Date: $current_date, Time: $(date +%T)" #Printing out the hostname, username, date and time

    echo "Uptime: $(uptime -p)" #Printing out the computer's uptime

    echo "Disk Usage:" 
    df -h / #printing disk usage
    echo "Memory Usage:"
    free -h #printing memory usage

    echo "Processes: $(ps aux --no-headers | wc -l)"    #Printing out the number processes the no headers flag to stop ps aux from printing the header line and stop wc -l from counting an extra line that is not a process.

    echo "NetworkManager: $(systemctl is-active NetworkManager)"    #Printing out whether NetworkManager is Active or not.
} | tee "reports/sysinfo-$current_date.txt" #Storing the output in file in reports folder. To store the output without printing on screen you can direct the output to the file using > and have no output on the terminal.

echo "Report saved to reports/sysinfo-$current_date.txt"