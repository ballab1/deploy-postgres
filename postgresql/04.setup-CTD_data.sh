#!/bin/bash

declare tools="$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )"
declare pg_data="${PG_DATA:-/var/lib/postgresql/data}"
declare -r conf_file="${pg_data}/postgresql.conf "
declare -r conf_entry="shared_preload_libraries = 'timescaledb'"
declare do_restart

if ! grep -q "$conf_entry" "$conf_file" ; then
    echo "Adding ${conf_entry}' to ${pg_data}/postgresql.conf"
    s -i "\$ a $conf_entry" "$conf_file"
    do_restart='restart'
fi

if -f "$conf_file" ; then
    echo "changing log directory"
    sed -E -i -e '^.*log_directory\s*=.*$|log_directory = /var/log|' "$conf_file"
    do_restart='restart'
fi


if [ "${do_restart:-}" ]; then
    echo "Restarting postgresql"
    pg_ctl restart
fi

if [ -e "${tools}/.setup-CTD_data.sql" ]; then
    psql -v ON_ERROR_STOP=1 \
         --username postgres \
         --dbname ctd_datalake \
         -f "${tools}/.setup-CTD_data.sql"
fi
