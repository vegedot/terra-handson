# Step 6: マルチ環境管理 - dev/staging/prod を効率的に管理する

[<- 前のステップ: Terragrunt 入門](05-terragrunt-basics.md)

---

## 学習目標

- 環境ごとの `terragrunt.hcl` 設定パターンを理解する
- `include` による親設定の継承を覚える
- 環境間の差分管理（インスタンスサイズ、CIDR 等）を学ぶ
- `terragrunt run-all` による複数環境の一括操作を体験する

---

## 概念の説明

### なぜマルチ環境管理が必要か？

実際のプロジェクトでは、dev（開発）、staging（検証）、prod（本番）といった複数の環境を管理します。各環境は同じ構成だが設定値が異なります:

| 設定項目 | dev | staging | prod |
|---------|-----|---------|------|
| インスタンスタイプ | t3.micro | t3.small | t3.medium |
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| タグ (CostCenter) | development | staging | production |

Terragrunt を使えば、**Terraform コードは 1 つだけ** で、環境ごとの設定値だけを `terragrunt.hcl` で管理できます。

### ディレクトリ構成

```
steps/06-terragrunt-multi-env/
├── terragrunt.hcl          # ルート設定（共通設定）
├── main.tf                 # Terraformコード（全環境共通）
├── variables.tf            # 変数定義
├── outputs.tf              # 出力定義
├── dev/terragrunt.hcl      # dev環境の設定値
├── staging/terragrunt.hcl  # staging環境の設定値
└── prod/terragrunt.hcl     # prod環境の設定値
```

---

## ハンズオン手順

### 1. 作業ディレクトリに移動

```bash
cd steps/06-terragrunt-multi-env
```

### 2. ルート terragrunt.hcl の確認

```hcl
# プロバイダ設定を自動生成
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "ap-northeast-1"
}
EOF
}
```

すべての環境で共有されるプロバイダ設定を定義しています。

### 3. 環境ごとの terragrunt.hcl の確認

#### dev 環境 (`dev/terragrunt.hcl`)

```hcl
# 親ディレクトリの terragrunt.hcl を継承する
include "root" {
  path = find_in_parent_folders()
}

# Terraform ソースコードのパス
terraform {
  source = "../"
}

# dev 環境固有の変数値
inputs = {
  project_name = "handson"
  environment  = "dev"

  # ネットワーク設定（小規模）
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

  # EC2設定（最小インスタンス）
  instance_type = "t3.micro"

  tags = {
    Environment = "dev"
    CostCenter  = "development"
  }
}
```

#### staging 環境 (`staging/terragrunt.hcl`)

```hcl
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../"
}

inputs = {
  project_name = "handson"
  environment  = "staging"

  vpc_cidr             = "10.1.0.0/16"
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs = ["10.1.10.0/24", "10.1.20.0/24"]

  # 中規模インスタンス
  instance_type = "t3.small"

  tags = {
    Environment = "staging"
    CostCenter  = "staging"
  }
}
```

#### prod 環境 (`prod/terragrunt.hcl`)

```hcl
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../"
}

inputs = {
  project_name = "handson"
  environment  = "prod"

  vpc_cidr             = "10.2.0.0/16"
  public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24"]
  private_subnet_cidrs = ["10.2.10.0/24", "10.2.20.0/24"]

  # 本番用インスタンス
  instance_type = "t3.medium"

  tags = {
    Environment = "prod"
    CostCenter  = "production"
    Critical    = "true"
  }
}
```

**ポイント**:
- `include "root"` で親の `terragrunt.hcl` から `generate` 設定を継承
- `terraform { source = "../" }` で親ディレクトリの Terraform コードを参照
- `inputs` で環境固有の値を設定
- VPC CIDR やインスタンスタイプが環境ごとに異なる

### 4. 共通の Terraform コード (`main.tf`)

```hcl
# VPCモジュール
module "vpc" {
  source = "../../modules/vpc"

  name                 = "${var.project_name}-${var.environment}"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  environment          = var.environment
  tags                 = var.tags
}

# EC2インスタンスモジュール
module "ec2" {
  source = "../../modules/ec2-instance"

  name          = "${var.project_name}-${var.environment}-web"
  ami_id        = var.ami_id
  instance_type = var.instance_type
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.public_subnet_ids[0]
  environment   = var.environment
  tags          = var.tags
}
```

このコードは全環境で共通です。環境ごとの違いは `terragrunt.hcl` の `inputs` だけで吸収します。

### 5. dev 環境をデプロイ

