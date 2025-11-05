#
# Helper script to restart tasks in a cluster that have not been restarted since a time
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <staging|test|production> <later than (YYYY-MM-DDTHH:MM:SS)> [y]>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
ENVIRONMENT=$1
shift
LATER_THAN=$1
shift
DO_IT=$1
shift

# validate the environment parameter
case $ENVIRONMENT in
   staging|test|production)
      ;;
   *) echo "ERROR: specify staging, test or production, aborting"
   exit 1
   ;;
esac

# validate supplied date/time
LATER_THAN_SECS=$(date -j -f "%Y-%m-%dT%H:%M:%S" ${LATER_THAN} +%s 2>/dev/null)
if [ -z "${LATER_THAN_SECS}" ]; then
   echo "Invalid date format. Must be YYYY-MM-DDTHH:MM:SS"
   exit 1
fi

# disabled because we sometimes operate using roles
# check our environment requirements
# check_aws_environment

# ensure we have the necessary tools available
SERVICE_STARTTIME=$SCRIPT_DIR/ecs-cluster-starttime.ksh
ensure_tool_available ${SERVICE_STARTTIME}
SERVICE_RESTART=$SCRIPT_DIR/ecs-service-restart.ksh
ensure_tool_available ${SERVICE_RESTART}

# ignore these services, we should not automatically restart them
IGNORE=( "analytics" "circdata-solr" "dataverse-solr" "fedora-avalon" "fedora-libra" "libra-easystore" "solr-01" "solr-02" "solr-03" "solr-04" "teamcity" "teamcity-agent" "vah-analytics")

SERVICE_LIST=/tmp/list.$$
${SERVICE_STARTTIME} uva ${ENVIRONMENT} | egrep -v "Getting|Terminating" > ${SERVICE_LIST}

# process the output
while read -r line; do

  START_TIME=$(echo ${line} | cut -c 1-19)
  SERVICE=$(echo ${line} | cut -c 36-)

  START_TIME_SECS=$(date -j -f "%Y-%m-%dT%H:%M:%S" ${START_TIME} +%s 2>/dev/null)
  if [ ${LATER_THAN_SECS} -gt ${START_TIME_SECS} ]; then

     FOUND=$(echo ${IGNORE[@]} | grep -ow "${SERVICE}" | wc -l | awk '{print $1}')
     if [ "${FOUND}" != "0" ]; then
        echo "IGNORING ${SERVICE} (started at ${START_TIME})"
     else
        
        if [ "${DO_IT}" == "y" ]; then
           echo "Restarting ${SERVICE} (started at ${START_TIME})"
           ${SERVICE_RESTART} uva ${ENVIRONMENT} ${SERVICE}
        else
           echo "Would restart ${SERVICE} (started at ${START_TIME})"
        fi
     fi

  #else
  #   echo "Unnecessary ${SERVICE} (started at ${START_TIME})"
  fi

done < ${SERVICE_LIST}

# all over
echo "Terminating normally"
exit 0

#
# end of file
#
