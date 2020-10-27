#!/usr/bin/env bash
#
# A helper to restart a running ecs service
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <service name> <staging|test|production>"
}

# ensure correct usage
if [ $# -lt 1 ]; then
   show_use_and_exit
fi

# input parameters for clarity
SERVICE=$1
shift
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
SERVICE_NAME=${SERVICE}-${ENVIRONMENT}
ARNS_FILE=/tmp/arns.$$

# force a new deployment of the service
$AWS_TOOL ecs list-tasks --cluster $CLUSTER_NAME --service-name $SERVICE_NAME --region $AWS_DEFAULT_REGION | $JQ_TOOL ".taskArns[]" | tr -d "\"" > $ARNS_FILE
res=$?
exit_on_error $res "ERROR listing tasks for $SERVICE_NAME, aborting"

# for each ARN
for arn in $(<$ARNS_FILE); do
   $AWS_TOOL ecs describe-tasks --cluster $CLUSTER_NAME --tasks $arn | $JQ_TOOL ".tasks[].startedAt" | tr -d "\""
done

# clean up
rm -fr $ARNS_FILE > /dev/null 2>&1

# all over
echo "OK"
exit 0

#
# end of file
#
