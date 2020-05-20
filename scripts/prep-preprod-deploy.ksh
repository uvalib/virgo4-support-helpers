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

CLONER=scripts/clone_pg_database.ksh
MIGRATOR=scripts/run-search-migrates.ksh

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
