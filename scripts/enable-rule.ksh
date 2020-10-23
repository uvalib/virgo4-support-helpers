#!/usr/bin/env bash
#
# A helper to enable a named rule
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <alarm name>"
}

# ensure correct usage
if [ $# -lt 1 ]; then
   show_use_and_exit
fi

# input parameters for clarity
RULE_NAME=$1
shift

# disabled because we sometimes operate using roles
# check our environment requirements
# check_aws_environment

# ensure we have the necessary tools available
AWS_TOOL=aws
ensure_tool_available $AWS_TOOL

$AWS_TOOL events enable-rule --name $RULE_NAME --region $AWS_DEFAULT_REGION
res=$?
exit_on_error $res "ERROR disabling $RULE_NAME"

# all over
echo "OK"
exit 0

#
# end of file
#
