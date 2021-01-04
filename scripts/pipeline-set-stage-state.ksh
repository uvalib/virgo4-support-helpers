#!/usr/bin/env bash
#
# A helper to set the state of a specific pipeline stage
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <pipeline name> <pipeline stage> [enabled|disabled]"
}

# ensure correct usage
if [ $# -lt 3 ]; then
   show_use_and_exit
fi

# input parameters for clarity
PIPELINE_NAME=$1
shift
STAGE_NAME=$1
shift
REQUIRED_STATE=$1
shift

case $REQUIRED_STATE in
   enabled|disabled)
   ;;

   *) show_use_and_exit
   ;;
esac

# disabled because we sometimes operate using roles
# check our environment requirements

# disabled because we sometimes operate using roles
# check our environment requirements
# check_aws_environment

# ensure we have the necessary tools available
AWS_TOOL=aws
ensure_tool_available $AWS_TOOL

if [ "$REQUIRED_STATE" == "disabled" ]; then
   $AWS_TOOL codepipeline disable-stage-transition --pipeline-name $PIPELINE_NAME --stage-name $STAGE_NAME --transition-type Inbound --reason "Set by $0"
else
   ACTION=enable-stage-transition
   $AWS_TOOL codepipeline enable-stage-transition --pipeline-name $PIPELINE_NAME --stage-name $STAGE_NAME --transition-type Inbound
fi

res=$?
exit_on_error $res "ERROR setting pipeline state for $PIPELINE_NAME/$STAGE_NAME"

# all over
exit 0

#
# end of file
#
