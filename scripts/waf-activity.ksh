#
# Helper script to show a sample of the blocked requests in the last hour
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <staging|test|production> <within hours (1-3)>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
ENVIRONMENT=$1
shift
BACK_HOURS=$1
shift

# validate the environment parameter
case $ENVIRONMENT in
   staging)
   # staging regional_acl_id (fixed)
   REGIONAL_ACL_ID=7df0b7b6-0284-4f8a-bfa4-507645b788aa
   ;;
   test)
   # test regional_acl_id (fixed)
   REGIONAL_ACL_ID=fb9121ab-d8a1-43d5-a5ba-4b9e536d1e35
   ;;
   production)
   # production regional_acl_id (fixed)
   REGIONAL_ACL_ID=69ebf5a1-5eaf-496d-b919-e95ed07dc3ee
   ;;
   *) show_use_and_exit
   ;;
esac

case $BACK_HOURS in
   1|2|3)
   ;;

   *) show_use_and_exit
   ;;
esac

# disabled because we sometimes operate using roles
# check our environment requirements
# check_aws_environment

# ensure we have the necessary tools available
AWS_TOOL=aws
ensure_tool_available $AWS_TOOL
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL

# times required in UTC
UTC_END=4
UTC_START=$(( $UTC_END - $BACK_HOURS))

# calculate our time window (convertot UTC)
START_TIME=$(date -v+${UTC_START}H +"%Y-%m-%dT%H:%M:%SZ")
END_TIME=$(date -v+${UTC_END}H +"%Y-%m-%dT%H:%M:%SZ")
#echo "start: $START_TIME"
#echo "end:   $END_TIME"

# define detailed output files
RATE_LIMIT_GLOBAL_FULL=/tmp/rate-limit-global.txt
IP_BLOCK_GLOBAL_FULL=/tmp/ip-block-global.txt
RATE_LIMIT_ENV_FULL=/tmp/rate-limit-${ENVIRONMENT}.txt
IP_BLOCK_ENV_FULL=/tmp/ip-block-${ENVIRONMENT}.txt

# global ACL ID
GLOBAL_ACL_ID=118ef938-40e9-42ac-8f67-85166dce86e8

# regional rule ID's
REGIONAL_RATE_LIMIT_RULE_ID=3177c7b1-36e7-449e-b06a-6dccee78d12f
REGIONAL_IP_BLOCK_RULE_ID=51cccbb1-9e9d-4ad8-b21d-203e1b70b360

# global rule ID's
GLOBAL_RATE_LIMIT_RULE_ID=4a14f21d-7c92-498c-9dd0-8f6f0eca3066
GLOBAL_IP_BLOCK_RULE_ID=a640b6cf-79f4-49d5-ac8b-83e42f5b3229

# maximum number of results
MAX_RESULTS=500

echo "IP rate limit ($ENVIRONMENT):"
aws waf-regional get-sampled-requests --web-acl-id $REGIONAL_ACL_ID --rule-id $REGIONAL_RATE_LIMIT_RULE_ID --max-items $MAX_RESULTS --time-window StartTime=$START_TIME,EndTime=$END_TIME > ${RATE_LIMIT_ENV_FULL}
cat ${RATE_LIMIT_ENV_FULL} | ${JQ_TOOL} -r ".SampledRequests[].Request.ClientIP" | sort | uniq -c

echo "IP block ($ENVIRONMENT):"
aws waf-regional get-sampled-requests --web-acl-id $REGIONAL_ACL_ID --rule-id $REGIONAL_IP_BLOCK_RULE_ID --max-items $MAX_RESULTS --time-window StartTime=$START_TIME,EndTime=$END_TIME > ${IP_BLOCK_ENV_FULL}
cat ${IP_BLOCK_ENV_FULL} | ${JQ_TOOL} -r ".SampledRequests[].Request.ClientIP" | sort | uniq -c

