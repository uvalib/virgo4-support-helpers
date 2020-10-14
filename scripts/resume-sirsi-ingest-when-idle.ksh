#
# Helper to resume the inbound sirsi ingest services once the queues are idle. USE WITH CARE
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <staging|production>"
}

# ensure correct usage
if [ $# -lt 1 ]; then
   show_use_and_exit
fi

ENVIRONMENT=$1
case $ENVIRONMENT in
   staging|production)
   ;;

   *) echo "ERROR: specify staging or production, aborting"
   exit 1
   ;;
esac

# check our environment requirements
check_aws_environment

# check the scripts we need
QUEUE_COUNT=$SCRIPT_DIR/sqs-queue-count.ksh
ensure_file_exists $QUEUE_COUNT
RESUME_INGEST=$SCRIPT_DIR/resume-sirsi-ingest.ksh
ensure_file_exists $RESUME_INGEST

# some basic definitions
SLEEP_TIME=15
SIRSI_UPDATE_QUEUE=virgo4-ingest-default-solr-update-${ENVIRONMENT}
DOC_DELETE_QUEUE=virgo4-ingest-default-solr-delete-${ENVIRONMENT}

# wait for queues to be idle
while true; do

   echo "Checking for pending ingest data..."
   SIRSI_UPDATE_COUNT=$($QUEUE_COUNT $SIRSI_UPDATE_QUEUE)
   DOC_DELETE_COUNT=$($QUEUE_COUNT $DOC_DELETE_QUEUE)

   if [ "$SIRSI_UPDATE_COUNT" != "0" -o "$DOC_DELETE_COUNT" != "0" ]; then
      echo "Waiting, zzzzzzz..."
      sleep $SLEEP_TIME
   else
      echo "Looks like all pending ingest data is done."
      break
   fi

done

# and resume...
$RESUME_INGEST $ENVIRONMENT
exit $?

#
# end of file
#
