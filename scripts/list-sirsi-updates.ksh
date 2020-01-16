#
# Helper to list the non-zero Sirsi update files from the current year
#

#set -x

# check command line use
if [ $# -ne 1 ]; then
   echo "use: $(basename $0) <staging|production>"
   exit 1
fi

ENVIRONMENT=$1
case $ENVIRONMENT in
   staging|production)
   ;;

   *) echo "ERROR: specify staging or production, aborting"
   exit 1
   ;;
esac

# bucket definition
BUCKET=virgo4-ingest-$ENVIRONMENT-inbound

# year definition
YEAR=$(date "+%Y")

# tool definition
TOOL=scripts/s3-list.ksh
if [ ! -x $TOOL ]; then
   echo "ERROR: $TOOL is not available, aborting"
   exit 1
fi

# temp file definition
TMPFILE=/tmp/list-sirsi.$$

BUCKET_PATH=$BUCKET/sirsi-update/$YEAR
$TOOL $BUCKET_PATH > $TMPFILE
res=$?

if [ $res -ne 0 ]; then
   echo "ERROR: $TOOL returns $res, aborting"
   exit $res
fi

# print all non-zero length objects
cat $TMPFILE | awk '{printf "%s %s\n", $3, $4}' | grep "updates-$YEAR" | grep -v "^0" | awk -v BUCKET=$BUCKET '{printf "%s/%s\n", BUCKET, $2}'

# remove the tempfile
rm $TMPFILE > /dev/null 2>&1

exit 0

#
# end of file
#
