# ============================================================================
# modules/codebuild 变量（封装 CodeArts Build 任务通用参数）
# ============================================================================
# 注：v1.97.1 provider 仅支持精简形态（name/project_id/arch/flavor），
# image_address / build_spec / agency / vpc 等字段暂留作 future-use，
# 当前不在 main.tf 中消费。

variable "pipeline_name" {
  description = "流水线名称"
  type        = string
}

variable "stage_key" {
  description = "阶段键（validate / fmt / lint / sast / tags）"
  type        = string
}

variable "project_id" {
  description = "CodeArts 项目 ID"
  type        = string
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}

variable "lts_group_id" {
  description = "LTS 日志组 ID（CodeArts Build 日志流归属于此组）"
  type        = string
}

variable "common_tags" {
  description = "应用到所有资源的通用 tags（覆盖变量便于模块独立打标）"
  type        = map(string)
  default     = {}
}
