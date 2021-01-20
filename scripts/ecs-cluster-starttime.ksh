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
   error_and_exit "use: $(basename $0) <uva|lic> <staging|test|production|global>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
CLUSTER=$1
shift
ENVIRONMENT=$1
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
SERVICE_LIST=$SCRIPT_DIR/ecs-service-list.ksh
ensure_tool_available $SERVICE_LIST
GET_START=$SCRIPT_DIR/ecs-service-starttime.ksh
ensure_tool_available $GET_START

# temp file
services=/tmp/services.$$
times=/tmp/times.$$

# get a list of services
echo "Getting running services..."
$SERVICE_LIST $CLUSTER $ENVIRONMENT | grep " =>" | awk '{print $2}' | sed -e "s/-$ENVIRONMENT//g" > $services

echo "Getting service start times..."
for s in $(<$services); do
   echo $s
   $GET_START $CLUSTER $ENVIRONMENT $s| grep -v "OK"
done > $times

# filter for services that have multiple container instances running
for line in $(<$times); do

  REGEX="^202"
  if [[ $line =~ $REGEX ]]; then
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
