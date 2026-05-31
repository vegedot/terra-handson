# Step 5: Terragrunt 入門 - DRY なインフラ管理

[<- 前のステップ: モジュール](04-modules.md) | [次のステップ: マルチ環境管理 ->](06-terragrunt-multi-env.md)

---

## 学習目標

- Terragrunt とは何か、なぜ必要かを理解する
- `terragrunt.hcl` の基本構文を覚える
- `generate` によるプロバイダ設定の自動生成を体験する
- `inputs` による変数の注入方法を学ぶ
- `remote_state` によるバックエンド設定の宣言的管理を理解する
- `generate` と `remote_state` のそれぞれの役割とメリット・デメリットを比較する

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

> **参考コード**: `steps/05-terraform-basics/` に、このステップと同等の構成を素の Terraform で実装したコードがあります。`provider.tf`・`terraform.tfvars`・`backend.tf` を Terragrunt の各ブロックと見比べると違いが分かりやすくなります。

### Terragrunt の主要ブロック

**`generate` ブロック**
任意の Terraform ファイルを動的生成します。プロバイダ設定など、**バックエンド以外**のファイル生成に適しています。

```hcl
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

**`remote_state` ブロック**
バックエンド設定を Terragrunt に宣言します。単なるファイル生成に留まらず、Terragrunt が「このモジュールの state がどこにあるか」を理解するための設定です。

```hcl
remote_state {
  backend = "s3"
  config = {
    bucket = "my-tfstate"
    key    = "${path_relative_to_include()}/terraform.tfstate"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
```

**`inputs` ブロック**
`terraform.tfvars` の代わりに、Terraform 変数の値を直接注入します。

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

## Part 1: generate と inputs

`generate` ブロックはプロバイダ設定など、**バックエンド以外**のファイルを動的生成するために使います。

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

## Part 2: remote_state によるバックエンド設定

`remote_state` ブロックは Terragrunt がモジュールの state 位置を「理解する」ための宣言です。単なるファイル生成ツールである `generate` とは本質的に異なります。

### generate だけでバックエンドを設定しようとすると？

「`generate` ブロックで `backend.tf` を生成すれば、`remote_state` は不要では？」という疑問は自然です。実際、ファイルの生成という観点では以下のように代替できます:

```hcl
# ❌ generate のみでバックエンドを設定するアプローチ
locals { rel = path_relative_to_include() }

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "s3" {
    bucket = "my-tfstate"
    key    = "${local.rel}/terraform.tfstate"
  }
}
EOF
}
```

しかしこのアプローチには致命的な問題があります。Terragrunt は `generate` の中身を「ただのファイル生成命令」としか認識しません。**state がどこにあるかを Terragrunt 自身は知らない**のです。

### generate vs remote_state 比較

| 機能 | `generate` のみ | `remote_state` あり |
|---|---|---|
| backend.tf の DRY 化 | 可能 | 可能 |
| key の動的命名 | locals 経由で可能 | 直接可能 |
| `dependency` ブロック | **使用不可** | 使用可能 |
| `run_all` の順序制御 | **機能しない** | 機能する |
| S3/DynamoDB 自動作成 | **不可** | 可能 |
| `mock_outputs` による CI 安定化 | **使用不可** | 使用可能 |
| クロスモジュール参照 | ハードコードに後退 | DRY のまま維持 |

#### dependency ブロックが使えない問題

`dependency` ブロックは内部的に `remote_state` の設定を参照して他モジュールの state を読みに行きます。`remote_state` がない場合、Terragrunt はどこに state があるかを知りません:

```hcl
# ❌ generate のみ → dependency が使えない
dependency "vpc" {
  config_path = "../vpc"
  # Terragrunt は ../vpc の state がどこにあるか不明
  # → data "terraform_remote_state" への後退
}
```

代替として `data "terraform_remote_state"` を使うことになりますが、解消しようとしていたハードコードが復活します:

```hcl
# ❌ ハードコードが復活する
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "my-tfstate"            # ハードコード
    key    = "vpc/terraform.tfstate" # ハードコード
    region = "ap-northeast-1"        # ハードコード
  }
}
```

#### run_all の依存順序制御が失われる問題

`run_all apply` は `dependency` ブロックの有向グラフを解析して適用順を自動決定します:

```
# remote_state あり
run_all apply
└─ Terragrunt が依存グラフを解析
   └─ vpc → rds → app の順で自動適用

