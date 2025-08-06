#!/usr/bin/env bash
#
# A helper to get the list of parameters
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
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL


# generate list of parameters
$AWS_TOOL ssm describe-parameters | $JQ_TOOL -r .Parameters[].Name | sort

# all over
exit 0

#
# end of file
#
