#!/usr/bin/env bash

NETDISCO_DB_NAME="${NETDISCO_DB_NAME:-netdisco}"
NETDISCO_DB_USER="${NETDISCO_DB_USER:-netdisco}"
NETDISCO_DB_PASS="${NETDISCO_DB_PASS:-netdisco}"

export COL='\033[0;35m'
export NC='\033[0m'

PGUSER="${PGUSER:-postgres}"
psql=( psql -X -v ON_ERROR_STOP=0 -v ON_ERROR_ROLLBACK=on )
psql+=( --username=${PGUSER} )

echo >&2 -e "${COL}netdisco-db-entrypoint: configuring Netdisco user and db${NC}"
"${psql[@]}" -c "CREATE ROLE ${NETDISCO_DB_USER} WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD '${NETDISCO_DB_PASS}'"
createdb --username=${PGUSER} -O ${NETDISCO_DB_USER} ${NETDISCO_DB_NAME}

echo >&2 -e "${COL}netdisco-db-entrypoint: restarting pg privately to container${NC}"
"${su[@]}" pg_ctl -D "$PGDATA" -m fast -w stop
"${su[@]}" pg_ctl -D "$PGDATA" -o "-c listen_addresses='localhost' -c log_min_error_statement=LOG -c log_min_messages=LOG" -w start

/usr/local/bin/netdisco-updatedb.sh
