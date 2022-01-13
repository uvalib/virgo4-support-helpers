#!/usr/bin/env bash
#
# A helper to pull ID's from Solr given a query file
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <staging|production> <core name> <solr query file> <output file>"
}

# ensure correct usage
if [ $# -lt 4 ]; then
   show_use_and_exit
fi

# input parameters for clarity
ENVIRONMENT=$1
shift
CORE_NAME=$1
shift
SOLR_QUERY=$1
shift
OUTFILE=$1
shift

# ensure we have the necessary tools available
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL

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

# get the query from the query file
QUERY=$(head -1 $SOLR_QUERY)
if [ -z "$QUERY" ]; then
   echo "ERROR: query file is empty, aborting"
   exit 1
fi

# temp definitions
SOLR_RESPONSE=/tmp/solr-response.$$

echo "Getting list of id's from Solr (this can take a while)..."
SOLR_QUERY="$SOLR_REPLICA/solr/$CORE_NAME/select?fl=id&${QUERY}"
#echo " ($SOLR_QUERY)"
curl $SOLR_QUERY > $SOLR_RESPONSE 2>/dev/null
exit_on_error $? "ERROR: $? querying Solr, aborting"

# process the response
$JQ_TOOL -r ".response.docs[].id" $SOLR_RESPONSE | sort > $OUTFILE

# cleanup
rm -fr $SOLR_RESPONSE > /dev/null 2>&1

# success
exit 0

#
# end of file
#
