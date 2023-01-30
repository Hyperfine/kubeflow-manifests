terraform {
  required_version = ">= 1.2.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.30.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.13.1"
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority.0.data)
  token                  = var.use_exec_plugin_for_auth ? null : data.aws_eks_cluster_auth.kubernetes_token[0].token

  # EKS clusters use short-lived authentication tokens that can expire in the middle of an 'apply' or 'destroy'. To
  # avoid this issue, we use an exec-based plugin here to fetch an up-to-date token. Note that this code requires a
  # binary—either kubergrunt or aws—to be installed and on your PATH.
  dynamic "exec" {
    for_each = var.use_exec_plugin_for_auth ? ["once"] : []

    content {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = var.use_kubergrunt_to_fetch_token ? "kubergrunt" : "aws"
      args = (
        var.use_kubergrunt_to_fetch_token
        ? ["eks", "token", "--cluster-id", var.eks_cluster_name]
        : ["eks", "get-token", "--cluster-name", var.eks_cluster_name]
      )
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority.0.data)
    token                  = var.use_exec_plugin_for_auth ? null : data.aws_eks_cluster_auth.kubernetes_token[0].token

    # EKS clusters use short-lived authentication tokens that can expire in the middle of an 'apply' or 'destroy'. To
    # avoid this issue, we use an exec-based plugin here to fetch an up-to-date token. Note that this code requires a
    # binary—either kubergrunt or aws—to be installed and on your PATH.
    dynamic "exec" {
      for_each = var.use_exec_plugin_for_auth ? ["once"] : []

      content {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = var.use_kubergrunt_to_fetch_token ? "kubergrunt" : "aws"
        args = (
          var.use_kubergrunt_to_fetch_token
          ? ["eks", "token", "--cluster-id", var.eks_cluster_name]
          : ["eks", "get-token", "--cluster-name", var.eks_cluster_name]
        )
      }
    }
  }
}


module context {
  source = "../../iaac/terraform/utils/blueprints-extended-outputs"
  eks_cluster_id = var.eks_cluster_name
}
output test {
  value = module.context.addon_context
}


resource "kubernetes_namespace" "kubeflow" {
  metadata {
    labels = {
      control-plane = "kubeflow"
      istio-injection = "enabled"
    }

    name = "kubeflow"
  }
}

module "kubeflow_issuer" {
  source            = "../../iaac/terraform/common/kubeflow-issuer"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/kubeflow-issuer"
  }

  addon_context = module.context.addon_context
  depends_on = [kubernetes_namespace.kubeflow]
}

module "kubeflow_istio" {
  source            = "../../iaac/terraform/common/istio"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/istio-1-14"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_issuer]
}

module "kubeflow_dex" {
  source            = "../../iaac/terraform/common/dex"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/dex"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_istio]
}

module "kubeflow_oidc_authservice" {
  source            = "../../iaac/terraform/common/oidc-authservice"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/oidc-authservice"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_dex]
}

module "kubeflow_knative_serving" {
  source            = "../../iaac/terraform/common/knative-serving"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/knative-serving"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_oidc_authservice]
}

module "kubeflow_cluster_local_gateway" {
  source            = "../../iaac/terraform/common/cluster-local-gateway"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/cluster-local-gateway"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_knative_serving]
}

module "kubeflow_knative_eventing" {
  source            = "../../iaac/terraform/common/knative-eventing"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/knative-eventing"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_cluster_local_gateway]
}

module "kubeflow_roles" {
  source            = "../../iaac/terraform/common/kubeflow-roles"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/kubeflow-roles"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_knative_eventing]
}

module "kubeflow_istio_resources" {
  source            = "../../iaac/terraform/common/kubeflow-istio-resources"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/kubeflow-istio-resources"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_roles]
}

module "kubeflow_pipelines" {
  source            = "../../iaac/terraform/apps/kubeflow-pipelines"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/kubeflow-pipelines/vanilla"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_istio_resources]
}

module "kubeflow_kserve" {
  source            = "../../iaac/terraform/common/kserve"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/kserve"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_pipelines]
}

module "kubeflow_models_web_app" {
  source            = "../../iaac/terraform/apps/models-web-app"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/models-web-app"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_kserve]
}

module "kubeflow_katib" {
  source            = "../../iaac/terraform/apps/katib"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/katib/vanilla"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_models_web_app]
}

module "kubeflow_central_dashboard" {
  source            = "../../iaac/terraform/apps/central-dashboard"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/central-dashboard"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_katib]
}

module "kubeflow_admission_webhook" {
  source            = "../../iaac/terraform/apps/admission-webhook"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/admission-webhook"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_central_dashboard]
}

module "kubeflow_notebook_controller" {
  source            = "../../iaac/terraform/apps/notebook-controller"
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
  depends_on = [module.kubeflow_admission_webhook]
}

module "kubeflow_jupyter_web_app" {
  source            = "../../iaac/terraform/apps/jupyter-web-app"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/jupyter-web-app"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_notebook_controller]
}

module "kubeflow_profiles_and_kfam" {
  source            = "../../iaac/terraform/apps/profiles-and-kfam"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/profiles-and-kfam"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_jupyter_web_app]
}

module "kubeflow_volumes_web_app" {
  source            = "../../iaac/terraform/apps/volumes-web-app"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/volumes-web-app"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_profiles_and_kfam]
}

module "kubeflow_tensorboards_web_app" {
  source            = "../../iaac/terraform/apps/tensorboards-web-app"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/tensorboards-web-app"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_volumes_web_app]
}

module "kubeflow_tensorboard_controller" {
  source            = "../../iaac/terraform/apps/tensorboard-controller"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/tensorboard-controller"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_tensorboards_web_app]
}

module "kubeflow_training_operator" {
  source            = "../../iaac/terraform/apps/training-operator"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/apps/training-operator"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_tensorboard_controller]
}

module "kubeflow_aws_telemetry" {
  count = var.enable_aws_telemetry ? 1 : 0
  source            = "../../iaac/terraform/common/aws-telemetry"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/aws-telemetry"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_training_operator]
}

module "kubeflow_user_namespace" {
  source            = "../../iaac/terraform/common/user-namespace"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/common/user-namespace"
  }
  addon_context = module.context.addon_context
  depends_on = [module.kubeflow_aws_telemetry]
}

module "ack_sagemaker" {
  source            = "../../iaac/terraform/common/ack-sagemaker-controller"
  addon_context = module.context.addon_context
}
