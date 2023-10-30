#
# Helper script to list the EC2 instances for the account.
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

# disabled because we sometimes operate using roles
# check our environment requirements
# check_aws_environment

# temp file
TMPFILE=/tmp/ec2-tags.$$

# ensure we have the necessary tools available
AWS_TOOL=aws
ensure_tool_available $AWS_TOOL
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL

# get the list of instance tags
${AWS_TOOL} ec2 describe-instances | ${JQ_TOOL} -r ".Reservations[].Instances[] | .Tags[] | select( .Key == \"Name\" or .Key == \"ImageName\")" > ${TMPFILE}

while read -r line; do

   if [ "${line}" == "}" -o "${line}" == "{" ]; then
      continue
   fi

   TAG=$(echo ${line} | awk -F: '{print $2}' | tr -d "\"," | sed -e 's/^ //g')
   VALUE=${TAG}

   if [ "${TAG}" == "Name" ]; then
      NEXT=${TAG}
      continue
   else
      if [ "${TAG}" == "ImageName" ]; then
         NEXT=${TAG}
         continue
      fi 
   fi

   if [ "${NEXT}" == "Name" ]; then
      NAME=${VALUE}
   else
      if [ "${NEXT}" == "ImageName" ]; then
         IMAGE_NAME=${VALUE}
      fi
   fi


   if [ -n "${NAME}" -a -n "${IMAGE_NAME}" ]; then
      echo " ${NAME} (${IMAGE_NAME})"
      NAME=""
      IMAGE_NAME=""
   fi

done < ${TMPFILE} | sort

# remove tmp file
rm -fr ${TMPFILE} > /dev/null 2>&1

# all over
exit 0

#
# end of file
#
