#
# helper to prepare the pre-production database environment
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

# hack, your mileage may vary
SEARCH_PROD_ENV=tmp/pg_production_search_readonly.env
SEARCH_TEST_ENV=tmp/pg_test_search.env
PDA_PROD_ENV=tmp/pg_production_pda_readonly.env
PDA_TEST_ENV=tmp/pg_test_pda.env

TERRAFORM_DIRECTORY=../terraform-infrastructure
SEARCH_PROD_DEPLOY_DIRECTORY=../virgo4-search-production-deploy

DUMPER=scripts/dump_pg_database.ksh
CLONER=scripts/clone_pg_database.ksh
MIGRATOR=scripts/run-search-migrates.ksh

# ensure out helpers exist
ensure_file_exists $DUMPER
ensure_file_exists $CLONER
ensure_file_exists $MIGRATOR

# first dump the necessary databases so we have a perminant copy
TIMESTAMP=$(date "+%Y-%m-%d-%H%M%S")
SEARCH_DUMP_NAME=$SEARCH_PROD_DEPLOY_DIRECTORY/db/$TIMESTAMP-virgo4.dump
PDA_DUMP_NAME=$SEARCH_PROD_DEPLOY_DIRECTORY/db/$TIMESTAMP-virgo4_pda.dump
$DUMPER $SEARCH_PROD_ENV $SEARCH_DUMP_NAME
exit_on_error $? "Search database dump failed"
$DUMPER $PDA_PROD_ENV $PDA_DUMP_NAME
exit_on_error $? "PDA database dump failed"
gzip $SEARCH_DUMP_NAME
exit_on_error $? "Search database dump compress failed"
gzip $PDA_DUMP_NAME
exit_on_error $? "PDA database dump compress failed"

# first clone the necessary databases
$CLONER $SEARCH_PROD_ENV $SEARCH_TEST_ENV
exit_on_error $? "Search database clone failed"
$CLONER $PDA_PROD_ENV $PDA_TEST_ENV
exit_on_error $? "PDA database clone failed"

# then run the migrates
$MIGRATOR $SEARCH_PROD_DEPLOY_DIRECTORY $TERRAFORM_DIRECTORY $SEARCH_TEST_ENV $PDA_TEST_ENV y
exit_on_error $? "Migrations failed"

#
# end of file
#
