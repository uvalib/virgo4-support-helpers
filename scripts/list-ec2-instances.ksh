#
# Helper script to list the EC2 instances for the account.
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

# disabled because we sometimes operate using roles
# check our environment requirements
# check_aws_environment

# temp files
TMPFILE1=/tmp/ec2-tags1.$$
TMPFILE2=/tmp/ec2-tags2.$$
TMPFILE3=/tmp/ec2-tags3.$$

# ensure we have the necessary tools available
AWS_TOOL=aws
ensure_tool_available $AWS_TOOL
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL

# get the instance details
${AWS_TOOL} ec2 describe-instances > ${TMPFILE1}

# get a list of Instance ID's
cat ${TMPFILE1} | ${JQ_TOOL} -r ".Reservations[].Instances[].InstanceId" > ${TMPFILE2}

for i in $(<${TMPFILE2}); do
   cat ${TMPFILE1} | ${JQ_TOOL} -r ".Reservations[].Instances[] | select( .InstanceId == \"${i}\")" | ${JQ_TOOL} -r ".Tags[] | select( .Key == \"Name\" or .Key == \"ImageName\")" > ${TMPFILE3}
   NAME=$(cat ${TMPFILE3} | grep -a1 "\"Name" | tail -1 | awk -F: '{print $2}' | tr -d "\"" | sed -e 's/^ //g')
   IMAGE=$(cat ${TMPFILE3} | grep -a1 "ImageName" | tail -1 | awk -F: '{print $2}' | tr -d "\"" | sed -e 's/^ //g')
   echo "${NAME} (${IMAGE})"
done | sort

# remove tmp files
rm -fr ${TMPFILE1} > /dev/null 2>&1
rm -fr ${TMPFILE2} > /dev/null 2>&1
rm -fr ${TMPFILE3} > /dev/null 2>&1

# all over
exit 0

#
# end of file
#
