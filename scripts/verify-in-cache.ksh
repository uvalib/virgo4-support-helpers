#!/usr/bin/env bash
#
# A helper to verify a set of id's exists in the cache
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <id_file> <source type> [<pg env>] <output_id_file>"
}

# ensure correct usage
if [ $# -lt 4 ]; then
   show_use_and_exit
fi

# input parameters for clarity
ID_FILE=$1
shift
SOURCE_TYPE=$1
shift
DATABASE_ENV=$1
shift
OUTPUT_ID_FILE=$1

# validate the source type
case $SOURCE_TYPE in
   sirsi|hathi)
      ;;
   dynamic)
      $SOURCE_TYPE="getty kanopy law swank viva"
      ;;

   *) echo "ERROR: specify sirsi, hathi or dynamic, aborting"
   exit 1
   ;;
esac

# if we are going to validate against the database before submitting, ensure we have a DB credentials file
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

# disabled because we sometimes operate using roles
# check our environment requirements
# check_aws_environment

# ensure our Solr query file exists
ensure_file_exists $ID_FILE

# check we actually have items to process
COUNT=$(wc -l $ID_FILE | awk '{print $1}')
if [ "$COUNT" != "0" ]; then
   echo "$COUNT id's to verify..."
else
   echo "No items to verify, aborting"
   exit 1
fi

# do the cache verification
echo "Verifying items in the cache (this takes a while)..."

# from our pg env file
export VIRGO4_CACHE_VERIFY_POSTGRES_HOST=$DBHOST
export VIRGO4_CACHE_VERIFY_POSTGRES_PORT=$DBPORT
export VIRGO4_CACHE_VERIFY_POSTGRES_USER=$DBUSER
export VIRGO4_CACHE_VERIFY_POSTGRES_PASS=$DBPASSWD
export VIRGO4_CACHE_VERIFY_POSTGRES_DATABASE=$DBNAME

# fixed
export VIRGO4_CACHE_VERIFY_POSTGRES_TABLE=source_cache
export VIRGO4_CACHE_VERIFY_DATA_SOURCE="$SOURCE_TYPE"
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

exit 0

#
# end of file
#
