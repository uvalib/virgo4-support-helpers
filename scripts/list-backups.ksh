#!/usr/bin/env bash
#
# A helper to get the list of configured backups
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

TMPFILE=/tmp/backups.$$

# generate list of protected resources
$AWS_TOOL backup list-protected-resources | $JQ_TOOL -r ".Results | map([.ResourceArn, .ResourceType, .LastBackupTime] | join(\", \")) | join(\"\n\")" > $TMPFILE

# process the output
while read -r line; do

   ARN=$(echo $line | awk -F, '{print $1}' | tr -d " ")
   BACKUP_TYPE=$(echo $line | awk -F, '{print $2}' | tr -d " ")
   LAST_BACKUP=$(echo $line | awk -F, '{print $3}' | tr -d " ")

   case $BACKUP_TYPE in
   EBS)
      VOL_ID=$(echo $ARN | awk -F / '{print $2}')
      NAME_TAG=$($AWS_TOOL ec2 describe-volumes --volume-ids $VOL_ID --query "Volumes[*].{Tags:Tags}" | $JQ_TOOL .[].Tags | $JQ_TOOL -r '.[] | select(.Key == "Name") .Value')
   ;;
   EFS)
      FS_ID=$(echo $ARN | awk -F / '{print $2}')
      NAME_TAG=$($AWS_TOOL efs describe-tags --file-system-id $FS_ID | $JQ_TOOL -r '.Tags[] | select(.Key == "Name") .Value')
   ;;
   RDS)
      NAME_TAG=$($AWS_TOOL rds list-tags-for-resource --resource-name $ARN | $JQ_TOOL -r '.TagList[] | select(.Key == "Name") .Value')
   ;;
   S3)
      NAME_TAG=$(echo $ARN | awk -F: '{print $6}')
   ;;
   default)
   ;;
   esac

   printf "%03s: %-40s Last backup: %s\n" $BACKUP_TYPE $NAME_TAG $LAST_BACKUP
done < $TMPFILE

# cleanup
rm -fr $TMPFILE > /dev/null 2>&1

# all over
exit 0

#
# end of file
#
