# アーキテクチャ設計書

## 概要

このリポジトリは、Terraform と Terragrunt を段階的に学ぶためのハンズオン教材です。
AWS をターゲットクラウドとし、LocalStack を使ったローカル実行にも対応しています。

## ディレクトリ構造

```
terra-handson/
├── docs/                          # ドキュメント
│   ├── ARCHITECTURE.md            # 本ファイル（設計書）
│   ├── cheatsheet.md              # コマンドチートシート
│   └── tutorials/                 # ステップ別チュートリアル
│       ├── 00-prerequisites.md    # 環境セットアップ
│       ├── 01-hello-terraform.md  # Step 1
│       ├── 02-variables-and-outputs.md  # Step 2
│       ├── 03-state-and-backend.md      # Step 3
│       ├── 04-modules.md                # Step 4
│       ├── 05-terragrunt-basics.md      # Step 5
│       └── 06-terragrunt-multi-env.md   # Step 6
├── steps/                         # ハンズオンのステップ（学習パス）
│   ├── 01-hello-terraform/        # Step 1: Terraform入門
│   ├── 02-variables-and-outputs/  # Step 2: 変数と出力
│   ├── 03-state-and-backend/      # Step 3: ステートとバックエンド
│   ├── 04-modules/                # Step 4: モジュール
│   ├── 05-terragrunt-basics/      # Step 5: Terragrunt入門
│   └── 06-terragrunt-multi-env/   # Step 6: マルチ環境管理
├── modules/                       # 再利用可能なTerraformモジュール
│   ├── s3-bucket/                 # S3バケットモジュール
│   ├── vpc/                       # VPCモジュール
│   └── ec2-instance/              # EC2インスタンスモジュール
├── environments/                  # Terragrunt環境別設定（参考用）
│   ├── terragrunt.hcl             # ルート設定
│   ├── dev/
│   ├── staging/
│   └── prod/
├── .gitignore
├── LICENSE
└── README.md
```

## 学習パス

### Step 1: Hello Terraform (`steps/01-hello-terraform/`)

**目標**: Terraform の基本概念を理解し、最初のリソースを作成する

- 学ぶこと:
  - HCL（HashiCorp Configuration Language）の基本構文
  - `provider` / `resource` ブロック
  - `terraform init` / `plan` / `apply` / `destroy` のワークフロー
- 作成するリソース: S3 バケット
- 前提知識: なし（完全な初心者向け）

### Step 2: 変数と出力 (`steps/02-variables-and-outputs/`)

**目標**: 設定を柔軟にするための変数と、結果を参照するための出力を学ぶ

- 学ぶこと:
  - `variable` ブロック（型、デフォルト値、バリデーション）
  - `output` ブロック
  - `locals` ブロック
  - `terraform.tfvars` による値の注入
- 作成するリソース: タグ付き S3 バケット
- 前提知識: Step 1

### Step 3: ステートとバックエンド (`steps/03-state-and-backend/`)

**目標**: Terraform のステート管理を理解し、リモートバックエンドを設定する

- 学ぶこと:
  - `terraform.tfstate` の役割と構造
  - ローカル vs リモートバックエンド（S3）
  - ステートロック（DynamoDB）
  - `terraform import` によるインポート
- 作成するリソース: S3 バックエンド + DynamoDB テーブル
- 前提知識: Step 1, 2

### Step 4: モジュール (`steps/04-modules/`)

**目標**: 再利用可能なモジュールを作成し、コードの重複を排除する

- 学ぶこと:
  - モジュールの構造（`main.tf`, `variables.tf`, `outputs.tf`）
  - モジュールの呼び出し方
  - モジュール間の依存関係
  - `modules/` ディレクトリの活用
- 作成するリソース: VPC + EC2（モジュールとして構成）
- 前提知識: Step 1, 2, 3

### Step 5: Terragrunt 入門 (`steps/05-terragrunt-basics/`)

**目標**: Terragrunt の基本概念を理解し、DRY な設定管理を始める

- 学ぶこと:
  - Terragrunt とは何か（Terraform のラッパー）
  - `terragrunt.hcl` の基本構文
  - バックエンド設定の自動生成（`generate` / `remote_state`）
  - `inputs` による変数の注入
  - `terragrunt run-all` によるまとめ実行
- 作成するリソース: Step 4 のモジュールを Terragrunt で管理
- 前提知識: Step 1〜4

### Step 6: マルチ環境管理 (`steps/06-terragrunt-multi-env/`)

**目標**: Terragrunt で dev/staging/prod の複数環境を効率的に管理する

- 学ぶこと:
  - 環境ごとの `terragrunt.hcl` 設定
  - `include` による親設定の継承
  - `dependency` ブロックによるモジュール間参照
  - `environments/` ディレクトリ構成パターン
  - 環境差分の管理戦略
- 作成するリソース: dev/staging/prod の3環境に VPC + EC2 をデプロイ
- 前提知識: Step 1〜5

## 設計方針

### 各ステップの独立性

各ステップは `steps/XX-name/` ディレクトリ内で完結します。
ステップごとに独自の `main.tf`, `variables.tf`, `outputs.tf` を持ち、
他のステップに影響を与えずに `terraform apply` を実行できます。

### LocalStack 対応

各ステップでは AWS プロバイダの設定に LocalStack のエンドポイントを
指定するオプションを用意します。これにより、AWS アカウントがなくても
ローカル環境でハンズオンを進められます。

### モジュール設計

`modules/` ディレクトリの共有モジュールは Step 4 以降で使用します。
Step 1〜3 では各ステップ内にリソース定義を直接記述し、
モジュール化の動機を自然に理解できるようにします。

### Terragrunt 導入タイミング

Step 1〜4 は純粋な Terraform のみを使用します。
Terraform の基礎を十分に理解した上で、Step 5 から Terragrunt を導入し、
Terragrunt が解決する課題（設定の重複、環境管理の複雑さ）を
実感できるように構成しています。
