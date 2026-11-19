# ============================================================================
# modules/codebuild 主体（封装 CodeArts Build 任务的创建）
# Description: Module encapsulating CodeArts Build task creation with optional LTS log streams
# ============================================================================
# 注：v1.97.1 provider 仅暴露 huaweicloud_codearts_build_task（精简形态，
# 必填字段仅 arch / name / project_id）。原 job 资源中的 image_address /
# build_spec / agency / host_network 等字段在本版本中无法通过 IaC 配置，
# 须在控制台手工补齐。

resource "huaweicloud_codearts_build_task" "this" {
  project_id = var.project_id
  name       = "${var.pipeline_name}-${var.stage_key}"
  arch       = "x86-64"
  flavor     = "2u8g"

  # 华为云 CodeArts Build 的 /v1/job/update API 不支持修改任务名（422），
  # pipeline_name 变更时保留云端任务名，避免 update 撞 422。
  lifecycle {
    ignore_changes = [name]
  }
}

# 启用构建日志推送至 LTS
resource "huaweicloud_lts_stream" "build_logs" {
  for_each    = { for k, _ in var.environment_variables : k => k }
  group_id    = var.lts_group_id
  stream_name = "${var.pipeline_name}-${var.stage_key}-${each.key}"
  tags        = var.common_tags
}
