#!/usr/bin/env bash
#
# A helper to get a subset of id's from Solr and submit for delete.
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <staging|production> <default|image> <solr query file> [delete=\"y\"]"
}

# ensure correct usage
if [ $# -lt 3 ]; then
   show_use_and_exit
fi

# input parameters for clarity
ENVIRONMENT=$1
shift
PIPELINE_TYPE=$1
shift
QUERY_FILE=$1
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

# validate the environment parameter and define our Solr endpoint
case $ENVIRONMENT in
   staging)
      SOLR_REPLICA=http://virgo4-solr-staging-replica-0-private.internal.lib.virginia.edu:8080
      ;;
   production)
      SOLR_REPLICA=http://v4-solr-production-replica-0-private.internal.lib.virginia.edu:8080
      ;;

   *) echo "ERROR: specify staging or production, aborting"
   exit 1
   ;;
esac

# validate the pipeline type parameter and define our core name
case $PIPELINE_TYPE in
   default)
      CORE_NAME=test_core
      ;;
   image)
      CORE_NAME=images_core
      ;;
   *) echo "ERROR: specify default or image, aborting"
      exit 1
      ;;
esac

# disabled because we sometimes operate using roles
# check our environment requirements
# check_aws_environment

# ensure our Solr query file exists
ensure_file_exists $QUERY_FILE

# ensure tool for uploading files to S3 exists
S3_PUT_TOOL=$SCRIPT_DIR/s3-put.ksh
ensure_file_exists $S3_PUT_TOOL

# ensure tool for getting SOLR id's exists
SOLR_ID_TOOL=$SCRIPT_DIR/solr-id-query.ksh
ensure_file_exists $SOLR_ID_TOOL

# notifications of optional behavior
if [ $LIVE_RUN == false ]; then
   echo "Dry running... add \"y\" to the command line to actually submit the delete"
fi

# get the query from the query file
QUERY=$(head -1 $QUERY_FILE)
if [ -z "$QUERY" ]; then
   echo "ERROR: query file is empty, aborting"
   exit 1
fi

# get some timestamps, etc
YEAR=$(date "+%Y")
TIMESTAMP=$(date "+%Y%m%d%H%M%S")

# define the target files
ID_FROM_SOLR=/tmp/delete-${TIMESTAMP}.ids
rm -f $ID_FROM_SOLR > /dev/null 2>&1

$SOLR_ID_TOOL $ENVIRONMENT $CORE_NAME $QUERY_FILE $ID_FROM_SOLR
exit_on_error $? "ERROR: $? getting id's from solr, aborting"

COUNT=$(wc -l $ID_FROM_SOLR | awk '{print $1}')

# check we actually have items to process
if [ "$COUNT" != "0" ]; then
   echo "$COUNT id's received from Solr query..."
else
   echo "No items received from Solr, aborting"
   exit 1
fi

# this is the bucket used for all inbound ingest files
BUCKET=virgo4-ingest-${ENVIRONMENT}-inbound
DESTINATION=doc-delete/$PIPELINE_TYPE/$YEAR
UPLOAD_NAME=$(basename $ID_FROM_SOLR)

# if this is a live run
if [ $LIVE_RUN == true ]; then
   # upload id file to S3
   echo "Uploading $ID_FROM_SOLR to s3://$BUCKET/$DESTINATION/$UPLOAD_NAME"
   $S3_PUT_TOOL $ID_FROM_SOLR $BUCKET/$DESTINATION/$UPLOAD_NAME
   exit_on_error $? "ERROR: $? uploading file, aborting"
else
   echo "Would upload $ID_FROM_SOLR to s3://$BUCKET/$DESTINATION/$UPLOAD_NAME"
fi

# cleanup
rm -fr $ID_FROM_SOLR > /dev/null 2>&1

# success
echo "Terminating normally"
exit 0

#
# end of file
#
