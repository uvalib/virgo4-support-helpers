#!/usr/bin/env bash
#
# A helper to get the name of all enabled pipelines
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) [enabled|disabled]"
}

# ensure correct usage
if [ $# -lt 1 ]; then
   show_use_and_exit
fi

REQUIRED_STATE=$1
shift

case $REQUIRED_STATE in
   enabled) ENABLED_STATE=true
   ;;

   disabled) ENABLED_STATE=false
   ;;

   *) show_use_and_exit
   ;;
esac

# disabled because we sometimes operate using roles
# check our environment requirements
# check_aws_environment

# ensure we have the necessary tools available
PIPELINE_LIST_TOOL=$SCRIPT_DIR/pipeline-names.ksh
ensure_file_exists $PIPELINE_LIST_TOOL
PIPELINE_STATE_TOOL=$SCRIPT_DIR/pipeline-get-stage-state.ksh
ensure_file_exists $PIPELINE_STATE_TOOL

NAMES=/tmp/pipeline-names.$$

$PIPELINE_LIST_TOOL > $NAMES
res=$?
exit_on_error $res "Terminating with status $res"

for name in $(<$NAMES); do

   state=$($PIPELINE_STATE_TOOL $name Build)

   if [ "$state" == "$ENABLED_STATE" ]; then
     echo "$name"
   fi

done

rm -fr $NAMES > /dev/null 2>&1

# all over
exit 0

#
# end of file
#
