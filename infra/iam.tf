# ============================================================================
# IAM 委托与策略（3 类委托 / 1 个角色）
# ============================================================================

# 委托：CodeArts Build 校验阶段使用（只读权限）
# 已修复：正确委托域为 op_svc_devcloud（CodeArts 前身 DevCloud 的 op_svc_ 旧名；
# op_svc_codearts / op_svc_codeci 均 404）。2026-09-09 主机实测确认。
resource "huaweicloud_identity_agency" "codebuild_validate" {
  count     = 1
  name                  = "${var.pipeline_name}-codebuild-validate"
  description           = "Agency for CodeArts Build validation tasks"
  duration              = "FOREVER"
  delegated_service_name = "op_svc_devcloud"
  # 注意：project_role 不能在 terraform 中附加——v1.97.1 provider 对 op_svc_devcloud
  # 委托生成角色绑定 URL 时 project 段为空（PUT .../projects//agencies/.../roles/...
  # 报 APIGW.0101）。需在华为云 IAM 控制台手动给本委托绑定项目角色：
  #   CodeArts Build Developer + OBS ReadOnlyAccess（项目 99c83fc2a22942c28276facbb90ba812）
}

# 委托：CodeArts Build 计划/应用阶段使用（默认 Tenant Administrator）
# 已修复：delegated_service_name 改为 op_svc_devcloud（同 codebuild_validate）。
resource "huaweicloud_identity_agency" "codebuild_execution" {
  count     = 1
  name                  = "${var.pipeline_name}-codebuild-execution"
  description           = "Agency for CodeArts Build plan/apply tasks"
  duration              = "FOREVER"
  delegated_service_name = "op_svc_devcloud"
  # 注意：project_role 不能在 terraform 中附加——与 codebuild_validate 同理，
  # v1.97.1 provider 对 op_svc_devcloud 委托生成角色绑定 URL 时 project 段为空
  # （PUT .../projects//agencies/.../roles/... 报 APIGW.0101）。需在华为云 IAM 控制台
  # 手动给本委托绑定项目角色：
  #   Tenant Administrator（项目 99c83fc2a22942c28276facbb90ba812）
  # 控制台绑定不受此 provider BUG 影响，绑定后即生效。
}

# 委托：事件网格（EG）调用 CodeArts Pipeline 使用
resource "huaweicloud_identity_agency" "eventbridge" {
  name                  = "${var.pipeline_name}-eventbridge"
  description           = "Agency for EG to invoke CodeArts Pipeline"
  duration              = "FOREVER"
  # API 回读为 op_svc_EG（大写），用小写会造成 plan 循环 diff
  delegated_service_name = "op_svc_EG"

  project_role {
    project = huaweicloud_codearts_project.main.id
    roles = [
      "CodeArts Pipeline Developer",
    ]
  }

  # provider 不回读 project_role 绑定，忽略之避免循环 diff（绑定实际生效）
  lifecycle {
    ignore_changes = [project_role]
  }
}

# 角色：CodeArts Pipeline 服务身份
# CodeArts Pipeline 的服务身份由 CodeArts 托管，仅在自定义外部权限场景使用
resource "huaweicloud_identity_role" "codepipeline" {
  name        = "${var.pipeline_name}-codepipeline"
  description = "Role for CodeArts Pipeline custom actions"
  type        = "AX"
  policy      = jsonencode({
    Version = "1.1"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codeartsbuild:StartJob",
          "codeartsbuild:ListJobs",
        ]
        Resource = ["*"]
      }
    ]
  })
}
