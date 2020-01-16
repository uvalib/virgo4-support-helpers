#
# Helper script to list the contents of a specified bucket/path
#

# check command line use
if [ $# -ne 1 ]; then
   echo "use: $(basename $0) <bucket/path>"
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

BUCKET_PATH=$1
aws s3 ls --recursive s3://${BUCKET_PATH}

exit $?

#
# end of file
#
