#!/usr/bin/env bash
#
# A helper to run an insights query on the solr pool logs
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <log group name> <start date/time YYYY/MM/DD HH:MM:SS> <end date/time YYYY/MM/DD HH:MM:SS>"
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
END=$1
shift

INSIGHTS_QUERY="fields @message | filter @message like /SOLR: res: header:/ | filter @message not like /ping status/ | parse @message 'QTime = * }' as @time | sort @time desc"

# disabled because we sometimes operate using roles
# check our environment requirements
# check_aws_environment

# ensure we have the necessary tools available
AWS_TOOL=aws
ensure_tool_available $AWS_TOOL
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL

# convert to seconds since epoch
START_EPOCH=$(date -ujf "%Y/%m/%d %H:%M:%S" "$START" +%s)
END_EPOCH=$(date -ujf "%Y/%m/%d %H:%M:%S" "$END" +%s)

# add 5 hours because AWS log times are GMT and the conversion assumes the time is GMT
START_EPOCH=$((START_EPOCH + 18000))
END_EPOCH=$((END_EPOCH + 18000))

# initiate the query
QID=$($AWS_TOOL logs start-query --log-group-name $LOG_GROUP --start-time $START_EPOCH --end-time $END_EPOCH --query-string "$INSIGHTS_QUERY" | $JQ_TOOL ".queryId" | tr -d "\"")

# check that we received a query id
if [ -z "$QID" ]; then
   error_and_exit "Issuing query"
fi

RESULTS=/tmp/qresults.$$

while true; do

   $AWS_TOOL logs get-query-results --query-id $QID > $RESULTS
   exit_on_error $? "Getting query results"

   # show any results
   cat $RESULTS | $JQ_TOOL ".results[]" | $JQ_TOOL ".[] | select(.field == \"@message\") .value"

   # get the status
   STATUS=$(cat $RESULTS | $JQ_TOOL ".status" | tr -d "\"")
   if [ "$STATUS" == "Running" ]; then
      sleep 2
   else
      cat $RESULTS | $JQ_TOOL ".statistics"
      break
   fi
done

rm -fr $RESULTS > /dev/null 2>&1

# all over
exit 0

#
# end of file
#
