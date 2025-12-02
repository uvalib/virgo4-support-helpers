#!/usr/bin/env bash
#
# A helper to get a shell in the SIS drop environment
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <environment> <user>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
ENVIRONMENT=$1
shift
USER=$1
shift

# validate the environment parameter
case ${ENVIRONMENT} in
   staging)
      ENDPOINT=librasis-staging.discovery.internal.lib.virginia.edu
      ;;
   production)
      ENDPOINT=librasis-production.discovery.internal.lib.virginia.edu
      ;;
   *) echo "ERROR: specify staging, or production, aborting"
   exit 1
   ;;
esac

# ensure we have the necessary tools available
SSH_TOOL=ssh
ensure_tool_available ${SSH_TOOL}

# ensure we have the private key available
PRIVATE_KEY=${SCRIPT_DIR}/../../terraform-infrastructure/global/private-keys/${USER}.pem
ensure_file_exists ${PRIVATE_KEY}

printf %40s |tr " " "*"
echo ""
echo "WARNING ${ENVIRONMENT} !!!!!"
printf %40s |tr " " "*"
echo ""

${SSH_TOOL} -i ${PRIVATE_KEY} ${USER}@${ENDPOINT}

# all over
echo "Terminating normally"
exit 0

#
# end of file
#
