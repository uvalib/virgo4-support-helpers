set -x

TMPFILE1=/tmp/ids1.$$
TMPFILE2=/tmp/ids2.$$
rm -f $TMPFILE1 > /dev/null 2>&1
rm -f $TMPFILE2 > /dev/null 2>&1

RESULTS1=/tmp/sirsi.ids
RESULTS2=/tmp/hathi.ids
rm -f $RESULTS1 > /dev/null 2>&1
rm -f $RESULTS2 > /dev/null 2>&1

SOLR_REPLICA=http://virgo4-solr-staging-replica-0-private.internal.lib.virginia.edu:8080
#SOLR_REPLICA=http://v4-solr-production-replica-0-private.internal.lib.virginia.edu:8080

echo "Getting sirsi items..."
curl "$SOLR_REPLICA/solr/test_core/select?fl=id&fq=data_source_f%3Asirsi&rows=10000000" > $TMPFILE1 2>/dev/null

echo "Getting hathi items..."
curl "$SOLR_REPLICA/solr/test_core/select?fl=id&fq=data_source_f%3Ahathitrust&rows=10000000" >> $TMPFILE2 2>/dev/null

echo "Filtering..."
cat $TMPFILE1 | grep "\"id\":" | awk -F: '{print $2}' | tr -d "\",}]" | sort > $RESULTS1
cat $TMPFILE2 | grep "\"id\":" | awk -F: '{print $2}' | tr -d "\",}]" | sort > $RESULTS2

echo $RESULTS1
echo $RESULTS2

rm -f $TMPFILE1 > /dev/null 2>&1
rm -f $TMPFILE2 > /dev/null 2>&1
