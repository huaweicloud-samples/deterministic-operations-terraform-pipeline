# ============================================================================
# 变量定义
# ============================================================================

variable "region" {
  description = "华为云区域"
  type        = string
  default     = "cn-north-4"
}

variable "project_id" {
  description = "CodeArts 项目所在华为云 Project ID（可空，自动按 name 查询）"
  type        = string
  default     = null
}

variable "project_name" {
  description = "CodeArts 项目名称（与 project_id 二选一；优先按 name 查询）"
  type        = string
  default     = "default"
}

variable "pipeline_name" {
  description = "流水线名称（用于资源命名前缀）"
  type        = string
}

variable "repo" {
  description = "源代码仓库（CodeHub 仓库 ID / GitHub org/repo）"
  type        = string
}

# 可选参数

variable "access_logging_bucket" {
  description = "OBS 访问日志投递目标桶名（留空不启用日志投递）"
  type        = string
  default     = null
}

variable "account_id" {
  description = "华为云账户 ID（32 位 hex 字符串，用于拼接 OBS 桶名与 KMS 命名；v1.97.1 provider 不暴露 data.huaweicloud_identity_account，由用户传入）"
  type        = string
  default     = "00000000000000000000000000000000"
  validation {
    condition     = can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32-character hex string (Huawei Cloud account ID format)"
  }
}

variable "hw_access_key" {
  description = "Huawei Cloud Access Key ID（敏感；建议通过部署脚本注入环境变量，不要写入 tfvars 文件）"
  type        = string
  sensitive   = true
  default     = null
}

variable "hw_secret_key" {
  description = "Huawei Cloud Secret Access Key（敏感；建议通过部署脚本注入环境变量，不要写入 tfvars 文件）"
  type        = string
  sensitive   = true
  default     = null
}

variable "artifact_retention" {
  description = "OBS 产物桶生命周期过期天数"
  type        = number
  default     = 90
}

variable "branch" {
  description = "源代码分支"
  type        = string
  default     = "main"
}

variable "build_timeout" {
  description = "CodeArts Build 任务超时（分钟）"
  type        = number
  default     = 10
}

variable "build_override" {
  description = "覆盖构建目录 / 镜像 / buildspec"
  type = object({
    directory       = optional(string, ".")
    plan_buildspec  = optional(string)
    plan_image      = optional(string)
    apply_buildspec = optional(string)
    apply_image     = optional(string)
  })
  default = {}
}

variable "checkov_skip" {
  description = "Checkov 跳过的检查项列表"
  type        = list(string)
  default     = [""]
}

variable "checkov_version" {
  type        = string
  default     = "3.2.0"
  description = "Checkov 版本"
  validation {
    condition     = can(regex("^\\d+\\.\\d+\\.\\d+$", var.checkov_version))
    error_message = "checkov version must use format x.y.z"
  }
}

variable "codebuild_policy" {
  description = "覆盖 CodeArts Build 默认权限策略（留空走 Tenant Administrator）"
  type        = string
  default     = null
}

variable "connection_arn" {
  description = "CodeArts 外部源接入连接标识（连接 GitHub/GitLab 时填写）"
  type        = string
  default     = null
}

variable "detect_changes" {
  description = "是否启用外部源变更检测（GitHub webhook）"
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "OBS 加密使用的 KMS 密钥 ID（留空使用 OBS 默认密钥）"
  type        = string
  default     = null
}

variable "log_retention" {
  description = "LTS 日志组 TTL（天）"
  type        = number
  default     = 90
}

variable "mode" {
  description = "流水线执行模式（SUPERSEDED / PARALLEL / QUEUED 映射为 stage parallelism）"
  type        = string
  default     = "SUPERSEDED"
  validation {
    condition     = contains(["SUPERSEDED", "PARALLEL", "QUEUED"], var.mode)
    error_message = "unsupported pipeline mode"
  }
}

variable "notifications" {
  description = "SMN 通知配置（sns_topic / events / detail_type）"
  type = object({
    sns_topic   = string
    events      = list(string)
    detail_type = string
  })
  default = null
}

variable "source_type" {
  description = "源代码源类型（codehub / github / gitlab）"
  type        = string
  default     = "codehub"
  validation {
    condition     = contains(["codehub", "github", "gitlab"], var.source_type)
    error_message = "source_type must be one of codehub, github, gitlab"
  }
}

variable "github_endpoint_id" {
  description = "CodeArts 服务扩展点 ID（GitHub OAuth 授权连接），source_type=github 时必填"
  type        = string
  default     = null
}

variable "tags" {
  description = "TagNAG 检查的目标标签（空串跳过 tags 阶段）"
  type        = string
  default     = ""
}

variable "tagnag_version" {
  type        = string
  default     = "0.7.9"
  description = "TagNAG 版本"
  validation {
    condition     = can(regex("^\\d+\\.\\d+\\.\\d+$", var.tagnag_version))
    error_message = "tagnag version must use format x.y.z"
  }
}

variable "terraform_version" {
  type        = string
  default     = "1.12.0"
  description = "Terraform 版本"
  validation {
    condition     = can(regex("^\\d+\\.\\d+\\.\\d+$", var.terraform_version))
    error_message = "terraform version must use format x.y.z"
  }
}

variable "tflint_version" {
  type        = string
  default     = "0.61.0"
  description = "TFLint 版本"
  validation {
    condition     = can(regex("^\\d+\\.\\d+\\.\\d+$", var.tflint_version))
    error_message = "tflint version must use format x.y.z"
  }
}

variable "vpc" {
  description = "构建任务的 VPC 联网配置（空对象 = 不启用 VPC 联网）"
  type = object({
    vpc_id             = string
    subnets            = list(string)
    security_group_ids = list(string)
  })
  default = null
}
