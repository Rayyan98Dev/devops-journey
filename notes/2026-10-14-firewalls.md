# Wed 14 Oct: Firewalls

*My own wording, spelling tidied. A **Check:** line is a correction we agreed on.*

## Models
- A firewall is really a bouncer that decides which incoming connections get in, by port, protocol and source address.
- A zone is really a set of rules (a trust level) attached to a network connection. Only that zone's rules apply to traffic arriving on it.
- Opening a port is really adding one "allow" line for that port and protocol in one specific zone. The app or site doesn't change.
- A port is like a door number, and the IP address is the building.
- A service is a named bundle of ports (`ssh` is `22/tcp`, `dns` is `53/tcp` and `53/udp`). Easier to remember, can cover several ports, and records intent, so fewer mistakes.

## What I found
- The phone couldn't reach the server because port 8000 wasn't allowed in the `public` zone. Being allowed and listening are two separate checks.
- `localhost` works even when the port is blocked, because the traffic never comes in from the network.
- `0.0.0.0:8000` in `ss` means the server listens on every connection. `127.0.0.1:8000` would mean local only.
- A fast error means I got a direct "no" (the firewall *rejects*). A slow error means it's waiting and getting nothing (*drop*).
- Only the zone my connection is in counts. Zones don't compare with each other.

## Runtime vs permanent
- Runtime only opens the port for the current session.
- `--permanent` only saves the rule, which doesn't take effect until a reload or a reboot.
- `--reload` loads the saved rules and throws away any unsaved runtime changes.

| Way to make a rule stick | What gets saved | Watch out for |
|---|---|---|
| Run the rule twice (without and with `--permanent`) | only that rule | typing it differently each time |
| `--permanent`, then `--reload` | only that rule | reload drops other unsaved runtime changes |
| runtime, then `--runtime-to-permanent` | everything currently active | also saves forgotten experiments |

- A runtime change disappearing is useful: if a rule locks someone out or lets the wrong people in, a reload or reboot puts it back.

## Commands
- `firewall-cmd --get-default-zone` and `firewall-cmd --get-active-zones`
- `sudo firewall-cmd --list-all` shows the zone's services, ports and interfaces.
- `sudo firewall-cmd --list-ports` shows runtime. `sudo firewall-cmd --permanent --list-ports` shows what's saved.
- `sudo firewall-cmd --permanent --zone=home --add-port=9300/tcp`, then `sudo firewall-cmd --reload`
- `sudo nmcli connection modify "<wifi>" connection.zone home`, then `nmcli connection up "<wifi>"`, moves a Wi-Fi connection to another zone.
- `ss -tulnp`: `t` = TCP, `u` = UDP, `l` = listening, `n` = numeric (port numbers, not names), `p` = process.
- The `-p` in `mkdir -p` means parent folders. The same letter means different things in different commands.

## Packet (a real example)
- My Wi-Fi was in `public` (the default) with only `dhcpv6-client`, `mdns` and `ssh` allowed.
- Packet uses UDP 5353 (mDNS, for finding devices, already allowed) and a TCP port for the transfer, which was random (40145).
- I turned on Packet's "Static Network Port" (9300), moved my home Wi-Fi to the `home` zone, and opened `9300/tcp` in `home` only, so café Wi-Fi stays strict. A photo sent with Quick Share arrived.

## Teach-back
- I learned what a firewall is: basically a bouncer that decides who gets in and who can't, on the network.
  - **Check:** it judges incoming connections (port, protocol, source), not people or devices.
- Zones are rule sets (trust levels) attached to a network connection. Only that zone's rules apply to the traffic it receives.
- Opening a port is editing a line to allow a port and protocol in one specific zone. Just changing it is runtime, and I need `--permanent` to keep it after a reboot.
  - **Check:** `--reload` doesn't save anything. `--permanent` saves the one rule, and the reload makes it active (dropping unsaved runtime changes). `--runtime-to-permanent` saves everything in runtime.
- I also learned how to change a network's zone and find the port a program uses.
