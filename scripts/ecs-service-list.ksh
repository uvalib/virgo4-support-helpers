#!/usr/bin/env bash
#
# A helper to get the list of running ecs services
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <staging|test|production>"
}

# ensure correct usage
if [ $# -lt 1 ]; then
   show_use_and_exit
fi

# input parameters for clarity
ENVIRONMENT=$1
shift

# validate the environment parameter
case $ENVIRONMENT in
   staging|test|production)
      ;;
   *) echo "ERROR: specify staging, test or production, aborting"
   exit 1
   ;;
esac

# disabled because we sometimes operate using roles
# check our environment requirements
# check_aws_environment

# ensure we have the necessary tools available
AWS_TOOL=aws
ensure_tool_available $AWS_TOOL
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL

# related definitions
CLUSTER_NAME=uva-ecs-cluster-${ENVIRONMENT}
SERVICE_PREFIX=arn:aws:ecs:us-east-1:115119339709:service

# get the list of running services
$AWS_TOOL ecs list-services --cluster $CLUSTER_NAME --region $AWS_DEFAULT_REGION | $JQ_TOOL .serviceArns[] | tr -d "\"" | sed -e "s&$SERVICE_PREFIX/$CLUSTER_NAME/&&" | sort | awk '{printf " => %s\n", $1 }'

# all over
echo "Terminating normally"
exit 0

#
# end of file
#
