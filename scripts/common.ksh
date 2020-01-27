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

# ensure a directory exists
function ensure_dir_exists {
   local DIR=$1
   if [ ! -d $DIR ]; then
      error_and_exit "$DIR is not available"
   fi
}

# ensure a file exists
function ensure_file_exists {
   local FILE=$1
   if [ ! -f $FILE ]; then
      error_and_exit "$FILE is not available"
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

# extract the value of an nv pair specified in a file
function extract_nv_from_file {
   local FILE=$1
   local NAME=$2

   # ensure the input file exists
   ensure_file_exists $FILE

   # extract the content and fail as appropriate
   local CONTENT=$(grep "$NAME=" $FILE | head -1)
   if [ -z "$CONTENT" ]; then
      error_and_exit "$NAME does not exist in $FILE"
   fi

   # extract the value and fail as appropriate
   VALUE=$(echo $CONTENT | awk -F= '{print $2}')
   if [ -z "$VALUE" ]; then
      error_and_exit "cannot extract $NAME from $FILE"
   fi
   echo $VALUE
}

#
# end of fle
#
