#!/usr/bin/env bash
#
# A helper to get the list of DNS names
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname ${FULL_NAME})
. ${SCRIPT_DIR}/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename ${0}) <zone id (use list-dns-zones.ksh)>"
}

# ensure correct usage
if [ $# -lt 1 ]; then
   show_use_and_exit
fi

# input parameters for clarity
ZONE_ID=${1}
shift

# disabled because we sometimes operate using roles
# check our environment requirements
# check_aws_environment

# ensure we have the necessary tools available
AWS_TOOL=aws
ensure_tool_available ${AWS_TOOL}
JQ_TOOL=jq
ensure_tool_available ${JQ_TOOL}

# generate list of DNS names
${AWS_TOOL} route53 list-resource-record-sets --hosted-zone-id ${ZONE_ID} | ${JQ_TOOL} -r ".ResourceRecordSets[] | select(.Type==\"A\" or .Type==\"CNAME\") | .Name" | sed -e 's/\.$//g' | sort

# all over
exit 0

#
# end of file
#
