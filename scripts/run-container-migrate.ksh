#!/usr/bin/env bash
#
# A helper to run the migration for a specific container
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <container:tag> <pg env> [deploy=\"y\"]"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
CONTAINER=$1
shift
DATABASE_ENV=$1
shift
LIVE_RUN=$1

# ensure our pg environment exist
ensure_file_exists $DATABASE_ENV

# ensure our docker environment exists
ensure_var_defined "$DOCKER_HOST" "DOCKER_HOST"

# ensure our basic AWS definitions exists
ensure_var_defined "$AWS_REGION" "AWS_REGION"

# ensure we have the necessary tools available
DOCKER_TOOL=docker
#DOCKER_TOOL=docker-17.04.0
ensure_tool_available $DOCKER_TOOL

if [ "$LIVE_RUN" != "y" ]; then
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

echo "Running migration with $CONTAINER against $DBHOST:$DBPORT $DBUSER/$DBNAME"

# if we are live running
if [ "$LIVE_RUN" == "y" ]; then

   # assume we are already authenticated with the registry

   # migrate entry point (this is a hack)
   case $CONTAINER in

      *client*)
      APP_DIR=virgo4-client
      ;;

      *pda*)
      APP_DIR=virgo4-pda
      ;;

      *) error_and_exit "Cannot run migrate for this container; must be a client or pda container"
      ;;

   esac

   DOCKER_ENTRY="--entrypoint /$APP_DIR/scripts/migrate.sh"

   # database environment
   DOCKER_ENV="-e DBHOST=$DBHOST -e DBPORT=$DBPORT -e DBNAME=$DBNAME -e DBUSER=$DBUSER -e DBPASS=$DBPASSWD"

   # run the migrate
   $DOCKER_TOOL run $DOCKER_ENTRY $DOCKER_ENV $REGISTRY/$CONTAINER
   res=$?
   if [ $res -ne 0 ]; then
      echo "Migrate process FAILED"
      exit $res
   fi
fi

# all over
exit 0

#
# end of file
#
