# ============================================================================
# 输出（与 AWS 输出保持结构对齐）
# ============================================================================

output "pipeline" {
  description = "CodeArts Pipeline 资源"
  value       = try(huaweicloud_codearts_pipeline.this[0], null)
  sensitive   = true
}

output "pipeline_id" {
  description = "CodeArts Pipeline ID"
  value       = try(huaweicloud_codearts_pipeline.this[0].id, null)
}

output "project_id" {
  description = "CodeArts Project ID"
  value       = huaweicloud_codearts_project.main.id
}

output "codebuild_validate_agencies" {
  description = "校验阶段 CodeArts Build 委托"
  value       = try(huaweicloud_identity_agency.codebuild_validate[0], null)
}

output "codebuild_execution_agency" {
  description = "计划/应用阶段 CodeArts Build 委托"
  value       = try(huaweicloud_identity_agency.codebuild_execution[0], null)
}

output "lts_log_group" {
  description = "流水线日志组"
  value       = huaweicloud_lts_group.pipeline_logs
}

output "lts_log_stream" {
  description = "流水线日志流"
  value       = huaweicloud_lts_stream.pipeline_logs
}

output "obs_artifacts_bucket" {
  description = "制品 OBS 桶"
  value       = huaweicloud_obs_bucket.artifacts
}

output "smn_topic" {
  description = "流水线通知 SMN 主题（可选）"
  value       = var.notifications == null ? null : huaweicloud_smn_topic.notifications[0]
}
