output "rules_map" {
  description = "A map of listener rules that can be passed into a for_each attribute to the aws_lb_listener_rule resource."
  value       = local.rules_map
}

locals {
  # For those rules indexed by listener port, flatten out the rule for each port identified in listener_ports. Note that
  # if both listener_arns and listener_ports is not specified, this will default to using the default_listener_ports for
  # the ports list.
  rules_by_listener_port = flatten([
    for rule_name, rule in var.rules : [
      for listener_port in lookup(rule, "listener_ports", var.default_listener_ports) : {
        # Used to key the final map
        rule_identifier = "${rule_name}-${listener_port}"

        listener_arn = var.default_listener_arns[listener_port]
        priority     = lookup(rule, "priority", null)

        # Forward config
        stickiness = lookup(rule, "stickiness", null)

        # Redirect config
        status_code = lookup(rule, "status_code", null)
        protocol    = lookup(rule, "protocol", null)
        port        = lookup(rule, "port", null)
        host        = lookup(rule, "host", null)
        path        = lookup(rule, "path", null)
        query       = lookup(rule, "query", null)

        # Fixed response config
        content_type = lookup(rule, "content_type", null)
        message_body = lookup(rule, "message_body", null)
        status_code  = lookup(rule, "status_code", null)

        # Conditions
        path_patterns        = lookup(rule, "path_patterns", [])
        host_headers         = lookup(rule, "host_headers", [])
        http_headers         = lookup(rule, "http_headers", [])
        source_ips           = lookup(rule, "source_ips", [])
        query_strings        = lookup(rule, "query_strings", [])
        http_request_methods = lookup(rule, "http_request_methods", [])
      }
    ]
    if lookup(rule, "listener_arns", null) == null
  ])

  # For those rules that have listener ARNs directly provided, flatten out the rule for each listener ARN.
  rules_by_listener_arns = flatten([
    for rule_name, rule in var.rules : [
      for listener_arn in rule.listener_arns : {
        # Used to key the final map
        rule_identifier = "${rule_name}-${listener_arn}"

        listener_arn = listener_arn
        priority     = lookup(rule, "priority", null)

        # Forward config
        stickiness = lookup(rule, "stickiness", null)

        # Redirect config
        status_code = lookup(rule, "status_code", null)
        protocol    = lookup(rule, "protocol", null)
        port        = lookup(rule, "port", null)
        host        = lookup(rule, "host", null)
        path        = lookup(rule, "path", null)
        query       = lookup(rule, "query", null)

        # Fixed response config
        content_type = lookup(rule, "content_type", null)
        message_body = lookup(rule, "message_body", null)
        status_code  = lookup(rule, "status_code", null)

        # Conditions
        path_patterns        = lookup(rule, "path_patterns", [])
        host_headers         = lookup(rule, "host_headers", [])
        http_headers         = lookup(rule, "http_headers", [])
        source_ips           = lookup(rule, "source_ips", [])
        query_strings        = lookup(rule, "query_strings", [])
        http_request_methods = lookup(rule, "http_request_methods", [])
      }
    ]
    if lookup(rule, "listener_arns", null) != null
  ])

  # Combine the two rules lists and construct the final map output, assigning a unique name key for each rule.
  rules_list = concat(local.rules_by_listener_port, local.rules_by_listener_arns)
  rules_map = {
    for item in local.rules_list :
    item.rule_identifier => item
  }
}
