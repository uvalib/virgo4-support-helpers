#
# Helper script to copy a file to/from a specified bucket/path
#

if [ $# -ne 2 ]; then
   echo "use: $(basename $0) <source bucket/path> <destination bucket/path>"
   exit 1
fi

SRC_PATH=$1
DST_PATH=$2
aws s3 cp s3://${SRC_PATH} s3://${DST_PATH}

exit $?

#
# end of file
#
