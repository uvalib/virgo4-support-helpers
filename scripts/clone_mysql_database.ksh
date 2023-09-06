#!/usr/bin/env bash
#
# A helper to clone a mysql database.
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <mysql source env> <mysql target env>"
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
DUMP_TOOL=mysqldump
ensure_tool_available $DUMP_TOOL
RESTORE_TOOL=mysql
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

# dump the data
echo "Dumping source dataset ($SRC_DBNAME @ $SRC_DBHOST)"
$DUMP_TOOL -h $SRC_DBHOST -P $SRC_DBPORT -u $SRC_DBUSER --password=$SRC_DBPASSWD --set-gtid-purged=OFF --flush-privileges --routines $SRC_DBNAME > $DUMP_FILE
exit_on_error $? "Extract from source failed with error $?"

# restore the data
echo "Restoring dataset ($TGT_DBNAME @ $TGT_DBHOST)"
$RESTORE_TOOL -h $TGT_DBHOST -u $TGT_DBUSER -D $TGT_DBNAME --password=$TGT_DBPASSWD < $DUMP_FILE > /dev/null
exit_on_error $? "Restore to target failed with error $?"

# remove the files
rm -fr $DUMP_FILE > /dev/null 2>&1
#echo $DUMP_FILE

# success
echo "Terminating normally"
exit 0

#
# end of file
#
