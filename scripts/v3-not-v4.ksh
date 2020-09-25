#!/usr/bin/env bash
#
# A helper to get a list of items that are in Virgo3 but not in Virgo4
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <staging|production>"
}

# ensure correct usage
if [ $# -lt 1 ]; then
   show_use_and_exit
fi

# input parameters for clarity
ENVIRONMENT=$1
shift

# validate the environment parameter and define our Solr endpoint
case $ENVIRONMENT in
   staging)
      V4_SOLR=http://virgo4-solr-staging-replica-0-private.internal.lib.virginia.edu:8080
      ;;
   production)
      V4_SOLR=http://v4-solr-production-replica-0-private.internal.lib.virginia.edu:8080
      ;;

   *) echo "ERROR: specify staging or production, aborting"
   exit 1
   ;;
esac

MAX_ITEMS=1000000
V3_SOLR=http://solr.lib.virginia.edu:8082

# temp file definitions
V3_SOLR_RESULTS_FILE=/tmp/v3-solr-results.$$
V4_SOLR_RESULTS_FILE=/tmp/v4-solr-results.$$
V3_DATA_FILE=/tmp/v3-data.$$
V3_ID_FILE=/tmp/v3-id.$$
V4_ID_FILE=/tmp/v4-id.$$
MISSING_ID_FILE=/tmp/missing-id.$$
RESULTS_FILE=/tmp/missing-data.$$
rm -f $V3_SOLR_RESULTS_FILE > /dev/null 2>&1
rm -f $V4_SOLR_RESULTS_FILE > /dev/null 2>&1
rm -f $V3_DATA_FILE > /dev/null 2>&1
rm -f $V3_ID_FILE > /dev/null 2>&1
rm -f $V4_ID_FILE > /dev/null 2>&1
rm -f $MISSING_ID_FILE > /dev/null 2>&1
rm -f $RESULTS_FILE > /dev/null 2>&1

echo "Getting items from V3 Solr (this takes a while)..."
SOLR_QUERY="$V3_SOLR/solr/core/select?q=-source_facet:%22Library%20Catalog%22%20-source_facet:%22Hathi%20Trust%20Digital%20Library%22&wt=json&fl=id,%20source_facet,%20digital_collection_facet&rows=$MAX_ITEMS&start=0"
echo " ($SOLR_QUERY)"
curl $SOLR_QUERY > $V3_SOLR_RESULTS_FILE 2>/dev/null
exit_on_error $? "ERROR: $? querying V3 Solr, aborting"

echo "Getting items from V4 Solr (this takes a while)..."
SOLR_QUERY="$V4_SOLR/solr/test_core/select?q=-source_f:%22Library%20Catalog%22%20-source_f:%22Hathi%20Trust%20Digital%20Library%22&rows=$MAX_ITEMS&start=0&fl=id"
echo " ($SOLR_QUERY)"
curl $SOLR_QUERY > $V4_SOLR_RESULTS_FILE 2>/dev/null
exit_on_error $? "ERROR: $? querying V4 Solr, aborting"

# cleanup the V3 results
cat $V3_SOLR_RESULTS_FILE | jq -c ".response.docs[]" > $V3_DATA_FILE
COUNT=$(wc -l $V3_DATA_FILE | awk '{print $1}')

# check we actually have items to process
if [ "$COUNT" != "0" ]; then
   echo "$COUNT id's received from V3 Solr query..."
else
   echo "No items received from V3 Solr, aborting"
   exit 1
fi

# cleanup the V4 results
cat $V4_SOLR_RESULTS_FILE | jq ".response.docs[].id" | tr -d "\"" | sort > $V4_ID_FILE
COUNT=$(wc -l $V4_ID_FILE | awk '{print $1}')

# check we actually have items to process
if [ "$COUNT" != "0" ]; then
   echo "$COUNT id's received from V4 Solr query..."
else
   echo "No items received from V4 Solr, aborting"
   exit 1
fi

# create a list of V3 id's
cat $V3_DATA_FILE | jq ".id" | tr -d "\"" | sort > $V3_ID_FILE

# create a list of what is missing from V4
comm -23 $V3_ID_FILE $V4_ID_FILE > $MISSING_ID_FILE
COUNT=$(wc -l $MISSING_ID_FILE | awk '{print $1}')
echo "$COUNT id's missing from V4..."

# dump the data for every item that is missing
echo "Generating list of missing items (this takes a very long time)..."
grep -F -f $MISSING_ID_FILE $V3_DATA_FILE > $RESULTS_FILE
echo "Results in $RESULTS_FILE"

# cleanup
rm -fr $V3_SOLR_RESULTS_FILE $V4_SOLR_RESULTS_FILE $V3_DATA_FILE $V3_ID_FILE $V4_ID_FILE $MISSING_ID_FILE > /dev/null 2>&1

# success
echo "Terminating normally"
exit 0

#
# end of file
#
