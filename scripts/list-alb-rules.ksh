#!/usr/bin/env bash
#
# A helper to get the list of configured ALB rules
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <staging|test|production> <public-1|private-1>"
}

# ensure correct usage
if [ $# -lt 2 ]; then
   show_use_and_exit
fi

# input parameters for clarity
ENVIRONMENT=$1
shift
LOADBALANCER=$1
shift

# validate the environment parameter
case $ENVIRONMENT in
   staging|test|production)
      ;;
   *) echo "ERROR: specify staging, test or production, aborting"
   exit 1
   ;;
esac

# validate the load balancer parameter
case $LOADBALANCER in
   public-1)
      case $ENVIRONMENT in
         staging)
         ARN=arn:aws:elasticloadbalancing:us-east-1:115119339709:listener/app/uva-alb-public-staging/b84fdf912c954f2b/811b3f66a27796bc
         ;;
         test)
         ARN=arn:aws:elasticloadbalancing:us-east-1:115119339709:listener/app/uva-alb-public-test/41504b776443e385/566afda8a940c2ed
         ;;
         production)
         ARN=arn:aws:elasticloadbalancing:us-east-1:115119339709:listener/app/uva-alb-public-production/1a4abe82abeaa8b1/81a0f809438d0015
         ;;
      esac
      ;;
   private-1)
      case $ENVIRONMENT in
         staging)
         ARN=arn:aws:elasticloadbalancing:us-east-1:115119339709:listener/app/uva-alb-uvaonly-staging/61557a20b11cf279/77c2057cfe9ba4d6
         ;;
         test)
         ARN=arn:aws:elasticloadbalancing:us-east-1:115119339709:listener/app/uva-alb-uvaonly-test/b56607aa7da3bdb0/b62a96d781fae83c
         ;;
         production)
         ARN=arn:aws:elasticloadbalancing:us-east-1:115119339709:listener/app/uva-alb-uvaonly-production/b263a111ffaace49/976af6ea359ed744
         ;;
      esac
      ;;
   *) echo "ERROR: specify public-1 or private-1, aborting"
   exit 1
   ;;
esac

# disabled because we sometimes operate using roles
# check our environment requirements
# check_aws_environment

# ensure we have the necessary tools available
AWS_TOOL=aws
ensure_tool_available $AWS_TOOL
JQ_TOOL=jq
ensure_tool_available $JQ_TOOL

$AWS_TOOL elbv2 describe-rules --listener-arn $ARN | $JQ_TOOL '.Rules[] .Conditions[] | select(.Field == "host-header") .Values[]' | tr -d "\"" | awk '{ printf " ==> %s\n", $1}'

# all over
exit 0

#
# end of file
#
