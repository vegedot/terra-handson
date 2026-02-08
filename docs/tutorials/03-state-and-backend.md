# Step 3: ステートとバックエンド - リソース状態の管理

[<- 前のステップ: 変数と出力](02-variables-and-outputs.md) | [次のステップ: モジュール ->](04-modules.md)

---

## 学習目標

- `terraform.tfstate` の役割と構造を理解する
- ローカルステートとリモートステートの違いを知る
- S3 + DynamoDB によるリモートバックエンドを構築する
- ステートロックの仕組みを理解する

---

## 概念の説明

### ステートファイルとは？

Terraform は `terraform.tfstate` というファイルに、管理しているリソースの現在の状態を記録します。このファイルがあるからこそ、Terraform は「何を作成済みか」「何を変更すべきか」を判断できます。

```
コード (.tf)  ←→  ステート (.tfstate)  ←→  実際のインフラ (AWS)
```

### なぜリモートバックエンドが重要か？

ローカルにステートファイルを置くと、以下の問題が発生します:

| 問題 | リモートバックエンドでの解決策 |
|------|--------------------------|
| チームメンバーとステートを共有できない | S3 に保存して共有 |
| 同時に `terraform apply` するとステートが壊れる | DynamoDB でロック |
| ステートファイルを紛失するリスク | S3 のバージョニングで復元可能 |
| 機密情報が平文で保存される | S3 の暗号化で保護 |

---

## ハンズオン手順

### 1. 作業ディレクトリに移動

```bash
cd steps/03-state-and-backend
```

### 2. コードの確認

`main.tf` では、リモートバックエンド用のインフラ自体を作成します。

```hcl
locals {
  state_bucket_name = "${var.project_name}-${var.environment}-terraform-state"
  lock_table_name   = "${var.project_name}-${var.environment}-terraform-lock"
}

# ステートファイルを保存する S3 バケット
resource "aws_s3_bucket" "terraform_state" {
  bucket        = local.state_bucket_name
  force_destroy = true  # 学習時は true にしておく

  tags = {
    Name        = local.state_bucket_name
    Purpose     = "Terraform State"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# バージョニング有効化（変更履歴の保持）
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 暗号化設定（機密情報の保護）
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ステートロック用の DynamoDB テーブル
resource "aws_dynamodb_table" "terraform_lock" {
  name         = local.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

### 3. バックエンドインフラの作成

```bash
terraform init
terraform plan
terraform apply
```

期待される出力:
```
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

lock_table_name   = "handson-dev-terraform-lock"
state_bucket_arn  = "arn:aws:s3:::handson-dev-terraform-state"
state_bucket_name = "handson-dev-terraform-state"
```

### 4. ステートファイルの確認

ここまでの状態では、ステートファイルはローカルに保存されています。

```bash
# ステートファイルの内容を表示
terraform show

# ステートファイルのリソース一覧
terraform state list
```

期待される出力:
```
aws_dynamodb_table.terraform_lock
aws_s3_bucket.terraform_state
aws_s3_bucket_server_side_encryption_configuration.terraform_state
aws_s3_bucket_versioning.terraform_state
```

### 5. ステートファイルの中身を見てみる（学習目的）

```bash
# JSON 形式のステートファイルを確認（macOS/Linux）
terraform show -json | python3 -m json.tool | head -50

# Windows（PowerShell）の場合
terraform show -json | python -m json.tool
```

> **注意**: ステートファイルには機密情報（パスワード、API キーなど）が含まれる可能性があります。Git にコミットしないよう `.gitignore` に追加してください。

### 6. リモートバックエンドへの移行（オプション）

`backend.tf` のコメントを外すことで、ステートを S3 に移行できます。

```hcl
terraform {
  backend "s3" {
    bucket         = "handson-dev-terraform-state"
    key            = "step03/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "handson-dev-terraform-lock"
    encrypt        = true
  }
}
```

コメントを外した後:

```bash
terraform init
```

期待される出力:
```
Initializing the backend...
Do you want to copy existing state to the new backend?

  Enter a value: yes

Successfully configured the backend "s3"!
```

### 7. クリーンアップ

リモートバックエンドに移行した場合は、まずローカルバックエンドに戻してから削除します。

```bash
# backend.tf をコメントアウトしてローカルに戻す
terraform init -migrate-state

# リソースを削除
terraform destroy
```

---

## 確認ポイント

- `terraform state list` で管理中のリソースが表示されたか
- S3 バケットと DynamoDB テーブルが作成されたか
- ステートファイルの JSON 構造を確認できたか

---

## よくあるエラーと対処法

### 1. `Error: Failed to get existing workspaces`

```
Error: Failed to get existing workspaces: S3 bucket does not exist.
```

**原因**: バックエンド設定で指定した S3 バケットがまだ作成されていない。

**対処法**: まず `backend.tf` をコメントアウトしたまま `terraform apply` でバケットを作成してから、バックエンド設定を有効化してください。

### 2. `Error: Error acquiring the state lock`

```
Error: Error acquiring the state lock
```

**原因**: 他のプロセスがステートをロック中、またはロックが不正に残っている。

**対処法**: 他に `terraform` プロセスが実行されていないか確認し、問題がなければ以下でロックを解除します。

```bash
terraform force-unlock <LOCK_ID>
```

### 3. `Error: Backend configuration changed`

```
Error: Backend configuration changed
```

**原因**: バックエンド設定を変更した後に `terraform init` を実行していない。

**対処法**: `terraform init -reconfigure` を実行してください。

---

## 発展課題

1. **ステートの中身を比較してみよう**: `terraform apply` の前後で `terraform.tfstate` の内容がどう変わるか比較してみましょう。

2. **`terraform import` を試してみよう**: AWS コンソールで手動作成したリソースを `terraform import` で Terraform 管理下に取り込んでみましょう。

3. **ワークスペースを試してみよう**: `terraform workspace new staging` で別のワークスペースを作成し、同じコードで異なる環境を管理してみましょう。

---

[<- 前のステップ: 変数と出力](02-variables-and-outputs.md) | [次のステップ: モジュール ->](04-modules.md)
