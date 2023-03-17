# Lambda Alarms Example

## Deploy Instructions

1. Install [Python 3](https://www.python.org).
1. Install [Docker](https://www.docker.com/).
1. Install [Terraform](https://www.terraform.io/).
1. Configure your AWS credentials ([instructions](https://blog.gruntwork.io/a-comprehensive-guide-to-authenticating-to-aws-on-the-command-line-63656a686799)).
1. Open [variables.tf](variables.tf) and set all required parameters (plus any others you wish to override). We recommend setting these variables in a `terraform.tfvars` file (see [here](https://www.terraform.io/docs/configuration/variables.html#assigning-values-to-root-module-variables) for all the ways you can set Terraform variables).
1. Build the lambda deployment package with `./python/build.sh`.
1. Run `terraform init`.
1. Run `terraform apply`.
1. The module will output the endpoint of the lambda function.
1. When you're done testing, to undeploy everything, run `terraform destroy`.

## How do I get notifications from these alarms?

This example configures the CloudWatch alarms to send notifications to an [SNS](https://aws.amazon.com/sns/) topic whenever the state of the alarm changes. You can subscribe to this topic to receive notifications via email and/or SMS:

1. When you run `terraform apply`, or, later, if you run `terraform output`, the name and ARN of this topic will be outputted to the console.
2. Login to the [SNS console](https://console.aws.amazon.com/sns/v2/home).
3. Click the "Topics" link in the menu on the left.
4. Find the topic with the name and ARN from step 1 in the list and click the checkbox next to it.
5. Click the "Actions" button and select "Subscribe to Topic".
6. Choose "Email" or "SMS Message" as the protocol, enter your email or phone number, and click "Create Subscription".
7. AWS will email or message you to confirm the subscription. Be sure to confirm it, or you won't receive any notifications, and the alarm will report its status as `INSUFFICIENT_DATA`!
