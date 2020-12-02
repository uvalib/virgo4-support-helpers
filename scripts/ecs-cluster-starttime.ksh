#!/usr/bin/env bash
#
# A helper to get the start time of all running services
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
SERVICE_LIST=$SCRIPT_DIR/ecs-service-list.ksh
ensure_tool_available $SERVICE_LIST
GET_START=$SCRIPT_DIR/ecs-service-starttime.ksh
ensure_tool_available $GET_START

# related definitions
CLUSTER_NAME=uva-ecs-cluster-${ENVIRONMENT}

# temp file
services=/tmp/services.$$
times=/tmp/times.$$

# get a list of services
echo "Getting running services..."
$SERVICE_LIST $ENVIRONMENT | grep "=>" | awk '{print $2}' | sed -e "s/-$ENVIRONMENT//g" > $services
echo "Getting service start times..."
for s in $(<$services); do
   echo $s
   $GET_START $s $ENVIRONMENT | grep -v "OK"
done > $times

for line in $(<$times); do

  if [[ $line =~ ^2020 ]]; then
     printf "%s : %s\n" $line $SERVICE
  else
     SERVICE=$line
  fi
done | sort

rm -f $services $times > /dev/null 2>&1

# all over
echo "Terminating normally"
exit 0

#
# end of file
#
