#!/usr/bin/env bash
#
# A helper to get the list of alarms
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


# generate list of custom metrics
$AWS_TOOL cloudwatch describe-alarms | $JQ_TOOL -r '.MetricAlarms[] | " \(.AlarmName) ==> \(.StateValue)"'

# all over
exit 0

#
# end of file
#
