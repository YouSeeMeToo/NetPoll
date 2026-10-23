# Architecture

## High-level flow

```
cron (every 5 min)
   │
   ▼
netpoll (no args)
   │
   ├─ database_interface('global') ── loads: customer, NBI list, device count
   │
   ├─ acquire lock (/var/lock/netpoll_<hostname>, non-blocking)
   │
   ├─ poll_master thread
   │     │
   │     ├─ waits for reader to populate the device queue
   │     ├─ spawns N poll_slave threads  (N = ceil(device_count / 70))
   │     ├─ waits for stop signal
   │     └─ enqueues 'END' sentinel for each poller
   │
   │     ├─ database_reader thread
   │     │     reads all devices → enqueues into device_unknown queue
   │     │
   │     └─ database_writer thread
   │           dequeues results → updates devices table
   │
   └─ send_heartbeat (SNMP trap to localhost NBI)
       log to syslog
```

## Thread model

NetPoll uses Perl interpreter threads (`use threads`). Each thread connects to
the SQLite database independently — WAL mode allows concurrent reads while a
write is in progress.

| Thread | Role |
|--------|------|
| **Main** | Parses options, acquires lock, spawns worker threads, joins all. |
| `database_interface` | General purpose DB handler — creates tables, handles add/drop/list operations, runs the poll coordinator function. |
| `database_reader` | Reads all devices from the DB and enqueues them into the `device_unknown` queue for polling. |
| `database_writer` | Dequeues polled results from the `device_known` queue and writes them to the DB. |
| `poll_master` | Coordinates the polling workers — spawns pollers, waits for reader, feeds END signals. |
| `poll_slave` | Individual worker — pings one IP, compares state, generates trap if changed, enqueues result. |

### Semaphores

| Semaphore | Initial value | Purpose |
|-----------|--------------|---------|
| `trap_limit` | 2 | Limits concurrent SNMP trap sends. |
| `queue_limit` | thread_max / 128 | Limits the pending queue size to prevent memory exhaustion. |
| `start_polling` | 0 | Signals `poll_master` that the reader has started. |
| `stop_polling` | 0 | Signals `poll_master` that all devices are queued and polling can begin. |

## Database schema

The SQLite database (`/var/lib/netpoll/netpoll.db` by default, overridable via
`NETPOLL_DB`) uses per-host table naming. Tables are created automatically on
first run. See [`sql/schema.sql`](../sql/schema.sql) for the full schema.

Three tables are created per host:

1. **`script`** — global config (customer, poll timestamps)
2. **`nbis_<hostname>`** — trap destination IPs
3. **`devices_<hostname>`** — monitored devices with last poll / status / change timestamp

### SQLite-specific settings

The `sqlite_connect()` helper applies these pragmas on every connection:

| Pragma | Value | Purpose |
|--------|-------|---------|
| `journal_mode` | `WAL` | Allows concurrent readers during a write. |
| `synchronous` | `NORMAL` | Good balance of speed and durability in WAL mode. |
| `busy_timeout` | `5000` | Waits up to 5s if another writer holds the lock. |

## SNMP trap forwarding (addsourceip)

```
snmptrapd
   │
   ├── receives trap from a device
   ├── traphandle → bin/addsourceip
   │     ├── reads hostname + source IP from STDIN
   │     ├── looks up customer + NBIs from SQLite (netpoll database)
   │     └── re-sends the trap to each configured NBI with source IP
   └── (trap forwarded)
```

The `addsourceip` script allows the trap receiver to re-transmit traps to
upstream NBI destinations, substituting the original source IP as the first
OID variable binding.

## Lock file

- **Location**: `/var/lock/netpoll_<hostname>`
- **Mechanism**: `flock(LOCK_EX | LOCK_NB)` — non-blocking, exits immediately if another instance is running.
- **Management commands** (add, drop, nbiadd, hostupdate, hostdelete) acquire a blocking `LOCK_EX` to serialize config changes.
