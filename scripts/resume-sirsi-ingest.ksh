#
# Helper to resume the inbound sirsi ingest services. USE WITH CARE
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

# disabled because we sometimes operate using roles
# check our environment requirements
# check_aws_environment

# check the scripts we need
ENABLE_AUTOSCALE=$SCRIPT_DIR/enable-ecs-autoscale.ksh
ensure_file_exists $ENABLE_AUTOSCALE
SCALE_SERVICE=$SCRIPT_DIR/scale-ecs-service.ksh
ensure_file_exists $SCALE_SERVICE

# enable autoscale services
for service in virgo4-sirsi-marc-ingest; do

   echo "Enabling autoscale for $service..."
   $ENABLE_AUTOSCALE $service $ENVIRONMENT
   exit_on_error $? "Enabling autoscale rule for $service"

done

for service in virgo4-default-doc-delete; do

   echo "Restarting $service..."
   $SCALE_SERVICE $service $ENVIRONMENT 1
   exit_on_error $? "Restarting $service"

done

echo "Terminating normally"
exit 0

#
# end of file
#
