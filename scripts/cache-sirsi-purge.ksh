#!/usr/bin/env bash
#
# A helper to purge items from the cache that are older than the supplied date.
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <date YYYY-MM-DDTHH:MM:SSZ> <pg env>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
DATE=$1
shift
DATABASE_ENV=$1
shift

# if we are going to validate against the database before submitting, ensure we have a DB credentials file
# ensure our pg environment exists
ensure_file_exists $DATABASE_ENV

# ensure the necessary tools exist
PSQL_TOOL=psql
ensure_tool_available $PSQL_TOOL

echo ""; echo ""
read -r -p "Purging cache contents older than $DATE: ARE YOU SURE? [Y/n]? " response
case "$response" in
  y|Y ) echo "Purging..."
  ;;
  * ) echo "Aborting..."
      exit 1
esac

# extract the needed values from the database environment
DBHOST=$(extract_nv_from_file $DATABASE_ENV DBHOST)
DBPORT=$(extract_nv_from_file $DATABASE_ENV DBPORT)
DBUSER=$(extract_nv_from_file $DATABASE_ENV DBUSER)
DBPASSWD=$(extract_nv_from_file $DATABASE_ENV DBPASSWD)
DBNAME=$(extract_nv_from_file $DATABASE_ENV DBNAME)

DBQUERY="DELETE FROM source_cache WHERE source = 'sirsi' AND updated_at < '$DATE'"
#echo $DBQUERY
PGPASSWORD=$DBPASSWD $PSQL_TOOL -h $DBHOST -p $DBPORT -U $DBUSER -d $DBNAME -t -c "$DBQUERY" > /dev/null
exit_on_error $? "Cache purge failed with error $?"

# success
exit 0

#
# end of file
#
