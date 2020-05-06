#!/usr/bin/env bash
#
# A helper to run the search migration for a specific tag
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <tag directory> <terraform directory> <pg env> [deploy=\"y\"]"
}

# ensure correct usage
if [ $# -lt 3 ]; then
   show_use_and_exit
fi

# input parameters for clarity
TAG_DIRECTORY=$1
shift
TERRAFORM_ASSETS=$1
shift
DATABASE_ENV=$1
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

# ensure the tag location exists
ensure_dir_exists $TAG_DIRECTORY/tags

# ensure the terraform environment exists
ensure_dir_exists $TERRAFORM_ASSETS/scripts

# ensure our pg environment exist
ensure_file_exists $DATABASE_ENV

# ensure our docker environment exists
ensure_var_defined "$DOCKER_HOST" "DOCKER_HOST"

# ensure our basic AWS definitions exists
ensure_var_defined "$AWS_REGION" "AWS_REGION"

# ensure we have the necessary tools available
DOCKER_TOOL=docker
ensure_tool_available $DOCKER_TOOL

# get our version tag
CLIENT_TAG=$(cat $TAG_DIRECTORY/tags/virgo4-client.tag)
ensure_var_defined "$CLIENT_TAG" "CLIENT_TAG"

if [ $LIVE_RUN == false ]; then
   echo "Dry running... add \"y\" to the command line to actually deploy"
fi

# extract the needed values from the database environment
DBHOST=$(extract_nv_from_file $DATABASE_ENV DBHOST)
DBPORT=$(extract_nv_from_file $DATABASE_ENV DBPORT)
DBUSER=$(extract_nv_from_file $DATABASE_ENV DBUSER)
DBPASSWD=$(extract_nv_from_file $DATABASE_ENV DBPASSWD)
DBNAME=$(extract_nv_from_file $DATABASE_ENV DBNAME)

# other definitions
REGISTRY=115119339709.dkr.ecr.us-east-1.amazonaws.com
CLIENT_IMAGE=uvalib/virgo4-client

echo "Running migration at $CLIENT_TAG against $DBHOST"

# if we are live running
if [ $LIVE_RUN == true ]; then

   # authenticate with the registry
   $TERRAFORM_ASSETS/scripts/ecr-authenticate.ksh
   res=$?
   if [ $res -ne 0 ]; then
      echo "Registry authticate FAILED"
      exit $res
   fi

   # migrate entry point
   DOCKER_ENTRY="--entrypoint /virgo4-client/scripts/migrate.sh"

   # database environment
   DOCKER_ENV="-e V4_DB_HOST=$DBHOST -e V4_DB_PORT=$DBPORT -e V4_DB_NAME=$DBNAME -e V4_DB_USER=$DBUSER -e V4_DB_PASS=$DBPASSWD"

   # run the migrate
   $DOCKER_TOOL run $DOCKER_ENTRY $DOCKER_ENV $REGISTRY/$CLIENT_IMAGE:$CLIENT_TAG
   res=$?
   if [ $res -ne 0 ]; then
      echo "Migrate process FAILED"
      exit $res
   fi
fi

echo "Terminating normally"

# all over
exit 0

#
# end of file
#
