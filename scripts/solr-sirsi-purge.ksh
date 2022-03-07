#!/usr/bin/env bash
#
# A helper to purge items from Solr that are older than the supplied date.
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <staging|production> <date YYYY-MM-DDTHH:MM:SSZ>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
ENVIRONMENT=$1
shift
DATE=$1
shift

# validate the environment parameter
case $ENVIRONMENT in
   staging)
      SOLR_MASTER=http://virgo4-solr-staging-master-private.internal.lib.virginia.edu:8080
      ;;
   production)
      SOLR_MASTER=http://virgo4-solr-production-master-private.internal.lib.virginia.edu:8080
      ;;
   *) echo "ERROR: specify staging or production, aborting"
   exit 1
   ;;
esac

SOLR_URL=$SOLR_MASTER/solr/test_core
echo ""; echo ""
read -r -p "Purging $SOLR_URL older than $DATE: ARE YOU SURE? [Y/n]? " response
case "$response" in
  y|Y ) echo "Purging ${SOLR_URL}..."
  ;;
  * ) echo "Aborting..."
      exit 1
esac

PAYLOAD="<delete><query>timestamp:[* TO \"$DATE\"] AND data_source_f:sirsi</query></delete>"
SOLR_QUERY="$SOLR_URL/update?commit=true"
curl -X POST $SOLR_QUERY -H "Content-Type: text/xml" --data-binary "$PAYLOAD"
exit_on_error $? "ERROR: $? purging Solr, aborting"

# success
exit 0

#
# end of file
#
