#
# Helper script to list the EBS volumes for the account.
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

TMPFILE1=/tmp/ebs-volumes1.$$
TMPFILE2=/tmp/ebs-volumes2.$$
TMPFILE3=/tmp/ebs-volumes3.$$
rm -fr $TMPFILE1 > /dev/null 2>&1
rm -fr $TMPFILE2 > /dev/null 2>&1
rm -fr $TMPFILE3 > /dev/null 2>&1

# get the list of EBS volumes
$AWS_TOOL ec2 describe-volumes --region $AWS_DEFAULT_REGION > $TMPFILE1

# create a list of volumes
$JQ_TOOL -r ".Volumes[] .VolumeId" $TMPFILE1 > $TMPFILE2

# get results for each volume
for vol_id in $(<$TMPFILE2); do

   # details for each volume
   $JQ_TOOL ".Volumes[] | select(.VolumeId==\"$vol_id\")" $TMPFILE1 > $TMPFILE3

   # select based on presence of the tags
   $JQ_TOOL ". | \"==> \(.VolumeId) (\(.State)) \(select(.Tags != null) | .Tags[] | select(.Key==\"Name\") | .Value)\"" $TMPFILE3 | tr -d "\""
   $JQ_TOOL ". | \"==> \(.VolumeId) (\(.State)) \(select(.Tags == null) | \"UNKNOWN\")\"" $TMPFILE3 | tr -d "\""
done

# cleanup
rm -fr $TMPFILE1 > /dev/null 2>&1
rm -fr $TMPFILE2 > /dev/null 2>&1
rm -fr $TMPFILE3 > /dev/null 2>&1

# all over
echo "Terminating normally"
exit 0

#
# end of file
#
