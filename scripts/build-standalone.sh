#!/bin/bash
#
# build-standalone.sh
#
# Compiles bin/netpoll into a self-contained standalone binary using
# PAR::Packer (pp), and optionally packages it (with addsourceip and
# supporting files) into a deployment tarball.
#
# The resulting binary has zero Perl-module dependencies at runtime —
# it bundles the Perl interpreter, all required modules, and the SQLite
# shared library. The only system tools needed at runtime are:
#   - bash + sqlite3 CLI (for bin/addsourceip, the snmptrapd handler)
#   - snmptrap (from Net-SNMP) — called by addsourceip to forward traps
#
# Usage:
#   ./scripts/build-standalone.sh --compile   # Just build the binary
#   ./scripts/build-standalone.sh --package    # Build binary + create tarball
#   ./scripts/build-standalone.sh              # Same as --package

set -e

VERSION="4.0"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

BINARY="netpoll"
TARBALL="netpoll-${VERSION}-standalone.tar.gz"
STAGEDIR="netpoll-${VERSION}"

# --- Modules to explicitly include in the binary (loaded via 'require') ---
# pp's static analysis may miss modules loaded with require inside subroutines,
# so we list them explicitly with -M flags.
INCLUDE_MODULES=(
    -M DBI
    -M DBD::SQLite
    -M Net::Ping
    -M Sys::Syslog
    -M Getopt::Long
)

# --- Ensure PAR::Packer is available ---
ensure_pp() {
    if perl -MPAR::Packer -e 1 2>/dev/null; then
        return 0
    fi
    echo "PAR::Packer not found. Installing..."
    if command -v cpanm >/dev/null 2>&1; then
        cpanm --notest PAR::Packer
    else
        echo "ERROR: cpanm not found. Install with:"
        echo "  Debian/Ubuntu: apt-get install libcpan-minisa-perl && cpan PAR::Packer"
        echo "  RHEL/CentOS:   yum install perl-CPAN"
        echo "  Or:            curl -L https://cpanmin.us | perl - PAR::Packer"
        exit 1
    fi
}

# --- Compile the standalone binary ---
compile_binary() {
    echo "Compiling bin/netpoll -> ./$BINARY ..."
    pp "${INCLUDE_MODULES[@]}" \
       -o "$BINARY" \
       bin/netpoll
    echo "Binary created: ./$BINARY ($(du -h "$BINARY" | cut -f1))"
}

# --- Create the deployment tarball ---
create_tarball() {
    echo "Staging files into $STAGEDIR/ ..."
    rm -rf "$STAGEDIR"
    mkdir -p "$STAGEDIR/docs"

    cp "$BINARY" "$STAGEDIR/"
    cp bin/addsourceip "$STAGEDIR/"
    cp conf/snmptrapd.conf.example "$STAGEDIR/"
    cp netpoll.cron "$STAGEDIR/"
    cp sql/schema.sql "$STAGEDIR/"
    cp README.md CHANGELOG.md LICENSE "$STAGEDIR/"
    cp -r docs/* "$STAGEDIR/docs/"

    chmod 755 "$STAGEDIR/$BINARY" "$STAGEDIR/addsourceip"

    echo "Creating $TARBALL ..."
    tar czf "$TARBALL" "$STAGEDIR"
    rm -rf "$STAGEDIR"

    echo ""
    echo "Deployment tarball created: $TARBALL"
    echo "Contents:"
    tar tzf "$TARBALL" | head -20
    if [ "$(tar tzf "$TARBALL" | wc -l)" -gt 20 ]; then
        echo "  ... and more"
    fi
}

# --- Main ---
ACTION="package"
[ $# -gt 0 ] && ACTION="$1"

case "$ACTION" in
    --compile)
        ensure_pp
        compile_binary
        ;;
    --package|package)
        ensure_pp
        compile_binary
        create_tarball
        ;;
    *)
        echo "Usage: $0 [--compile|--package]"
        exit 1
        ;;
esac

echo ""
echo "Done."
