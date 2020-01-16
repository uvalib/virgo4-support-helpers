#
# Helper script to list the contents of a specified bucket/path
#

if [ $# -ne 1 ]; then
   echo "use: $(basename $0) <bucket/path>"
   exit 1
fi

BUCKET_PATH=$1
aws s3 ls --recursive s3://${BUCKET_PATH}

exit $?

#
# end of file
#
