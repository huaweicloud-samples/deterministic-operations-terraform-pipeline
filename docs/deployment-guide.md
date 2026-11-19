# 部署指导书

## 1. 前置条件

| 项 | 要求 | 说明 |
|---|---|---|
| **账号** | 已开通华为云账号并完成实名认证 | 个人/企业账号均可 |
| **权限** | 账号具备 IAM **Tenant Administrator** 或等效权限 | 用于创建 CodeArts / OBS / IAM 委托 / LTS / SMN / KMS / EG |
| **Region** | 推荐 `cn-north-4` | CodeArts / OBS / LTS / SMN 跨 region 能力存在差异 |
| **Terraform** | `>= 1.5.7` | IaC 部署工具 |
| **huaweicloud Provider** | `= 1.97.1` | 华为云 Terraform Provider（与本仓库本地 mirror 版本严格对齐） |
| **本地网络** | 能访问 `obs.cn-north-4.myhuaweicloud.com` 与 Terraform Registry（可走本地 mirror） | 沙箱通常受限，须在用户本地 PC 执行 |
| **SWR 镜像预置** | `swr.cn-north-4.myhuaweicloud.com/codeartsbuild/terraform:1.12.0` | 需提前推送到 SWR；若无镜像须先 `docker push` |
| **AK/SK** | 在华为云「我的凭证」页面获取 Access Key ID 与 Secret Access Key，并填入部署脚本 | **不要**将凭据写入任何代码或配置文件 |

## 2. 快速开始

### 步骤 1：进入部署目录

```powershell
Set-Location D:\workbuddy\huaweicloud\deterministic-operations-terraform-pipeline\infra
```

### 步骤 2：初始化 Terraform（使用本地 mirror）

> 若你的本地 `~/.terraformrc` 已配置 `filesystem_mirror`，Terraform 会自动从 mirror 拉取 provider。

```powershell
terraform init
```

**预期输出**：
```
Terraform has been successfully initialized!
```

### 步骤 3：预演资源变更

```powershell
terraform plan -out=tfplan
```

**预期输出**：
```
Plan: N to add, 0 to change, 0 to destroy.
```

### 步骤 4：执行部署

```powershell
terraform apply -auto-approve tfplan
```

**预期输出**：
```
Apply complete! Resources: N added, 0 changed, 0 destroyed.
```

### 步骤 5：记录关键输出

```powershell
terraform output
```

**预期输出**：列出 `pipeline_id` / `project_id` / `obs_artifacts_bucket` / `lts_log_group` / `smn_topic` 等字段值。

## 3. 完整部署步骤（含 PowerShell 块）

```powershell
# 1. 准备目录
Set-Location D:\workbuddy\huaweicloud\deterministic-operations-terraform-pipeline

# 2. 创建 terraform.tfvars
@"
region         = "cn-north-4"
project_name   = "default"
pipeline_name  = "myorg-pipeline"
repo           = "myorg/myrepo"
branch         = "main"
source_type    = "github"
connection_arn = "github-connection-arn"

# 可选：VPC 联网
vpc = {
  vpc_id             = "vpc-xxxxxxxx"
  subnets            = ["subnet-xxxxxxxx"]
  security_group_ids = ["sg-xxxxxxxx"]
}

# 可选：SMN 通知
notifications = {
  sns_topic   = "ops-team@example.com"
  events      = ["pipeline.failed", "pipeline.succeeded"]
  detail_type = "BASIC"
}
"@ | Out-File -Encoding utf8 terraform.tfvars

# 3. 进入 infra 目录
Set-Location infra

# 4. 设置凭据（替换为你的实际 AK/SK）
$env:TF_VAR_access_key = "<HW_ACCESS_KEY>"
$env:TF_VAR_secret_key = "<HW_SECRET_KEY>"

# 5. 初始化并部署
terraform init
terraform plan -out=tfplan
terraform apply -auto-approve tfplan

# 6. 记录关键输出
terraform output
```

## 4. 自定义配置

| 场景 | 设置项 | 示例 |
|---|---|---|
| 仅做校验 | `tags = ""`（默认） | 不启用 TagNAG 阶段 |
| 启用标签检查 | `tags = "Environment[Dev,Prod]"` | 多轮 tag 校验 |
| 覆盖计划镜像 | `build_override.plan_image = "swr.cn-north-4.myhuaweicloud.com/your-org/your-image:tag"` | 自定义 SWR 镜像 |
| 收紧执行权限 | `codebuild_policy = "CodeArts Build Developer"` | 替代默认 Tenant Administrator |
| OBS 加密用自定义 KMS | `kms_key_id = "<your-kms-key-id>"` | 跳过自动 KMS 密钥创建 |
| 跨账号/跨 region | `region = "cn-east-3"` | 切换 region |

## 5. 验证清单（部署后必做）

> **强制实测**：本节所列验证步骤在交付前已经本会话**列出预期命令与判定条件**。请按本节步骤自行验证，确认业务功能可用后方可视为交付完成。

### 验证 1：OBS 制品桶已创建

```powershell
# 列出桶
terraform output -json obs_artifacts_bucket | ConvertFrom-Json
```

**预期输出**：含 `bucket` 字段，值为 `<pipeline_name>-artifacts-<account_id>`

### 验证 2：CodeArts 项目与流水线已创建

```powershell
# 控制台路径：CodeArts → 项目列表 → <pipeline_name>
# 或 CLI：
$projects = hcloud codearts project list --region cn-north-4
$projects | Where-Object { $_.name -eq "myorg-pipeline" }
```

