resource "aws_efs_access_point" "access" {
  file_system_id = var.efs_filesystem_id

  posix_user {
    gid = 100
    uid = 1000
  }

  root_directory {
    creation_info {
      owner_gid   = 100
      owner_uid   = 1000
      permissions = "0775"
    }
    path = var.efs_access_point_path != "" ? var.efs_access_point_path : null
  }

  tags = {
    Name = local.name
  }
}

resource "kubernetes_persistent_volume_v1" "pv" {
  metadata {
    name = "${local.name}-efs-home-pv"
    labels = {
      usage = "${local.name}-efs"
    }
  }

  spec {
    capacity = {
      storage : "30Gi"
    }
    access_modes                     = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain"
    volume_mode                      = "Filesystem"

    persistent_volume_source {
      csi {
        driver        = "efs.csi.aws.com"
        volume_handle = "${var.efs_filesystem_id}::${aws_efs_access_point.access.id}"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "pvc" {
  metadata {
    name      = "efs-home"
    namespace = local.name
  }

  spec {
    access_modes = ["ReadWriteMany"]
    selector {
      match_labels = {
        usage = "${local.name}-efs"
      }
    }
    resources {
      requests = {
        storage = "30Gi"
      }
    }
  }
}
