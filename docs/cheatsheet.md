# Terraform / Terragrunt コマンドチートシート

## Terraform 基本コマンド

### 初期化・計画・適用・削除

```bash
# 初期化（プロバイダのダウンロード、バックエンドの設定）
terraform init

# 実行計画の確認（何が変更されるか表示）
terraform plan

# 変更の適用（リソースを作成・変更・削除）
terraform apply

# 確認プロンプトをスキップして適用
terraform apply -auto-approve

# リソースの削除
terraform destroy

# 確認プロンプトをスキップして削除
terraform destroy -auto-approve
```

### 変数の指定

```bash
# コマンドライン引数で指定
terraform plan -var="environment=prod"
terraform plan -var="instance_type=t3.large"

# 変数ファイルを指定
terraform plan -var-file="prod.tfvars"

# 環境変数で指定（TF_VAR_ プレフィックス）
export TF_VAR_environment=prod
terraform plan
```

### ステート管理

```bash
# 管理中のリソース一覧
terraform state list

# 特定リソースの詳細
terraform state show aws_s3_bucket.my_bucket

# リソースのリネーム（コード上の名前変更時）
terraform state mv aws_s3_bucket.old_name aws_s3_bucket.new_name

# ステートからリソースを除外（Terraform管理を外す）
terraform state rm aws_s3_bucket.my_bucket

# 既存リソースをインポート
terraform import aws_s3_bucket.my_bucket my-bucket-name
```

### 出力・情報表示

```bash
# すべての出力値を表示
terraform output

# 特定の出力値を表示
terraform output bucket_name

# JSON形式で出力
terraform output -json

# 現在のステートの内容を表示
terraform show

# JSON形式で表示
terraform show -json
```

### フォーマット・検証

```bash
# コードのフォーマット（自動整形）
terraform fmt

# 再帰的にフォーマット
terraform fmt -recursive

# フォーマットのチェックのみ（CI向け）
terraform fmt -check

# 構文の検証
terraform validate
```

### よく使うオプション

| オプション | 説明 |
|-----------|------|
| `-auto-approve` | 確認プロンプトをスキップ |
| `-var="key=value"` | 変数を指定 |
| `-var-file="file.tfvars"` | 変数ファイルを指定 |
| `-target=resource` | 特定リソースのみ操作 |
| `-refresh=false` | 実行前のステートリフレッシュをスキップ |
| `-parallelism=N` | 並列実行数を指定（デフォルト: 10） |
| `-compact-warnings` | 警告を簡潔に表示 |

---

## Terragrunt コマンド

### 基本コマンド（Terraform と同じ操作）

```bash
# 初期化
terragrunt init

# 実行計画
terragrunt plan

# 適用
terragrunt apply

# 削除
terragrunt destroy
```

### 複数ディレクトリの一括操作

```bash
# 全サブディレクトリに対して plan
terragrunt run-all plan

# 全サブディレクトリに対して apply
terragrunt run-all apply

# 全サブディレクトリに対して destroy
terragrunt run-all destroy

# 全サブディレクトリの出力を表示
terragrunt run-all output
```

### Terragrunt 固有のコマンド

```bash
# 生成されるTerraformコードの確認
terragrunt render-json

# 設定のデバッグ情報を表示
terragrunt terragrunt-info

# Terragruntのキャッシュをクリア
terragrunt clean
```

---

## デバッグ / トラブルシューティング

### ログレベルの設定

```bash
# Terraform のデバッグログを有効化
export TF_LOG=DEBUG
terraform plan

# ログをファイルに出力
export TF_LOG_PATH=./terraform.log
terraform plan

# ログレベルの種類: TRACE, DEBUG, INFO, WARN, ERROR

# Terragrunt のデバッグログ
export TERRAGRUNT_LOG_LEVEL=debug
terragrunt plan
```

### よくあるトラブルと解決法

```bash
# プロバイダのキャッシュを再構築
rm -rf .terraform
terraform init

# ステートのロックを強制解除
terraform force-unlock <LOCK_ID>

# ステートをローカルに移行（バックエンド変更時）
terraform init -migrate-state

# バックエンド設定を再構成
terraform init -reconfigure

# 特定リソースだけ再作成
terraform apply -replace="aws_instance.web"

# 依存関係グラフの表示
terraform graph
```

### 状態の確認コマンド

```bash
# Terraform のバージョン確認
terraform version

# 使用中のプロバイダ確認
terraform providers

# ワークスペース一覧
terraform workspace list

# 現在のワークスペース
terraform workspace show
```

---

## HCL 構文クイックリファレンス

### 変数定義

```hcl
variable "name" {
  description = "説明"
  type        = string
  default     = "default_value"

  validation {
    condition     = length(var.name) > 0
    error_message = "名前は必須です。"
  }
}
```

### 出力定義

```hcl
output "id" {
  description = "リソースのID"
  value       = aws_instance.this.id
}
```

### ローカル変数

```hcl
locals {
  name = "${var.project}-${var.env}"
  tags = merge(var.tags, { ManagedBy = "terraform" })
}
```

### モジュール呼び出し

```hcl
module "vpc" {
  source = "./modules/vpc"

  name = var.name
  cidr = var.cidr
}
# 出力参照: module.vpc.vpc_id
```

### よく使う関数

| 関数 | 説明 | 例 |
|------|------|-----|
| `merge(map1, map2)` | マップの結合 | `merge({a=1}, {b=2})` |
| `length(list)` | リストの長さ | `length(["a","b"])` -> 2 |
| `contains(list, val)` | リスト内の検索 | `contains(["a"], "a")` -> true |
| `lookup(map, key, default)` | マップの検索 | `lookup({a=1}, "a", 0)` -> 1 |
| `join(sep, list)` | リストの結合 | `join("-", ["a","b"])` -> "a-b" |
| `format(fmt, args...)` | 文字列フォーマット | `format("hello %s", "world")` |
| `file(path)` | ファイル読み込み | `file("script.sh")` |
| `templatefile(path, vars)` | テンプレート処理 | `templatefile("tpl.sh", {name="x"})` |
| `can(expression)` | エラー判定 | `can(regex("^[a-z]+$", var.x))` |
