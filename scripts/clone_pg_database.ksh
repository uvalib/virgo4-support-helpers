#!/usr/bin/env bash
#
# A helper to deploy the search preproduction environment based on the current version tags
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <pg source env> <pc target env>"
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
DUMP_TOOL=pg_dump
ensure_tool_available $DUMP_TOOL
RESTORE_TOOL=psql
ensure_tool_available $RESTORE_TOOL

# extract the needed values from the source environment
SRC_DBHOST=$(extract_nv_from_file $SOURCE_ENV DBHOST)
SRC_DBPORT=$(extract_nv_from_file $SOURCE_ENV DBPORT)
SRC_DBUSER=$(extract_nv_from_file $SOURCE_ENV DBUSER)
SRC_DBPASSWD=$(extract_nv_from_file $SOURCE_ENV DBPASSWD)
SRC_DBNAME=$(extract_nv_from_file $SOURCE_ENV DBNAME)

# extract the needed values from the target environment
TGT_DBHOST=$(extract_nv_from_file $TARGET_ENV DBHOST)
TGT_DBPORT=$(extract_nv_from_file $TARGET_ENV DBPORT)
TGT_DBUSER=$(extract_nv_from_file $TARGET_ENV DBUSER)
TGT_DBPASSWD=$(extract_nv_from_file $TARGET_ENV DBPASSWD)
TGT_DBNAME=$(extract_nv_from_file $TARGET_ENV DBNAME)

DUMP_FILE=/tmp/dump.$$
REWRITE_FILE=/tmp/rewrite.$$

# dump the data
echo "Dumping source dataset..."
PGPASSWORD=$SRC_DBPASSWD $DUMP_TOOL -w --clean -h $SRC_DBHOST -p $SRC_DBPORT -U $SRC_DBUSER -d $SRC_DBNAME -f $DUMP_FILE
exit_on_error $? "Extract from source failed with error $?"

# data rewrite phase
echo "Rewriting as necessary..."
cat $DUMP_FILE | sed -e 's/.private.production/-test.private.production/g' | sed -e 's/.internal.lib.virginia.edu/-test.internal.lib.virginia.edu/g' > $REWRITE_FILE

# restore the data
echo "Restoring dataset..."
PGPASSWORD=$TGT_DBPASSWD $RESTORE_TOOL -w -q -h $TGT_DBHOST -p $TGT_DBPORT -U $TGT_DBUSER -d $TGT_DBNAME -f $REWRITE_FILE > /dev/null
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
