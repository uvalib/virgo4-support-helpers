#
# Helper script to copy a file to a specified bucket/path
#

if [ $# -ne 2 ]; then
   echo "use: $(basename $0) <source file> <destination bucket/path>"
   exit 1
fi

SRC_PATH=$1
DST_PATH=$2
aws s3 cp ${SRC_PATH} s3://${DST_PATH}

exit $?

#
# end of file
#
