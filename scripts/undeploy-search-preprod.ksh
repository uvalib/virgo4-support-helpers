#!/usr/bin/env bash
#
# A helper to deploy the preproduction environment based on the current version tags
#

#set -x

function show_use_and_exit {
   echo "use: $(basename $0) <terraform directory>" >&2
   exit 1
}

# show the error message and exit
function error_and_exit {
   echo "$*" >&2
   exit 1
}

# exit if an error occurrs
function exit_on_error {
   local STATUS=$1
   local MESSAGE=$2
   if [ $STATUS -ne 0 ]; then
      error_and_exit "$MESSAGE"
   fi
}

# ensure a required tool is available
function ensure_tool_available {

   local TOOL_NAME=$1
   which $TOOL_NAME > /dev/null 2>&1
   res=$?
   if [ $res -ne 0 ]; then
      error_and_exit "$TOOL_NAME is not available in this environment"
   fi
}

# ensure correct usage
if [ $# -lt 1 ]; then
   show_use_and_exit
fi

# input parameters for clarity
TERRAFORM_ASSETS=$1
shift

# check our environment requirements
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
   error_and_exit "AWS_ACCESS_KEY_ID is not defined in the environment"
fi
if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
   error_and_exit "AWS_SECRET_ACCESS_KEY is not defined in the environment"
fi
if [ -z "$AWS_DEFAULT_REGION" ]; then
   error_and_exit "AWS_DEFAULT_REGION is not defined in the environment"
fi

# ensure we have the necessary tools available
TERRAFORM_TOOL=terraform
ensure_tool_available $TERRAFORM_TOOL

# ensure the terraform asset environment exists
if [ ! -d $TERRAFORM_ASSETS/virgo4.lib.virginia.edu ]; then
   error_and_exit "$TERRAFORM_ASSETS/virgo4.lib.virginia.edu is not available"
fi

# define the location of the terraform assets for the service
BASE_DIR=$(realpath $TERRAFORM_ASSETS)/virgo4.lib.virginia.edu/ecs-tasks/production

for service in ils-connector-ws \
            virgo4-client \
            search-ws \
            pool-eds-ws \
            pool-solr-ws; do

   cd $BASE_DIR/$service
   exit_on_error $? "$service asset directory missing"

   $TERRAFORM_TOOL workspace select test
   exit_on_error $? "$service test workspace unavailable"

   $TERRAFORM_TOOL destroy
   res=$?

   # special case to ensure the generated files remain after we do a terraform destroy
   if [ $service == "pool-solr-ws" ]; then
      git checkout head *generated*
   fi

   $TERRAFORM_TOOL workspace select default
   exit_on_error $? "$service test workspace unavailable"

   exit_on_error $res "$service destroy failed"
done

# all over
exit 0

#
# end of file
#
