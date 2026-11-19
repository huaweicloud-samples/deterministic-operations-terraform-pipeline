# ============================================================================
# 版本约束
# ============================================================================

terraform {
  required_version = ">= 1.5.7"

  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = "= 1.97.1"
    }
  }

  # 状态文件建议存储到 OBS 桶
  backend "local" {
    # 生产环境可改为：
    # backend "s3" {
    #   endpoint = "https://obs.cn-north-4.myhuaweicloud.com"
    #   bucket   = "your-tfstate-bucket"
    #   key      = "deterministic-operations-terraform-pipeline/terraform.tfstate"
    #   region   = "cn-north-4"
    # }
  }
}

# 显式 provider 配置（v1.97.1 要求 explicit configuration）
# 注意：access_key/secret_key 默认从环境变量 HW_ACCESS_KEY / HW_SECRET_KEY 读取
#       （不入 .tfvars、不入 git）。如使用 ECS Metadata，则保留空。
provider "huaweicloud" {
  region = var.region
}
