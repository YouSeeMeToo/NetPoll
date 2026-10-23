# Installation

## Quick Install (Prebuilt Packages)

Prebuilt packages are available from the [GitHub Releases](https://github.com/YouSeeMeToo/NetPoll/releases)
page. Download the appropriate package and install it:

- **Debian/Ubuntu**: `sudo dpkg -i netpoll_4.0-1_all.deb`
- **RHEL/CentOS**: `sudo rpm -i netpoll-4.0-1.noarch.rpm`
- **Standalone binary (no installation)**: `./netpoll -customer <community>`
- **Standalone tarball (portable layout)**: `tar xzf netpoll-4.0-standalone.tar.gz && cd netpoll-4.0 && ./netpoll -customer <community>`

Package installation handles script placement (`/usr/sbin/`), cron
configuration (`/etc/cron.d/netpoll`), snmptrapd config, and database
initialization automatically via the post-install hook.

Alternatively, compile from source with `make build` — see
[Architecture](ARCHITECTURE.md) for build requirements.

---

## 1. Prerequisites

### System packages

```bash
# Debian/Ubuntu
apt-get install perl libdbi-perl libdbd-sqlite3-perl sqlite3 libsnmp-base

# RHEL/CentOS
yum install perl-DBI perl-DBD-SQLite sqlite net-snmp net-snmp-utils
```

### Perl modules

Verify ithreads support:

```bash
perl -MConfig -e 'die "Perl was not built with ithreads\n" unless $Config{useithreads}'
```

The script uses these modules:

- `threads`, `threads::shared`, `Thread::Queue`, `Thread::Semaphore` (core, require ithreads)
- `POSIX` (core)
- `Fcntl` (core)
- `File::Basename`, `File::Path` (core)
- `DBI` + `DBD::SQLite`
- `Net::Ping`
- `Sys::Syslog`
- `Getopt::Long`

## 2. Database setup

**No database server installation required.** SQLite stores all data in a single
file. The script creates the database and tables automatically on first run.

The default database path is `/var/lib/netpoll/netpoll.db`. Override with the
`NETPOLL_DB` environment variable if needed:

```bash
export NETPOLL_DB=/opt/netpoll/data/netpoll.db
```

To manually create the database directory:

```bash
sudo mkdir -p /var/lib/netpoll
sudo chown $(whoami):$(whoami) /var/lib/netpoll
```

Table schemas are created automatically by `netpoll` on first run. See
[`sql/schema.sql`](../sql/schema.sql) for reference.

> **Note:** Table names are suffixed with the hostname (e.g. `devices_monitor01`),
> so the database can be shared across multiple polling hosts that share the same
> filesystem (e.g. via NFS).

## 3. Install scripts

```bash
# Install netpoll (adjust path as needed)
sudo cp bin/netpoll /usr/local/sbin/netpoll
sudo chmod 755 /usr/local/sbin/netpoll

# Install addsourceip (snmptrapd trap handler)
sudo cp bin/addsourceip /usr/local/sbin/addsourceip
sudo chmod 755 /usr/local/sbin/addsourceip
```

## 4. Configure snmptrapd (optional)

If you use the trap forwarding handler:

```bash
sudo cp conf/snmptrapd.conf.example /etc/snmp/snmptrapd.conf
sudo chmod 640 /etc/snmp/snmptrapd.conf
```

Ensure `addsourceip` path in `snmptrapd.conf` matches where you installed it:

```
traphandle default /usr/local/sbin/addsourceip
```

Restart the trap daemon:

```bash
sudo systemctl restart snmptrapd
```

## 5. Configure cron

```bash
# Install the cron entry (runs every 5 minutes)
sudo cp netpoll.cron /etc/cron.d/netpoll
sudo chmod 644 /etc/cron.d/netpoll
```

Or add manually:

```bash
sudo crontab -e
# Add:
*/5 * * * * /usr/local/sbin/netpoll
```

## 6. Initial configuration

```bash
# Set the SNMP community / customer name
sudo /usr/local/sbin/netpoll customer mycommunity

# Add NBI destinations (SNMP trap targets)
sudo /usr/local/sbin/netpoll nbiadd 192.168.1.10
sudo /usr/local/sbin/netpoll nbiadd 192.168.1.11

# Add devices to poll
sudo /usr/local/sbin/netpoll add 192.168.1.1
sudo /usr/local/sbin/netpoll listadd /path/to/devices.txt
```

## 7. Backup and restore

```bash
# Back up the SQLite database (safe to run while poller is active)
sudo /usr/local/sbin/netpoll backup /var/backups/netpoll-$(date +%F).db

# Restore from a backup (stops writes during restore)
sudo /usr/local/sbin/netpoll restore /var/backups/netpoll-2026-01-01.db
```
