# Usage

## Synopsis

```
netpoll [-<command> <argument>]
```

Run `netpoll` with no arguments to perform a poll of the IP list. With a
command, it performs a management operation. The script is designed to be run
from cron every 5 minutes — **no arguments needed for normal polling**.

## Database location

By default, `netpoll` uses SQLite at `/var/lib/netpoll/netpoll.db`. Override
with the `NETPOLL_DB` environment variable:

```bash
export NETPOLL_DB=/opt/netpoll/netpoll.db
/usr/local/sbin/netpoll
```

## Commands

| Command | Argument | Description |
|---------|----------|-------------|
| `-add` | `<IP>` | Add a single IP to the poll list. |
| `-drop` | `<IP>` | Remove a single IP from the poll list. |
| `-listadd` | `<file>` | Add all IPs from a file to the poll list. |
| `-listdrop` | `<file>` | Remove all IPs in a file from the poll list. |
| `-nbiadd` | `<IP>` | Add an NBI (SNMP trap destination) for this host. |
| `-nbidrop` | `<IP>` | Remove an NBI destination for this host. |
| `-customer` | `<name>` | Set the SNMP community string for all traps. |
| `-hostupdate` | `<name>` | Update an old hostname entry to the current hostname. |
| `-hostdelete` | `<name>` | Delete a hostname entry from the config. |
| `-status` | `<search>` | Check the status of specific device(s). Use `%` as a wildcard instead of `*`. |
| `-status` | `devices` | Display the status of all devices, sorted by last change time. |
| `-status` | `resend` | Resend the current status of all devices via SNMP traps. |
| `-status` | `poller` | Display the status of the poller process. |
| `-backup` | `<file>` | Save the SQLite database to a backup file (uses `sqlite3 .backup`). |
| `-restore` | `<file>` | Load poller config from a saved backup (uses `sqlite3 .restore`). **Overwrites current config!** |

To see the help message at any time:

```bash
netpoll -help    # or just run with an unknown option
```

## Examples

```bash
# Poll all configured devices (the normal cron operation):
netpoll

# Add a device:
netpoll -add 10.0.0.5

# Add devices from a file:
netpoll -listadd /etc/netpoll/devices.txt

# Set the SNMP community:
netpoll -customer public

# Add a trap destination:
netpoll -nbiadd 192.168.1.100

# Check the status of all devices:
netpoll -status devices

# Check the status of devices matching a pattern:
netpoll -status '10.0.0%'

# Back up the configuration:
netpoll -backup /var/backups/netpoll-$(date +%F).db

# Restore from a backup:
netpoll -restore /var/backups/netpoll-2026-01-01.db
```

## Locking

`netpoll` uses file-based locking (`/var/lock/netpoll_<hostname>`) to prevent
overlapping runs. If a lock is held, the script exits immediately with a
warning.

## Thread model

For large device lists, `netpoll` spawns parallel poller threads. The thread
count is automatically calculated as `ceil(device_count / 70)`, capped
at `kernel.threads-max / 128`. Each poller attempts ICMP ping up to three
times before declaring a device down.

## SQLite concurrency

Each Perl thread creates its own SQLite connection. WAL mode is enabled
automatically to allow concurrent reads during a write, and a 5-second busy
timeout handles lock contention gracefully.

## SNMP trap format

Traps use standard SNMPv2-MIB OIDs:

| Trap type | OID | Condition |
|-----------|-----|-----------|
| linkDown | `.1.3.6.1.6.3.1.1.5.3` | Device transitioned from up to down |
| linkUp | `.1.3.6.1.6.3.1.1.5.4` | Device transitioned from down to up |
| warmStart | `.1.3.6.1.6.3.1.1.5.2` | Heartbeat (sent after every poll completes) |

Each trap includes these variable bindings:

| OID suffix | Value |
|-----------|-------|
| `.1.1.0` | Device IP |
| `.1.2.0` | Message (e.g. "Node failure. 10.0.0.1 at 2026-10-22 12:00:00 from monitor01") |
| `.1.10.0` | `"netpoll"` |

Trap rate is limited to 2 simultaneous sends via a semaphore.
