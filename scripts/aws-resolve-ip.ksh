#!/usr/bin/env bash
#
# A helper to lookup an IP address in the AWS DNS
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <IP address>"
}

# ensure correct usage
if [ $# -lt 1 ]; then
   show_use_and_exit
fi

# input parameters for clarity
IP_ADDRESS=$1
shift

# disabled because we sometimes operate using roles
# check our environment requirements
# check_aws_environment

# ensure we have the necessary tools available
AWS_TOOL=aws
ensure_tool_available $AWS_TOOL
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL

HOSTED_ZONES=/tmp/dns-zones.$$
rm -fr ${HOSTED_ZONES} > /dev/null 2>&1

ZONE_RESULTS=/tmp/dns-lookup.$$
rm -fr ${ZONE_RESULTS} > /dev/null 2>&1

# create the list of hosted zones (fix me later)
echo "Z281N5AUOBFTEX" >> ${HOSTED_ZONES}             # internal.lib.virginia.edu
echo "Z3G4XE1CD9EP0E" >> ${HOSTED_ZONES}             # internal.library.virginia.edu
echo "Z0349235GICZFG1XGQM9" >> ${HOSTED_ZONES}       # private.production
echo "Z07655502CPLUEUORQNXQ" >> ${HOSTED_ZONES}      # private.staging
echo "Z06007352ENSZMTCKAQFN" >> ${HOSTED_ZONES}      # private.test
echo "Z03038201TXPHWJ1CFFOZ" >> ${HOSTED_ZONES}      # discovery.internal.lib.virginia.edu

echo -n "Looking up IP addresses... "

# for each hosted zone, get the A records
for zone in $(<${HOSTED_ZONES}); do
   # get the zone records
   ${AWS_TOOL} route53 list-resource-record-sets --hosted-zone-id ${zone} | ${JQ_TOOL} -r ".ResourceRecordSets[] | select(.Type==\"A\") | .Name, .ResourceRecords" >> ${ZONE_RESULTS}
done

echo "done"

# find the IP address if possible
grep -B3 -A2 ${IP_ADDRESS} ${ZONE_RESULTS}

rm -fr ${ZONE_RESULTS} > /dev/null 2>&1
rm -fr ${HOSTED_ZONES} > /dev/null 2>&1

# all over
exit 0

#
# end of file
#
