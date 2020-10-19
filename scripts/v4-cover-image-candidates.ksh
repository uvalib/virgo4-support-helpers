#!/usr/bin/env bash
#
# A helper to get a list of items in Virgo4 that are candidates for cover images.
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <staging|production> <output file>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
ENVIRONMENT=$1
shift
OUTFILE=$1
shift

# validate the environment parameter and define our Solr endpoint
case $ENVIRONMENT in
   staging)
      SOLR_URL=http://virgo4-solr-staging-replica-0-private.internal.lib.virginia.edu:8080
      ;;
   production)
      SOLR_URL=http://v4-solr-production-replica-0-private.internal.lib.virginia.edu:8080
      ;;

   *) echo "ERROR: specify staging or production, aborting"
   exit 1
   ;;
esac

MAX_ITEMS=10000000

# temp file definitions
SOLR_RESULTS_FILE=/tmp/solr-results.$$
rm -f $SOLR_RESULTS_FILE > /dev/null 2>&1

echo "Getting items from default Solr (this takes a while)..."
SOLR_QUERY="$SOLR_URL/solr/test_core/select?q=isbn_a%3A*&rows=$MAX_ITEMS&start=0&fl=id,isbn_a"
#echo " ($SOLR_QUERY)"
curl $SOLR_QUERY > $SOLR_RESULTS_FILE 2>/dev/null
exit_on_error $? "ERROR: $? querying default Solr, aborting"

# cleanup the default V4 results
cat $SOLR_RESULTS_FILE | jq ".response.docs[] | .id + \"|\" + .isbn_a[0]" | tr -d "\"" > $OUTFILE

# cleanup
rm -fr $SOLR_RESULTS_FILE > /dev/null 2>&1

# success
echo "Terminating normally"
exit 0

#
# end of file
#
