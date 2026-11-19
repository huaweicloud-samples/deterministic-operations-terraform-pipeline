# ============================================================================
# CodeArts Build 任务（validate / fmt / lint / sast / tags / plan / apply 共 6-7 个）
# ============================================================================
# v1.97.1 provider 限制：
#   - 资源名 huaweicloud_codearts_build_task（精简形态，仅 arch/name/project_id/flavor）
#   - image_address / build_spec / agency / host_network 字段在本版本未暴露
#   - codearts_project 没有 source block 也没有 tags 字段
# ============================================================================

# CodeArts 项目（承载流水线与构建任务）
# 注：项目名不跟随 pipeline_name 改名——华为云 ProjectMan 项目重命名在云端已有
# 同名项目时报 PM.02100508（demo-pipeline-v2 项目由历史部署创建）。项目仅作容器，
# 名字与 pipeline 名解耦，避免 apply 反复撞重名。
resource "huaweicloud_codearts_project" "main" {
  name        = "demo-pipeline"
  description = "CodeArts project for ${var.pipeline_name} CI/CD"
  type        = "scrum"
  template_id = "0"

  lifecycle {
    ignore_changes = [name, description]
  }
}

# CodeArts Build - 校验阶段（validate / fmt / lint / sast / tags）
module "build_validate" {
  source   = "./modules/codebuild"
  for_each = var.tags == "" ? local.validation_stages : local.conditional_validation_stages

  pipeline_name          = var.pipeline_name
  stage_key              = each.key
  project_id             = huaweicloud_codearts_project.main.id
  lts_group_id           = huaweicloud_lts_group.pipeline_logs.id
  environment_variables  = var.tags == "" ? local.env_var : local.conditional_env_var
  common_tags            = local.common_tags
}

# CodeArts Build - 计划阶段
module "build_plan" {
  source = "./modules/codebuild"

  pipeline_name         = var.pipeline_name
  stage_key             = "plan"
  project_id            = huaweicloud_codearts_project.main.id
  lts_group_id          = huaweicloud_lts_group.pipeline_logs.id
  environment_variables = local.env_var
  common_tags           = local.common_tags
}

# CodeArts Build - 应用阶段
module "build_apply" {
  source = "./modules/codebuild"

  pipeline_name         = var.pipeline_name
  stage_key             = "apply"
  project_id            = huaweicloud_codearts_project.main.id
  lts_group_id          = huaweicloud_lts_group.pipeline_logs.id
  environment_variables = local.env_var
  common_tags           = local.common_tags
}
