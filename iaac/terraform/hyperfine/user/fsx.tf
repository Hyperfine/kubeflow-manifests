locals {
  fsx = values(var.fsx_configs)[0]                          # only support one config atm
}

resource kubernetes_persistent_volume_v1 "fsx_pv" {
  metadata {
    name = "${local.name}-dl-fsx-pv"
    labels = {
      usage = "${local.name}-fsx"
    }
  }

  spec {
    volume_mode = "Filesystem"
    access_modes = ["ReadWriteMany"]
    mount_options = ["flock"]
    persistent_volume_reclaim_policy = "Recycle"
    capacity = {
      storage = "${lookup(local.fsx, "capacity", 1200)}Gi"
    }

    persistent_volume_source {
      csi {
        driver        = "fsx.csi.aws.com"
        volume_handle = lookup(local.fsx, "file_system_id")
        volume_attributes = {
          mountname = lookup(local.fsx, "mount_name")
          dnsname = lookup(local.fsx, "dns_name")
        }
      }
    }
  }
}

resource kubernetes_persistent_volume_claim_v1 "fsx_pvc" {
  metadata {
    name : "dl-fsx-claim"
    namespace : local.name
  }

  spec {
    access_modes = ["ReadWriteMany"]
    volume_name  = "${local.name}-dl-fsx-claim"
    resources {
      requests = {
        storage = "${lookup(local.fsx, "capacity", 1200)}Gi"
      }
    }
    selector {
      match_labels = {
        usage = "${local.name}-fsx"
      }
    }
  }
}
