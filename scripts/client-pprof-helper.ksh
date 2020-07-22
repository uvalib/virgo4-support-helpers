#!/usr/bin/env bash
#
# A helper to dump the commandlines required to use for client pprof tooling.
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <staging|production> <terraform directory>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
ENVIRONMENT=$1
shift
TERRAFORM_ASSETS=$1
shift

case $ENVIRONMENT in
   staging)
   PRIVATE_ENDPOINT=virgo4-client-staging.private.staging
   ;;

   production)
   PRIVATE_ENDPOINT=virgo4-client.private.production
   ;;

   *) echo "ERROR: specify staging or production, aborting"
   exit 1
   ;;
esac

# ensure the terraform environment exists
ensure_dir_exists $TERRAFORM_ASSETS/scripts

# run the resolver
RESOLVER=$TERRAFORM_ASSETS/scripts/resolve-private.ksh
RESULTS=$($RESOLVER $PRIVATE_ENDPOINT | tr "\n" " ")

# parse results
TOKEN1=$(echo $RESULTS | awk '{print $1}' | tr -d ":")
TOKEN2=$(echo $RESULTS | awk '{print $2}')
TOKEN3=$(echo $RESULTS | awk '{print $3}')

# did we get something plausable
if [ "$PRIVATE_ENDPOINT" == "$TOKEN1" ]; then

   echo "go tool pprof ${TOKEN2}:8080/debug/pprof/heap|allocs"
   if [ -n "$TOKEN3" ]; then
      echo "go tool pprof ${TOKEN3}:8080/debug/pprof/heap|allocs"
   fi

else
   echo "ERROR: cannot resolve endpoint ($PRIVATE_ENDPOINT) correctly"
fi

# all over
exit 0

#
# end of file
#
