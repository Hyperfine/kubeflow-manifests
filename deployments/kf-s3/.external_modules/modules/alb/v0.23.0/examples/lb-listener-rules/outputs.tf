output "lb_listener_rule_forward_arns" {
  value = module.lb_listener_rules.lb_listener_rule_forward_arns
}

output "lb_listener_rule_redirect_arns" {
  value = module.lb_listener_rules.lb_listener_rule_redirect_arns
}

output "listener_arns" {
  value = module.alb.listener_arns
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "alb_name" {
  value = module.alb.alb_name
}
