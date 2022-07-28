#!/usr/bin/env bash
#
# A helper to shell into a running ecs service
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <uva|lic> <staging|test|production|global> <service name> [shell (default /bin/bash)]"
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
SHELL=${1:-/bin/bash}

# validate the cluster parameter
case ${CLUSTER} in
   uva|lic)
      ;;
   *) echo "ERROR: specify uva or lic, aborting"
   exit 1
   ;;
esac

# validate the environment parameter
case ${ENVIRONMENT} in
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
ensure_tool_available ${AWS_TOOL}
JQ_TOOL=jq
ensure_tool_available ${JQ_TOOL}

# related definitions
CLUSTER_NAME=${CLUSTER}-ecs-cluster-${ENVIRONMENT}
if [ "$ENVIRONMENT" != "global" ]; then
  SERVICE_NAME=${SERVICE}-${ENVIRONMENT}
else
  SERVICE_NAME=${SERVICE}
fi

#ARN="arn:aws:ecs:${AWS_DEFAULT_REGION}:115119339709:service/${CLUSTER_NAME}/${SERVICE_NAME}"

# check that shell access is enabled
ENABLE=$(${AWS_TOOL} ecs describe-services --cluster ${CLUSTER_NAME} --services ${SERVICE_NAME} --region ${AWS_DEFAULT_REGION} | ${JQ_TOOL} -r ".services[].enableExecuteCommand")

case ${ENABLE} in
   true)
      ;;
   false) 
      echo "ERROR: shell access is not enabled for ${SERVICE_NAME}, aborting"
      exit 1
      ;;
   *) echo "ERROR: service ${SERVICE_NAME} does not exist, aborting"
      exit 1
      ;;
esac

# get the task ID
ARNS=$(${AWS_TOOL} ecs list-tasks --cluster ${CLUSTER_NAME} --service-name ${SERVICE_NAME} --region ${AWS_DEFAULT_REGION} | ${JQ_TOOL} -r ".taskArns[]")
COUNT=$(echo ${ARNS} | wc -l | awk '{print $1}')
ARN=$(echo ${ARNS} | head -1)
if [ "$COUNT" != "1" ]; then
   echo "INFO: service ${SERVICE_NAME} has multiple tasks, selecting the first one"
fi

# extract the task ID from the ARN
TASK_ID=$(echo ${ARN} | awk -F/ '{print $3}')

# exec the shell
${AWS_TOOL} ecs execute-command  \
    --region ${AWS_DEFAULT_REGION} \
    --cluster ${CLUSTER_NAME} \
    --task ${TASK_ID} \
    --container ${SERVICE_NAME} \
    --command "${SHELL} -l" \
    --interactive

# all over
exit $?

#
# end of file
#
