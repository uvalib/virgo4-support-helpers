#
# Helper script to show a sample of the blocked requests in the last hour
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <within hours (1-3)>"
}

# ensure correct usage
if [ $# -lt 1 ]; then
   show_use_and_exit
fi

# input parameters for clarity
BACK_HOURS=$1
shift

case $BACK_HOURS in
   1|2|3)
   ;;

   *) show_use_and_exit
   ;;
esac

# verify environment
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
   echo "ERROR: AWS_ACCESS_KEY_ID is not definied, aborting"
   exit 1
fi
if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
   echo "ERROR: AWS_SECRET_ACCESS_KEY is not definied, aborting"
   exit 1
fi
if [ -z "$AWS_REGION" ]; then
   echo "ERROR: AWS_REGION is not definied, aborting"
   exit 1
fi

# times required in UTC
UTC_END=5
UTC_START=$(( $UTC_END - $BACK_HOURS))

# calculate our time window (convertot UTC)
START_TIME=$(date -v+${UTC_START}H +"%Y-%m-%dT%H:%M:%SZ")
END_TIME=$(date -v+${UTC_END}H +"%Y-%m-%dT%H:%M:%SZ")

# production regional_acl_id (fixed)
ACL_ID=69ebf5a1-5eaf-496d-b919-e95ed07dc3ee

# waf_regional_ip_rate_limit_rule_id (fixed)
RULE_ID=3177c7b1-36e7-449e-b06a-6dccee78d12f

# maximum number of results
MAX_RESULTS=500

aws waf-regional get-sampled-requests --web-acl-id $ACL_ID --rule-id $RULE_ID --max-items $MAX_RESULTS --time-window StartTime=$START_TIME,EndTime=$END_TIME | jq ".SampledRequests[].Request.ClientIP" | tr -d "\"" | sort | uniq -c

exit $?

#
# end of file
#
