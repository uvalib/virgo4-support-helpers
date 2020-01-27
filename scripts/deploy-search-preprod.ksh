#!/usr/bin/env bash
#
# A helper to deploy the search preproduction environment based on the current version tags
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <tag directory> <terraform directory> [deploy=\"y\"]"
}

# ensure our build tags are defined
function ensure_tag_defined {
   local TAG_VALUE=$1
   local TAG_NAME=$2
   if [ -z "$TAG_VALUE" ]; then
      error_and_exit "$TAG_NAME is not defined"
   fi
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
TAG_DIRECTORY=$1
shift
TERRAFORM_ASSETS=$1
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

# check our environment requirements
check_aws_environment

# ensure we have the necessary tools available
TERRAFORM_TOOL=terraform
ensure_tool_available $TERRAFORM_TOOL

# ensure the tag location exists
ensure_dir_exists $TAG_DIRECTORY/tags

# ensure the terraform asset environment exists
ensure_dir_exists $TERRAFORM_ASSETS/virgo4.lib.virginia.edu

# get our version tags
ILS_CONNECTOR_WS_TAG=$(cat $TAG_DIRECTORY/tags/ils-connector.tag)
ensure_tag_defined "$ILS_CONNECTOR_WS_TAG" "ILS_CONNECTOR_WS_TAG"

CLIENT_WS_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-client.tag)
ensure_tag_defined "$CLIENT_WS_TAG" "CLIENT_WS_TAG"

SEARCH_WS_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-search-ws.tag)
ensure_tag_defined "$SEARCH_WS_TAG" "SEARCH_WS_TAG"

POOL_EDS_WS_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-pool-eds-ws.tag)
ensure_tag_defined "$POOL_EDS_WS_TAG" "POOL_EDS_WS_TAG"

POOL_SOLR_WS_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-pool-solr-ws.tag)
ensure_tag_defined "$POOL_SOLR_WS_TAG" "POOL_SOLR_WS_TAG"

BASE_DIR=$(realpath $TERRAFORM_ASSETS)/virgo4.lib.virginia.edu/ecs-tasks/production

for service in ils-connector-ws \
            virgo4-client \
            search-ws \
            pool-eds-ws \
            pool-solr-ws; do

   # ensure we use the correct tag file
   case $service in

     ils-connector-ws)
        TAG=$ILS_CONNECTOR_WS_TAG
        ;;

     search-ws)
        TAG=$SEARCH_WS_TAG
        ;;

     pool-eds-ws)
        TAG=$POOL_EDS_WS_TAG
        ;;

     pool-solr-ws)
        TAG=$POOL_SOLR_WS_TAG
        ;;

     virgo4-client)
        TAG=$CLIENT_WS_TAG
        ;;

   esac

   cd $BASE_DIR/$service
   exit_on_error $? "$service asset directory missing"

   echo "Deploy $service at $TAG..."

   if [ $LIVE_RUN == true ]; then
      $TERRAFORM_TOOL workspace select test
      exit_on_error $? "$service test workspace unavailable"

      $TERRAFORM_TOOL apply --var container_tag=$TAG
      res=$?

      $TERRAFORM_TOOL workspace select default
      exit_on_error $? "$service test workspace unavailable"

      exit_on_error $res "$service create failed"
   fi

done

# all over
exit 0

#
# end of file
#
