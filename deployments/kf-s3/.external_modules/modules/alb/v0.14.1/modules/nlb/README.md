# Network Load Balancer (NLB) Module

This Terraform Module creates a [Network Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/introduction.html)
that you can use as a load balancer for any [Target Group](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html).
In practice, a Target Group is usually an [EC2 Instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts.html)
or an [Auto Scaling Group](http://docs.aws.amazon.com/autoscaling/latest/userguide/WhatIsAutoScaling.html).

See the [Background](#background) section below for more information on the NLB.

## How do you use this module?

* See the [root README](/README.md) for instructions on using Terraform modules.
* See the [examples](/examples) folder for example usage.
* See [vars.tf](./vars.tf) for all the variables you can set on this module.

## NLB Components

Here's what makes up a complete NLB deployment:

- **Load Balancer** serves as the single point of contact for clients. The load balancer increases the availability of your application by distributing incoming traffic across multiple targets, such as Amazon EC2 instances.

- **Listener:** Checks for incoming traffic on a specific protocol and port and forwards to your target groups

- **Listener Rules:** Represents a mapping between Listeners and Target Groups. For each of your Listeners, you can
  specify which ports and/or domain names should be routed to which Target Groups. For example, you could configure `foo.my-domain.com:3000` to go to target group `foo-3000` and `foo.my-domain.com:8000` to go to target group `foo-8000`.

- **Target Group:** Represents one or more servers, usually EC2 instances, that are listening for requests. You can configure what TCP protocol and port(s) those servers listen on and how to perform health checks on the servers. 

## Background

### What is an NLB

A Network Load Balancer is a [Layer 4](https://en.wikipedia.org/wiki/Transport_layer) level load balancer. It can handle millions of requests per second. After the load balancer receives a connection request, it selects a target from the target group for the default rule. It attempts to open a TCP connection to the selected target on the port specified in the listener configuration. All in all, an NLB is a good improvement over CLB for all TCP use cases and is a better choice over an ALB when you need very rapid scaling and a static IP for your load balancer.

### ALB vs NLB vs CLB

Network load balancers, application load balancers and elastic load balancers are the three different kind of load balancers that are available in AWS. Each of them have their strengths and weaknesses and situations when they're more appropriate for use.

#### ALB Functionality

The ALB gives us the following HTTP-specific functionality compared to the rest:

- Route requests via HTTP or HTTPS
- Native support for WebSockets
- Native support for HTTP/2
- Path-based routing
- Hostname-based routing
- Ability to route to a [Target](http://docs.aws.amazon.com/elasticloadbalancing/latest/application/target-group-register-targets.html), which incorporates both an endpoint and a port and therefore allows different instances of an ECS Service to receive traffic on different ports.
- Supports specifying Security groups


#### NLB Functionality

The NLB gives us the following functionality compared to the rest:

- Route requests via TCP only
- Native support for WebSockets
- Ability to route to a [Target](http://docs.aws.amazon.com/elasticloadbalancing/latest/network/target-group-register-targets.html)
- Choose a Static IP
- Rapid scaling - Can handle much bigger traffic spikes than ALB and CLB
- Very high queries per second with low latency
- Relies on Security groups of target group instances

#### CLB Functionality

The Classic Load Balancer, or CLB, gives us the following unique functionality compared to the rest:

- Route requests via HTTP, HTTPS or TCP
- Support for sticky sessions using application-generated cookies

From the above analysis we can conclude that you should preferrably select an ALB when your service relies heavily on HTTP(S) features like headers, routes, cookies etc and use NLB for everything else e.g messaging queues, database servers etc. It's not advisable to still use a CLB at this time mainly because its functionalities have been largely replaced by ALBs and NLBs which are specialized and do a much better job. Also, because of its "classic" status, chances are it could be deprecated by AWS.