# Step 1: Hello Terraform - 最初の Terraform コード

[<- 前のステップ: 環境セットアップ](00-prerequisites.md) | [次のステップ: 変数と出力 ->](02-variables-and-outputs.md)

---

## 学習目標

- HCL (HashiCorp Configuration Language) の基本構文を理解する
- `provider` と `resource` ブロックの書き方を覚える
- `terraform init` / `plan` / `apply` / `destroy` のワークフローを体験する
- S3 バケットを Terraform で作成・削除する

---

## 概念の説明

### Terraform とは？

Terraform は **Infrastructure as Code (IaC)** ツールです。GUI やコマンドラインで手動操作する代わりに、コードでインフラを定義・管理します。

これが重要な理由:
- **再現性**: 同じコードから同じインフラを何度でも作成できる
- **バージョン管理**: Git でインフラの変更履歴を追跡できる
- **レビュー**: コードレビューでインフラ変更を事前に確認できる
- **自動化**: CI/CD パイプラインに組み込める

### HCL の基本構造

Terraform のコードは `.tf` ファイルに HCL で記述します。基本的なブロック構造は以下の通りです。

```hcl
ブロックタイプ "ラベル1" "ラベル2" {
  属性名 = 値
}
```

---

## ハンズオン手順

### 1. 作業ディレクトリに移動

```bash
cd steps/01-hello-terraform
```

### 2. コードの確認

`main.tf` を開いて内容を確認しましょう。

```hcl
# Terraformブロック: 使用するTerraformとプロバイダのバージョンを指定
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# プロバイダブロック: AWSへの接続設定
provider "aws" {
  region = "ap-northeast-1"
}

# リソースブロック: 作成するインフラリソースの定義
resource "aws_s3_bucket" "my_first_bucket" {
  bucket = "my-first-terraform-bucket-handson"

  tags = {
    Name      = "My First Bucket"
    ManagedBy = "terraform"
  }
}
```

各ブロックの役割:

| ブロック | 役割 |
|---------|------|
| `terraform` | Terraform 本体とプロバイダのバージョン制約 |
| `provider "aws"` | AWS への接続情報（リージョンなど） |
| `resource "aws_s3_bucket" "my_first_bucket"` | S3 バケットのリソース定義 |

> **LocalStack を使う場合**: `main.tf` の `provider "aws"` ブロックを削除し、`providers.tf` のコメントを外してください。`providers.tf` には LocalStack 用の接続設定（エンドポイント、ダミークレデンシャル等）が記載されています。

### 3. 初期化 (`terraform init`)

プロバイダプラグインのダウンロードと初期化を行います。

```bash
terraform init
```

期待される出力:
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...
- Installed hashicorp/aws v5.x.x (signed by HashiCorp)

Terraform has been successfully initialized!
```

### 4. 実行計画の確認 (`terraform plan`)

実際に何が作成されるかを事前に確認します。

```bash
terraform plan
```

期待される出力:
```
Terraform will perform the following actions:

  # aws_s3_bucket.my_first_bucket will be created
  + resource "aws_s3_bucket" "my_first_bucket" {
      + bucket = "my-first-terraform-bucket-handson"
      + tags   = {
          + "ManagedBy" = "terraform"
          + "Name"      = "My First Bucket"
        }
      ...
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

`+` マークは「新規作成」を意味します。

### 5. リソースの作成 (`terraform apply`)

確認を経てリソースを作成します。

```bash
terraform apply
```

確認プロンプトが表示されるので、`yes` と入力します。

```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

期待される出力:
```
aws_s3_bucket.my_first_bucket: Creating...
aws_s3_bucket.my_first_bucket: Creation complete after 2s [id=my-first-terraform-bucket-handson]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

### 6. 作成されたリソースの確認

```bash
# AWS CLI で確認
aws s3 ls

# LocalStack を使用している場合
aws --endpoint-url=http://localhost:4566 s3 ls
```

### 7. リソースの削除 (`terraform destroy`)

作成したリソースを削除します。

```bash
terraform destroy
```

`yes` と入力して削除を確定します。

```
aws_s3_bucket.my_first_bucket: Destroying... [id=my-first-terraform-bucket-handson]
aws_s3_bucket.my_first_bucket: Destruction complete after 1s

Destroy complete! Resources: 1 destroyed.
```

---

## 確認ポイント

- `terraform init` 後に `.terraform/` ディレクトリが作成されたか
- `terraform plan` で `Plan: 1 to add` と表示されたか
- `terraform apply` 後に S3 バケットが実際に作成されたか
- `terraform destroy` 後にリソースが削除されたか

---

## よくあるエラーと対処法

### 1. `Error: No valid credential sources found`

```
Error: No valid credential sources found for AWS Provider.
```

**原因**: AWS クレデンシャルが設定されていない。

**対処法**: `aws configure` でクレデンシャルを設定するか、LocalStack を使用する場合はプロバイダ設定の LocalStack 用コメントを外してください。

### 2. `BucketAlreadyExists`

```
Error: creating Amazon S3 Bucket: BucketAlreadyExists
```

**原因**: S3 バケット名はグローバルに一意である必要があり、同名のバケットが既に存在している。

**対処法**: `main.tf` の `bucket` 属性を自分のユニークな名前に変更してください（例: `my-first-terraform-bucket-yourname-2024`）。

### 3. `Error: Failed to install provider`

```
Error: Failed to install provider from shared cache
```

**原因**: ネットワーク接続の問題やプロバイダのキャッシュ破損。

**対処法**: `.terraform/` ディレクトリを削除してから `terraform init` を再実行してください。

```bash
# macOS/Linux
rm -rf .terraform

# Windows（PowerShell）
Remove-Item -Recurse -Force .terraform

terraform init
```

---

## 発展課題

1. **タグを追加してみよう**: `tags` ブロックに `Owner = "自分の名前"` を追加して `terraform apply` してみましょう。`terraform plan` で差分がどう表示されるか確認してください。

2. **2つ目のバケットを作成してみよう**: `resource "aws_s3_bucket" "second_bucket"` として別のバケットを定義し、2つのリソースを同時に管理してみましょう。

3. **`terraform show` を試してみよう**: `terraform apply` 後に `terraform show` を実行して、Terraform が管理しているリソースの現在の状態を確認してみましょう。

---

[<- 前のステップ: 環境セットアップ](00-prerequisites.md) | [次のステップ: 変数と出力 ->](02-variables-and-outputs.md)
