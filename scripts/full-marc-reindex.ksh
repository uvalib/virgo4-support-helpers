#!/usr/bin/env bash
#
# A helper to initiate a complete MARC reindex
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <staging|production> <pg env> [reindex=\"y\"]"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
ENVIRONMENT=$1
shift
DATABASE_ENV=$1
shift
LIVE_RUN=${1:-false}

# determine if this is a live run or not
if [ -n "$LIVE_RUN" ]; then
   if [ $LIVE_RUN == "y" ]; then
      LIVE_RUN=true
   else
      LIVE_RUN=false
   fi
fi

# validate the environment parameter
case $ENVIRONMENT in
   staging|production)
      ;;
   *) echo "ERROR: specify staging or production, aborting"
   exit 1
   ;;
esac

# check our environment requirements
check_aws_environment

# ensure our pg environment exist
ensure_file_exists $DATABASE_ENV

# tool for issuing Postgres queries
QUERY_TOOL=scripts/pg_query.ksh
ensure_file_exists $QUERY_TOOL

# tool for listing files in S3
DYNAMIC_FILE_LIST=scripts/list-dynamic-files.ksh
ensure_file_exists $DYNAMIC_FILE_LIST

# tool for uploading files to S3
S3_PUT_TOOL=scripts/s3-put.ksh
ensure_file_exists $S3_PUT_TOOL

# tool for sending S3 file notifications
FILE_NOTIFY_TOOL=bin/virgo4-file-notify
ensure_file_exists $FILE_NOTIFY_TOOL

# extract the needed values from the database environment
DBHOST=$(extract_nv_from_file $DATABASE_ENV DBHOST)
DBPORT=$(extract_nv_from_file $DATABASE_ENV DBPORT)
DBUSER=$(extract_nv_from_file $DATABASE_ENV DBUSER)
DBPASSWD=$(extract_nv_from_file $DATABASE_ENV DBPASSWD)
DBNAME=$(extract_nv_from_file $DATABASE_ENV DBNAME)

if [ $LIVE_RUN == false ]; then
   echo "Dry running... add \"y\" to the command line to actually reindex"
fi

# get a list of the dynamic MARC files to reindex
DYNAMIC_FILES=/tmp/dynamic.$$
echo "Getting list of dynamic MARC files..."
$DYNAMIC_FILE_LIST $ENVIRONMENT > $DYNAMIC_FILES
exit_on_error $? "ERROR: $? getting list of dynamic MARC files"

if [ $LIVE_RUN == false ]; then

   echo "Getting count of Sirsi records..."
   SIRSI_COUNT=$($QUERY_TOOL $DBHOST $DBPORT $DBUSER $DBPASSWD $DBNAME "select count(*) from source_cache where source='sirsi'" | head -1 | awk '{print $1}')
   echo "Getting count of Hathi records..."
   HATHI_COUNT=$($QUERY_TOOL $DBHOST $DBPORT $DBUSER $DBPASSWD $DBNAME "select count(*) from source_cache where source='hathi'" | head -1 | awk '{print $1}')

   echo "Would reindex $SIRSI_COUNT Sirsi records, $HATHI_COUNT Hathi records and the following dynamic MARC files:"
   cat $DYNAMIC_FILES
   rm -fr $DYNAMIC_FILES > /dev/null 2>&1
   exit 0
fi

# our work files containing the output from the database queries
SIRSI_ID_FILE=/tmp/sirsi-ids.$$
HATHI_ID_FILE=/tmp/hathi-ids.$$

echo "Getting list of Sirsi records (takes a while)..."
$QUERY_TOOL $DBHOST $DBPORT $DBUSER $DBPASSWD $DBNAME "select id from source_cache where source='sirsi'" > $SIRSI_ID_FILE
exit_on_error $? "ERROR: $? getting list of Sirsi ID's"
echo "Getting list of Hathi records (takes a while)..."
$QUERY_TOOL $DBHOST $DBPORT $DBUSER $DBPASSWD $DBNAME "select id from source_cache where source='hathi'" > $HATHI_ID_FILE
exit_on_error $? "ERROR: $? getting list of Hathi ID's"

# get some timestamps, etc
YEAR=$(date "+%Y")
TIMESTAMP=$(date "+%Y%m%d%H%M%S")

# define the target files
SIRSI_TARGET=/tmp/sirsi-reindex-$TIMESTAMP.ids
HATHI_TARGET=/tmp/hathi-reindex-$TIMESTAMP.ids

# cleanup the database dump files rto prepare for upload
cat $SIRSI_ID_FILE | sed -e 's/^ //g' | sed '/^$/d' > $SIRSI_TARGET
cat $HATHI_ID_FILE | sed -e 's/^ //g' | sed '/^$/d' > $HATHI_TARGET

# this is the bucket used for all inbound ingest files
BUCKET=virgo4-ingest-${ENVIRONMENT}-inbound

# send S3 file notifications for each of the dynamic MARC files
echo "Sending file notifications for all dynamic MARC files..."
OUTQUEUE=virgo4-ingest-dynamic-update-notify-${ENVIRONMENT}
for file in $(<$DYNAMIC_FILES); do
   key=${file#$BUCKET/}
   $FILE_NOTIFY_TOOL --bucket $BUCKET --key $key --outqueue $OUTQUEUE
   exit_on_error $? "ERROR: $? sending file notification for $key"
done

# upload sirsi id's to S3
DESTINATION=sirsi-reindex/$YEAR
TARGET=$(basename $SIRSI_TARGET)
echo "Uploading $SIRSI_TARGET to s3://$BUCKET/$DESTINATION/$TARGET"
$S3_PUT_TOOL $SIRSI_TARGET $BUCKET/$DESTINATION/$TARGET
exit_on_error $? "ERROR: $? uploading file"

# upload hathi id's to S3
DESTINATION=hathi-reindex/$YEAR
TARGET=$(basename $HATHI_TARGET)
echo "Uploading $HATHI_TARGET to s3://$BUCKET/$DESTINATION/$TARGET"
$S3_PUT_TOOL $HATHI_TARGET $BUCKET/$DESTINATION/$TARGET
exit_on_error $? "ERROR: $? uploading file"

# cleanup
rm -fr $DYNAMIC_FILES $SIRSI_ID_FILE $HATHI_ID_FILE $SIRSI_TARGET $HATHI_TARGET > /dev/null 2>&1

# success
exit 0

#
# end of file
#
