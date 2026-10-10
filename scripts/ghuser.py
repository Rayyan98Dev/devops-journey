import sys
import requests
# script to get user github login username and number of public repos

#--- Check if no arguments are sent ---
if (len(sys.argv) <= 1):
    print("Please enter your username", file=sys.stderr)
    sys.exit(2)

#--- Check if argument is an empty string ---
string = sys.argv[1].strip()
if len(string) == 0:
    print("Please enter your username", file=sys.stderr)
    sys.exit(2)
name = string

#--- try exception block to connect to user git hub extension account ---
try:
    url = "https://api.github.com/users/"+name
    r = requests.get(url, timeout=10)
    if r.status_code == 404: 
        print("Error: 404 account not found", file=sys.stderr)
        sys.exit(1)
    elif 200 <= r.status_code < 400:
        print("Connection success")
        data = r.json()
        print(data["login"])
        print(data["public_repos"])
    else:
        print("Error: "+f"{r.status_code}", file=sys.stderr)
        sys.exit(1)
    
except requests.RequestException:
    print("Could not connect to account or account does not exist", file=sys.stderr)
    sys.exit(1)