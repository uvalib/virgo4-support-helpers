#!/usr/bin/env bash
#
# A helper to restart the virgo4 ingest services
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
SERVICES="virgo4-default-doc-delete          \
          virgo4-default-doc-ingest          \
          virgo4-image-doc-delete            \
          virgo4-image-doc-ingest            \
          virgo4-dynamic-cache-reprocess     \
          virgo4-dynamic-marc-convert        \
          virgo4-dynamic-marc-ingest         \
          virgo4-hathi-cache-reprocess       \
          virgo4-hathi-marc-convert          \
          virgo4-hathi-marc-ingest           \
          virgo4-sirsi-cache-reprocess       \
          virgo4-sirsi-cache-reprocess-ws    \
          virgo4-sirsi-marc-convert          \
          virgo4-sirsi-marc-ingest           \
          virgo4-sirsi-full-marc-ingest      \
          virgo4-default-solr-delete         \
          virgo4-default-solr-update         \
          virgo4-image-solr-delete           \
          virgo4-image-solr-update           \
          virgo4-source-cache                \
          virgo4-image-tracksys-convert      \
          virgo4-image-tracksys-enrich       \
          virgo4-image-tracksys-reprocess-ws"

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