# generate のみ
run_all apply
└─ 依存関係が不明 → 並列または任意順で実行
   └─ vpc が未適用のまま app が apply されてエラー
```

手動での apply 順序管理が必要になり、運用負荷が Terragrunt 導入前の水準に戻ります。

#### S3/DynamoDB の自動プロビジョニングがない問題

`remote_state` ブロックには、バックエンドリソースが存在しない場合に自動作成する機能があります:

```hcl
remote_state {
  backend = "s3"
  config = {
    bucket         = "my-tfstate"
    dynamodb_table = "terraform-locks"
    # S3バケット・DynamoDBテーブルが存在しなければ自動作成される
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
```

`generate` のみのアプローチでは、バックエンドリソースを別途手動または別の Terraform コードで管理する必要があります。

### generate と remote_state の使い分け

`remote_state` ブロックも内部で `generate` フィールドを持ち、`backend.tf` のファイル生成を行えます。使い分けは明確です:

- プロバイダ設定など **バックエンド以外** → `generate` ブロック
- バックエンド設定 → `remote_state` ブロック（`generate` フィールドでファイルも生成）

### ハンズオン: remote_state を追加する

`terragrunt.hcl` に `remote_state` ブロックを追加します。現在のファイルにはコメントアウトされた `remote_state` ブロックがあるので、コメントを外してください:

```hcl
remote_state {
  backend = "s3"
  config = {
    bucket   = "terragrunt-state-bucket"
    key      = "${path_relative_to_include()}/terraform.tfstate"
    region   = "ap-northeast-1"
    encrypt  = false

    # LocalStack用設定
    endpoint                    = "http://localhost:4566"
    sts_endpoint                = "http://localhost:4566"
    force_path_style            = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    access_key                  = "mock_access_key"
    secret_key                  = "mock_secret_key"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
```

初期化を実行します:

```bash
terragrunt init
```

Terragrunt がバックエンドの S3 バケットを自動作成するか確認します:

```
Remote state S3 bucket terragrunt-state-bucket does not exist or you don't have
permissions to access it. Would you like Terragrunt to create it? (y/n)
```

`y` を入力すると、Terragrunt が S3 バケットを自動作成します。この自動プロビジョニングは `generate` のみのアプローチでは実現できない機能です。

`backend.tf` が生成されたことを確認:

```bash
# Windows
type backend.tf

# macOS/Linux
cat backend.tf
```

適用:

```bash
terragrunt plan
terragrunt apply
```

### クリーンアップ

```bash
terragrunt destroy
```

---

## 確認ポイント

- `terragrunt init` 後に `provider.tf` が自動生成されたか
- `inputs` で指定した値がリソースに反映されたか
- `terragrunt` コマンドが Terraform と同じように使えたか
- `inputs` の値を変更して `terragrunt plan` で差分が表示されたか
- `remote_state` 追加後に `backend.tf` が自動生成されたか
- `generate` と `remote_state` の役割の違いを説明できるか

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

### 4. `Error: Failed to get existing workspaces: S3 bucket does not exist`

```
Error: Failed to get existing workspaces: S3 bucket does not exist
```

**原因**: `remote_state` の S3 バケットが存在しない。LocalStack が起動していない可能性もある。

**対処法**: LocalStack を起動してから再実行してください。Terragrunt が「バケットを作成するか？」と確認してきたら `y` を入力します。

---

## 発展課題

1. **`dependency` を使ってみよう**: 別のモジュールを作成して、`dependency` ブロックで出力値を参照してみましょう。`generate` のみの場合と何が違うか確認しましょう。

2. **`mock_outputs` を試してみよう**: `dependency` に `mock_outputs` を設定して、依存モジュールが未 apply の状態でも `plan` が通ることを確認しましょう。

3. **Terragrunt と Terraform の比較をしてみよう**: 同じリソースを Terraform 単体 (`terraform apply -var-file=...`) と Terragrunt (`terragrunt apply`) の両方で管理してみて、違いを体感しましょう。

---

[<- 前のステップ: モジュール](04-modules.md) | [次のステップ: マルチ環境管理 ->](06-terragrunt-multi-env.md)
