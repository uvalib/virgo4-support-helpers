#!/usr/bin/env bash
#
# A helper to deploy the search preproduction environment based on the current version tags
#

#set -x

function show_use_and_exit {
   echo "use: $(basename $0) <tag directory> <terraform directory> [deploy=\"y\"]" >&2
   exit 1
}

# show the error message and exit
function error_and_exit {
   echo "$*" >&2
   exit 1
}

# exit if an error occurrs
function exit_on_error {
   local STATUS=$1
   local MESSAGE=$2
   if [ $STATUS -ne 0 ]; then
      error_and_exit "$MESSAGE"
   fi
}

# ensure our build tags are defined
function ensure_tag_defined {
   local TAG_VALUE=$1
   local TAG_NAME=$2
   if [ -z "$TAG_VALUE" ]; then
      error_and_exit "$TAG_NAME is not defined"
   fi
}

# ensure a required tool is available
function ensure_tool_available {

   local TOOL_NAME=$1
   which $TOOL_NAME > /dev/null 2>&1
   res=$?
   if [ $res -ne 0 ]; then
      error_and_exit "$TOOL_NAME is not available in this environment"
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
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
   error_and_exit "AWS_ACCESS_KEY_ID is not defined in the environment"
fi
if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
   error_and_exit "AWS_SECRET_ACCESS_KEY is not defined in the environment"
fi
if [ -z "$AWS_DEFAULT_REGION" ]; then
   error_and_exit "AWS_DEFAULT_REGION is not defined in the environment"
fi

# ensure we have the necessary tools available
TERRAFORM_TOOL=terraform
ensure_tool_available $TERRAFORM_TOOL

# ensure the tag location exists
if [ ! -d $TAG_DIRECTORY/tags ]; then
   error_and_exit "$TAG_DIRECTORY/tags is not available"
fi

# ensure the terraform asset environment exists
if [ ! -d $TERRAFORM_ASSETS/virgo4.lib.virginia.edu ]; then
   error_and_exit "$TERRAFORM_ASSETS/virgo4.lib.virginia.edu is not available"
fi

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
