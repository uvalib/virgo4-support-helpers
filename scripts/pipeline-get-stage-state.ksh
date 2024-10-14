#!/usr/bin/env bash
#
# A helper to get the state of a specific pipeline stage
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <pipeline name> <pipeline stage>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
PIPELINE_NAME=$1
shift
STAGE_NAME=$1
shift

# disabled because we sometimes operate using roles
# check our environment requirements
# check_aws_environment

# ensure we have the necessary tools available
AWS_TOOL=aws
ensure_tool_available $AWS_TOOL
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL

$AWS_TOOL codepipeline get-pipeline-state --name $PIPELINE_NAME | ${JQ_TOOL} ".stageStates[] | select(.stageName == \"$STAGE_NAME\") | .inboundTransitionState.enabled"
res=$?
exit_on_error $res "ERROR getting pipeline state for $PIPELINE_NAME/$STAGE_NAME"

# all over
exit 0

#
# end of file
#
