# ECS Service with ALB Alarms

To add CloudWatch alarms for use with the Gruntwork Module [ecs-service-with-alb](
https://github.com/gruntwork-io/terraform-aws-ecs/tree/master/modules/ecs-service-with-alb), use the [alb-target-group-alarms](
../alb-target-group-alarms) module. This is because all of an ECS Service's containers exist within an [ALB Target Group](
http://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html).