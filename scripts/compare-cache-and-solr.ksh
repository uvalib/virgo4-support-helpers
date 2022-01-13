#!/usr/bin/env bash
#
# A helper to compare the ID's in the cache with the ID's in Solr and report the difference.
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <sirsi|hathi> <staging|production> <pg env>"
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

# validate the marc type parameter
case $MARC_TYPE in
   sirsi)
      SOLR_QUERY=$SCRIPT_DIR/../solr-queries/all-sirsi.txt
      ;;
   hathi)
      SOLR_QUERY=$SCRIPT_DIR/../solr-queries/all-hathi.txt
      ;;
   *) echo "ERROR: specify sirsi or hathi, aborting"
   exit 1
   ;;
esac

# validate the environment parameter
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

# disabled because we sometimes operate using roles
# check our environment requirements
# check_aws_environment

# ensure our Solr query file exist
ensure_file_exists $SOLR_QUERY

# ensure our pg environment exist
ensure_file_exists $DATABASE_ENV

# tool for issuing Postgres queries
QUERY_TOOL=$SCRIPT_DIR/pg_query.ksh
ensure_file_exists $QUERY_TOOL

# extract the needed values from the database environment
DBHOST=$(extract_nv_from_file $DATABASE_ENV DBHOST)
DBPORT=$(extract_nv_from_file $DATABASE_ENV DBPORT)
DBUSER=$(extract_nv_from_file $DATABASE_ENV DBUSER)
DBPASSWD=$(extract_nv_from_file $DATABASE_ENV DBPASSWD)
DBNAME=$(extract_nv_from_file $DATABASE_ENV DBNAME)

# get the query from the query file
QUERY=$(head -1 $SOLR_QUERY)
if [ -z "$QUERY" ]; then
   echo "ERROR: query file is empty, aborting"
   exit 1
fi

# our work file containing the output from the database queries
ID_LIST=/tmp/$MARC_TYPE-ids.$$

echo "Getting list of $MARC_TYPE records from cache (this takes a while)..."
$QUERY_TOOL $DBHOST $DBPORT $DBUSER $DBPASSWD $DBNAME "select id from source_cache where source='$MARC_TYPE'" > $ID_LIST
exit_on_error $? "ERROR: $? getting list of $MARC_TYPE ID's"

# define the target files
ID_FROM_CACHE=/tmp/$MARC_TYPE-from-cache.$$
ID_FROM_SOLR=/tmp/$MARC_TYPE-from-solr.$$

# cleanup the database dump file
cat $ID_LIST | sed -e 's/^ //g' | sed '/^$/d' | sort > $ID_FROM_CACHE

echo "Getting list of $MARC_TYPE records from Solr (this takes a while)..."
SOLR_QUERY="$SOLR_REPLICA/solr/test_core/select?fl=id&${QUERY}"
echo " ($SOLR_QUERY)"
curl $SOLR_QUERY > $ID_LIST 2>/dev/null
exit_on_error $? "ERROR: $? querying Solr, aborting"

# filter the results
cat $ID_LIST | grep "\"id\":" | awk -F: '{print $2}' | tr -d "\",}]" | sort > $ID_FROM_SOLR

# results files
CACHE_NOT_IN_SOLR=/tmp/cache-not-solr.$$
SOLR_NOT_IN_CACHE=/tmp/solr-not-cache.$$

echo "Comparing lists..."
comm -23 $ID_FROM_CACHE $ID_FROM_SOLR > $CACHE_NOT_IN_SOLR
exit_on_error $? "ERROR: $? comparing ID lists, aborting"

comm -13 $ID_FROM_CACHE $ID_FROM_SOLR > $SOLR_NOT_IN_CACHE
exit_on_error $? "ERROR: $? comparing ID lists, aborting"

COUNT_NOT_IN_SOLR=$(wc -l $CACHE_NOT_IN_SOLR | awk '{print $1}')
COUNT_NOT_IN_CACHE=$(wc -l $SOLR_NOT_IN_CACHE | awk '{print $1}')

if [ "$COUNT_NOT_IN_SOLR" != "0" -o "$COUNT_NOT_IN_CACHE" != "0" ]; then
   if [ "$COUNT_NOT_IN_SOLR" != "0" ]; then
      echo "$COUNT_NOT_IN_SOLR items appear in cache but NOT in Solr ($CACHE_NOT_IN_SOLR)"
   else
      echo "All items in the cache appear in Solr"
   fi
   if [ "$COUNT_NOT_IN_CACHE" != "0" ]; then
      echo "$COUNT_NOT_IN_CACHE items appear in Solr but NOT in the cache ($SOLR_NOT_IN_CACHE)"
   else
      echo "All items in Solr appear in the cache"
   fi

   # cleanup
   rm -fr $ID_LIST $ID_FROM_CACHE $ID_FROM_SOLR > /dev/null 2>&1

   echo "Terminating normally"
   exit 1
fi

echo "Solr and the cache are in sync, YAY!

# cleanup
rm -fr $ID_LIST $ID_FROM_CACHE $ID_FROM_SOLR $CACHE_NOT_IN_SOLR $SOLR_NOT_IN_CACHE > /dev/null 2>&1

# success
echo "Terminating normally"
exit 0

#
# end of file
#
