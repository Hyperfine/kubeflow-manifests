terraform {
  required_version = ">= 1.2.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.71"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.13.1"
    }
  }
}


module context {
  source = "../../utils/blueprints-extended-outputs"
  eks_cluster_id = var.eks_cluster_name
  providers = {
    aws = aws
  }
}


module "kubeflow_issuer" {
  source            = "../../common/kubeflow-issuer"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/kubeflow-issuer"
  }

  addon_context = module.context.addon_context
   providers = {
    aws = aws
  }
}

module "kubeflow_istio" {
  source            = "../../common/istio"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/istio-1-14"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_issuer]

    providers = {
    aws = aws
  }
}

module "kubeflow_knative_serving" {
  source            = "../../common/knative-serving"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/knative-serving"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_istio]

    providers = {
    aws = aws
  }
}

module "kubeflow_cluster_local_gateway" {
  source            = "../../common/cluster-local-gateway"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/cluster-local-gateway"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_knative_serving]

    providers = {
    aws = aws
  }
}

module "kubeflow_knative_eventing" {
  source            = "../../common/knative-eventing"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/knative-eventing"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_cluster_local_gateway]

    providers = {
    aws = aws
  }
}

module "kubeflow_roles" {
  source            = "../../common/kubeflow-roles"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/kubeflow-roles"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_knative_serving]

    providers = {
    aws = aws
  }
}

module "kubeflow_istio_resources" {
  source            = "../../common/kubeflow-istio-resources"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/kubeflow-istio-resources"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_roles]

    providers = {
    aws = aws
  }
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
  providers = {
    aws = aws
  }
}

module "kubeflow_kserve" {
  source            = "../../common/kserve"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/kserve"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_istio_resources]

    providers = {
    aws = aws
  }
}

module "kubeflow_models_web_app" {
  source            = "../../apps/models-web-app"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/models-web-app"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_kserve]

    providers = {
    aws = aws
  }
}

module "kubeflow_katib" {
  source            = "../../apps/katib"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/katib/vanilla"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_models_web_app]

    providers = {
    aws = aws
  }
}

module "kubeflow_central_dashboard" {
  source            = "../../apps/central-dashboard"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/central-dashboard"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_katib]

    providers = {
    aws = aws
  }
}

module "kubeflow_admission_webhook" {
  source            = "../../apps/admission-webhook"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/admission-webhook"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_central_dashboard]

    providers = {
    aws = aws
  }
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

    providers = {
    aws = aws
  }
}

module "kubeflow_jupyter_web_app" {
  source            = "../../apps/jupyter-web-app"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/jupyter-web-app"
    version = "0.1.2"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_notebook_controller]

    providers = {
    aws = aws
  }
}


module "kubeflow_profiles_and_kfam" {
  source            = "../../apps/profiles-and-kfam"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/profiles-and-kfam"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_central_dashboard]

    providers = {
    aws = aws
  }
}

module "kubeflow_volumes_web_app" {
  source            = "../../apps/volumes-web-app"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/volumes-web-app"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_profiles_and_kfam]

    providers = {
    aws = aws
  }
}

module "kubeflow_tensorboards_web_app" {
  source            = "../../apps/tensorboards-web-app"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/tensorboards-web-app"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_volumes_web_app]

    providers = {
    aws = aws
  }
}

module "kubeflow_tensorboard_controller" {
  source            = "../../apps/tensorboard-controller"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/tensorboard-controller"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_tensorboards_web_app]

    providers = {
    aws = aws
  }
}

module "kubeflow_training_operator" {
  source            = "../../apps/training-operator"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/training-operator"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_tensorboard_controller]

    providers = {
    aws = aws
  }
}

module "kubeflow_aws_telemetry" {
  count = var.enable_aws_telemetry ? 1 : 0
  source            = "../../common/aws-telemetry"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/aws-telemetry"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_training_operator]

    providers = {
    aws = aws
  }
}

module "kubeflow_user_namespace" {
  source            = "../../common/user-namespace"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/user-namespace"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_aws_telemetry]

    providers = {
    aws = aws
  }
}

module "ack_sagemaker" {
  source            = "../../common/ack-sagemaker-controller"
  addon_context = module.context.addon_context

    providers = {
    aws = aws
  }
}
