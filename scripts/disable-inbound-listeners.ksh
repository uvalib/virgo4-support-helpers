#
# Helper to disable the inbound listener services. USE WITH CARE
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <dynamic|hathi|sirsi> <staging|production>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
INGEST_TYPE=$1
shift
ENVIRONMENT=$1
shift

# validate input
case $INGEST_TYPE in
   dynamic|hathi|sirsi)
   ;;

   *) echo "ERROR: specify dynamic, hathi or sirsi, aborting"
   exit 1
   ;;
esac

# infrastructure location definition
case $ENVIRONMENT in
   staging|production)
   ;;

   *) echo "ERROR: specify staging or production, aborting"
   exit 1
   ;;
esac

# ensure we can access the helpers
SCALE_SERVICE_TOOL=$SCRIPT_DIR/scale-ecs-service.ksh
ensure_file_exists $SCALE_SERVICE_TOOL
DISABLE_AUTOSCALE_TOOL=$SCRIPT_DIR/disable-ecs-autoscale.ksh
ensure_file_exists $DISABLE_AUTOSCALE_TOOL

# prompt to be sure
echo -n "Disabling $INGEST_TYPE inbound listeners in $ENVIRONMENT... ARE YOU SURE? [yes/no] "
read x
if [ "$x" != "yes" ]; then
  echo "Aborted"
  exit 1
fi

# define our services
DELETE_SERVICE=virgo4-default-doc-delete
INGEST_SERVICE=virgo4-${INGEST_TYPE}-marc-ingest

# delete service is not autoscaled
$SCALE_SERVICE_TOOL "uva" $ENVIRONMENT $DELETE_SERVICE 0
exit_on_error $? "ERROR: scaling $DELETE_SERVICE to 0"

# ingest service is autoscaled
$DISABLE_AUTOSCALE_TOOL "uva" $ENVIRONMENT $INGEST_SERVICE
exit_on_error $? "ERROR: disabling autoscale for $INGEST_SERVICE"
$SCALE_SERVICE_TOOL "uva" $ENVIRONMENT $INGEST_SERVICE 0
exit_on_error $? "ERROR: scaling $INGEST_SERVICE to 0"

# its all over
exit 0

#
# end of file
#
