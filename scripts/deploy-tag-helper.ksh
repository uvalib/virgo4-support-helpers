#
# helper to report the build version
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

# ensure we have the necessary tools available
TERRAFORM_TOOL=terraform
ensure_tool_available $TERRAFORM_TOOL

# get the current deploy tag
DEPLOY_TAG=$($TERRAFORM_TOOL output 2>/dev/null | grep deploy_tag | awk '{print $3}')

if [ -n "$DEPLOY_TAG" ]; then
   echo "$DEPLOY_TAG"
fi

exit 0

#
# end of file
#
