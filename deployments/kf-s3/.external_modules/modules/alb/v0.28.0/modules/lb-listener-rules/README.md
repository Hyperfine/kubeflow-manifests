# Load Balancer Listener Rules

This Terraform Module provides a simpler, more declarative interface for creating
[Load Balancer Listener Rules](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html)
that determine how the load balancer routes requests to its registered targets. It's an alternative to creating
[`lb_listener_rule`](https://www.terraform.io/docs/providers/aws/r/lb_listener_rule.html) resources directly in
Terraform, which can be convenient, for example, when configuring listener rules in a
[Terragrunt configuration](https://terragrunt.gruntwork.io/). 

This module currently supports:
 * Most major rule types: forward rules, redirect rules, fixed-response
 * Most condition types: host header, HTTP header, request method, path pattern, query string, source IP.  
 
This module does NOT currently support:
* `authenticate_cognito` and `authenticate_oidc` rules


This feature may be added later, but if you need them now, you should use the
[`lb_listener_rule`](https://www.terraform.io/docs/providers/aws/r/lb_listener_rule.html) resource directly.

## How do you use this module?

* See the [root README](/README.md) for instructions on using Terraform modules.
* See the [examples](/examples) folder for example usage.
* See [variables.tf](./variables.tf) for all the variables you can set on this module.

## Gotcha's

### Make sure your Listeners handle all possible request paths

An [LB Listener](http://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html) 
represents an open port on your ALB, waiting to receive requests and route them to a [Target 
Group](http://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html). 

Suppose you want to have this LB Listener route requests for `/foo` to ServiceFoo and requests for `/bar` to ServiceBar. 
You'd accomplish this creating two [LB Listener 
Rules](http://docs.aws.amazon.com/elasticloadbalancing/latest/application/listener-update-rules.html) as follows:

  - Route `/foo` traffic to Target Group ServiceFoo
  - Route `/bar` traffic to Target Group ServiceBar
  
So far so good. But what if the Listener receives a request for `/hello`? Since no Listener Rule handles that path, the 
LB needs to handle it with a default action. The default action in [the ALB module](https://github.com/gruntwork-io/terraform-aws-load-balancer/blob/f95b13e/modules/alb/main.tf#L50-L89), for example, returns a fixed response, which 
by default is a blank 404 page. You can also add an ALB Listener Rule that catches ALL requests (i.e., `*`) and have that
rule forward to a custom Target Group so your own apps can respond in any way you wish.  
 
### Make sure your Listener Rules each have a unique "priority"

See the [prior section](#make-sure-your-listeners-handle-all-possible-request-paths) understand what Listener Rules are.

When defining a Listener Rule, you must specify both a priority and a path. The priority tells the ALB in what priority
a particular Listener Rule should be evaluated. For example, suppose you have the following Listener Rules defined on
your ALB:

  - Route `/foo` traffic to Target Group ServiceFoo
  - Route `/foo*` traffic to Target Group ServiceBar
  
To which Target Group should a request for `/foo` be routed? Based on the above, it's non-determinate. For this reason,
you must include a "priority" in the Listener Rule. A priority is an integer value where the lower the number the higher 
the priority. For example, if we add in priorities to our Listener Rules:
 
   - Priority: 100. Route `/foo` traffic to Target Group ServiceFoo
   - Priority: 200. Route `/foo*` traffic to Target Group ServiceBar
   
Now we know that the first Listener Rule has a higher priority. That means that requests for `/foo` will be routed to
ServiceFoo, while all other requests will be routed to ServiceBar.

The gotcha here is that, because you define the Listener Rules for a single Listener across potentially many different
ECS Services or Auto Scaling Groups, take care to make sure that each Listener Rule uses a globally unique priority number.

Note that in most cases, your path definitions should be mutually exclusive and the actual priority value won't matter.