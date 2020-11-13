#!/usr/bin/env bash
#
# A helper to verify the versions in the search preproduction environment based on the current version tags
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <test|production> <tag directory>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
ENVIRONMENT=$1
shift
TAG_DIRECTORY=$(realpath $1)
shift

case $ENVIRONMENT in
   test|production)
   ;;

   *) echo "ERROR: specify test or production, aborting"
   exit 1
   ;;
esac

# ensure the tag location exists
ensure_dir_exists $TAG_DIRECTORY/tags

# define the wait tool
WAIT_TOOL=$TAG_DIRECTORY/pipeline/wait_for_version.sh

# get our version tags
AVAILABILITY_WS_TAG=$(cat $TAG_DIRECTORY/tags/availability-ws.tag)
ensure_var_defined "$AVAILABILITY_WS_TAG" "AVAILABILITY_WS_TAG"

CITATIONS_WS_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-citations-ws.tag)
ensure_var_defined "$CITATIONS_WS_TAG" "CITATIONS_WS_TAG"

CLIENT_WS_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-client.tag)
ensure_var_defined "$CLIENT_WS_TAG" "CLIENT_WS_TAG"

ILS_CONNECTOR_WS_TAG=$(cat $TAG_DIRECTORY/tags/ils-connector.tag)
ensure_var_defined "$ILS_CONNECTOR_WS_TAG" "ILS_CONNECTOR_WS_TAG"

PDA_WS_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-pda-ws.tag)
ensure_var_defined "$PDA_WS_TAG" "PDA_WS_TAG"

POOL_EDS_WS_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-pool-eds-ws.tag)
ensure_var_defined "$POOL_EDS_WS_TAG" "POOL_EDS_WS_TAG"

POOL_JMRL_WS_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-pool-jmrl-ws.tag)
ensure_var_defined "$POOL_JMRL_WS_TAG" "POOL_JMRL_WS_TAG"

POOL_WORLDCAT_WS_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-pool-worldcat-ws.tag)
ensure_var_defined "$POOL_WORLDCAT_WS_TAG" "POOL_WORLDCAT_WS_TAG"

POOL_SOLR_WS_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-pool-solr-ws.tag)
ensure_var_defined "$POOL_SOLR_WS_TAG" "POOL_SOLR_WS_TAG"

SEARCH_WS_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-search-ws.tag)
ensure_var_defined "$SEARCH_WS_TAG" "SEARCH_WS_TAG"

SHELF_BROWSE_WS_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-shelf-browse-ws.tag)
ensure_var_defined "$SHELF_BROWSE_WS_TAG" "SHELF_BROWSE_WS_TAG"

SUGGESTOR_WS_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-suggestor-ws.tag)
ensure_var_defined "$SUGGESTOR_WS_TAG" "SUGGESTOR_WS_TAG"

# service name changes for the test environment
TEST_EXTRA=""
if [ $ENVIRONMENT == "test" ]; then
   TEST_EXTRA="-test"
fi

for service in availability-ws      \
               citations-ws         \
               ils-connector-ws     \
               pda-ws               \
               pool-eds-ws          \
               pool-jmrl-ws         \
               pool-solr-ws         \
               pool-worldcat-ws     \
               search-ws            \
               shelf-browse-ws      \
               suggestor-ws         \
               virgo4-client; do

   # ensure we use the correct tag file
   case $service in

     availability-ws)
        TAG=$AVAILABILITY_WS_TAG
        ENDPOINT=https://${service}${TEST_EXTRA}.internal.lib.virginia.edu
        ;;

     citations-ws)
        TAG=$CITATIONS_WS_TAG
        ENDPOINT=https://${service}${TEST_EXTRA}.internal.lib.virginia.edu
        ;;

     # no public endpoint for the ils-connector
     #ils-connector-ws)
     #   TAG=$ILS_CONNECTOR_WS_TAG
     #   ENDPOINT=https://${service}${TEST_EXTRA}.internal.lib.virginia.edu
     #   ;;

     pda-ws)
        TAG=$PDA_WS_TAG
        ENDPOINT=https://${service}${TEST_EXTRA}.internal.lib.virginia.edu
        ;;

     pool-eds-ws)
        TAG=$POOL_EDS_WS_TAG
        ENDPOINT=https://${service}${TEST_EXTRA}.internal.lib.virginia.edu
        ;;

     pool-jmrl-ws)
        TAG=$POOL_JMRL_WS_TAG
        ENDPOINT=https://${service}${TEST_EXTRA}.internal.lib.virginia.edu
        ;;

     pool-worldcat-ws)
        TAG=$POOL_WORLDCAT_WS_TAG
        ENDPOINT=https://${service}${TEST_EXTRA}.internal.lib.virginia.edu
        ;;

     pool-solr-ws)
        TAG=$POOL_SOLR_WS_TAG
        for pool in archival \
                    catalog \
                    hathitrust \
                    images     \
                    maps       \
                    music-recordings \
                    musical-scores   \
                    serials          \
                    sound-recordings \
                    thesis           \
                    uva-library      \
                    video; do
           ENDPOINT=https://${service}-${pool}${TEST_EXTRA}.internal.lib.virginia.edu
           $WAIT_TOOL $ENDPOINT $TAG 300
           res=$?
           exit_on_error $res "Failed to get correct version for $service-${pool}"
        done
        continue
        ;;

     search-ws)
        TAG=$SEARCH_WS_TAG
        ENDPOINT=https://${service}${TEST_EXTRA}.internal.lib.virginia.edu
        ;;

     shelf-browse-ws)
        TAG=$SHELF_BROWSE_WS_TAG
        ENDPOINT=https://${service}${TEST_EXTRA}.internal.lib.virginia.edu
        ;;

     suggestor-ws)
        TAG=$SUGGESTOR_WS_TAG
        ENDPOINT=https://${service}${TEST_EXTRA}.internal.lib.virginia.edu
        ;;

     virgo4-client)
        TAG=$CLIENT_WS_TAG
        ENDPOINT=https://v4${TEST_EXTRA}.lib.virginia.edu
        ;;

   esac


   $WAIT_TOOL $ENDPOINT $TAG 300
   res=$?
   exit_on_error $res "Failed to get correct version for $service"

done

# all over
exit 0

#
# end of file
#
