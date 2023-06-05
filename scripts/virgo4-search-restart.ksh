#!/usr/bin/env bash
#
# A helper to restart the virgo4 search services
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname ${FULL_NAME})
. ${SCRIPT_DIR}/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <staging|production>"
}

# ensure correct usage
if [ $# -lt 1 ]; then
   show_use_and_exit
fi

# input parameters for clarity
ENVIRONMENT=$1
shift

# validate the environment parameter
case ${ENVIRONMENT} in
   staging|production|global)
      ;;
   *) echo "ERROR: specify staging, or production, aborting"
   exit 1
   ;;
esac

# ensure we have the necessary tools available
RESTART_TOOL=${SCRIPT_DIR}/ecs-service-restart.ksh
ensure_file_exists ${RESTART_TOOL}

# define the list of services we are interested in
SERVICES="availability-ws          \
          ils-connector-ws         \
          virgo4-client            \
          virgo4-client-lite       \
          citations-ws             \
          collections-ws           \
          pda-ws                   \
          pool-eds-ws              \
          pool-jmrl-ws             \
          pool-worldcat-ws         \
          pool-solr-ws-hathitrust  \
          pool-solr-ws-images      \
          pool-solr-ws-uva-library \
          search-ws                \
          shelf-browse-ws          \
          suggestor-ws"

# for each service
for service in ${SERVICES}; do

   # restart the service
   ${RESTART_TOOL} uva ${ENVIRONMENT} ${service}
   res=$?
   if [ ${res} -ne 0 ]; then
      exit ${res}
   fi

done

echo "Terminating normally"
exit 0

#
# end of file
#
