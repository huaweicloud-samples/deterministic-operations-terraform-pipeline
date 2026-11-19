# ============================================================================
# 局部变量
# ============================================================================

locals {
  # 命名空间与标签
  name_prefix = var.pipeline_name
  common_tags = {
    pipeline = var.pipeline_name
    managed  = "terraform"
  }

  # 校验阶段映射（华为云 SWR 镜像标识）
  # CodeArts Build 不直接复用通用镜像字符串，按阶段绑定 SWR 镜像
  validation_stages = {
    validate = "swr.cn-north-4.myhuaweicloud.com/codeartsbuild/terraform:${var.terraform_version}"
    fmt      = "swr.cn-north-4.myhuaweicloud.com/codeartsbuild/terraform:${var.terraform_version}"
    lint     = "swr.cn-north-4.myhuaweicloud.com/codearts/amazonlinux-3-x86_64:latest"
    sast     = "swr.cn-north-4.myhuaweicloud.com/codearts/amazonlinux-3-x86_64:latest"
  }

  conditional_validation_stages = merge(local.validation_stages, {
    tags = "swr.cn-north-4.myhuaweicloud.com/codearts/amazonlinux-3-x86_64:latest"
  })

  # 构建环境变量
  env_var = {
    TF_VERSION          = var.terraform_version
    TFLINT_VERSION      = var.tflint_version
    CHECKOV_VERSION     = var.checkov_version
    CHECKOV_SKIPS       = join(",", var.checkov_skip)
    TERRAFORM_DIRECTORY = var.build_override["directory"]
  }

  conditional_env_var = merge(local.env_var, {
    TAGS           = var.tags
    TAGNAG_VERSION = var.tagnag_version
  })
}
