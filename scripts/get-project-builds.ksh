#!/usr/bin/env bash
#
# A helper to get the list of builds associated with a project
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <project name>"
}

# ensure correct usage
if [ $# -lt 1 ]; then
   show_use_and_exit
fi

# input parameters for clarity
PROJECT_NAME=$1
shift

TMPFILE1=/tmp/builds1.$$
TMPFILE2=/tmp/builds2.$$
rm -fr $TMPFILE1 > /dev/null 2>&1
rm -fr $TMPFILE2 > /dev/null 2>&1

# check our environment requirements
check_aws_environment

# ensure we have the necessary tools available
AWS_TOOL=aws
ensure_tool_available $AWS_TOOL
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL

# get the details
$AWS_TOOL ecr describe-images --repository-name $PROJECT_NAME --region $AWS_DEFAULT_REGION | $JQ_TOOL ".imageDetails[].imageTags" | sed -e 's/]$//g' | sed -e 's/\[/=====/g' | tr -d "\"," > $TMPFILE1
exit_on_error $? "Error getting details for $PROJECT_NAME"

TAG=""
BUILD=""
for line in $(<$TMPFILE1); do

   case $line in
   =====)
      if [ -n "$BUILD" ]; then
         echo "$BUILD: ${TAG:-none}" >> $TMPFILE2
      fi
      TAG=""
      BUILD=""
      ;;
   build-*)
      BUILD=$line
      ;;
   gitcommit-*)
      TAG=$line
      ;;
   default)
      ;;
   esac

done
if [ -n "$BUILD" ]; then
   echo "$BUILD: ${TAG:-none}" >> $TMPFILE2
fi

cat $TMPFILE2 | sort

rm -fr $TMPFILE1 > /dev/null 2>&1
rm -fr $TMPFILE2 > /dev/null 2>&1

# all over
echo "Terminating normally"
exit 0

#
# end of file
#
