#!/usr/bin/env bash
#
# A helper to enable the autoscale for the specified ECS service
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <uva|lic> <staging|test|production|global> <service name>"
}

# ensure correct usage
if [ $# -lt 3 ]; then
   show_use_and_exit
fi

# input parameters for clarity
CLUSTER=$1
shift
ENVIRONMENT=$1
shift
SERVICE=$1
shift

# validate the cluster parameter
case $CLUSTER in
   uva|lic)
      ;;
   *) echo "ERROR: specify uva or lic, aborting"
   exit 1
   ;;
esac

# validate the environment parameter
case $ENVIRONMENT in
   staging|test|production|global)
      ;;
   *) echo "ERROR: specify staging, test, production or global, aborting"
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
CLUSTER_NAME=${CLUSTER}-ecs-cluster-${ENVIRONMENT}
if [ "$ENVIRONMENT" != "global" ]; then
  SERVICE_NAME=${SERVICE}-${ENVIRONMENT}
else
  SERVICE_NAME=${SERVICE}
fi

# get existing autoscale attributes
TMPFILE=/tmp/autoscale.$$
$AWS_TOOL application-autoscaling describe-scalable-targets --service-namespace ecs --resource-ids service/$CLUSTER_NAME/$SERVICE_NAME > $TMPFILE
res=$?
exit_on_error $res "ERROR getting autoscale attributes for $SERVICE_NAME, aborting"
MIN_COUNT=$($JQ_TOOL ".ScalableTargets[0].MinCapacity" $TMPFILE)
MAX_COUNT=$($JQ_TOOL ".ScalableTargets[0].MaxCapacity" $TMPFILE)
rm $TMPFILE > /dev/null 2>&1

# apply the autoscale rule
$AWS_TOOL application-autoscaling register-scalable-target --service-namespace ecs --scalable-dimension ecs:service:DesiredCount --min-capacity $MIN_COUNT --max-capacity $MAX_COUNT --resource-id service/$CLUSTER_NAME/$SERVICE_NAME --suspended-state file://$SCRIPT_DIR/ecs-autoscale-enable.json --region $AWS_DEFAULT_REGION
res=$?
exit_on_error $res "ERROR enabling autoscale for $SERVICE_NAME, aborting"

# all over
echo "OK"
exit 0

#
# end of file
#
