#
# Helper script to list the contents of a specified bucket/path
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

# check our environment requirements
check_aws_environment

# ensure we have the necessary tools available
AWS_TOOL=aws
ensure_tool_available $AWS_TOOL
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL

# get the list of running services
$AWS_TOOL s3api list-buckets | $JQ_TOOL .Buckets[] | grep Name | tr -d "\"," | sort | awk '{printf " => %s\n", $2 }'

# all over
echo "Terminating normally"
exit 0

#
# end of file
#
