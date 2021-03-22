#
# helper to apply the same build version
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
DEPLOY_TAG=$($TERRAFORM_TOOL output | grep deploy_tag | awk '{print $3}' | tr -d "\"")

if [ -n "$DEPLOY_TAG" ]; then
   echo "Using existing deploy tag: $DEPLOY_TAG"
   TERRAFORM_OPTS="-var container_tag=$DEPLOY_TAG"
else
   echo "Using default deploy tag"
   TERRAFORM_OPTS=""
fi

$TERRAFORM_TOOL apply $TERRAFORM_OPTS
exit_on_error $? "Apply failed"

#
# end of file
#
