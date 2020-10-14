#
# Helper to pause the inbound sirsi ingest services. USE WITH CARE
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
DISABLE_AUTOSCALE=$SCRIPT_DIR/disable-ecs-autoscale.ksh
ensure_file_exists $DISABLE_AUTOSCALE
SCALE_SERVICE=$SCRIPT_DIR/scale-ecs-service.ksh
ensure_file_exists $SCALE_SERVICE

# disable autoscale services
for service in virgo4-sirsi-marc-ingest; do

   echo "Disabling autoscale for $service..."
   $DISABLE_AUTOSCALE $service $ENVIRONMENT
   exit_on_error $? "Disabling autoscale rule for $service"

   echo "Disabling $service..."
   $SCALE_SERVICE $service $ENVIRONMENT 0
   exit_on_error $? "Disabling $service"
done

# disable regular services
for service in virgo4-default-doc-delete; do

   echo "Disabling $service..."
   $SCALE_SERVICE $service $ENVIRONMENT 0
   exit_on_error $? "Disabling $service"
done

echo "Terminating normally"
exit 0

#
# end of file
#
