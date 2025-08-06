#!/usr/bin/env bash
#
# A helper to set the value of a parameter
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <parameter name> <new value (as string)>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
NAME=$1
shift
VALUE=$1
shift

# disabled because we sometimes operate using roles
# check our environment requirements
# check_aws_environment

# ensure we have the necessary tools available
AWS_TOOL=aws
ensure_tool_available $AWS_TOOL
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL

# generate list of parameters
$AWS_TOOL ssm put-parameter --type String --overwrite --name ${NAME} --value ${VALUE} # | $JQ_TOOL -r .Parameter.Value

# all over
exit 0

#
# end of file
#
