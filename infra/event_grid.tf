# ============================================================================
# 事件网格（EG）+ SMN 通知
# ============================================================================
# CodeArts Pipeline 自身已通过 .triggers 块支持 Git 触发（见 codearts_pipeline.tf）；
# 额外的事件驱动由 EG 补充：CodeHub / OBS / 自定义事件 → CodeArts Pipeline / SMN
# ============================================================================
# v1.97.1 资源命名：
#   huaweicloud_eg_channel      → huaweicloud_eg_custom_event_channel
#   huaweicloud_eg_subscription → huaweicloud_eg_event_subscription（targets 内嵌）
#   huaweicloud_eg_target       → 字段在 v1.97.1 已并入 subscription.targets 内嵌块

# SMN 通知主题
resource "huaweicloud_smn_topic" "notifications" {
  count        = var.notifications == null ? 0 : 1
  name         = "${var.pipeline_name}-notifications"
  display_name = "${var.pipeline_name} pipeline notifications"
  tags         = local.common_tags
}

# SMN 订阅：邮件/HTTP/FunctionGraph
resource "huaweicloud_smn_subscription" "email" {
  count     = var.notifications == null ? 0 : 1
  topic_urn = huaweicloud_smn_topic.notifications[0].topic_urn
  protocol  = "email"
  endpoint  = var.notifications["sns_topic"]
}

# EG 通道：EG 投递管道
resource "huaweicloud_eg_custom_event_channel" "pipeline_channel" {
  name        = "${var.pipeline_name}-channel"
  description = "Event channel for ${var.pipeline_name} pipeline triggers"
}

# EG 自定义事件源：监听 CodeHub 仓库推送
# 由 CodeHub webhook 推送到 EG 自定义通道，事件类型由 webhook 配置决定
resource "huaweicloud_eg_custom_event_source" "codehub_push" {
  count       = var.source_type == "codehub" ? 1 : 0
  name        = "${var.pipeline_name}-codehub-push"
  channel_id  = huaweicloud_eg_custom_event_channel.pipeline_channel.id
  description = "CodeHub repository push events for ${var.pipeline_name}"
}

# EG 订阅：自定义事件 → 触发 CodeArts Pipeline
# 事件源在 CodeHub 侧配 webhook 推送到 EG channel
# 跳过创建：targets.detail 引用 pipeline id，而 pipeline 由控制台手工创建
# （provider v1.97.1 无法通过 API 创建，见 codearts_pipeline.tf 注释），订阅随之手工配置。
resource "huaweicloud_eg_event_subscription" "codehub_to_pipeline" {
  count      = 0
  name       = "${var.pipeline_name}-codehub-sub"
  channel_id = huaweicloud_eg_custom_event_channel.pipeline_channel.id

  sources {
    name          = "${var.pipeline_name}-codehub-src"
    provider_type = "codehub"
    filter_rule   = jsonencode({
      "source" = [{
        "type" = "codehub"
      }]
    })
  }

  targets {
    name          = "${var.pipeline_name}-invoke-pipeline"
    provider_type = "codearts"
    detail        = jsonencode({
      pipeline_id = huaweicloud_codearts_pipeline.this[0].id
      project_id  = huaweicloud_codearts_project.main.id
    })
    detail_name = "codearts_detail"
    transform   = jsonencode({
      type   = "ORIGINAL"
      value  = ""
      template = ""
    })
  }
}
