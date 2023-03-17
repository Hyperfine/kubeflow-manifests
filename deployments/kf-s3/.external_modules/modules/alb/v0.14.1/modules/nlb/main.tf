# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN NETWORK LOAD BALANCER (NLB)
# This template creates an NLB and sets up the desired NLB Listeners. A single NLB is
# expected to serve as the load balancer for potentially multiple ECS Services and Auto Scaling Groups.
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  # This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
  required_version = ">= 0.12"
}

locals {
  # List indexer expressions (e.g. some_list[0]) are validated even when they appear within resources with count == 0.
  # Pad the end of the final 'subnet_mapping' list to ensure it has at least 6 members.
  subnet_mapping = concat(
    var.subnet_mapping,
    [{ "0" = "0" }],
    [{ "0" = "0" }],
    [{ "0" = "0" }],
    [{ "0" = "0" }],
    [{ "0" = "0" }],
    [{ "0" = "0" }],
  )

  tags = merge(
    {
      "Environment" = var.environment_name
    },
    var.custom_tags,
  )
  load_balancer_type = "network"

  nlb_access_logs_config = {
    bucket = var.nlb_access_logs_s3_bucket_name
    prefix = var.nlb_name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN NETWORK LOAD BALANCER
# We have multiple aws_nlb resources, but only one will be created, based on the subnet_mapping_size passed in.
# This workaround is necessary because subnet_mapping is an inline block and Terraform limitations offer no way to
# make those dynamic.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_lb" "nlb" {
  count = var.subnet_mapping_size == 0 ? 1 : 0

  name         = var.nlb_name
  internal     = var.is_internal_nlb
  subnets      = var.vpc_subnet_ids
  idle_timeout = var.idle_timeout

  load_balancer_type         = local.load_balancer_type
  enable_deletion_protection = var.enable_deletion_protection

  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  ip_address_type                  = var.ip_address_type

  tags = local.tags

  # We use a dynamic block here to control the access_logs config, instead of using the feature flag with the `enabled`
  # attribute. Specifically, regardless of the `enabled` flag, you must pass in a valid bucket and prefix to the
  # access_logs config. This means that you can't use "" or null to for the bucket/prefix when the access logs are
  # disabled. To workaround this, we use a dynamic block that omits the subblock when access logs are disabled.
  dynamic "access_logs" {
    # Ideally we can do `for_each = var.enable_nlb_access_logs ? [object] : []`, but due to a terraform bug, this
    # doesn't work. See https://github.com/hashicorp/terraform/issues/21465. So we simulate it using a for expression.
    for_each = [
      for x in [local.nlb_access_logs_config] : x if var.enable_nlb_access_logs
    ]

    content {
      bucket  = access_logs.value.bucket
      prefix  = access_logs.value.prefix
      enabled = true
    }
  }
}

resource "aws_lb" "nlb_1_az" {
  count = var.subnet_mapping_size == 1 ? 1 : 0

  name         = var.nlb_name
  internal     = var.is_internal_nlb
  idle_timeout = var.idle_timeout

  load_balancer_type         = local.load_balancer_type
  enable_deletion_protection = var.enable_deletion_protection

  subnet_mapping {
    subnet_id     = local.subnet_mapping[0]["subnet_id"]
    allocation_id = lookup(local.subnet_mapping[0], "allocation_id", "")
  }

  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  ip_address_type                  = var.ip_address_type

  tags = local.tags

  # We use a dynamic block here to control the access_logs config, instead of using the feature flag with the `enabled`
  # attribute. Specifically, regardless of the `enabled` flag, you must pass in a valid bucket and prefix to the
  # access_logs config. This means that you can't use "" or null to for the bucket/prefix when the access logs are
  # disabled. To workaround this, we use a dynamic block that omits the subblock when access logs are disabled.
  dynamic "access_logs" {
    # Ideally we can do `for_each = var.enable_nlb_access_logs ? [object] : []`, but due to a terraform bug, this
    # doesn't work. See https://github.com/hashicorp/terraform/issues/21465. So we simulate it using a for expression.
    for_each = [
      for x in [local.nlb_access_logs_config] : x if var.enable_nlb_access_logs
    ]

    content {
      bucket  = access_logs.value.bucket
      prefix  = access_logs.value.prefix
      enabled = true
    }
  }
}

resource "aws_lb" "nlb_2_az" {
  count = var.subnet_mapping_size == 2 ? 1 : 0

  name         = var.nlb_name
  internal     = var.is_internal_nlb
  idle_timeout = var.idle_timeout

  load_balancer_type         = local.load_balancer_type
  enable_deletion_protection = var.enable_deletion_protection

  subnet_mapping {
    subnet_id     = local.subnet_mapping[0]["subnet_id"]
    allocation_id = lookup(local.subnet_mapping[0], "allocation_id", "")
  }

  subnet_mapping {
    subnet_id     = local.subnet_mapping[1]["subnet_id"]
    allocation_id = lookup(local.subnet_mapping[1], "allocation_id", "")
  }

  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  ip_address_type                  = var.ip_address_type

  tags = local.tags

  # We use a dynamic block here to control the access_logs config, instead of using the feature flag with the `enabled`
  # attribute. Specifically, regardless of the `enabled` flag, you must pass in a valid bucket and prefix to the
  # access_logs config. This means that you can't use "" or null to for the bucket/prefix when the access logs are
  # disabled. To workaround this, we use a dynamic block that omits the subblock when access logs are disabled.
  dynamic "access_logs" {
    # Ideally we can do `for_each = var.enable_nlb_access_logs ? [object] : []`, but due to a terraform bug, this
    # doesn't work. See https://github.com/hashicorp/terraform/issues/21465. So we simulate it using a for expression.
    for_each = [
      for x in [local.nlb_access_logs_config] : x if var.enable_nlb_access_logs
    ]

    content {
      bucket  = access_logs.value.bucket
      prefix  = access_logs.value.prefix
      enabled = true
    }
  }
}

resource "aws_lb" "nlb_3_az" {
  count = var.subnet_mapping_size == 3 ? 1 : 0

  name         = var.nlb_name
  internal     = var.is_internal_nlb
  idle_timeout = var.idle_timeout

  load_balancer_type         = local.load_balancer_type
  enable_deletion_protection = var.enable_deletion_protection

  subnet_mapping {
    subnet_id     = local.subnet_mapping[0]["subnet_id"]
    allocation_id = lookup(local.subnet_mapping[0], "allocation_id", "")
  }

  subnet_mapping {
    subnet_id     = local.subnet_mapping[1]["subnet_id"]
    allocation_id = lookup(local.subnet_mapping[1], "allocation_id", "")
  }

  subnet_mapping {
    subnet_id     = local.subnet_mapping[2]["subnet_id"]
    allocation_id = lookup(local.subnet_mapping[2], "allocation_id", "")
  }

  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  ip_address_type                  = var.ip_address_type

  tags = local.tags

  # We use a dynamic block here to control the access_logs config, instead of using the feature flag with the `enabled`
  # attribute. Specifically, regardless of the `enabled` flag, you must pass in a valid bucket and prefix to the
  # access_logs config. This means that you can't use "" or null to for the bucket/prefix when the access logs are
  # disabled. To workaround this, we use a dynamic block that omits the subblock when access logs are disabled.
  dynamic "access_logs" {
    # Ideally we can do `for_each = var.enable_nlb_access_logs ? [object] : []`, but due to a terraform bug, this
    # doesn't work. See https://github.com/hashicorp/terraform/issues/21465. So we simulate it using a for expression.
    for_each = [
      for x in [local.nlb_access_logs_config] : x if var.enable_nlb_access_logs
    ]

    content {
      bucket  = access_logs.value.bucket
      prefix  = access_logs.value.prefix
      enabled = true
    }
  }
}

resource "aws_lb" "nlb_4_az" {
  count = var.subnet_mapping_size == 4 ? 1 : 0

  name         = var.nlb_name
  internal     = var.is_internal_nlb
  idle_timeout = var.idle_timeout

  load_balancer_type         = local.load_balancer_type
  enable_deletion_protection = var.enable_deletion_protection

  subnet_mapping {
    subnet_id     = local.subnet_mapping[0]["subnet_id"]
    allocation_id = lookup(local.subnet_mapping[0], "allocation_id", "")
  }

  subnet_mapping {
    subnet_id     = local.subnet_mapping[1]["subnet_id"]
    allocation_id = lookup(local.subnet_mapping[1], "allocation_id", "")
  }

  subnet_mapping {
    subnet_id     = local.subnet_mapping[2]["subnet_id"]
    allocation_id = lookup(local.subnet_mapping[2], "allocation_id", "")
  }

  subnet_mapping {
    subnet_id     = local.subnet_mapping[3]["subnet_id"]
    allocation_id = lookup(local.subnet_mapping[3], "allocation_id", "")
  }

  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  ip_address_type                  = var.ip_address_type

  tags = local.tags

  # We use a dynamic block here to control the access_logs config, instead of using the feature flag with the `enabled`
  # attribute. Specifically, regardless of the `enabled` flag, you must pass in a valid bucket and prefix to the
  # access_logs config. This means that you can't use "" or null to for the bucket/prefix when the access logs are
  # disabled. To workaround this, we use a dynamic block that omits the subblock when access logs are disabled.
  dynamic "access_logs" {
    # Ideally we can do `for_each = var.enable_nlb_access_logs ? [object] : []`, but due to a terraform bug, this
    # doesn't work. See https://github.com/hashicorp/terraform/issues/21465. So we simulate it using a for expression.
    for_each = [
      for x in [local.nlb_access_logs_config] : x if var.enable_nlb_access_logs
    ]

    content {
      bucket  = access_logs.value.bucket
      prefix  = access_logs.value.prefix
      enabled = true
    }
  }
}

resource "aws_lb" "nlb_5_az" {
  count = var.subnet_mapping_size == 5 ? 1 : 0

  name         = var.nlb_name
  internal     = var.is_internal_nlb
  idle_timeout = var.idle_timeout

  load_balancer_type         = local.load_balancer_type
  enable_deletion_protection = var.enable_deletion_protection

  subnet_mapping {
    subnet_id     = local.subnet_mapping[0]["subnet_id"]
    allocation_id = lookup(local.subnet_mapping[0], "allocation_id", "")
  }

  subnet_mapping {
    subnet_id     = local.subnet_mapping[1]["subnet_id"]
    allocation_id = lookup(local.subnet_mapping[1], "allocation_id", "")
  }

  subnet_mapping {
    subnet_id     = local.subnet_mapping[2]["subnet_id"]
    allocation_id = lookup(local.subnet_mapping[2], "allocation_id", "")
  }

  subnet_mapping {
    subnet_id     = local.subnet_mapping[3]["subnet_id"]
    allocation_id = lookup(local.subnet_mapping[3], "allocation_id", "")
  }

  subnet_mapping {
    subnet_id     = local.subnet_mapping[4]["subnet_id"]
    allocation_id = lookup(local.subnet_mapping[4], "allocation_id", "")
  }

  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  ip_address_type                  = var.ip_address_type

  tags = local.tags

  # We use a dynamic block here to control the access_logs config, instead of using the feature flag with the `enabled`
  # attribute. Specifically, regardless of the `enabled` flag, you must pass in a valid bucket and prefix to the
  # access_logs config. This means that you can't use "" or null to for the bucket/prefix when the access logs are
  # disabled. To workaround this, we use a dynamic block that omits the subblock when access logs are disabled.
  dynamic "access_logs" {
    # Ideally we can do `for_each = var.enable_nlb_access_logs ? [object] : []`, but due to a terraform bug, this
    # doesn't work. See https://github.com/hashicorp/terraform/issues/21465. So we simulate it using a for expression.
    for_each = [
      for x in [local.nlb_access_logs_config] : x if var.enable_nlb_access_logs
    ]

    content {
      bucket  = access_logs.value.bucket
      prefix  = access_logs.value.prefix
      enabled = true
    }
  }
}

resource "aws_lb" "nlb_6_az" {
  count = var.subnet_mapping_size == 6 ? 1 : 0

  name         = var.nlb_name
  internal     = var.is_internal_nlb
  idle_timeout = var.idle_timeout

  load_balancer_type         = local.load_balancer_type
  enable_deletion_protection = var.enable_deletion_protection

  subnet_mapping {
    subnet_id     = local.subnet_mapping[0]["subnet_id"]
    allocation_id = lookup(local.subnet_mapping[0], "allocation_id", "")
  }

  subnet_mapping {
    subnet_id     = local.subnet_mapping[1]["subnet_id"]
    allocation_id = lookup(local.subnet_mapping[1], "allocation_id", "")
  }

  subnet_mapping {
    subnet_id     = local.subnet_mapping[2]["subnet_id"]
    allocation_id = lookup(local.subnet_mapping[2], "allocation_id", "")
  }

  subnet_mapping {
    subnet_id     = local.subnet_mapping[3]["subnet_id"]
    allocation_id = lookup(local.subnet_mapping[3], "allocation_id", "")
  }

  subnet_mapping {
    subnet_id     = local.subnet_mapping[4]["subnet_id"]
    allocation_id = lookup(local.subnet_mapping[4], "allocation_id", "")
  }

  subnet_mapping {
    subnet_id     = local.subnet_mapping[5]["subnet_id"]
    allocation_id = lookup(local.subnet_mapping[5], "allocation_id", "")
  }

  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  ip_address_type                  = var.ip_address_type

  tags = local.tags

  # We use a dynamic block here to control the access_logs config, instead of using the feature flag with the `enabled`
  # attribute. Specifically, regardless of the `enabled` flag, you must pass in a valid bucket and prefix to the
  # access_logs config. This means that you can't use "" or null to for the bucket/prefix when the access logs are
  # disabled. To workaround this, we use a dynamic block that omits the subblock when access logs are disabled.
  dynamic "access_logs" {
    # Ideally we can do `for_each = var.enable_nlb_access_logs ? [object] : []`, but due to a terraform bug, this
    # doesn't work. See https://github.com/hashicorp/terraform/issues/21465. So we simulate it using a for expression.
    for_each = [
      for x in [local.nlb_access_logs_config] : x if var.enable_nlb_access_logs
    ]

    content {
      bucket  = access_logs.value.bucket
      prefix  = access_logs.value.prefix
      enabled = true
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE NLB TARGET GROUP & LISTENER RULE
# - To understand the NLB concepts of a Listener, Listener Rule, and Target Group, visit https://goo.gl/Vct3sf.
# ---------------------------------------------------------------------------------------------------------------------

# Create one TCP Listener for each given TCP port.
resource "aws_lb_listener" "tcp" {
  count = length(var.tcp_listener_ports)

  load_balancer_arn = data.template_file.nlb_arn.rendered
  port              = element(var.tcp_listener_ports, count.index)
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.blackhole.arn
    type             = "forward"
  }
}

# A Listener requires a default Target Group to send requests to. Since we must define the Listener in this module, we
# create a "blackhole" Target Group that satisfies the requirements but for which we expect zero Targets to actually
# exist. Note that we can share a single blackhole Target Group with many Listeners.
resource "aws_lb_target_group" "blackhole" {
  name     = "${var.nlb_name}-blackhole"
  port     = 80
  protocol = "TCP"
  vpc_id   = var.vpc_id
}

# ---------------------------------------------------------------------------------------------------------------------
# CONVENIENCE VARIABLES
# Because we've got some conditional logic in this template, some values will depend on our properties. This section
# wraps such values in a nicer construct.
# ---------------------------------------------------------------------------------------------------------------------

# The NLB's ARN depends on the value of var.nlb_access_logs_s3_bucket_name
data "template_file" "nlb_arn" {
  template = element(
    concat(
      aws_lb.nlb.*.arn,
      aws_lb.nlb_1_az.*.arn,
      aws_lb.nlb_2_az.*.arn,
      aws_lb.nlb_3_az.*.arn,
      aws_lb.nlb_4_az.*.arn,
      aws_lb.nlb_5_az.*.arn,
      aws_lb.nlb_6_az.*.arn,
    ),
    0,
  )
}