```bash
cd dev
terragrunt init
terragrunt plan
terragrunt apply
```

期待される出力:
```
Apply complete! Resources: 9 added, 0 changed, 0 destroyed.

Outputs:

instance_id       = "i-xxxxxxxxxxxxxxxxx"
instance_public_ip = "xx.xx.xx.xx"
public_subnet_ids  = [...]
vpc_id            = "vpc-xxxxxxxxxxxxxxxxx"
```

### 6. staging 環境をデプロイ

```bash
cd ../staging
terragrunt init
terragrunt plan
terragrunt apply
```

VPC CIDR が `10.1.0.0/16`、インスタンスタイプが `t3.small` になっていることを `terragrunt plan` の出力で確認してください。

### 7. 全環境を一括操作 (`run-all`)

ルートディレクトリから全環境をまとめて操作できます。

```bash
cd ..  # steps/06-terragrunt-multi-env/ に戻る

# 全環境の実行計画を確認
terragrunt run-all plan

# 全環境を一括デプロイ
terragrunt run-all apply

# 全環境を一括削除
terragrunt run-all destroy
```

> **注意**: `run-all` は各サブディレクトリの `terragrunt.hcl` を検出して並列実行します。確認プロンプトが表示されるので内容をよく確認してください。

### 8. クリーンアップ

```bash
# 個別に削除する場合
cd dev && terragrunt destroy
cd ../staging && terragrunt destroy
cd ../prod && terragrunt destroy

# または一括削除
cd ..
terragrunt run-all destroy
```

---

## 確認ポイント

- `include` で親設定が継承されたか（`provider.tf` が自動生成される）
- 同じ Terraform コードから、環境ごとに異なる設定のインフラが作成されたか
- `terragrunt run-all plan` で全環境の計画が一覧表示されたか
- 環境間で VPC CIDR やインスタンスタイプが正しく異なっているか

---

## よくあるエラーと対処法

### 1. `Error: Could not find a terragrunt.hcl`

```
Could not find a terragrunt.hcl file
```

**原因**: `terragrunt` コマンドを実行しているディレクトリに `terragrunt.hcl` がない。

**対処法**: `dev/`、`staging/`、`prod/` のいずれかのディレクトリに移動してから実行してください。

### 2. `Error: No Terraform configuration files found`

```
Error: No Terraform configuration files found in directory
```

**原因**: `terraform { source = "../" }` のパスが間違っている。

**対処法**: `terragrunt.hcl` の `source` パスが、`main.tf` のあるディレクトリを正しく指しているか確認してください。

### 3. `run-all` で一部の環境だけ失敗する

```
Error: Error applying in .../prod
```

**原因**: 環境固有の設定（AMI ID やリソース名の競合など）に問題がある。

**対処法**: 失敗した環境のディレクトリに移動して個別に `terragrunt plan` を実行し、エラーの詳細を確認してください。

---

## 発展課題

1. **新しい環境を追加してみよう**: `qa/terragrunt.hcl` を作成して、QA (品質保証) 環境を追加してみましょう。既存の環境設定をコピーして値を変更するだけで OK です。

2. **`environments/` ディレクトリを試してみよう**: リポジトリ直下の `environments/` ディレクトリには、`remote_state` を使ったより実践的な Terragrunt 設定があります。こちらの構成も確認してみましょう。

3. **環境差分をさらに追加してみよう**: prod 環境だけに RDS (データベース) モジュールを追加するなど、環境ごとにリソース構成を変える方法を考えてみましょう。

---

## 学習のまとめ

全 6 ステップを通じて、以下を学びました:

| ステップ | 学んだこと |
|---------|-----------|
| Step 1 | Terraform の基本（HCL、provider、resource、ワークフロー） |
| Step 2 | 設定の柔軟化（variable、output、locals、tfvars） |
| Step 3 | 状態管理（tfstate、S3 バックエンド、DynamoDB ロック） |
| Step 4 | コードの再利用（モジュールの作成と呼び出し） |
| Step 5 | DRY 化（Terragrunt の generate と inputs） |
| Step 6 | マルチ環境管理（include、環境分離、run-all） |

次のステップとして:
- [コマンドチートシート](../cheatsheet.md) を手元に置いて実践で活用しましょう
- [Terraform 公式ドキュメント](https://developer.hashicorp.com/terraform/docs) でより深く学びましょう
- [Terragrunt 公式ドキュメント](https://terragrunt.gruntwork.io/docs/) で高度な機能を探索しましょう

---

[<- 前のステップ: Terragrunt 入門](05-terragrunt-basics.md)
