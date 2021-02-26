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
BACKEND_DIR=backend
PRODUCTION_DIR=production
STAGING_DIR=staging
BASE_NAME=$(basename $PWD)

function get_tag {
   local DIR=$1
   local CWD=$PWD
   cd $DIR
   local TAG=$($VERSION_HELPER)
   cd $CWD
   echo "$TAG"
}

# look for the production directory
if [ -d $PRODUCTION_DIR ]; then
   if [ -d $PRODUCTION_DIR/$BACKEND_DIR ]; then
      PRODUCTION_TAG=$(get_tag $PRODUCTION_DIR/$BACKEND_DIR)
   else
      PRODUCTION_TAG=$(get_tag $PRODUCTION_DIR)
   fi
else
   if [ -d ../../$PRODUCTION_DIR/$BASE_NAME ]; then
      if [ -d ../../$PRODUCTION_DIR/$BASE_NAME/$BACKEND_DIR ]; then
         PRODUCTION_TAG=$(get_tag ../../$PRODUCTION_DIR/$BASE_NAME/$BACKEND_DIR)
      else
         PRODUCTION_TAG=$(get_tag ../../$PRODUCTION_DIR/$BASE_NAME)
      fi
   fi
fi

if [ -d $STAGING_DIR ]; then
   if [ -d $STAGING_DIR/$BACKEND_DIR ]; then
      STAGING_TAG=$(get_tag $STAGING_DIR/$BACKEND_DIR)
   else
     STAGING_TAG=$(get_tag $STAGING_DIR)
   fi
else
   if [ -d ../../$STAGING_DIR/$BASE_NAME ]; then
      if [ -d ../../$STAGING_DIR/$BASE_NAME/$BACKEND_DIR ]; then
         STAGING_TAG=$(get_tag ../../$STAGING_DIR/$BASE_NAME/$BACKEND_DIR)
      else
         STAGING_TAG=$(get_tag ../../$STAGING_DIR/$BASE_NAME)
      fi
   fi
fi

ERROR=false
# output the info
if [ -n "$PRODUCTION_TAG" ]; then
   echo " Production: $PRODUCTION_TAG"
else
   echo "Cannot locate $PRODUCTION_DIR tag"
   ERROR=true
fi

if [ -n "$STAGING_TAG" ]; then
   echo "    Staging: $STAGING_TAG"
else
   echo "Cannot locate $STAGING_DIR tag"
   ERROR=true
fi

# error out if we cannot get one of the tags
if [ $ERROR == true ]; then
   exit 1
fi

if [ "$PRODUCTION_TAG" == "$STAGING_TAG" ]; then
   echo "Same, YAY!!"
   exit 0
fi

exit 1

#
# end of file
#
