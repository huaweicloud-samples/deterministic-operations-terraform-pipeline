output "build_task" {
  description = "CodeArts Build 任务资源"
  value       = huaweicloud_codearts_build_task.this
}

output "build_task_id" {
  description = "CodeArts Build 任务 ID"
  value       = huaweicloud_codearts_build_task.this.id
}
