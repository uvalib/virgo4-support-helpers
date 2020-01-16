#
# Helper to send a notify for all objects in the supplied file
#

#set -x

# check command line use
if [ $# -lt 2 ]; then
   echo "use: $(basename $0) <input file> <sleep seconds>"
   exit 1
fi

INPUT_FILE=$1
SLEEP_TIME=$2

if [ ! -f $INPUT_FILE ]; then
   echo "ERROR: $INPUT_FILE is not available, aborting"
   exit 1
fi

# tool definition
TOOL=../virgo4-file-notify/bin/virgo4-file-notify.darwin
if [ ! -x $TOOL ]; then
   echo "ERROR: $TOOL is not available, aborting"
   exit 1
fi

# process each item
for obj in $(<$INPUT_FILE); do

   # assume the object is the bucket name followed bu the key
   BUCKET=$(echo $obj | awk -F/ '{print $1}')
   KEY=${obj#$BUCKET/}

   # extract the environment from the bucket name
   ENVIRONMENT=$(echo $BUCKET | awk -F- '{print $3}')

   # build the notify queue based on the things we know
   ASSET_TYPE=$(echo $KEY | awk -F/ '{print $1}')
   NOTIFY_QUEUE=virgo4-ingest-$ASSET_TYPE-notify-$ENVIRONMENT

   # do the notify
   $TOOL --bucket $BUCKET --key $KEY --outqueue $NOTIFY_QUEUE
   res=$?

   if [ $res -ne 0 ]; then
      echo "ERROR: $TOOL returns $res, aborting"
      exit $res
   fi

   if [ "$SLEEP_TIME" != "0" ]; then
      sleep $SLEEP_TIME
   fi
done

exit 0

#
# end of file
#
