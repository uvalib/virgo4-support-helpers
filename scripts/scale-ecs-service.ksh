#!/usr/bin/env bash
#
# A helper to scale a running ecs service
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <service name> <staging|test|production> <desired count>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
SERVICE=$1
shift
ENVIRONMENT=$1
shift
COUNT=$1
shift

# validate the environment parameter
case $ENVIRONMENT in
   staging|test|production)
      ;;
   *) echo "ERROR: specify staging, test or production, aborting"
   exit 1
   ;;
esac

# check our environment requirements
check_aws_environment

# ensure we have the necessary tools available
AWS_TOOL=aws
ensure_tool_available $AWS_TOOL

# related definitions
CLUSTER_NAME=uva-ecs-cluster-${ENVIRONMENT}
SERVICE_NAME=${SERVICE}-${ENVIRONMENT}

$AWS_TOOL ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --desired-count $COUNT > /dev/null
res=$?
exit_on_error $res "ERROR scaling $SERVICE_NAME"

# all over
echo "OK"
exit 0

#
# end of file
#
