# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

> **Origin:** This project was initially developed in 2012 to solve a
> functionality gap in a private network management environment and is
> being refreshed for public release. See [History](README.md#history)
> in the README for details.

## [4.0] - 2026-10-22

### netpoll & addsourceip
- **Ported from MySQL to SQLite** — no external database server required. The
  database is now a local file (default: `/var/lib/netpoll/netpoll.db`),
  overridable via the `NETPOLL_DB` environment variable.
- SQLite WAL mode enabled for concurrent read/write access across threads.
- `mysqldump`/`mysql` backup-restore replaced with `sqlite3 .backup`/`.restore`.
- MySQL-specific SQL (`INSERT IGNORE`, `RENAME TABLE`, `sql_buffer_result`)
  replaced with SQLite equivalents (`INSERT OR IGNORE`, `ALTER TABLE ... RENAME TO`,
  plain `SELECT`).
- Date format in changelog entries changed to ISO 8601 (YYYY-MM-DD).

### netpoll
- Added `sqlite_connect()` helper that sets WAL mode, `synchronous = NORMAL`,
  and a 5-second busy timeout on every connection.
- Added `File::Basename` and `File::Path` imports for automatic database
  directory creation.
- Help text updated to mention SQLite database path and `NETPOLL_DB`.
- Removed MySQL host/user/password globals.
- Added detailed inline commentary documenting the architecture, thread
  coordination model, and poll timing calculations.
- Consolidated shared variable declarations (`my $var = 0; share($var)`).
- Replaced Motorola enterprise OID (.1.3.6.1.4.1.161.3.10.104.3) with standard
  SNMPv2-MIB linkDown (.1.3.6.1.6.3.1.1.5.3) and linkUp (.1.3.6.1.6.3.1.1.5.4)
  OIDs for vendor-neutral SNMP trap compatibility. Heartbeat now uses warmStart
  (.1.3.6.1.6.3.1.1.5.2).

### addsourceip
- Replaced MySQL CLI aliases with a `MyCMD()` function using `sqlite3`.
- Replaced `MySQL <<EOF` database creation block with a file-existence check.
- Updated version to 3.0.

---

## [3.0] - 2012-07-16

### netpoll
- Re-implemented in Perl to improve performance.

---

## [2.1] - 2012-07-06

### netpoll
- Added thread limiting to avoid crashes on extremely large device lists.
- Added MySQL queueing to prevent update failures.

---

## [2.0] - 2012-06-19

### netpoll
- Added multi-host shared configuration capability.
- Configuration can now be backed up and restored.
- New script locking mechanism in place allowing finer control.
- Added function to automatically upgrade old v1.x configuration.

### addsourceip
- Updated to use new config database format.

---

## [1.3] - 2012-06-14

### netpoll
- Added NBI configuration into db.

### addsourceip
- Added NBI configuration into db.

---

## [1.2] - 2012-06-08

### netpoll
- Added status reporting functionality.

---

## [1.1] - 2012-06-01

### netpoll
- Adapted to work with addsourceip script.

### addsourceip
- Initial release.

---

## [1.0] - 2012-05-30

### netpoll
- Initial release.
