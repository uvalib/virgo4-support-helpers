#!/usr/bin/env bash
#
# A helper to clone a postgres database.
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <pg source env> <pg target env>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
SOURCE_ENV=$1
shift
TARGET_ENV=$1
shift

# ensure both our pg environments exist
ensure_file_exists $SOURCE_ENV
ensure_file_exists $TARGET_ENV

# ensure the necessary tools exist
DUMP_SCRIPT=$SCRIPT_DIR/dump_pg_database.ksh
ensure_file_exists $DUMP_SCRIPT
PSQL_TOOL=psql
ensure_tool_available $PSQL_TOOL

# extract the needed values from the target environment
TGT_DBHOST=$(extract_nv_from_file $TARGET_ENV DBHOST)
TGT_DBPORT=$(extract_nv_from_file $TARGET_ENV DBPORT)
TGT_DBUSER=$(extract_nv_from_file $TARGET_ENV DBUSER)
TGT_DBPASSWD=$(extract_nv_from_file $TARGET_ENV DBPASSWD)
TGT_DBNAME=$(extract_nv_from_file $TARGET_ENV DBNAME)

DUMP_FILE=/tmp/dump.$$
REWRITE_FILE=/tmp/rewrite.$$

# dump the data
$DUMP_SCRIPT $SOURCE_ENV $DUMP_FILE
exit_on_error $? "Terminating"

# data rewrite phase
echo "Rewriting as necessary..."
cat $DUMP_FILE | sed -e 's/.private.production/-test.private.test/g' | sed -e 's/.internal.lib.virginia.edu/-test.internal.lib.virginia.edu/g' > $REWRITE_FILE

# purge the existing database
echo "Purging target database ($TGT_DBNAME @ $TGT_DBHOST)"
PGPASSWORD=$TGT_DBPASSWD $PSQL_TOOL -h $TGT_DBHOST -p $TGT_DBPORT -U $TGT_DBUSER -d $TGT_DBNAME -t -c "DROP OWNED BY $TGT_DBUSER" > /dev/null
exit_on_error $? "Purge of target failed with error $?"

# restore the data
echo "Restoring dataset ($TGT_DBNAME @ $TGT_DBHOST)"
PGPASSWORD=$TGT_DBPASSWD $PSQL_TOOL -w -q -h $TGT_DBHOST -p $TGT_DBPORT -U $TGT_DBUSER -d $TGT_DBNAME -f $REWRITE_FILE > /dev/null
exit_on_error $? "Restore to target failed with error $?"

# remove the files
rm -fr $DUMP_FILE > /dev/null 2>&1
rm -fr $REWRITE_FILE > /dev/null 2>&1

# success
echo "Terminating normally"
exit 0

#
# end of file
#
