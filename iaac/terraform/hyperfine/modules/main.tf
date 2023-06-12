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

  name             = "istio"
  namespace        = "istio-system"
  chart            = "${var.chart_root_folder}/common/istio"
}
/*
resource "helm_release" "cluster-local-gateway" {
  depends_on = [helm_release.istio-istiod]

  name      = "cluster-local-gateway"
  namespace = "kubeflow"
  chart     = "${var.chart_root_folder}/common/cluster-local-gateway"
}


resource "helm_release" "knative-serving" {
  depends_on = [helm_release.cluster-local-gateway]

  name      = "knative-serving"
  namespace = "kubeflow"
  chart     = "${var.chart_root_folder}/charts/common/knative-serving"

}

resource "helm_release" "kubeflow_knative_eventing" {
  depends_on = [helm_release.knative-serving]

  name      = "knative-eventing"
  namespace = "kubeflow"
  chart     = "${var.chart_root_folder}/charts/common/knative-eventing"
}


module "kubeflow_roles" {
  source            = "../../common/kubeflow-roles"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/kubeflow-roles"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_knative_serving]
}

module "kubeflow_istio_resources" {
  source            = "../../common/kubeflow-istio-resources"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/kubeflow-istio-resources"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_roles]
}

module "kubeflow_pipelines" {
  source            = "../../apps/kubeflow-pipelines"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/kubeflow-pipelines/rds-s3"
    set =[{
          name =  "rds.dbHost",
          value = var.rds_host
    },
      {
        name = "rds.mlmdDb",
        value = "kubeflow"
      },
      {
        name = "s3.bucketName"
        value = var.s3_bucket
      },
      {
        name = "s3.minioServiceHost"
        value = "s3.amazonaws.com"
      },
      {
        name = "s3.minioServiceRegion"
        value = var.s3_region
      }
    ]
  }

  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_istio_resources]

}

module "kubeflow_kserve" {
  source            = "../../common/kserve"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/kserve"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_istio_resources]
}

module "kubeflow_models_web_app" {
  source            = "../../apps/models-web-app"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/models-web-app"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_kserve]
}

module "kubeflow_katib" {
  source            = "../../apps/katib"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/katib/vanilla"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_models_web_app]
}

module "kubeflow_central_dashboard" {
  source            = "../../apps/central-dashboard"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/central-dashboard"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_katib]
}

module "kubeflow_admission_webhook" {
  source            = "../../apps/admission-webhook"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/admission-webhook"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_central_dashboard]
}

module "kubeflow_notebook_controller" {
  source            = "../../apps/notebook-controller"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/notebook-controller"
    set = [
      {
        name = "cullingPolicy.cullIdleTime",
        value = var.notebook_cull_idle_time
      },
      {
        name = "cullingPolicy.enableCulling",
        value = var.notebook_enable_culling
      },
      {
        name = "cullingPolicy.idlenessCheckPeriod",
        value= var.notebook_idleness_check_period
      }
    ]
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_central_dashboard]
}

module "kubeflow_jupyter_web_app" {
  source            = "../../apps/jupyter-web-app"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/jupyter-web-app"
    version = "0.1.2"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_notebook_controller]
}


module "kubeflow_profiles_and_kfam" {
  source            = "../../apps/profiles-and-kfam"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/profiles-and-kfam"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_central_dashboard]
}

module "kubeflow_volumes_web_app" {
  source            = "../../apps/volumes-web-app"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/volumes-web-app"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_profiles_and_kfam]
}

module "kubeflow_tensorboards_web_app" {
  source            = "../../apps/tensorboards-web-app"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/tensorboards-web-app"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_volumes_web_app]
}

module "kubeflow_tensorboard_controller" {
  source            = "../../apps/tensorboard-controller"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/tensorboard-controller"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_tensorboards_web_app]
}

module "kubeflow_training_operator" {
  source            = "../../apps/training-operator"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/training-operator"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_tensorboard_controller]
}

module "kubeflow_aws_telemetry" {
  count = var.enable_aws_telemetry ? 1 : 0
  source            = "../../common/aws-telemetry"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/aws-telemetry"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_training_operator]
}

module "kubeflow_user_namespace" {
  source            = "../../common/user-namespace"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/user-namespace"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_aws_telemetry]
}

module "ack_sagemaker" {
  source            = "../../common/ack-sagemaker-controller"
  addon_context = module.context.addon_context
}
*/