echo "IP rate limit (global):"
aws waf get-sampled-requests --web-acl-id $GLOBAL_ACL_ID --rule-id $GLOBAL_RATE_LIMIT_RULE_ID --max-items $MAX_RESULTS --time-window StartTime=$START_TIME,EndTime=$END_TIME > ${RATE_LIMIT_GLOBAL_FULL}
cat ${RATE_LIMIT_GLOBAL_FULL} | ${JQ_TOOL} -r ".SampledRequests[].Request.ClientIP" | sort | uniq -c

echo "IP block (global):"
aws waf get-sampled-requests --web-acl-id $GLOBAL_ACL_ID --rule-id $GLOBAL_IP_BLOCK_RULE_ID --max-items $MAX_RESULTS --time-window StartTime=$START_TIME,EndTime=$END_TIME > ${IP_BLOCK_GLOBAL_FULL}
cat ${IP_BLOCK_GLOBAL_FULL} | ${JQ_TOOL} -r ".SampledRequests[].Request.ClientIP" | sort | uniq -c

echo ""
echo "Full details in:"
echo " ${RATE_LIMIT_ENV_FULL}"
echo " ${IP_BLOCK_ENV_FULL}"
echo " ${RATE_LIMIT_GLOBAL_FULL}"
echo " ${IP_BLOCK_GLOBAL_FULL}"

# define URI output files
RATE_LIMIT_GLOBAL_URI=/tmp/rate-limit-global.uri
IP_BLOCK_GLOBAL_URI=/tmp/ip-block-global.uri
RATE_LIMIT_ENV_URI=/tmp/rate-limit-${ENVIRONMENT}.uri
IP_BLOCK_ENV_URI=/tmp/ip-block-${ENVIRONMENT}.uri

# generate the list of URL's
HOSTNAMES=/tmp/hostnames.txt
cat ${RATE_LIMIT_ENV_FULL} | ${JQ_TOOL} -r ".SampledRequests[].Request | .Headers[] | select(.Name==\"host\") | .Value" > ${HOSTNAMES}
cat ${RATE_LIMIT_ENV_FULL} | ${JQ_TOOL} -r ".SampledRequests[].Request.URI" | paste -d: ${HOSTNAMES} - > ${RATE_LIMIT_ENV_URI}

cat ${RATE_LIMIT_GLOBAL_FULL} | ${JQ_TOOL} -r ".SampledRequests[].Request | .Headers[] | select(.Name==\"host\") | .Value" > ${HOSTNAMES}
cat ${RATE_LIMIT_GLOBAL_FULL} | ${JQ_TOOL} -r ".SampledRequests[].Request.URI" | paste -d: ${HOSTNAMES} - > ${RATE_LIMIT_GLOBAL_URI}

cat ${IP_BLOCK_ENV_FULL} | ${JQ_TOOL} -r ".SampledRequests[].Request | .Headers[] | select(.Name==\"Host\") | .Value" > ${HOSTNAMES}
cat ${IP_BLOCK_ENV_FULL} | ${JQ_TOOL} -r ".SampledRequests[].Request.URI" | paste -d: ${HOSTNAMES} - > ${IP_BLOCK_ENV_URI}

cat ${IP_BLOCK_GLOBAL_FULL} | ${JQ_TOOL} -r ".SampledRequests[].Request | .Headers[] | select(.Name==\"Host\") | .Value" > ${HOSTNAMES}
cat ${IP_BLOCK_GLOBAL_FULL} | ${JQ_TOOL} -r ".SampledRequests[].Request.URI" | paste -d: ${HOSTNAMES} - > ${IP_BLOCK_GLOBAL_URI}

echo ""
echo "Hostname/URI's in:"
echo " ${RATE_LIMIT_ENV_URI}"
echo " ${IP_BLOCK_ENV_URI}"
echo " ${RATE_LIMIT_GLOBAL_URI}"
echo " ${IP_BLOCK_GLOBAL_URI}"

exit $?

#
# end of file
#
