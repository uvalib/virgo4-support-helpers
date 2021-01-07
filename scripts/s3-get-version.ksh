#
# Helper script to copy a version of a file from a specified bucket/path
#

# check command line use
if [ $# -ne 4 ]; then
   echo "use: $(basename $0) <source bucket> <source key> <version tag> <outfile>"
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

SRC_BUCKET=$1
SRC_KEY=$2
VERSION_TAG=$3
OUTFILE=$4

aws s3api get-object --bucket $SRC_BUCKET --key $SRC_KEY --version-id $VERSION_TAG $OUTFILE
exit $?

#
# end of file
#
