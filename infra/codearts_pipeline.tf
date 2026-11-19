# ============================================================================
# CodeArts Pipeline（含 4 阶段编排 / SMN 通知）
# ============================================================================
# CodeArts Pipeline 使用 JSON 内联的 definition 描述 stages / jobs / steps；
# 通过 stages[].jobs[].steps[].task 标识符（official_devcloud_*）绑定构建任务。
# ============================================================================

# LTS 日志组（90 天 TTL）
resource "huaweicloud_lts_group" "pipeline_logs" {
  group_name  = "${var.pipeline_name}-logs"
  ttl_in_days = var.log_retention
}

resource "huaweicloud_lts_stream" "pipeline_logs" {
  group_id    = huaweicloud_lts_group.pipeline_logs.id
  stream_name = "${var.pipeline_name}-stream"
}

# CodeArts Pipeline 主资源
# 跳过创建：provider v1.97.1 的 sources payload 与当前 Pipeline v5 API 不兼容，
# codehub / github 源均报 DEVPIPE.00011000（"流水线源类型必须为代码源或制品源"），
# 即使 repo 为真实仓库也无法通过校验。Pipeline 实体（7696d44c-...）由控制台/API 手工创建。
# 待 provider 升级适配 v5 API 后改回 count 表达式。
resource "huaweicloud_codearts_pipeline" "this" {
  count       = 0
  project_id  = huaweicloud_codearts_project.main.id
  name        = var.pipeline_name
  description = "Pipeline for ${var.pipeline_name}"
  is_publish  = true

  # 源代码源：CodeHub / GitHub / GitLab
  dynamic "sources" {
    for_each = var.source_type == "codehub" ? [1] : []
    content {
      type = "codehub"
      dynamic "params" {
        for_each = var.source_type == "codehub" ? [1] : []
        content {
          codehub_id     = var.repo
          default_branch = var.branch
        }
      }
    }
  }

  dynamic "sources" {
    for_each = var.source_type != "codehub" ? [1] : []
    content {
      type = var.source_type
      dynamic "params" {
        for_each = var.source_type != "codehub" ? [1] : []
        content {
          # v1.97.1 schema：sources.params 合法属性为 git_type / repo_name /
          # endpoint_id / default_branch 等，没有 repo_id（repo_id 只存在于
          # triggers block）。GitHub 源需配 OAuth 服务扩展点 endpoint_id。
          git_type       = var.source_type
          repo_name      = var.repo
          endpoint_id    = var.github_endpoint_id
          default_branch = var.branch
        }
      }
    }
  }

  # 触发器（push / merge_request）
  triggers {
    git_type = var.source_type
    repo_id  = var.repo
    events {
      type   = "push"
      enable = true
    }
    events {
      type   = "merge_request"
      enable = true
    }
  }

  # 自定义变量
  variables {
    name      = "TF_VERSION"
    type      = "string"
    value     = var.terraform_version
    is_secret = false
  }

  # 流水线定义：JSON 内联 stages / jobs / steps
  # 流水线阶段编排说明：
  # CodeArts 阶段顺序：Source → Validation → Plan（含 PlanApproval）→ Apply
  # Build 步骤用 official_devcloud_build 任务；Approval 用 official_devcloud_checkpoint
  definition = jsonencode({
    pipeline = {
      name        = var.pipeline_name
      description = "Deploy Terraform with Terraform"
      version     = 2
      parallelism = var.mode == "PARALLEL"
    }
    stages = concat(
      [
        {
          name        = "Source"
          identifier  = "stage_source"
          sequence    = 1
          parallel    = false
          jobs = [{
            name       = "SourceJob"
            identifier = "job_source"
            exec_type  = "default"
            steps = [{
              name    = "Checkout"
              task    = "official_devcloud_codeCheck"
              inputs  = [{ key = "branch", value = var.branch }]
            }]
          }]
        }
      ],
      var.tags == "" ? [] : [{
        name        = "TagCheck"
        identifier  = "stage_tag"
        sequence    = 2
        parallel    = false
        jobs = [{
          name       = "TagNAG"
          identifier = "job_tag"
          exec_type  = "default"
          steps = [{
            name    = "TagScan"
            task    = "official_devcloud_build"
            inputs  = [
              { key = "jobId", value = module.build_validate["tags"].build_task_id }
            ]
          }]
        }]
      }],
      [
        {
          name        = "Validation"
          identifier  = "stage_validation"
          sequence    = 3
          parallel    = true
          jobs = [for k, j in module.build_validate : {
            name       = "Validation-${k}"
            identifier = "job_validation_${k}"
            exec_type  = "default"
            steps = [{
              name    = "Run-${k}"
              task    = "official_devcloud_build"
              inputs  = [{ key = "jobId", value = j.build_task_id }]
            }]
          }]
        },
        {
          name        = "Plan"
          identifier  = "stage_plan"
          sequence    = 4
          parallel    = false
          jobs = [
            {
              name       = "TerraformPlan"
              identifier = "job_plan"
              exec_type  = "default"
              steps = [{
                name    = "Plan"
                task    = "official_devcloud_build"
                inputs  = [{ key = "jobId", value = module.build_plan.build_task_id }]
              }]
            },
            {
              name       = "PlanApproval"
              identifier = "job_approval"
              exec_type  = "default"
              steps = [{
                name    = "ManualReview"
                task    = "official_devcloud_checkpoint"
                inputs  = [{
                  key   = "approvers"
                  value = var.notifications == null ? "admin" : var.notifications["sns_topic"]
                }]
              }]
            }
          ]
        },
        {
          name        = "Apply"
          identifier  = "stage_apply"
          sequence    = 5
          parallel    = false
          jobs = [{
            name       = "TerraformApply"
            identifier = "job_apply"
            exec_type  = "default"
            steps = [{
              name    = "Apply"
              task    = "official_devcloud_build"
              inputs  = [{ key = "jobId", value = module.build_apply.build_task_id }]
            }]
          }]
        }
      ]
    )
  })

  # 运行期由 CodeArts 控制台与用户改写名称/描述/Crontab 时不让 Terraform 回滚
  lifecycle {
    ignore_changes = [
      description,
    ]
  }
}
