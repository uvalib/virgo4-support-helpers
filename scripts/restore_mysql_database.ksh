#!/usr/bin/env bash
#
# A helper to restore a mysql database.
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <mysql env> <input file>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
TARGET_ENV=$1
shift
RESTORE_FILE=$1
shift

# ensure our environment exists
ensure_file_exists ${TARGET_ENV}

# ensure our restore file exists
ensure_file_exists ${RESTORE_FILE}

# ensure the necessary tools exist
RESTORE_TOOL=mysql
ensure_tool_available ${RESTORE_TOOL}

# extract the needed values from the target environment
TGT_DBHOST=$(extract_nv_from_file ${TARGET_ENV} DBHOST)
TGT_DBPORT=$(extract_nv_from_file ${TARGET_ENV} DBPORT)
TGT_DBUSER=$(extract_nv_from_file ${TARGET_ENV} DBUSER)
TGT_DBPASSWD=$(extract_nv_from_file ${TARGET_ENV} DBPASSWD)
TGT_DBNAME=$(extract_nv_from_file ${TARGET_ENV} DBNAME)

# restore the data
echo "Restoring dataset (${TGT_DBNAME} @ ${TGT_DBHOST})"
MYSQL_PWD=${TGT_DBPASSWD} ${RESTORE_TOOL} -h ${TGT_DBHOST} -u ${TGT_DBUSER} -D ${TGT_DBNAME} < ${RESTORE_FILE} > /dev/null
exit_on_error $? "Restore to target failed with error $?"

# success
echo "Terminating normally"
exit 0

#
# end of file
#
