#
# Helper script to show a sample of the blocked requests
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <global|regional> <within hours (1-3)>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
SCOPE=$1
shift
BACK_HOURS=$1
shift

# validate the environment parameter
case $SCOPE in
   global|regional)
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
TIME_WINDOW="StartTime=${START_TIME},EndTime=${END_TIME}"

# define detailed output files
CUSTOM_FULL=/tmp/wafv2-custom.txt
MANAGED_FULL=/tmp/wafv2-managed.txt

if [ ${SCOPE} == "global" ]; then
   # global ACL ARN
   ACL_ARN=$(${AWS_TOOL} wafv2 list-web-acls --scope CLOUDFRONT | ${JQ_TOOL} -r ".WebACLs[0].ARN")
else
   # regional ACL ARN
   ACL_ARN=$(${AWS_TOOL} wafv2 list-web-acls --scope REGIONAL | ${JQ_TOOL} -r ".WebACLs[0].ARN")
fi

CUSTOM_RULE_NAME=waf-v2-${SCOPE}-custom-rule-group
MANAGED_RULE_NAME=waf-v2-${SCOPE}-AWSManagedRulesCommonRuleSet

# maximum number of results
MAX_RESULTS=500

if [ ${SCOPE} == "global" ]; then
   echo "custom rule (global):"
   ${AWS_TOOL} wafv2 get-sampled-requests --web-acl-arn ${ACL_ARN} --scope=CLOUDFRONT --rule-metric-name ${CUSTOM_RULE_NAME} --max-items ${MAX_RESULTS} --time-window ${TIME_WINDOW} > ${CUSTOM_FULL}
   cat ${CUSTOM_FULL} | ${JQ_TOOL} -r ".SampledRequests | select(.Action==\"BLOCK\") | .Request.ClientIP" | sort | uniq -c

   echo "managed rule (global):"
   ${AWS_TOOL} wafv2 get-sampled-requests --web-acl-arn ${ACL_ARN} --scope=CLOUDFRONT --rule-metric-name ${MANAGED_RULE_NAME} --max-items ${MAX_RESULTS} --time-window ${TIME_WINDOW} > ${MANAGED_FULL}
   cat ${MANAGED_FULL} | ${JQ_TOOL} -r ".SampledRequests | select(.Action==\"BLOCK\") | .Request.ClientIP" | sort | uniq -c

else
   echo "custom rule (regional):"
   ${AWS_TOOL} wafv2 get-sampled-requests --web-acl-arn ${ACL_ARN} --scope=REGIONAL --rule-metric-name ${CUSTOM_RULE_NAME} --max-items ${MAX_RESULTS} --time-window ${TIME_WINDOW} > ${CUSTOM_FULL}
   cat ${CUSTOM_FULL} | ${JQ_TOOL} -r ".SampledRequests[] | select(.Action==\"BLOCK\") | .Request.ClientIP" | sort | uniq -c

   echo "managed rule (regional):"
   ${AWS_TOOL} wafv2 get-sampled-requests --web-acl-arn ${ACL_ARN} --scope=REGIONAL --rule-metric-name ${MANAGED_RULE_NAME} --max-items ${MAX_RESULTS} --time-window ${TIME_WINDOW} > ${MANAGED_FULL}
   cat ${MANAGED_FULL} | ${JQ_TOOL} -r ".SampledRequests[] | select(.Action==\"BLOCK\") | .Request.ClientIP" | sort | uniq -c

fi

echo ""
echo "Full details in:"
echo " ${CUSTOM_FULL}"
echo " ${MANAGED_FULL}"

exit 0

# define URI output files
CUSTOM_URI=/tmp/wafv2-custom-uri.txt
MANAGED_URI=/tmp/wafv2-managed-uri.txt

# generate the list of URL's
HOSTNAMES=/tmp/hostnames.txt
cat ${CUSTOM_FULL} | ${JQ_TOOL} -r ".SampledRequests[].Request | .Headers[] | select(.Name==\"Host\") | .Value" > ${HOSTNAMES}
cat ${CUSTOM_FULL} | ${JQ_TOOL} -r ".SampledRequests[].Request.URI" | paste -d: ${HOSTNAMES} - > ${CUSTOM_URI}

cat ${MANAGED_FULL} | ${JQ_TOOL} -r ".SampledRequests[].Request | .Headers[] | select(.Name==\"Host\") | .Value" > ${HOSTNAMES}
cat ${MANAGED_FULL} | ${JQ_TOOL} -r ".SampledRequests[].Request.URI" | paste -d: ${HOSTNAMES} - > ${MANAGED_URI}

echo ""
echo "Hostname/URI's in:"
echo " ${CUSTOM_URI}"
echo " ${MANAGED_URI}"

exit $?

#
# end of file
#
