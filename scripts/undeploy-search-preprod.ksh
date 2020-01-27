#!/usr/bin/env bash
#
# A helper to deploy the preproduction environment based on the current version tags
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <terraform directory> [undeploy=\"y\"]"
}

# ensure correct usage
if [ $# -lt 1 ]; then
   show_use_and_exit
fi

# input parameters for clarity
TERRAFORM_ASSETS=$1
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

# check our environment requirements
check_aws_environment

# ensure we have the necessary tools available
TERRAFORM_TOOL=terraform
ensure_tool_available $TERRAFORM_TOOL

# ensure the terraform asset environment exists
ensure_dir_exists $TERRAFORM_ASSETS/virgo4.lib.virginia.edu

if [ $LIVE_RUN == false ]; then
   echo "Dry running... add \"y\" to the command line to actually undeploy"
fi

# define the location of the terraform assets for the service
BASE_DIR=$(realpath $TERRAFORM_ASSETS)/virgo4.lib.virginia.edu/ecs-tasks/production

for service in ils-connector-ws \
            virgo4-client \
            search-ws \
            pool-eds-ws \
            pool-solr-ws; do

   echo "Undeploy $service"

   if [ $LIVE_RUN == true ]; then
      cd $BASE_DIR/$service
      exit_on_error $? "$service asset directory missing"

      $TERRAFORM_TOOL init
      exit_on_error $? "$service init failed"

      $TERRAFORM_TOOL workspace select test
      exit_on_error $? "$service test workspace unavailable"

      $TERRAFORM_TOOL destroy -auto-approve
      res=$?

      # special case to ensure the generated files remain after we do a terraform destroy
      if [ $service == "pool-solr-ws" ]; then
         git checkout head *generated*
      fi

      $TERRAFORM_TOOL workspace select default
      exit_on_error $? "$service test workspace unavailable"

      exit_on_error $res "$service destroy failed"
   fi

done

# all over
exit 0

#
# end of file
#
