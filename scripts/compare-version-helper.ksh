#
# helper to compare staging and production the build versions
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

# some definitions
VERSION_HELPER=$SCRIPT_DIR/deploy-tag-helper.ksh
PRODUCTION_DIR=production
STAGING_DIR=staging

# look for the production directory
if [ -d $PRODUCTION_DIR ]; then
   cd $PRODUCTION_DIR
   PRODUCTION_TAG=$($VERSION_HELPER)
   cd ..
else
   if [ -d ../$PRODUCTION_DIR ]; then
      cd ../$PRODUCTION_DIR
      PRODUCTION_TAG=$($VERSION_HELPER)
      cd ../$STAGING_DIR
   fi
fi

if [ -d $STAGING_DIR ]; then
   cd $STAGING_DIR
   STAGING_TAG=$($VERSION_HELPER)
   cd ..
else
   if [ -d ../$STAGING_DIR ]; then
      cd ../$STAGING_DIR
      STAGING_TAG=$($VERSION_HELPER)
      cd ../$PRODUCTION_DIR
   fi
fi

# output the info
if [ -n "$PRODUCTION_TAG" ]; then
   echo "Production: $PRODUCTION_TAG"
else
   echo "Cannot locate $PRODUCTION_DIR tag"
fi

if [ -n "$STAGING_TAG" ]; then
   echo "Staging: $STAGING_TAG"
else
   echo "Cannot locate $STAGING_DIR tag"
fi

exit 0

#
# end of file
#
