#
# Helper script to show current rate limited IP addresses
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <global|regional>>"
}

# ensure correct usage
if [ $# -lt 1 ]; then
   show_use_and_exit
fi

# input parameters for clarity
SCOPE=$1
shift

# validate the environment parameter
case $SCOPE in
   global|regional)
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

if [ ${SCOPE} == "global" ]; then
   # global ACL ARN
   ACL_NAME=$(${AWS_TOOL} wafv2 list-web-acls --scope CLOUDFRONT | ${JQ_TOOL} -r ".WebACLs[0].Name")
   ACL_ID=$(${AWS_TOOL} wafv2 list-web-acls --scope CLOUDFRONT | ${JQ_TOOL} -r ".WebACLs[0].Id")
else
   # regional ACL ARN
   ACL_NAME=$(${AWS_TOOL} wafv2 list-web-acls --scope REGIONAL | ${JQ_TOOL} -r ".WebACLs[0].Name")
   ACL_ID=$(${AWS_TOOL} wafv2 list-web-acls --scope REGIONAL | ${JQ_TOOL} -r ".WebACLs[0].Id")
fi

CUSTOM_RULE_GROUP_NAME=waf-v2-${SCOPE}-custom-rule-group
RATE_LIMIT_RULE_NAME=waf-v2-${SCOPE}-ip-rate-limit

if [ ${SCOPE} == "global" ]; then
   SCOPE=CLOUDFRONT
else
   SCOPE=REGIONAL
fi

#--web-acl-name waf-v2-regional-acl --web-acl-id fbae1adf-8551-4e6d-9610-ac8d6ddca77f --rule-name waf-v2-regional-ip-rate-limit --rule-group-rule-name waf-v2-regional-custom-rule-group

${AWS_TOOL} wafv2 get-rate-based-statement-managed-keys --scope=${SCOPE} --web-acl-name ${ACL_NAME} --web-acl-id ${ACL_ID} --rule-group-rule-name ${CUSTOM_RULE_GROUP_NAME} --rule-name ${RATE_LIMIT_RULE_NAME}

exit $?

#
# end of file
#
