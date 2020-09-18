#!/usr/bin/env bash
#
# A helper to initiate a complete MARC reindex
#

#set -x

# source common helpers
#FULL_NAME=$(realpath $0)
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
#SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <sirsi|hathi> <staging|production> <pg env> [reindex=\"y\"]"
}

# ensure correct usage
if [ $# -lt 3 ]; then
   show_use_and_exit
fi

# input parameters for clarity
MARC_TYPE=$1
shift
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

# validate the marc type parameter
case $MARC_TYPE in
   sirsi|hathi)
      ;;
   *) echo "ERROR: specify sirsi or hathi, aborting"
   exit 1
   ;;
esac

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

# tool for uploading files to S3
S3_PUT_TOOL=scripts/s3-put.ksh
ensure_file_exists $S3_PUT_TOOL

# extract the needed values from the database environment
DBHOST=$(extract_nv_from_file $DATABASE_ENV DBHOST)
DBPORT=$(extract_nv_from_file $DATABASE_ENV DBPORT)
DBUSER=$(extract_nv_from_file $DATABASE_ENV DBUSER)
DBPASSWD=$(extract_nv_from_file $DATABASE_ENV DBPASSWD)
DBNAME=$(extract_nv_from_file $DATABASE_ENV DBNAME)

if [ $LIVE_RUN == false ]; then
   echo "Dry running... add \"y\" to the command line to actually reindex"
fi

if [ $LIVE_RUN == false ]; then

   echo "Getting count of $MARC_TYPE records..."
   RECORD_COUNT=$($QUERY_TOOL $DBHOST $DBPORT $DBUSER $DBPASSWD $DBNAME "select count(*) from source_cache where source='$MARC_TYPE'" | head -1 | awk '{print $1}')

   echo "Would reindex $RECORD_COUNT $MARC_TYPE records"
   exit 0
fi

# our work files containing the output from the database queries
ID_FILE=/tmp/$MARC_TYPE-ids.$$

echo "Getting list of $MARC_TYPE records (takes a while)..."
$QUERY_TOOL $DBHOST $DBPORT $DBUSER $DBPASSWD $DBNAME "select id from source_cache where source='$MARC_TYPE'" > $ID_FILE
exit_on_error $? "ERROR: $? getting list of $MARC_TYPE ID's"

# get some timestamps, etc
YEAR=$(date "+%Y")
TIMESTAMP=$(date "+%Y%m%d%H%M%S")

# define the target files
ID_TARGET=/tmp/$MARC_TYPE-reindex-$TIMESTAMP.ids

# cleanup the database dump file to prepare for upload
cat $ID_FILE | sed -e 's/^ //g' | sed '/^$/d' > $ID_TARGET

# this is the bucket used for all inbound ingest files
BUCKET=virgo4-ingest-${ENVIRONMENT}-inbound

# upload id file to S3
DESTINATION=$MARC_TYPE-reindex/$YEAR
TARGET=$(basename $ID_TARGET)
echo "Uploading $ID_TARGET to s3://$BUCKET/$DESTINATION/$TARGET"
$S3_PUT_TOOL $ID_TARGET $BUCKET/$DESTINATION/$TARGET
exit_on_error $? "ERROR: $? uploading file"

# cleanup
rm -fr $ID_FILE $ID_TARGET > /dev/null 2>&1

# success
exit 0

#
# end of file
#
