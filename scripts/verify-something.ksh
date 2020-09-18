#!/bin/bash

DIR=`(cd $1; /bin/pwd)`

cat /dev/null > ~/records/all_shouldntbe.ids
cat /dev/null > ~/records/all_should_be.ids

for file in `find "$DIR" -name "$2" | sort`
do
    echo "file is $file"
    cat $file | getrecord -id > ~/records/ids.ids
    lastid=`tail -1 ~/records/ids.ids | sed -e 's/u//'`
    id=`head -1 ~/records/ids.ids | sed -e 's/u//'`
    i=$id;
    cat /dev/null >  ~/records/all_ids.ids
    while [[ i -le $lastid ]]
    do 
        echo "u$i"
        i=$(( i + 1 ))
    done > ~/records/all_ids.ids
    cat ~/records/ids.ids ~/records/all_ids.ids | sort -k1.2n | uniq -u > ~/records/no_ids.ids
    scripts/verify-in-cache.ksh ~/records/ids.ids  production env/pg_production_ingest_readonly.env ~/records/should_be.ids
    scripts/verify-not-in-cache.ksh ~/records/no_ids.ids  production env/pg_production_ingest_readonly.env ~/records/shouldntbe.ids
    cat ~/records/shouldntbe.ids >> ~/records/all_shouldntbe.ids
    cat ~/records/should_be.ids >> ~/records/all_should_be.ids
done

curl -s 'http://v4-solr-production-replica-0-private.internal.lib.virginia.edu:8080/solr/test_core/select?fl=id&q=data_source_f:sirsi&defType=lucene&rows=7000000' | egrep '"id":' | sed -e 's/.*:"//' -e 's/".*$//' | sort -k1.2n > ~/records/sirsi_ids_in_production.ids

cat ~/recordsrc/bib/data/full_dump_new/uva_0*.mrc | getrecord -id > ~/records/sirsi_ids_in_full_dump_new.ids

diff ~/records/sirsi_ids_in_production.ids ~/records/sirsi_ids_in_full_dump_new.ids | egrep '>' | sed -e 's/> //'  >  ~/records/all_should_be_solr.ids

diff ~/records/sirsi_ids_in_production.ids ~/records/sirsi_ids_in_full_dump_new.ids | egrep '<' | sed -e 's/< //'  >  ~/records/all_shouldntbe_solr.ids

