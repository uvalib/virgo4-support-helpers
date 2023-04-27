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

# ensure we have the necessary tools available
AWS_TOOL=aws
ensure_tool_available $AWS_TOOL
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL

# get the list of instances
${AWS_TOOL} ec2 describe-instances | ${JQ_TOOL} -r ".Reservations[].Instances[] | .Tags[] | select(.Key==\"Name\") | .Value" | sort

# all over
exit 0

#
# end of file
#
