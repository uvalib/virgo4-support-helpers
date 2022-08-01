#!/usr/bin/env bash
#
# A helper to get the list of Route53 healthchecks
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

# disabled because we sometimes operate using roles
# check our environment requirements
# check_aws_environment

# ensure we have the necessary tools available
AWS_TOOL=aws
ensure_tool_available $AWS_TOOL
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL

# get the list of CDN's
$AWS_TOOL route53 list-health-checks | jq -r '.HealthChecks[] | "\(.Id) \(.HealthCheckConfig.FullyQualifiedDomainName)"' | awk '{printf "%-50s %s\n", $2, $1}' | sort

# all over
echo "Terminating normally"
exit 0

#
# end of file
#
