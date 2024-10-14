#!/usr/bin/env bash
#
# A helper to get the name of all pipelines
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

$AWS_TOOL codepipeline list-pipelines | ${JQ_TOOL} -r '.pipelines[] | "\(.name), \(.pipelineType)"'
res=$?
exit_on_error $res "ERROR getting pipeline names"

# all over
exit 0

#
# end of file
#
