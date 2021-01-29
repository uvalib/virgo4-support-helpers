#!/usr/bin/env bash
#
# A helper to dump a postgres database.
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <pg source env> <target file>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
SOURCE_ENV=$1
shift
TARGET_FILE=$1
shift

# ensure our pg environments exist
ensure_file_exists $SOURCE_ENV

# ensure the necessary tools exist
DUMP_TOOL=pg_dump
ensure_tool_available $DUMP_TOOL

# extract the needed values from the source environment
SRC_DBHOST=$(extract_nv_from_file $SOURCE_ENV DBHOST)
SRC_DBPORT=$(extract_nv_from_file $SOURCE_ENV DBPORT)
SRC_DBUSER=$(extract_nv_from_file $SOURCE_ENV DBUSER)
SRC_DBPASSWD=$(extract_nv_from_file $SOURCE_ENV DBPASSWD)
SRC_DBNAME=$(extract_nv_from_file $SOURCE_ENV DBNAME)

# dump the data
echo "Dumping database ($SRC_DBNAME @ $SRC_DBHOST)"
PGPASSWORD=$SRC_DBPASSWD $DUMP_TOOL -w -h $SRC_DBHOST -p $SRC_DBPORT -U $SRC_DBUSER -d $SRC_DBNAME -f $TARGET_FILE
exit_on_error $? "Extract from database failed with error $?"

# success
echo "Terminating normally"
exit 0

#
# end of file
#
