# Step 5: Terragrunt 入門 - DRY なインフラ管理

[<- 前のステップ: モジュール](04-modules.md) | [次のステップ: マルチ環境管理 ->](06-terragrunt-multi-env.md)

---

## 学習目標

- Terragrunt とは何か、なぜ必要かを理解する
- `terragrunt.hcl` の基本構文を覚える
- `generate` によるファイル自動生成を体験する
- `inputs` による変数の注入方法を学ぶ

---

## 概念の説明

### Terragrunt とは？

Terragrunt は **Terraform のラッパーツール** です。Terraform をそのまま使うと発生する以下の課題を解決します:

| Terraform の課題 | Terragrunt の解決策 |
|-----------------|-------------------|
| `provider` 設定を全ステップにコピーする必要がある | `generate` で自動生成 |
| `backend` 設定を手動で書く必要がある | `remote_state` で一元管理 |
| `terraform.tfvars` が環境ごとに増える | `inputs` で一箇所に集約 |
| 複数ディレクトリへの一括実行ができない | `terragrunt run-all` |

### Terragrunt のコマンド体系

Terragrunt のコマンドは Terraform とほぼ同じです:

```bash
# Terraform          → Terragrunt
terraform init       → terragrunt init
terraform plan       → terragrunt plan
terraform apply      → terragrunt apply
terraform destroy    → terragrunt destroy
```

---

## ハンズオン手順

### 1. 作業ディレクトリに移動

```bash
cd steps/05-terragrunt-basics
```

### 2. terragrunt.hcl の確認

```hcl
# プロバイダ設定を自動生成する
# この設定により provider.tf が自動的に作成される
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "ap-northeast-1"
}
EOF
}

# Terraform変数に値を注入する
# terraform.tfvars の代わりにここで管理できる
inputs = {
  bucket_name        = "handson-terragrunt-demo"
  environment        = "dev"
  versioning_enabled = true

  tags = {
    ManagedBy = "terragrunt"
    Step      = "05-terragrunt-basics"
  }
}
```

**ポイント**:
- `generate` ブロック: 指定した内容でファイルを自動生成する。`provider.tf` を手動で各ディレクトリに作る必要がなくなる
- `inputs` ブロック: Terraform 変数に値を注入する。`terraform.tfvars` の代わりになる
- `if_exists = "overwrite_terragrunt"`: Terragrunt が生成したファイルは毎回上書きする

### 3. Terraform コードの確認 (`main.tf`)

```hcl
# S3バケットモジュールの呼び出し
module "s3" {
  source = "../../modules/s3-bucket"

  bucket_name        = var.bucket_name
  environment        = var.environment
  versioning_enabled = var.versioning_enabled
  tags               = var.tags
}
```

Terraform コード自体は普通の Terraform です。Terragrunt は `terraform.tfvars` の代わりに `inputs` で変数を渡します。

### 4. Terragrunt で初期化と実行

```bash
terragrunt init
```

期待される出力:
```
Initializing modules...
- s3 in ../../modules/s3-bucket

Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...

Terraform has been successfully initialized!
```

`provider.tf` が自動生成されていることを確認:

```bash
# 自動生成されたファイルを確認（Windows）
type provider.tf

# macOS/Linux
cat provider.tf
```

### 5. 実行計画の確認と適用

```bash
terragrunt plan
terragrunt apply
```

期待される出力:
```
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn  = "arn:aws:s3:::handson-terragrunt-demo"
bucket_name = "handson-terragrunt-demo"
```

### 6. inputs の値を変えてみる

`terragrunt.hcl` の `inputs` を編集して再適用してみましょう:

```hcl
inputs = {
  bucket_name        = "handson-terragrunt-demo"
  environment        = "dev"
  versioning_enabled = false  # true から false に変更

  tags = {
    ManagedBy = "terragrunt"
    Step      = "05-terragrunt-basics"
    Updated   = "true"          # タグを追加
  }
}
```

```bash
terragrunt plan
# バージョニングの無効化とタグの追加が表示される

terragrunt apply
```

### 7. クリーンアップ

```bash
terragrunt destroy
```

---

## 確認ポイント

- `terragrunt init` 後に `provider.tf` が自動生成されたか
- `inputs` で指定した値がリソースに反映されたか
- `terragrunt` コマンドが Terraform と同じように使えたか
- `inputs` の値を変更して `terragrunt plan` で差分が表示されたか

---

## よくあるエラーと対処法

### 1. `terragrunt: command not found`

```
bash: terragrunt: command not found
```

**原因**: Terragrunt がインストールされていない、またはパスが通っていない。

**対処法**: [環境セットアップガイド](00-prerequisites.md) の Terragrunt インストール手順を確認してください。

### 2. `Error: Duplicate provider configuration`

```
Error: Duplicate provider configuration
```

**原因**: `main.tf` に `provider` ブロックが残っている状態で、`generate` でも `provider.tf` が生成されている。

**対処法**: `main.tf` から `provider` ブロックを削除してください（Terragrunt 使用時は `generate` で管理するため）。

### 3. `Error: Failed to read variables from inputs`

```
Error: No value for required variable
```

**原因**: `variables.tf` で定義された必須変数に対応する `inputs` が `terragrunt.hcl` に設定されていない。

**対処法**: `terragrunt.hcl` の `inputs` に必要な変数をすべて追加してください。

---

## 発展課題

1. **`generate` でバックエンド設定を追加してみよう**: `generate "backend"` ブロックを追加して、S3 バックエンド設定を自動生成してみましょう。

2. **`remote_state` を設定してみよう**: `generate` の代わりに `remote_state` ブロックを使って、バックエンド設定を宣言的に管理してみましょう。

3. **Terragrunt と Terraform の比較をしてみよう**: 同じリソースを Terraform 単体 (`terraform apply -var-file=...`) と Terragrunt (`terragrunt apply`) の両方で管理してみて、違いを体感しましょう。

---

[<- 前のステップ: モジュール](04-modules.md) | [次のステップ: マルチ環境管理 ->](06-terragrunt-multi-env.md)
