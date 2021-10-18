#!/usr/bin/env bash
#
# A helper to get the list of ECR repository names.
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

# disabled because we sometimes operate using roles
# check our environment requirements
# check_aws_environment

# ensure we have the necessary tools available
AWS_TOOL=aws
ensure_tool_available $AWS_TOOL

# get the list of projects
$AWS_TOOL ecr describe-repositories --region $AWS_DEFAULT_REGION | grep "repositoryName" | awk -F\" '{printf " %s\n", $4}' | sort
exit_on_error $? "Error getting ECR repository names"

echo "Terminating normally"

# all over
exit 0

#
# end of file
#
