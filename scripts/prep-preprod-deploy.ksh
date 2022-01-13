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
COLLECTIONS_PROD_ENV=tmp/pg_production_collections_readonly.env
COLLECTIONS_TEST_ENV=tmp/pg_test_collections.env

TERRAFORM_DIRECTORY=../terraform-infrastructure
SEARCH_PROD_DEPLOY_DIRECTORY=../virgo4-search-production-deploy

# our helpers
DUMPER=$SCRIPT_DIR/dump_pg_database.ksh
CLONER=$SCRIPT_DIR/clone_pg_database.ksh
MIGRATOR=$SCRIPT_DIR/run-search-migrates.ksh

# ensure our helpers exist
ensure_file_exists $DUMPER
ensure_file_exists $CLONER
ensure_file_exists $MIGRATOR

# define dump file names
SEARCH_DUMP_NAME=$SEARCH_PROD_DEPLOY_DIRECTORY/db/virgo4.dump
PDA_DUMP_NAME=$SEARCH_PROD_DEPLOY_DIRECTORY/db/virgo4_pda.dump
COLLECTIONS_DUMP_NAME=$SEARCH_PROD_DEPLOY_DIRECTORY/db/v4_collections.dump

# first dump the necessary databases so we have a perminent copy
$DUMPER $SEARCH_PROD_ENV $SEARCH_DUMP_NAME
exit_on_error $? "Search database dump failed"
$DUMPER $PDA_PROD_ENV $PDA_DUMP_NAME
exit_on_error $? "PDA database dump failed"
$DUMPER $COLLECTIONS_PROD_ENV $COLLECTIONS_DUMP_NAME
exit_on_error $? "Collections database dump failed"

# then clone the necessary databases
$CLONER $SEARCH_PROD_ENV $SEARCH_TEST_ENV
exit_on_error $? "Search database clone failed"
$CLONER $PDA_PROD_ENV $PDA_TEST_ENV
exit_on_error $? "PDA database clone failed"
$CLONER $COLLECTIONS_PROD_ENV $COLLECTIONS_TEST_ENV
exit_on_error $? "Collections database clone failed"

# then run the migrates
$MIGRATOR $SEARCH_PROD_DEPLOY_DIRECTORY $TERRAFORM_DIRECTORY $SEARCH_TEST_ENV $PDA_TEST_ENV $COLLECTIONS_TEST_ENV y
exit_on_error $? "Migrations failed"

#
# end of file
#
