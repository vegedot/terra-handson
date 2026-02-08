# Step 2: 変数と出力 - 設定を柔軟にする

[<- 前のステップ: Hello Terraform](01-hello-terraform.md) | [次のステップ: ステートとバックエンド ->](03-state-and-backend.md)

---

## 学習目標

- `variable` ブロックで入力変数を定義する方法を理解する
- `output` ブロックで作成結果を出力する方法を覚える
- `locals` ブロックで値を加工する方法を学ぶ
- `terraform.tfvars` で変数値を管理する方法を知る

---

## 概念の説明

### なぜ変数が重要か？

Step 1 ではバケット名や設定値を直接コードに書きました（ハードコーディング）。これでは環境ごとに別のファイルが必要になり、コードの重複が発生します。

変数を使えば:
- **同じコードを異なる設定で再利用** できる（dev/staging/prod など）
- **設定値を一箇所で管理** できる
- **バリデーション** で不正な入力を防げる

### 変数の型

Terraform では以下の型が使えます:

| 型 | 説明 | 例 |
|----|------|-----|
| `string` | 文字列 | `"hello"` |
| `number` | 数値 | `42` |
| `bool` | 真偽値 | `true` |
| `list(type)` | リスト | `["a", "b"]` |
| `map(type)` | マップ | `{key = "value"}` |

---

## ハンズオン手順

### 1. 作業ディレクトリに移動

```bash
cd steps/02-variables-and-outputs
```

### 2. 変数定義の確認 (`variables.tf`)

```hcl
# プロジェクト名
variable "project_name" {
  description = "プロジェクト名（リソース名のプレフィックスに使用）"
  type        = string
  default     = "handson"
}

# バケット名（バリデーション付き）
variable "bucket_name" {
  description = "S3バケットの名前"
  type        = string
  default     = "data"

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 30
    error_message = "バケット名は3文字以上30文字以下で指定してください。"
  }
}

# 環境名（許可値のバリデーション付き）
variable "environment" {
  description = "環境名（dev, staging, prod のいずれか）"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "環境名は dev, staging, prod のいずれかを指定してください。"
  }
}

# マップ型の変数
variable "tags" {
  description = "リソースに付与する追加のタグ"
  type        = map(string)
  default     = {}
}
```

**ポイント**:
- `description` で変数の説明を記述する
- `type` で型を指定する
- `default` でデフォルト値を設定する（省略すると必須入力になる）
- `validation` で入力値を検証できる

### 3. ローカル変数の確認 (`main.tf`)

```hcl
locals {
  # 変数を組み合わせてバケット名を生成
  bucket_full_name = "${var.project_name}-${var.environment}-${var.bucket_name}"

  # 共通タグ: すべてのリソースに付与するタグをマージ
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}
```

`locals` は変数を加工して新しい値を作るのに便利です。`merge()` 関数で複数のマップを結合できます。

### 4. 出力定義の確認 (`outputs.tf`)

```hcl
output "bucket_arn" {
  description = "作成されたS3バケットのARN"
  value       = aws_s3_bucket.this.arn
}

output "bucket_name" {
  description = "作成されたS3バケットの名前"
  value       = aws_s3_bucket.this.id
}

output "bucket_region" {
  description = "S3バケットが作成されたリージョン"
  value       = aws_s3_bucket.this.region
}
```

### 5. 初期化と実行

```bash
terraform init
terraform plan
terraform apply
```

期待される出力（apply 後）:
```
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn    = "arn:aws:s3:::handson-dev-data"
bucket_name   = "handson-dev-data"
bucket_region = "ap-northeast-1"
bucket_tags   = tomap({
  "Environment" = "dev"
  "ManagedBy"   = "terraform"
  "Project"     = "handson"
})
```

### 6. 変数を変えて実行してみる

#### コマンドライン引数で変数を渡す

```bash
terraform plan -var="environment=staging"
```

バケット名が `handson-staging-data` に変わることを確認してください。

#### tfvars ファイルで変数を管理する

`terraform.tfvars` ファイルを作成します:

```hcl
project_name = "myproject"
environment  = "dev"
bucket_name  = "assets"
tags = {
  Owner = "your-name"
  Team  = "engineering"
}
```

```bash
terraform plan
# terraform.tfvars の値が自動的に読み込まれる
```

### 7. 出力の確認

```bash
# すべての出力を表示
terraform output

# 特定の出力だけ表示
terraform output bucket_name

# JSON 形式で出力（スクリプトで使う場合に便利）
terraform output -json
```

### 8. クリーンアップ

```bash
terraform destroy
```

---

## 確認ポイント

- 変数のデフォルト値が使われたか
- `-var` でデフォルト値を上書きできたか
- `terraform output` で作成結果が表示されたか
- バリデーションが機能するか（例: `terraform plan -var="environment=invalid"` でエラーになるか）

---

## よくあるエラーと対処法

### 1. `Error: Invalid value for variable`

```
Error: Invalid value for variable
  環境名は dev, staging, prod のいずれかを指定してください。
```

**原因**: `validation` ブロックの条件を満たさない値が指定された。

**対処法**: 許可された値（dev, staging, prod）のいずれかを指定してください。

### 2. `Error: Reference to undeclared input variable`

```
Error: Reference to undeclared input variable
  An input variable with the name "xxx" has not been declared.
```

**原因**: `main.tf` で使用している `var.xxx` が `variables.tf` に定義されていない。

**対処法**: `variables.tf` に対応する `variable` ブロックを追加してください。

### 3. `Error: Missing required argument`

```
Error: Missing required argument
  The argument "bucket" is required, but no definition was found.
```

**原因**: リソースの必須属性が未指定。

**対処法**: エラーメッセージに示された属性をリソースブロックに追加してください。

---

## 発展課題

1. **新しい変数を追加してみよう**: `versioning_enabled` (bool 型) を追加し、バージョニングの有効/無効を切り替えられるようにしてみましょう。

2. **カスタムバリデーションを書いてみよう**: `bucket_name` のバリデーションに「英小文字とハイフンのみ許可」する条件を追加してみましょう（`can(regex("^[a-z0-9-]+$", var.bucket_name))`）。

3. **`terraform.tfvars` と `-var-file` を試してみよう**: `dev.tfvars` と `prod.tfvars` を作成し、`terraform plan -var-file="prod.tfvars"` で環境を切り替えてみましょう。

---

[<- 前のステップ: Hello Terraform](01-hello-terraform.md) | [次のステップ: ステートとバックエンド ->](03-state-and-backend.md)
