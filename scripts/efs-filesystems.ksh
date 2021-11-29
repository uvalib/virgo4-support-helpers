#
# Helper script to list the EFS filesystems for the account.
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

# get the list EFS filesystems
$AWS_TOOL efs describe-file-systems --region $AWS_DEFAULT_REGION | $JQ_TOOL '.FileSystems[] | "==> \(.Name) (\(.FileSystemId))"' | tr -d "\"" | sort

# all over
echo "Terminating normally"
exit 0

#
# end of file
#
