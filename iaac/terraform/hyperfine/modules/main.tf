terraform {
  required_version = ">= 1.2.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.71"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.13.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}



resource "helm_release" "kubeflow_issuer" {
  name      = "kubeflow-issuer"
  namespace = "kubeflow"
  chart     = "${var.chart_root_folder}/common/kubeflow-issuer"
}


resource "helm_release" "istio" {
  depends_on = [helm_release.kubeflow_issuer]

  name      = "istio"
  namespace = "kube-system"
  chart     = "${var.chart_root_folder}/common/istio"
}

resource "helm_release" "cluster-local-gateway" {
  depends_on = [helm_release.istio]

  name      = "cluster-local-gateway"
  namespace = "kubeflow"
  chart     = "${var.chart_root_folder}/common/cluster-local-gateway"
}


resource "helm_release" "knative-serving" {
  depends_on = [helm_release.cluster-local-gateway]

  name      = "knative-serving"
  namespace = "kubeflow"
  chart     = "${var.chart_root_folder}/common/knative-serving"

}

resource "helm_release" "kubeflow_knative_eventing" {
  depends_on = [helm_release.knative-serving]

  name      = "knative-eventing"
  namespace = "kubeflow"
  chart     = "${var.chart_root_folder}/common/knative-eventing"
}


resource "helm_release" "kubeflow_roles" {
  depends_on = [helm_release.istio]

  name      = "kubeflow-roles"
  namespace = "kubeflow"
  chart     = "${var.chart_root_folder}/common/kubeflow-roles"

}

resource "helm_release" "kubeflow_istio_resources" {
  depends_on = [helm_release.kubeflow_roles]

  name      = "kubeflow-istio-resources"
  namespace = "kubeflow"
  chart     = "${var.chart_root_folder}/common/kubeflow-istio-resources"
}


resource "helm_release" "kubeflow_pipelines" {
  depends_on = [helm_release.kubeflow_istio_resources]

  name  = "kubeflow-pipelines"
  chart = "${var.chart_root_folder}/apps/kubeflow-pipelines/rds-s3"
  set {
    name  = "rds.dbHost"
    value = var.rds_host
  }
  set {
    name  = "rds.mlmdDb"
    value = "kubeflow"
  }
  set {
    name  = "s3.bucketName"
    value = var.s3_bucket_name
  }
  set {
    name  = "s3.minioServiceHost"
    value = "s3.amazonaws.com"
  }
  set {
    name  = "s3.minioServiceRegion"
    value = var.s3_region
  }
}


resource "helm_release" "kubeflow_kserve" {
  depends_on = [helm_release.kubeflow_istio_resources]

  name      = "kserve"
  namespace = "kubeflow"
  chart     = "${var.chart_root_folder}/common/kserve"
}

resource "helm_release" "kubeflow_models_web_app" {
  depends_on = [helm_release.kubeflow_istio_resources]

  name      = "models-web-app"
  namespace = "kubeflow"
  chart     = "${var.chart_root_folder}/apps/models-web-app"
}

resource "helm_release" "kubeflow_katib" {
  depends_on = [helm_release.kubeflow_istio_resources]

  name      = "katib"
  namespace = "kubeflow"
  chart     = "${var.chart_root_folder}/apps/katib/vanilla"
}

resource "helm_release" "kubeflow_central_dashboard" {
  depends_on = [helm_release.kubeflow_istio_resources]

  name      = "central-dashboard"
  namespace = "kubeflow"
  chart     = "${var.chart_root_folder}/apps/central-dashboard"
}

resource "helm_release" "kubeflow_admission_webhook" {
  depends_on = [helm_release.kubeflow_istio_resources]

  name      = "admission-webhook"
  namespace = "kubeflow"
  chart     = "${var.chart_root_folder}/apps/admission-webhook"
}

resource "helm_release" "kubeflow_notebook_controller" {
  depends_on = [helm_release.kubeflow_central_dashboard]

  name      = "notebook-controller"
  namespace = "kubeflow"
  chart     = "${var.chart_root_folder}/apps/notebook-controller"
  set {
    name  = "cullingPolicy.cullIdleTime"
    value = var.notebook_cull_idle_time
  }
  set {
    name  = "cullingPolicy.enableCulling"
    value = var.notebook_enable_culling
  }
  set {
    name  = "cullingPolicy.idlenessCheckPeriod"
    value = var.notebook_idleness_check_period
  }


}
/*
resource "helm_release" "kubeflow_jupyter_web_app" {
  depends_on = [helm_release.kubeflow_central_dashboard]

  name      = "jupyter-web-app"
  namespace = "kubeflow"
  chart     = "${var.chart_root_folder}/apps/jupyter-web-app"
  version   = "0.2.2"
}
*/

resource "helm_release" "kubeflow_profiles_and_kfam" {
  depends_on = [helm_release.kubeflow_central_dashboard]

  name      = "profiles-and-kfam"
  namespace = "kubeflow"
  chart     = "${var.chart_root_folder}/apps/profiles-and-kfam"
}

resource "helm_release" "kubeflow_volumes_web_app" {
  depends_on = [helm_release.kubeflow_central_dashboard]

  name      = "volumes-web-app"
  namespace = "kubeflow"
  chart     = "${var.chart_root_folder}/apps/volumes-web-app"
}

resource "helm_release" "kubeflow_tensorboards_web_app" {
  depends_on = [helm_release.kubeflow_central_dashboard]

  name      = "tensorboards-web-app"
  namespace = "kubeflow"
  chart     = "${var.chart_root_folder}/apps/tensorboards-web-app"
}

resource "helm_release" "kubeflow_tensorboard_controller" {
  depends_on = [helm_release.kubeflow_central_dashboard]

  name      = "tensorboard-controller"
  namespace = "kubeflow"
  chart     = "${var.chart_root_folder}/apps/tensorboard-controller"
}

resource "helm_release" "kubeflow_training_operator" {
  depends_on = [helm_release.kubeflow_central_dashboard]

  name      = "training-operator"
  namespace = "kubeflow"
  chart     = "${var.chart_root_folder}/apps/training-operator"
}

resource "helm_release" "kubeflow_aws_telemetry" {
  count      = var.enable_aws_telemetry ? 1 : 0
  depends_on = [helm_release.kubeflow_central_dashboard]

  name      = "aws-telemetry"
  namespace = "kubeflow"
  chart     = "${var.chart_root_folder}/common/aws-telemetry"

}

resource "helm_release" "kubeflow_user_namespace" {
  depends_on = [helm_release.kubeflow_central_dashboard]

  name      = "user-namespace"
  namespace = "kubeflow"
  chart     = "${var.chart_root_folder}/common/user-namespace"

}

/*
module "ack_sagemaker" {
  source            = "../../common/ack-sagemaker-controller"
  addon_context = module.context.addon_context
}
*/