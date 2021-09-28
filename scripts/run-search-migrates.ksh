#!/usr/bin/env bash
#
# A helper to run the search migrations
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <tag directory> <terraform directory> <search pg env> <pda pg env> <collections pg env> [deploy=\"y\"]"
}

# ensure correct usage
if [ $# -lt 5 ]; then
   show_use_and_exit
fi

# input parameters for clarity
TAG_DIRECTORY=$1
shift
TERRAFORM_ASSETS=$1
shift
SEARCH_DATABASE_ENV=$1
shift
PDA_DATABASE_ENV=$1
shift
COLLECTIONS_DATABASE_ENV=$1
shift
LIVE_RUN=$1
shift

# ensure the tag location exists
ensure_dir_exists $TAG_DIRECTORY/tags

# ensure the terraform environment exists
ensure_dir_exists $TERRAFORM_ASSETS/scripts

# the migrate runner
MIGRATE_RUNNER=./scripts/run-container-migrate.ksh
ensure_file_exists $MIGRATE_RUNNER

# get our version tags
CLIENT_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-client.tag)
ensure_var_defined "$CLIENT_TAG" "CLIENT_TAG"
PDA_WS_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-pda-ws.tag)
ensure_var_defined "$PDA_WS_TAG" "PDA_WS_TAG"
COLLECTIONS_WS_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-collections-ws.tag)
ensure_var_defined "$COLLECTIONS_WS_TAG" "COLLECTIONS_WS_TAG"

# other definitions
CLIENT_IMAGE=uvalib/virgo4-client
PDA_WS_IMAGE=uvalib/virgo4-pda-ws
COLLECTIONS_WS_IMAGE=uvalib/virgo4-collections-ws

# if we are live running then authenticate with the ECR
if [ "$LIVE_RUN" == "y" ]; then

   # authenticate with the registry
   $TERRAFORM_ASSETS/scripts/ecr-authenticate.ksh
   res=$?
   if [ $res -ne 0 ]; then
      echo "Registry authticate FAILED"
      exit $res
   fi
fi

# run the search client migrations
IMAGE=$CLIENT_IMAGE:$CLIENT_TAG
$MIGRATE_RUNNER $IMAGE $SEARCH_DATABASE_ENV $LIVE_RUN
res=$?
if [ $res -ne 0 ]; then
   echo "Client migrate with $IMAGE FAILED"
   exit $res
fi

# run the pda migrations
IMAGE=$PDA_WS_IMAGE:$PDA_WS_TAG
$MIGRATE_RUNNER $IMAGE $PDA_DATABASE_ENV $LIVE_RUN
res=$?
if [ $res -ne 0 ]; then
   echo "PDA migrate with $IMAGE FAILED"
   exit $res
fi

# run the collections migrations
IMAGE=$COLLECTIONS_WS_IMAGE:$COLLECTIONS_WS_TAG
$MIGRATE_RUNNER $IMAGE $COLLECTIONS_DATABASE_ENV $LIVE_RUN
res=$?
if [ $res -ne 0 ]; then
   echo "Collections migrate with $IMAGE FAILED"
   exit $res
fi

# all over
echo "Terminating normally"
exit 0

#
# end of file
#
