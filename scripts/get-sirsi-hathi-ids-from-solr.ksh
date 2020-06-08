#
# Helper to extract sirsi and hathi ID's from the appropriate SOLR instance
#

#set -x

# check command line use
if [ $# -ne 1 ]; then
   echo "use: $(basename $0) <staging|production>"
   exit 1
fi

ENVIRONMENT=$1
case $ENVIRONMENT in
   staging)
      SOLR_REPLICA=http://virgo4-solr-staging-replica-0-private.internal.lib.virginia.edu:8080
      ;;
   production)
      SOLR_REPLICA=http://v4-solr-production-replica-0-private.internal.lib.virginia.edu:8080
      ;;

   *) echo "ERROR: specify staging or production, aborting"
   exit 1
   ;;
esac

# temp file definitions
TMPFILE1=/tmp/ids1.$$
TMPFILE2=/tmp/ids2.$$
rm -f $TMPFILE1 > /dev/null 2>&1
rm -f $TMPFILE2 > /dev/null 2>&1

# result files
RESULTS1=/tmp/sirsi-$ENVIRONMENT.ids
RESULTS2=/tmp/hathi-$ENVIRONMENT.ids
rm -f $RESULTS1 > /dev/null 2>&1
rm -f $RESULTS2 > /dev/null 2>&1

echo "Getting sirsi items..."
curl "$SOLR_REPLICA/solr/test_core/select?fl=id&fq=data_source_f%3Asirsi&rows=10000000" > $TMPFILE1 2>/dev/null

echo "Getting hathi items..."
curl "$SOLR_REPLICA/solr/test_core/select?fl=id&fq=data_source_f%3Ahathitrust&rows=10000000" >> $TMPFILE2 2>/dev/null

echo "Filtering..."
cat $TMPFILE1 | grep "\"id\":" | awk -F: '{print $2}' | tr -d "\",}]" | sort > $RESULTS1
cat $TMPFILE2 | grep "\"id\":" | awk -F: '{print $2}' | tr -d "\",}]" | sort > $RESULTS2

echo "Sirst results: $RESULTS1"
echo "Hathi results: $RESULTS2"

rm -f $TMPFILE1 > /dev/null 2>&1
rm -f $TMPFILE2 > /dev/null 2>&1

exit 0

#
# end of file
#
