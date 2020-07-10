#
# helper to stop an ECS task and destroy the associated alarms
#

#set -x

# source common helpers
FULL_NAME=$(realpath $0)
SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

# ensure we have the necessary tools available
TERRAFORM_TOOL=terraform
ensure_tool_available $TERRAFORM_TOOL

# targets to remove when stopping an ECS task
TERRAFORM_TARGETS="--target=aws_ecs_service.task --target=module.memory_utilization_alarm.aws_cloudwatch_metric_alarm.memory_alarm --target=module.cpu_alarm.aws_cloudwatch_metric_alarm.cpu_alarm"

$TERRAFORM_TOOL destroy $TERRAFORM_TARGETS

#
# end of file
#
