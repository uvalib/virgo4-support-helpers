#
# Helper script to list the versions of a specified bucket object
#

# check command line use
if [ $# -ne 2 ]; then
   echo "use: $(basename $0) <source bucket> <source key>"
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

aws s3api list-object-versions --bucket $SRC_BUCKET --prefix $SRC_KEY | jq ".Versions[] .VersionId" | tr -d "\""
exit $?

#
# end of file
#
