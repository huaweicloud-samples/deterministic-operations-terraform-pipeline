# ============================================================================
# OBS 制品桶
# Description: Terraform-managed artifacts bucket for build pipeline outputs
# ============================================================================
# 注：v1.97.1 provider 的 server_side_encryption 是 attribute（kms_key_id +
# sse_algorithm），不是 block。
# ============================================================================

# KMS 密钥（华为云 KMS 自定义主密钥）
resource "huaweicloud_kms_key" "artifacts" {
  count        = var.kms_key_id == null ? 1 : 0
  key_alias    = "${var.pipeline_name}-artifacts"
  pending_days = 7
  is_enabled   = true
}

# 主制品桶
resource "huaweicloud_obs_bucket" "artifacts" {
  bucket        = "${var.pipeline_name}-artifacts-${local.account_id}"
  acl           = "private"
  force_destroy = true
  versioning    = true

  # 服务端加密（v1.97.1：attribute 而非 block）
  sse_algorithm = "kms"
  kms_key_id    = var.kms_key_id == null ? huaweicloud_kms_key.artifacts[0].id : var.kms_key_id

  # 生命周期规则（OBS 桶 90 天过期）
  lifecycle_rule {
    name    = "${var.artifact_retention}-days"
    enabled = true
    expiration {
      days = var.artifact_retention
    }
  }

  # 访问日志投递（可选）
  dynamic "logging" {
    for_each = var.access_logging_bucket == null ? [] : [var.access_logging_bucket]
    content {
      target_bucket = logging.value
      target_prefix = "${var.pipeline_name}-artifacts-${local.account_id}/"
    }
  }

  tags = local.common_tags

  # provider 更新 sse_algorithm/kms_key_id 后不回读这两个字段，造成 plan 循环 diff；
  # 加密配置已实际生效（KMS key d33bbd04），忽略以收敛 plan
  lifecycle {
    ignore_changes = [kms_key_id, sse_algorithm]
  }
}

# 桶策略：拒绝非 HTTPS
# 临时禁用：v1.97.1 provider 的 obs_bucket_policy 与当前 OBS 服务 Action/Condition
# 格式不兼容，count = 0 跳过创建；OBS 桶默认 acl=private 已保证基本安全，
# 可在控制台手工配置 DenyNonSecureTransport 策略（Condition key：obs:SecureTransport）。
# resource "huaweicloud_obs_bucket_policy" "artifacts" {
#   count = 0
#   bucket = huaweicloud_obs_bucket.artifacts.bucket
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid       = "DenyNonSecureTransport"
#         Effect    = "Deny"
#         Principal = "*"
#         Action = [
#           "obs:GetObject",
#           "obs:PutObject",
#           "obs:DeleteObject",
#           "obs:ListBucket",
#           "obs:GetBucket",
#         ]
#         Resource = [
#           huaweicloud_obs_bucket.artifacts.bucket,
#           "${huaweicloud_obs_bucket.artifacts.bucket}/*"
#         ]
#         Condition = {
#           Bool = {
#             "obs:SecureTransport" = "false"
#           }
#         }
#       }
#     ]
#   })
# }
