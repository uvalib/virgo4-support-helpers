#
# common helpers
#

# show the error message and exit
function error_and_exit {
   echo "$*" >&2
   exit 1
}

# exit if an error occurrs
function exit_on_error {
   local STATUS=$1
   local MESSAGE=$2
   if [ $STATUS -ne 0 ]; then
      error_and_exit "$MESSAGE"
   fi
}

# ensure a required tool is available
function ensure_tool_available {

   local TOOL_NAME=$1
   which $TOOL_NAME > /dev/null 2>&1
   res=$?
   if [ $res -ne 0 ]; then
      error_and_exit "$TOOL_NAME is not available in this environment"
   fi
}

# check our AWS environment requirements
function check_aws_environment {

   if [ -z "$AWS_ACCESS_KEY_ID" ]; then
      error_and_exit "AWS_ACCESS_KEY_ID is not defined in the environment"
   fi
   if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
      error_and_exit "AWS_SECRET_ACCESS_KEY is not defined in the environment"
   fi
   if [ -z "$AWS_DEFAULT_REGION" ]; then
      error_and_exit "AWS_DEFAULT_REGION is not defined in the environment"
   fi
}

#
# end of fle
#
