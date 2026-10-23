--
-- NetPoll Database Schema (SQLite)
--
-- The netpoll database uses per-host tables (table names include the hostname
-- as a suffix) to allow multiple polling hosts to share a single database
-- file. Tables are created automatically by `bin/netpoll` on first run;
-- this file is provided for reference and manual deployment.
--
-- Variables are substituted at runtime:
--   $hostname  -- the system hostname (e.g. "monitor01")
--   $CUSTOMER  -- the SNMP community string (default: "changeme")
--
-- WAL mode is enabled automatically for concurrent read/write access.
-- The database file defaults to /var/lib/netpoll/netpoll.db
-- (override with NETPOLL_DB environment variable).
--

-- ---------------------------------------------------------------------------
-- script: Per-host metadata table
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS script (
    server      VARCHAR(128) UNIQUE DEFAULT '$hostname',
    customer    VARCHAR(128) DEFAULT 'changeme',
    last_start  DATETIME,
    last_end    DATETIME,
    cur_start   DATETIME
);

-- ---------------------------------------------------------------------------
-- nbis_$hostname: Network Behavior Inspector (NBI) destinations
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nbis_$hostname (
    ip  VARCHAR(20) UNIQUE
);

-- ---------------------------------------------------------------------------
-- devices_$hostname: Monitored devices and their polling state
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS devices_$hostname (
    ip          VARCHAR(20) UNIQUE,
    last_poll   DATETIME,
    last_stat   VARCHAR(50) DEFAULT 'unknown',
    last_chng   DATETIME,
    count       INTEGER DEFAULT 0,
    priority    INTEGER DEFAULT 0,
    special1    VARCHAR(128),
    special2    INTEGER DEFAULT 0
);
