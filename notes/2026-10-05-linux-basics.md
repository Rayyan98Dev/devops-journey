LINUX AND LINUX COMMANDS

I learned some commands

 * chmod = changes the files permission. 
 		   The position of the numbers determines who gets what permission i.e. the first position is for the owner, the second position is for the group and the third position is for everyone.
 		   The numbers are how the permissions are written as 4 is for read, 2 is for write and 1 is for execute and to add up the numbers i.e. 7 = 4+2+1 so read, write and execute
		   You can also use letters +x means everyone can execute u+x means user is granted execute permission and g-x means we are removing the groups ability to execute

 * > sends output to a file and overwrites it
 * >> sends output to file and appends it		   
 * 2>&1 2 is for error messages i.e stderr and > sends it to the same place as stdout (thats is what 1 is for stdout). **The & is important that &1 mean stream for 1 which is stdout with the & it would just make a file 1**

 * ls -l is the long listing with permissions, owner, size, and date
 * grep filters lines of text and grep error will only show lines containing error.
 * wc -l counts the lines
 * | feeds the output of one command into the other.

 * A process is a running instance of a program with a PID while a service is a long running background process managed systemd, so it starts on boot, restarts on crash, and has logs.
 * User accounts are stored in /etc/passwd while the password hashes are stored /etc/shadow readable only by root

FILE SYSTEM LAYOUT

* head only shows the first 10 lines while tail shows the last 10 you can -n 5 to show 5 lines instead or change it to whatever number you want
* $$, $ expands variables and $$ is the PID for the shell.
* jobs show the processes started by the shell jobs was called in
* ps aux will show all the process a mean all users, u means user friendly and x means processes with no terminal. 
* /etc = config files, /var = changing data like logs, /home = users,
  /usr = installed programs, /tmp = scratch space, /proc = live kernel/process info

PROCESSES & SIGNALS
* & runs a command in the background. [1] is the job number (this shell only), 27472 is the PID (system-wide)
* kill sends a signal. Default is SIGTERM (polite stop); kill -9 is SIGKILL (forced, last resort)
* kill %1 = job 1, kill 27472 = by PID
* ps aux | grep sleep also matches the grep itself; pgrep -a sleep avoids that

SERVICES
* systemctl status <name>, systemctl is-active <name>, journalctl -u <name> for logs

USEFUL
* && runs the next command only if the previous one succeeded
* tail -f file.log follows a log live
* ls -l prints a "total" line first, so ls -l | wc -l counts one extra