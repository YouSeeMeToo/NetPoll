# Contributing to NetPoll

Thank you for your interest in contributing to NetPoll!

## Development Setup

1. Clone the repository.
2. Install dependencies:

   ```bash
   # Debian/Ubuntu
   apt-get install perl libdbi-perl libdbd-sqlite3-perl sqlite3 libsnmp-base

   # RHEL/CentOS
   yum install perl-DBI perl-DBD-SQLite sqlite net-snmp net-snmp-utils
   ```

3. Ensure scripts are executable:

   ```bash
   chmod +x bin/netpoll bin/addsourceip
   ```

4. Verify syntax:

   ```bash
   perl -c bin/netpoll
   bash -n bin/addsourceip
   ```

## Testing

Test with a local SQLite database:

```bash
export NETPOLL_DB=/tmp/netpoll-test.db
perl bin/netpoll -customer testcommunity
perl bin/netpoll -nbiadd 127.0.0.1
perl bin/netpoll -add 127.0.0.1
perl bin/netpoll -status devices
```

Clean up test artifacts:

```bash
rm -f /tmp/netpoll-test.db
```

## Code Style

- **Indentation**: Tabs in Perl scripts, consistent with existing style
- **Dates**: ISO 8601 format (`YYYY-MM-DD`)
- **Comments**: Extensive inline documentation — keep it up to date
- **Shell scripts**: Follow POSIX sh compatibility where possible

## Pull Requests

1. Create a feature branch from `main`
2. Make your changes with clear, descriptive commits
3. Ensure `perl -c` and `bash -n` pass
4. Update documentation if your change affects user-facing behavior
5. Reference relevant issues in your commit messages

## Reporting Bugs

When reporting issues, please include:

- Perl version (`perl -v`) and OS
- SQLite version (`sqlite3 --version`)
- Net-SNMP version (if SNMP-related)
- Relevant error messages from syslog
