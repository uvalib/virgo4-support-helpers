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
   staging|test|production)
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
UTC_END=5
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

# regional ACL ID
REGIONAL_ACL_ID=$(${AWS_TOOL} waf-regional list-web-acls | ${JQ_TOOL} -r ".WebACLs[] | select(.Name==\"waf-${ENVIRONMENT}-regional-acl\") | .WebACLId")

# global ACL ID
GLOBAL_ACL_ID=$(${AWS_TOOL} waf list-web-acls | ${JQ_TOOL} -r ".WebACLs[].WebACLId")

# regional rule ID's
REGIONAL_RATE_LIMIT_RULE_ID=$(${AWS_TOOL} waf-regional list-rate-based-rules | ${JQ_TOOL} -r ".Rules[].RuleId")
REGIONAL_IP_BLOCK_RULE_ID=$(${AWS_TOOL} waf-regional list-rules | ${JQ_TOOL} -r ".Rules[] | select(.Name==\"waf-regional-ip-block\") | .RuleId")

# global rule ID's
GLOBAL_RATE_LIMIT_RULE_ID=$(${AWS_TOOL} waf list-rate-based-rules | ${JQ_TOOL} -r ".Rules[].RuleId")
GLOBAL_IP_BLOCK_RULE_ID=$(${AWS_TOOL} waf list-rules | ${JQ_TOOL} -r ".Rules[] | select(.Name==\"waf-global-ip-block\") | .RuleId")

# maximum number of results
MAX_RESULTS=500

echo "IP rate limit ($ENVIRONMENT):"
${AWS_TOOL} waf-regional get-sampled-requests --web-acl-id $REGIONAL_ACL_ID --rule-id $REGIONAL_RATE_LIMIT_RULE_ID --max-items $MAX_RESULTS --time-window StartTime=$START_TIME,EndTime=$END_TIME > ${RATE_LIMIT_ENV_FULL}
cat ${RATE_LIMIT_ENV_FULL} | ${JQ_TOOL} -r ".SampledRequests[].Request.ClientIP" | sort | uniq -c

echo "IP block ($ENVIRONMENT):"
${AWS_TOOL} waf-regional get-sampled-requests --web-acl-id $REGIONAL_ACL_ID --rule-id $REGIONAL_IP_BLOCK_RULE_ID --max-items $MAX_RESULTS --time-window StartTime=$START_TIME,EndTime=$END_TIME > ${IP_BLOCK_ENV_FULL}
cat ${IP_BLOCK_ENV_FULL} | ${JQ_TOOL} -r ".SampledRequests[].Request.ClientIP" | sort | uniq -c

echo "IP rate limit (global):"
${AWS_TOOL} waf get-sampled-requests --web-acl-id $GLOBAL_ACL_ID --rule-id $GLOBAL_RATE_LIMIT_RULE_ID --max-items $MAX_RESULTS --time-window StartTime=$START_TIME,EndTime=$END_TIME > ${RATE_LIMIT_GLOBAL_FULL}
cat ${RATE_LIMIT_GLOBAL_FULL} | ${JQ_TOOL} -r ".SampledRequests[].Request.ClientIP" | sort | uniq -c

echo "IP block (global):"
${AWS_TOOL} waf get-sampled-requests --web-acl-id $GLOBAL_ACL_ID --rule-id $GLOBAL_IP_BLOCK_RULE_ID --max-items $MAX_RESULTS --time-window StartTime=$START_TIME,EndTime=$END_TIME > ${IP_BLOCK_GLOBAL_FULL}
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
