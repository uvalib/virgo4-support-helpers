#!/usr/bin/env bash
#
# A helper to get the number of messages in the specified queue
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <queue name>"
}

# ensure correct usage
if [ $# -lt 1 ]; then
   show_use_and_exit
fi

# input parameters for clarity
QUEUE_NAME=$1
shift

# check our environment requirements
check_aws_environment

# ensure we have the necessary tools available
AWS_TOOL=aws
ensure_tool_available $AWS_TOOL

# related definitions
QUEUE_PREFIX=https://sqs.us-east-1.amazonaws.com/115119339709
ATTRIBUTE_NAME=ApproximateNumberOfMessages

$AWS_TOOL sqs get-queue-attributes --queue-url $QUEUE_PREFIX/$QUEUE_NAME --attribute-names $ATTRIBUTE_NAME  --region $AWS_DEFAULT_REGION | grep "$ATTRIBUTE_NAME" | awk '{ print $2}' | tr -d "\""

# all over
exit $?

#
# end of file
#
