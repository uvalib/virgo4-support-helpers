#
# Helper to disable the inbound listener services. USE WITH CARE
#

#set -x

# check command line use
if [ $# -ne 1 ]; then
   echo "use: $(basename $0) <staging|production>"
   exit 1
fi

ENVIRONMENT=$1
case $ENVIRONMENT in
   staging|production)
   ;;

   *) echo "ERROR: specify staging or production, aborting"
   exit 1
   ;;
esac

# infrastructure location definition
TERRAFORM_REPO=../terraform-infrastructure
if [ ! -d $TERRAFORM_REPO ]; then
   echo "ERROR: $TERRAFORM_REPO is not available, aborting"
   exit 1
fi

# prompt to be sure
echo -n "Disabling inbound listeners in $ENVIRONMENT... ARE YOU SURE? [yes/no] "
read x
if [ "$x" != "yes" ]; then
  echo "Aborted"
  exit 1
fi

CWD=$(pwd)

# for each service
for service in virgo4-default-doc-delete    \
               virgo4-default-doc-ingest    \
               virgo4-dynamic-marc-ingest   \
               virgo4-hathi-cache-reprocess \
               virgo4-hathi-marc-ingest     \
               virgo4-image-doc-delete      \
               virgo4-image-doc-ingest      \
               virgo4-sirsi-cache-reprocess \
               virgo4-sirsi-marc-ingest; do


   cd $TERRAFORM_REPO/virgo4.lib.virginia.edu/ecs-tasks/$ENVIRONMENT/$service
   res=$?
   if [ $res -ne 0 ]; then
      echo "ERROR: move to directory failed, aborting"
      exit $res
   fi

   # destroy the task
   terraform destroy --target=aws_ecs_service.task
   res=$?
   if [ $res -ne 0 ]; then
      echo "ERROR: terraform destroy failed, aborting"
      exit $res
   fi

   cd $CWD

done

exit 0

#
# end of file
#
