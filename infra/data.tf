# ============================================================================
# 数据源（华为云 IAM 当前账号）
# ============================================================================
# 注：v1.97.1 provider 不暴露 data.huaweicloud_identity_account；
# 项目 ID / 账户 ID 改为通过 var.project_id / var.account_id 显式传入，
# 避免在 plan 阶段因华为云 API 失败导致 project_role 静态校验失败。

locals {
  region     = var.region
  project_id = var.project_id
  account_id = var.account_id
}
