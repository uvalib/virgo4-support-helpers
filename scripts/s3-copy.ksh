#
# Helper script to copy a file to/from a specified bucket/path
#

# check command line use
if [ $# -ne 2 ]; then
   echo "use: $(basename $0) <source bucket/path> <destination bucket/path>"
   exit 1
fi

# verify environment
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
   echo "ERROR: AWS_ACCESS_KEY_ID is not definied, aborting"
   exit 1
fi
if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
   echo "ERROR: AWS_SECRET_ACCESS_KEY is not definied, aborting"
   exit 1
fi
if [ -z "$AWS_REGION" ]; then
   echo "ERROR: AWS_REGION is not definied, aborting"
   exit 1
fi

SRC_PATH=$1
DST_PATH=$2
aws s3 cp s3://${SRC_PATH} s3://${DST_PATH}

exit $?

#
# end of file
#
