#!/usr/bin/env bash
#
# A helper to get a subset of id's from Solr and submit for a reindex.
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <id_file> <staging|production> [<pg env>] <output_id_file>"
}

# ensure correct usage
if [ $# -lt 3 ]; then
   show_use_and_exit
fi

# input parameters for clarity
ID_FILE=$1
shift
ENVIRONMENT=$1
shift
DATABASE_ENV=${1:-""}
shift
OUTPUT_ID_FILE=$1

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

# check our environment requirements
check_aws_environment

# ensure our Solr query file exists
ensure_file_exists $ID_FILE

# ensure tool for uploading files to S3 exists
S3_PUT_TOOL=scripts/s3-put.ksh
ensure_file_exists $S3_PUT_TOOL

# get some timestamps, etc
YEAR=$(date "+%Y")
TIMESTAMP=$(date "+%Y%m%d%H%M%S")


COUNT=$(wc -l $ID_FILE | awk '{print $1}')

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
   export VIRGO4_CACHE_VERIFY_INFILE=$ID_FILE

   CACHE_RESULTS=/tmp/cache-results.$$
   rm -f $CACHE_RESULTS > /dev/null 2>&1

   $CACHE_VERIFY_TOOL > $CACHE_RESULTS 2>&1
   if [[ "$?" != "0" ]]; then
       cat $CACHE_RESULTS | egrep "ERROR" | cut -d ' ' -f 5 >  $OUTPUT_ID_FILE
   else
      cat /dev/null > $OUTPUT_ID_FILE
   fi

   #rm -f $CACHE_RESULTS > /dev/null 2>&1

   num=`cat $OUTPUT_ID_FILE | wc -l`

   if [[ "$num" == "0" ]]; then
      echo "All items appear in the cache... (which is expected)"
      echo "$CACHE_RESULTS"
      #rm -f $CACHE_RESULTS > /dev/null 2>&1
   else
      echo "$num items aren't in the cache, when they should be"
      echo "$CACHE_RESULTS"
   fi
fi

exit 0

#
# end of file
#
