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
   error_and_exit "use: $(basename $0) <uva|lic> <staging|test|production|global> <service name(s) ...>"
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
SERVICES=$*
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

# cluster definition
CLUSTER_NAME=${CLUSTER}-ecs-cluster-${ENVIRONMENT}

# for each service provided
for service in ${SERVICES}; do
   if [ "$ENVIRONMENT" != "global" ]; then
     SERVICE_NAME=${service}-${ENVIRONMENT}
   else
     SERVICE_NAME=${service}
   fi

   # force a new deployment of the service
   $AWS_TOOL ecs update-service --force-new-deployment --cluster $CLUSTER_NAME --service ${SERVICE_NAME} --region $AWS_DEFAULT_REGION > /dev/null
   res=$?
   if [ ${res} -ne 0 ]; then
      echo "ERROR restarting ${SERVICE_NAME}..."
   else
      echo "${SERVICE_NAME} OK"
   fi
done

# all over
exit 0

#
# end of file
#
