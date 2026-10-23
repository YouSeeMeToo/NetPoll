Name:           netpoll
Version:        4.0
Release:        1%{?dist}
Summary:        Network Ping Poller with SNMP trap generation

License:        MIT
URL:            https://github.com/ulyssecruz/NetPoll
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch

Requires:       perl >= 5.26
Requires:       perl-DBI
Requires:       perl-DBD-SQLite
Requires:       sqlite
# Net::Ping and Sys::Syslog ship with core perl

%description
NetPoll pings a large number of IPs in a set time interval and generates
SNMP traps when the up/down status of an IP changes. All configuration
and runtime data is stored in a SQLite database — no external database
server required.

The script is designed to run from cron every 5 minutes. It uses Perl
ithreads for parallel ICMP polling, SQLite WAL mode for concurrent
database access, and standard SNMPv2-MIB OIDs (linkDown/linkUp) for
vendor-neutral trap reception.

Integration with snmptrapd is handled by the companion addsourceip
trap handler, which forwards and re-indexes incoming traps to configured
NBI destinations.

%prep
%setup -n %{name}-%{version}

%build
# Verify Perl syntax
perl -c bin/netpoll
# Verify Bash syntax
bash -n bin/addsourceip

%install
install -d %{buildroot}%{_sbindir}
install -m 755 bin/netpoll %{buildroot}%{_sbindir}/netpoll
install -m 755 bin/addsourceip %{buildroot}%{_sbindir}/addsourceip

install -d %{buildroot}%{_sysconfdir}/cron.d
install -m 644 netpoll.cron %{buildroot}%{_sysconfdir}/cron.d/netpoll

install -d %{buildroot}%{_sysconfdir}/snmptrapd.d
install -m 644 conf/snmptrapd.conf.example \
	%{buildroot}%{_sysconfdir}/snmptrapd.d/netpoll.conf.example

install -d %{buildroot}%{_localstatedir}/lib/netpoll
install -d %{buildroot}%{_docdir}/%{name}/examples
cp -a sql/schema.sql %{buildroot}%{_docdir}/%{name}/examples/
cp -a conf/snmptrapd.conf.example %{buildroot}%{_docdir}/%{name}/examples/

# Fix cron file path for installed location
sed -i 's|/usr/local/sbin/netpoll|%{_sbindir}/netpoll|' \
	%{buildroot}%{_sysconfdir}/cron.d/netpoll

%files
%{_sbindir}/netpoll
%{_sbindir}/addsourceip
%{_sysconfdir}/cron.d/netpoll
%config(noreplace) %{_sysconfdir}/snmptrapd.d/netpoll.conf.example
%{_docdir}/%{name}/examples/schema.sql
%{_docdir}/%{name}/examples/snmptrapd.conf.example
%doc README.md CHANGELOG.md LICENSE docs/*
%dir %{_localstatedir}/lib/netpoll

%post
# Initialize the database directory
if [ ! -d /var/lib/netpoll ]; then
    mkdir -p /var/lib/netpoll
    chmod 755 /var/lib/netpoll
fi

# Initialize database with default customer
/usr/bin/sqlite3 /var/lib/netpoll/netpoll.db \
    "create table if not exists script (server varchar(128) UNIQUE default '$(hostname)', customer varchar(128) default 'changeme', last_start datetime, last_end datetime, cur_start datetime);" \
    2>/dev/null || true

echo "============================================"
echo "  NetPoll installed!"
echo "============================================"
echo "Next steps:"
echo "  1. Set the SNMP community: netpoll -customer <community>"
echo "  2. Add trap destinations:   netpoll -nbiadd <ip>"
echo "  3. Configure snmptrapd:     see /etc/snmptrapd.d/netpoll.conf.example"
echo "  4. Start snmptrapd service"
echo "============================================"

%postun
if [ $1 -eq 0 ]; then
    # Package removed (not upgraded) — clean up cron
    rm -f /etc/cron.d/netpoll 2>/dev/null || true
fi

%preun
if [ $1 -eq 0 ]; then
    # Package being removed — stop any running poller
    pkill -f "%{_sbindir}/netpoll" 2>/dev/null || true
fi

%changelog
* Thu Oct 22 2026 Ulysses Cruz <ulyssecruz@example.com> - 4.0-1
- Initial RPM packaging
- SQLite database (no external database server required)
- SNMP traps using standard SNMPv2-MIB OIDs
