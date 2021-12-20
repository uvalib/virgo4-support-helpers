#!/usr/bin/env bash
#
# A helper to get a list of the SQS queues
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

# related definitions
QUEUE_PREFIX=https://sqs.us-east-1.amazonaws.com/115119339709

# run the command
$AWS_TOOL sqs list-queues | $JQ_TOOL -r ".QueueUrls[]" | sed -e "s&$QUEUE_PREFIX/&&g" | awk '{printf " => %s\n", $1}'

# all over
echo "Terminating normally"
exit $?

#
# end of file
#
