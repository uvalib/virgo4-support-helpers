#!/usr/bin/env bash
#
# A helper to search aws logs
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <log group name> <start date/time YYYY/MM/DD HH:MM:SS> <pattern>"
}

# ensure correct usage
if [ $# -lt 3 ]; then
   show_use_and_exit
fi

# input parameters for clarity
LOG_GROUP=$1
shift
START=$1
shift
PATTERN=$1
shift

# disabled because we sometimes operate using roles
# check our environment requirements
# check_aws_environment

# ensure we have the necessary tools available
AWS_TOOL=aws
ensure_tool_available $AWS_TOOL

# convert to seconds since epoch
START_EPOCH=$(date -ujf "%Y/%m/%d %H:%M:%S" "$START" +%s)
# add 4 hours because AWS log times are GMT and the conversion assumes the time is GMT
START_EPOCH=$((START_EPOCH + 14400))
START_MILLIS=${START_EPOCH}000

$AWS_TOOL logs filter-log-events --log-group-name $LOG_GROUP --start-time $START_MILLIS --filter-pattern "$PATTERN" --output text --max-items 1000000

# all over
exit 0

#
# end of file
#
