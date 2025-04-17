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
TAG_DIRECTORY=$(realpath $1)
shift
TERRAFORM_ASSETS=$(realpath $1)
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

# disabled because we sometimes operate using roles
# check our environment requirements
# check_aws_environment

# ensure we have the necessary tools available
TERRAFORM_TOOL=terraform
ensure_tool_available $TERRAFORM_TOOL

# ensure the tag location exists
ensure_dir_exists $TAG_DIRECTORY/tags

# ensure the terraform asset environment exists
ensure_dir_exists $TERRAFORM_ASSETS/virgo4.lib.virginia.edu

# get our version tags
CITATIONS_WS_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-citations-ws.tag)
ensure_var_defined "$CITATIONS_WS_TAG" "CITATIONS_WS_TAG"

COLLECTIONS_WS_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-collections-ws.tag)
ensure_var_defined "$COLLECTIONS_WS_TAG" "COLLECTIONS_WS_TAG"

CLIENT_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-client.tag)
ensure_var_defined "$CLIENT_TAG" "CLIENT_TAG"

ILS_CONNECTOR_TAG=$(cat $TAG_DIRECTORY/tags/ils-connector-ws.tag)
ensure_var_defined "$ILS_CONNECTOR_TAG" "ILS_CONNECTOR_TAG"

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

# capture the commit tag or happy log message
if [ $LIVE_RUN == true ]; then
   cd $TERRAFORM_ASSETS
   git rev-parse HEAD > $TAG_DIRECTORY/tags/terraform-infrastructure.hash
else
   echo "Dry running... add \"y\" to the command line to actually deploy"
fi

BASE_DIR=$TERRAFORM_ASSETS/virgo4.lib.virginia.edu/ecs-tasks/production

for service in citations-ws         \
               collections-ws       \
               ils-connector        \
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

     citations-ws)
        TAG=$CITATIONS_WS_TAG
        ;;

     collections-ws)
        TAG=$COLLECTIONS_WS_TAG
        ;;

     ils-connector)
        TAG=$ILS_CONNECTOR_TAG
        ;;

     pda-ws)
        TAG=$PDA_WS_TAG
        ;;

     pool-eds-ws)
        TAG=$POOL_EDS_WS_TAG
        ;;

     pool-jmrl-ws)
        TAG=$POOL_JMRL_WS_TAG
        ;;

     pool-worldcat-ws)
        TAG=$POOL_WORLDCAT_WS_TAG
        ;;

     pool-solr-ws)
        TAG=$POOL_SOLR_WS_TAG
        ;;

     search-ws)
        TAG=$SEARCH_WS_TAG
        ;;

     shelf-browse-ws)
        TAG=$SHELF_BROWSE_WS_TAG
        ;;

     suggestor-ws)
        TAG=$SUGGESTOR_WS_TAG
        ;;

     virgo4-client)
        TAG=$CLIENT_TAG
        ;;

   esac

   printf "Deploying %18s: %s\n" $service $TAG

   if [ $LIVE_RUN == true ]; then

      cd $BASE_DIR/$service
      exit_on_error $? "$service asset directory missing"

      $TERRAFORM_TOOL init --upgrade
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
