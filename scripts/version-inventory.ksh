#
# helper to compare staging and production service versions
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <terraform directory>"
}

# ensure correct usage
if [ $# -lt 1 ]; then
   show_use_and_exit
fi

# input parameters for clarity
TERRAFORM_ASSETS=$(realpath $1)
shift

# some definitions
COMPARE_VERSION_HELPER=$SCRIPT_DIR/compare-version-helper.ksh
SERVICE_LIST=$SCRIPT_DIR/service.list

# ensure the terraform location exists
ensure_dir_exists $TERRAFORM_ASSETS

# ensure service list exists
ensure_file_exists $SERVICE_LIST

for service in $(<$SERVICE_LIST); do

   echo "**************************************************"
   echo "* $service"
   echo "**************************************************"

   cd $TERRAFORM_ASSETS/$service
   exit_on_error $? "ERROR: $TERRAFORM_ASSETS/$service missing"

   $COMPARE_VERSION_HELPER
   #exit_on_error $? "ERROR: Running version helper"

done

# all over
exit 0

#
# end of file
#
