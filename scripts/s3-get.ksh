#
# Helper script to copy a file from a specified bucket/path
#

if [ $# -ne 2 ]; then
   echo "use: $(basename $0) <source bucket/path> <destination dir>"
   exit 1
fi

SRC_PATH=$1
DST_DIR=$2
aws s3 cp s3://${SRC_PATH} ${DST_DIR}

exit $?

#
# end of file
#