**预期输出**：项目存在，类型 `scrum`，含 1 条流水线

### 验证 3：构建任务已就绪

```powershell
# 控制台：CodeArts → Build → 任务列表
# 预期：7 个任务（validate / fmt / lint / sast / tags / plan / apply）
```

### 验证 4：LTS 日志组已创建

```powershell
$logGroup = hcloud lts group list --region cn-north-4
$logGroup | Where-Object { $_.group_name -eq "myorg-pipeline-logs" }
```

### 验证 5：IAM 委托已就绪

```powershell
hcloud iam agency list --region cn-north-4 | Where-Object { $_.name -like "myorg-pipeline-*" }
```

**预期输出**：3 个 agency（codebuild_validate / codebuild_execution / eventbridge）

### 验证 6：触发流水线（端到端）

在 CodeArts 控制台选择流水线 → 点击「运行」→ 观察 4 阶段执行：

- Source：检出代码
- Validation：4 个并行任务（validate / fmt / lint / sast）全部 PASS
- Plan：plan 任务 PASS
- PlanApproval：等待人工审批（点击「通过」）
- Apply：apply 任务 PASS

**预期结果**：流水线整体 PASS；OBS 制品桶有新的 `apply-{日期}.zip` 产物；LTS 日志可查 7 个任务的完整输出

## 6. 费用说明

> 本节为占位章节；具体费用信息仅在 `others/` 内部过程产物中保留，不对外公开。
>
> **本节无对外公开内容**。如需了解数量级与计费规则，请在部署前自行查阅华为云官方计费文档（CodeArts / OBS / KMS / LTS / SMN / EG），并按 `cost-guard` 流程在 apply 前完成估算。

本实践涉及的计费项如下：

| 服务 | 计费项 | 数量级 |
|---|---|---|
| OBS 桶 | 存储 + 请求 | 制品桶（GB 级）+ 少量请求 |
| KMS 密钥 | 密钥实例 + API 调用 | 1 个密钥（默认 OBS 加密可省） |
| LTS 日志 | 存储 + 写入 | 1 个 group + 1 个 stream（90 天 TTL） |
| SMN 主题 | API 请求 | 1 个 topic + 1 个 email 订阅（邮件无 API 费） |
| CodeArts Build | 构建时长 | 7 个任务 × 每次流水线触发 |
| CodeArts Pipeline | 流水线执行次数 | 1 条流水线 |

**无公网入口**（不含 EIP / ELB / NAT），不产生公网流量费。

> 调试期实测用量均在 CodeArts 免费体验额度内（构建时长 600 分钟/月、流水线并发 5 个）。超出免费额度后 CodeArts Build / Pipeline 的单价未实测，apply 前如有疑问查 https://support.huaweicloud.com/price-devcloud/codearts_29_0033.html 。

## 7. 清理资源

```powershell
Set-Location D:\workbuddy\huaweicloud\deterministic-operations-terraform-pipeline\infra
terraform destroy -auto-approve
```

**预期输出**：`Destroy complete! Resources: N destroyed.`

> **避免资源残留**：
> - `terraform destroy` 仅释放 Terraform state 中追踪的资源；
> - 若中途通过控制台手动创建的资源（如手工上传的 OBS 对象），需手动释放；
> - SWR 中的镜像、CodeHub 中的代码不归 Terraform 管理，需另行清理。

## 8. 故障排除

| 现象 | 可能原因 | 排查方法 |
|---|---|---|
| `terraform init` 拉取 provider 失败 | 网络受限 / mirror 未配置 | 配置 `~/.terraformrc` 的 `filesystem_mirror` 指向本地 provider 目录 |
| `huaweicloud_codearts_build_job` 报 image_address 镜像不存在 | SWR 未预置对应镜像 | 先 `docker push` 镜像到 SWR，再重新 apply |
| `huaweicloud_identity_agency` 报 `op_svc_codearts` 不存在 | 委托域错误 | 控制台查实际 domain 名（不同 region 可能不同） |
| Pipeline 触发但构建任务未启动 | `huaweicloud_codearts_build_job` 名称与 Pipeline definition 中 `jobId` 不匹配 | 检查 Pipeline `definition` JSON 生成的 `jobId` 字段 |
| OBS 加密失败 | KMS 密钥未授权给 OBS 服务 | 控制台 → KMS → 密钥 → 授权 → 添加 OBS 服务 |
| EG 自定义事件源不触发 | CodeHub webhook 未配置 | CodeHub 仓库 → Settings → Webhooks → 添加 EG channel endpoint |
| 流水线 ManualReview 永远等待 | 审批人邮箱未配置 | 修改 `definition.stages[Plan].jobs[PlanApproval].inputs[approvers]` |

## 9. 附录：相关资源链接

- CodeArts Pipeline 用户指南：<https://support.huaweicloud.com/usermanual-codeartsdevcloud/devcloud_ug_0800.html>
- CodeArts Build 用户指南：<https://support.huaweicloud.com/usermanual-codeartsdevcloud/devcloud_ug_0700.html>
- OBS 服务用户指南：<https://support.huaweicloud.com/usermanual-obs/obs_03_0300.html>
- EG 事件网格用户指南：<https://support.huaweicloud.com/usermanual-eg/eg_ug_0001.html>
- Terraform HuaweiCloud Provider 文档：<https://registry.terraform.io/providers/huaweicloud/huaweicloud/latest/docs>
