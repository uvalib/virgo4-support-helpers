#!/usr/bin/env bash
#
# A helper to get a subset of id's from Solr and submit for a reindex.
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <sirsi|hathi> <Solr query file> <staging|production> [<pg env>] [reindex=\"y\"]"
}

# ensure correct usage
if [ $# -lt 3 ]; then
   show_use_and_exit
fi

# input parameters for clarity
MARC_TYPE=$1
shift
QUERY_FILE=$1
shift
ENVIRONMENT=$1
shift
DATABASE_ENV=${1:-""}
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

# if we are going to validate against the database before submitting, ensure we have a DB credentials file
if [ -n "$DATABASE_ENV" ]; then
   # ensure our pg environment exists
   ensure_file_exists $DATABASE_ENV

   # extract the needed values from the database environment
   DBHOST=$(extract_nv_from_file $DATABASE_ENV DBHOST)
   DBPORT=$(extract_nv_from_file $DATABASE_ENV DBPORT)
   DBUSER=$(extract_nv_from_file $DATABASE_ENV DBUSER)
   DBPASSWD=$(extract_nv_from_file $DATABASE_ENV DBPASSWD)
   DBNAME=$(extract_nv_from_file $DATABASE_ENV DBNAME)

   # tool for verifying id's in the cache
   CACHE_VERIFY_TOOL=bin/virgo4-cache-verify
   ensure_file_exists $CACHE_VERIFY_TOOL
fi

# disabled because we sometimes operate using roles
# check our environment requirements
# check_aws_environment

# ensure our Solr query file exists
ensure_file_exists $QUERY_FILE

# ensure tool for uploading files to S3 exists
S3_PUT_TOOL=$SCRIPT_DIR/s3-put.ksh
ensure_file_exists $S3_PUT_TOOL

# notifications of optional behavior
if [ $LIVE_RUN == false ]; then
   echo "Dry running... add \"y\" to the command line to actually submit the reindex"
fi

if [ -z "$DATABASE_ENV" ]; then
   echo "No cache verification... include the database environment file to verify the id's in the cache"
fi

# get the query from the query file
QUERY=$(head -1 $QUERY_FILE)
if [ -z "$QUERY" ]; then
   echo "ERROR: query file is empty, aborting"
   exit 1
fi

# temp file definitions
SOLR_RESULTS_FILE=/tmp/solr-results.$$
rm -f $SOLR_RESULTS_FILE > /dev/null 2>&1

# get some timestamps, etc
YEAR=$(date "+%Y")
TIMESTAMP=$(date "+%Y%m%d%H%M%S")

# define the target files
ID_TARGET=/tmp/${MARC_TYPE}-marc-reindex-${TIMESTAMP}.ids
rm -f $ID_TARGET > /dev/null 2>&1

# this is the bucket used for all inbound ingest files
BUCKET=virgo4-ingest-${ENVIRONMENT}-inbound

echo "Getting items from Solr (this takes a while)..."
SOLR_QUERY="$SOLR_REPLICA/solr/test_core/select?fl=id&${QUERY}"
echo " ($SOLR_QUERY)"
curl $SOLR_QUERY > $SOLR_RESULTS_FILE 2>/dev/null
exit_on_error $? "ERROR: $? querying Solr, aborting"

# filter the results
cat $SOLR_RESULTS_FILE | grep "\"id\":" | awk -F: '{print $2}' | tr -d "\",}]" | sort > $ID_TARGET
COUNT=$(wc -l $ID_TARGET | awk '{print $1}')

# check we actually have items to process
if [ "$COUNT" != "0" ]; then
   echo "$COUNT id's received from Solr query..."
else
   echo "No items received from Solr, aborting"
   exit 1
fi

# do the cache verification if appropriate
if [ -n "$DATABASE_ENV" ]; then

   echo "Verifying items in the cache (this takes a while)..."

   # from our pg env file
   export VIRGO4_CACHE_VERIFY_POSTGRES_HOST=$DBHOST
   export VIRGO4_CACHE_VERIFY_POSTGRES_PORT=$DBPORT
   export VIRGO4_CACHE_VERIFY_POSTGRES_USER=$DBUSER
   export VIRGO4_CACHE_VERIFY_POSTGRES_PASS=$DBPASSWD
   export VIRGO4_CACHE_VERIFY_POSTGRES_DATABASE=$DBNAME

   # fixed
   export VIRGO4_CACHE_VERIFY_POSTGRES_TABLE=source_cache
   export VIRGO4_CACHE_VERIFY_DATA_SOURCE=$MARC_TYPE
   export VIRGO4_CACHE_VERIFY_INFILE=$ID_TARGET

   CACHE_RESULTS=/tmp/cache-results.$$
   rm -f $CACHE_RESULTS > /dev/null 2>&1

   $CACHE_VERIFY_TOOL > $CACHE_RESULTS 2>&1
   exit_on_error $? "ERROR: $? verifying cache, aborting (errors: $CACHE_RESULTS, ID list: $ID_TARGET)"
   rm -f $CACHE_RESULTS > /dev/null 2>&1

   echo "All items appear in the cache..."
fi

# if this is a live run
if [ $LIVE_RUN == true ]; then
   # upload id file to S3
   DESTINATION=$MARC_TYPE-reindex/$YEAR
   TARGET=$(basename $ID_TARGET)
   echo "Uploading $ID_TARGET to s3://$BUCKET/$DESTINATION/$TARGET"
   $S3_PUT_TOOL $ID_TARGET $BUCKET/$DESTINATION/$TARGET
   exit_on_error $? "ERROR: $? uploading file, aborting"
fi

# cleanup
rm -fr $SOLR_RESULTS_FILE $ID_TARGET > /dev/null 2>&1

# success
echo "Terminating normally"
exit 0

#
# end of file
#
