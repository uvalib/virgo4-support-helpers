#!/usr/bin/env bash
#
# A helper to get the list of NLB IP addresses
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

# disabled because we sometimes operate using roles
# check our environment requirements
# check_aws_environment

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <staging|test|production> [public|uvaonly]"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
ENVIRONMENT=$1
shift
SCOPE=$1
shift

# validate the environment parameter
case $ENVIRONMENT in
   staging|test|production)
   ;;

   *) show_use_and_exit
   ;;
esac

case $SCOPE in
   public|uvaonly)
   ;;

   *) show_use_and_exit
   ;;
esac

# ensure we have the necessary tools available
AWS_TOOL=aws
ensure_tool_available ${AWS_TOOL}
JQ_TOOL=jq
ensure_tool_available ${JQ_TOOL}
AWK_TOOL=awk
ensure_tool_available ${AWK_TOOL}

# get load balancer name
LB_NAME=$(${AWS_TOOL} elbv2 describe-load-balancers --names "uva-nlb-${SCOPE}-${ENVIRONMENT}" | ${JQ_TOOL} -r '.LoadBalancers[0].LoadBalancerArn' | ${AWK_TOOL} -F/ '{printf "%s/%s/%s", $2, $3, $4}')

${AWS_TOOL} ec2 describe-network-interfaces --filters Name=description,Values="ELB ${LB_NAME}" --query 'NetworkInterfaces[*].PrivateIpAddresses[*].PrivateIpAddress' --output text | sort -n

# all over
exit 0

#
# end of file
#
