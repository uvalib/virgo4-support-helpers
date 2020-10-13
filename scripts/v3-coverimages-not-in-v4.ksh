#!/usr/bin/env bash
#
# A helper to dump a list of ID's/ISBN's that appear in the V3 cover images instance but not in the V4 one
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <v3 db env> <v4 db env> <results>"
}

# ensure correct usage
if [ $# -lt 3 ]; then
   show_use_and_exit
fi

# input parameters for clarity
V3_DATABASE_ENV=$1
shift
V4_DATABASE_ENV=$1
shift
RESULTS_FILE=$1
shift

# ensure our environment files exist
ensure_file_exists $V3_DATABASE_ENV
ensure_file_exists $V4_DATABASE_ENV

# tool for issuing Postgres queries
QUERY_TOOL=scripts/mysql_query.ksh
ensure_file_exists $QUERY_TOOL

# extract the needed values from the database environments
V3_DBHOST=$(extract_nv_from_file $V3_DATABASE_ENV DBHOST)
V3_DBPORT=$(extract_nv_from_file $V3_DATABASE_ENV DBPORT)
V3_DBUSER=$(extract_nv_from_file $V3_DATABASE_ENV DBUSER)
V3_DBPASS=$(extract_nv_from_file $V3_DATABASE_ENV DBPASSWD)
V3_DBNAME=$(extract_nv_from_file $V3_DATABASE_ENV DBNAME)

V4_DBHOST=$(extract_nv_from_file $V4_DATABASE_ENV DBHOST)
V4_DBPORT=$(extract_nv_from_file $V4_DATABASE_ENV DBPORT)
V4_DBUSER=$(extract_nv_from_file $V4_DATABASE_ENV DBUSER)
V4_DBPASS=$(extract_nv_from_file $V4_DATABASE_ENV DBPASSWD)
V4_DBNAME=$(extract_nv_from_file $V4_DATABASE_ENV DBNAME)

# our work files containing the output from the database queries
V3_LIST=/tmp/v3-ids.$$
V4_LIST=/tmp/v4-ids.$$

QUERY="select doc_id, isbn from cover_images where isbn is not null"

echo "Getting list of v3 cover image records (this takes a while)..."
$QUERY_TOOL $V3_DBHOST $V3_DBPORT $V3_DBUSER $V3_DBPASS $V3_DBNAME "$QUERY" > $V3_LIST
exit_on_error $? "ERROR: $? getting list of v3 cover image records"

echo "Getting list of v4 cover image records (this takes a while)..."
$QUERY_TOOL $V4_DBHOST $V4_DBPORT $V4_DBUSER $V4_DBPASS $V4_DBNAME "$QUERY" > $V4_LIST
exit_on_error $? "ERROR: $? getting list of v4 cover image records"

# cleaned up data
CLEAN_V3_LIST=/tmp/clean-v3-ids.$$
CLEAN_V4_LIST=/tmp/clean-v4-ids.$$

echo "Cleaning up data..."
cat $V3_LIST | grep -v doc_id | awk '{print $1, $2}' | awk -F, '{print $1}' | sed -e 's/(.*)$//g' | sed -e 's/pbk$//g' | sed -e 's/(pbk.$//g' | grep -v "\\$" | awk '{if ($2) printf "%s|%s\n", $1, $2}' | sort > $CLEAN_V3_LIST
cat $V4_LIST | grep -v doc_id | awk '{print $1, $2}' | awk -F, '{print $1}' | sed -e 's/(.*)$//g' | sed -e 's/pbk$//g' | sed -e 's/(pbk.$//g' | grep -v "\\$" | awk '{if ($2) printf "%s|%s\n", $1, $2}' | sort > $CLEAN_V4_LIST

echo "Generating missing list..."
comm -23 $CLEAN_V3_LIST $CLEAN_V4_LIST > $RESULTS_FILE

echo "Output in $RESULTS_FILE"

# cleanup
#rm -fr $V3_LIST $V4_LIST $CLEAN_V3_LIST $CLEAN_V4_LIST > /dev/null 2>&1

# success
echo "Terminating normally"
exit 0

#
# end of file
#
