# NetPoll

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A high-performance network ping polling script that pings a large number of IPs at set intervals and generates SNMP traps when the up/down status of an IP changes. All configuration and runtime data is stored in a local SQLite database — no external database server required.

Intended for deployment as a remote poller for network management and observability environments where security policy prevents inbound communication from the NM/NO network. It is designed for deployment on small-footprint or shared systems, limiting both CPU and memory utilization. Automatic resource scaling intended to guarantee polling completes in a 5-minute window, and active heartbeat notifications allow for reliable operation without constant user oversight.

## History

NetPoll was initially developed in 2012 to solve a functionality gap in a private network management environment — a remote poller capable of monitoring a large number of IPs across disconnected networks and forwarding traps to a central Network Management System. The original implementation used MySQL for configuration storage and Motorola enterprise SNMP OIDs for trap generation.

In 2026, the project was refreshed for public release: ported from MySQL to SQLite for portability, switched to standard SNMPv2-MIB OIDs for vendor-neutral trap compatibility, and modernized with detailed inline documentation, ISO 8601 date formats, and deb/rpm packaging support.

## Overview

NetPoll is designed to:

- **Ping many IPs quickly** — Uses Perl ithreads for parallel ICMP polling, with dynamic thread count scaling based on device count and system thread limits.
- **Trap on status change** — Generates SNMP traps (v2c) to configured NBI destinations whenever a device transitions up→down or down→up.
- **Zero-dependency database** — Uses SQLite for all configuration and runtime data. The database is a single local file, making deployment trivial.
- **Cron-driven** — Intended to be run from cron every 5 minutes.

## Components

| File | Description |
|------|-------------|
| `bin/netpoll` | Main Perl polling script. |
| `bin/addsourceip` | Bash trap-handler for `snmptrapd` — re-sends incoming traps to configured NBI destinations. |
| `conf/snmptrapd.conf.example` | Example `snmptrapd.conf` configuration. |
| `sql/schema.sql` | Database schema reference. |
| `debian/` | Debian packaging files (deb helper). |
| `rpm/netpoll.spec` | RPM spec file for building an RPM package. |
| `Makefile` | Build automation for standalone binary and tarball. |
| `scripts/build-standalone.sh` | Compiles netpoll into a standalone binary via PAR::Packer. |

## Standalone Binary

For deployments without Perl or package management, NetPoll can be compiled
into a fully self-contained binary using PAR::Packer:

```bash
make build      # Compiles bin/netpoll -> ./netpoll (standalone executable)
make tarball    # Creates netpoll-4.0-standalone.tar.gz with all dependencies
```

The compiled binary bundles the Perl interpreter, all required modules,
and the SQLite library — no Perl installation or CPAN modules needed at
runtime. The deployment tarball also includes `addsourceip`, configuration
examples, and documentation.

## Prebuilt Packages

Prebuilt packages are available from the [GitHub Releases](https://github.com/YouSeeMeToo/NetPoll/releases)
page. Download the appropriate package for your platform and install it directly:

| Package | Description |
|---------|-------------|
| `netpoll_4.0-1_all.deb` | Debian/Ubuntu package (installs to `/usr/sbin/`, includes cron + postinst) |
| `netpoll-4.0-1.noarch.rpm` | RHEL/CentOS/Fedora package (same files, RPM post-install hook) |
| `netpoll` | Standalone binary — zero dependencies, works on any Linux x86_64 |
| `netpoll-4.0-standalone.tar.gz` | Deployment tarball (binary + addsourceip + configs + docs) |

```bash
# Debian/Ubuntu
sudo dpkg -i netpoll_4.0-1_all.deb
sudo systemctl restart snmptrapd  # if using trap forwarding

# RHEL/CentOS/Fedora
sudo rpm -i netpoll-4.0-1.noarch.rpm

# Standalone (no installation required)
./netpoll -customer <snmp-community>

# Standalone tarball (portable directory layout)
tar xzf netpoll-4.0-standalone.tar.gz
cd netpoll-4.0
./netpoll -customer <snmp-community>
```

## Requirements

- **Perl** with ithreads (`perl -MConfig -e 'print $Config{useithreads}'` must return a true value)
- **Perl modules**: `DBI`, `DBD::SQLite`, `Net::Ping`, `Sys::Syslog`, `Getopt::Long`, `Fcntl`, `POSIX`, `threads`, `threads::shared`, `Thread::Queue`, `Thread::Semaphore`
- **SQLite** (bundled with `DBD::SQLite`, no server process)
- **snmptrap** (from Net-SNMP) for trap generation
- **snmptrapd** (from Net-SNMP) if using the trap forwarding handler

## Quick Start

See [Installation Guide](docs/INSTALL.md) for full details.

## Documentation

- [Installation Guide](docs/INSTALL.md)
- [Usage Guide](docs/USAGE.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Changelog](CHANGELOG.md)

## License

Copyright © 2012-2026 Ulysses Cruz. Released under the MIT License — see [LICENSE](LICENSE).
