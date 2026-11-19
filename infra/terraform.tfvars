region         = "cn-north-4"
project_id     = "00000000000000000000000000000000"
project_name   = "default"
pipeline_name  = "demo-pipeline-v2"
# 必须改为真实 GitHub 仓库（格式 user/repo），Pipeline 才会创建；当前占位会让 Pipeline 被跳过
# 源码仓使用 CodeHub（repo 传 CodeHub 数字仓库 ID）。
# GitHub 源类型被 CodeArts Pipeline v5 创建 API 拒绝（DEVPIPE.00011000
# "流水线源类型必须为代码源或制品源"），CodeHub 是一等公民代码源。
source_type    = "codehub"
repo           = "3083752"
branch         = "main"
account_id     = "00000000000000000000000000000000"
# 复用已存在的 KMS 密钥（demo-pipeline-v2-artifacts），不再由 terraform 创建/销毁
# KMS 密钥删除是异步 7 天等待期，由 terraform 管理生命周期会在 replace 时反复撞 alias
kms_key_id     = "d33bbd04-ebc1-47c0-ace3-a3cdc12491e6"
