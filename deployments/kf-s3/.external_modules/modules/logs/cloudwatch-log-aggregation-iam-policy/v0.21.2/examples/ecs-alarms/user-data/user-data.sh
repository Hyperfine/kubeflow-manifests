#!/bin/bash
#
# This script configures an EC2 Instance so it registers in the specified ECS cluster. It assumes it is running on an
# ECS Optimized Amazon Linux AMI.

set -e

echo "ECS_CLUSTER=${ecs_cluster_name}" >> /etc/ecs/ecs.config