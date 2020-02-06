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
CLIENT_WS_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-client.tag)
ensure_var_defined "$CLIENT_WS_TAG" "CLIENT_WS_TAG"

ILS_CONNECTOR_WS_TAG=$(cat $TAG_DIRECTORY/tags/ils-connector.tag)
ensure_var_defined "$ILS_CONNECTOR_WS_TAG" "ILS_CONNECTOR_WS_TAG"

POOL_EDS_WS_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-pool-eds-ws.tag)
ensure_var_defined "$POOL_EDS_WS_TAG" "POOL_EDS_WS_TAG"

POOL_JMRL_WS_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-pool-jmrl-ws.tag)
ensure_var_defined "$POOL_JMRL_WS_TAG" "POOL_JMRL_WS_TAG"

POOL_SOLR_WS_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-pool-solr-ws.tag)
ensure_var_defined "$POOL_SOLR_WS_TAG" "POOL_SOLR_WS_TAG"

SEARCH_WS_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-search-ws.tag)
ensure_var_defined "$SEARCH_WS_TAG" "SEARCH_WS_TAG"

SUGGESTOR_WS_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-suggestor-ws.tag)
ensure_var_defined "$SUGGESTOR_WS_TAG" "SUGGESTOR_WS_TAG"

if [ $LIVE_RUN == false ]; then
   echo "Dry running... add \"y\" to the command line to actually deploy"
fi

BASE_DIR=$(realpath $TERRAFORM_ASSETS)/virgo4.lib.virginia.edu/ecs-tasks/production

for service in ils-connector-ws \
               pool-eds-ws      \
               pool-jmrl-ws     \
               pool-solr-ws     \
               search-ws        \
               suggestor-ws     \
               virgo4-client; do

   # ensure we use the correct tag file
   case $service in

     ils-connector-ws)
        TAG=$ILS_CONNECTOR_WS_TAG
        ;;

     pool-eds-ws)
        TAG=$POOL_EDS_WS_TAG
        ;;

     pool-jmrl-ws)
        TAG=$POOL_JMRL_WS_TAG
        ;;

     pool-solr-ws)
        TAG=$POOL_SOLR_WS_TAG
        ;;

     search-ws)
        TAG=$SEARCH_WS_TAG
        ;;

     suggestor-ws)
        TAG=$SUGGESTOR_WS_TAG
        ;;

     virgo4-client)
        TAG=$CLIENT_WS_TAG
        ;;

   esac

   echo "Deploy $service at: $TAG"

   if [ $LIVE_RUN == true ]; then

      cd $BASE_DIR/$service
      exit_on_error $? "$service asset directory missing"

      $TERRAFORM_TOOL init
      exit_on_error $? "$service init failed"

      $TERRAFORM_TOOL workspace select test
      exit_on_error $? "$service test workspace unavailable"

      $TERRAFORM_TOOL apply -auto-approve --var container_tag=$TAG
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
