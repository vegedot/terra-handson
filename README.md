# Terra Handson - Terraform & Terragrunt ハンズオン学習教材

Terraform と Terragrunt を **ゼロから段階的に** 学ぶためのハンズオン教材です。
AWS をターゲットクラウドとし、LocalStack を使ったローカル実行にも対応しているため、AWS アカウントがなくても学習を始められます。

## 前提条件

| ツール | バージョン | 用途 |
|--------|-----------|------|
| [Terraform](https://www.terraform.io/) | >= 1.0 | インフラのコード化 |
| [Terragrunt](https://terragrunt.gruntwork.io/) | >= 0.50 | Terraform の DRY な設定管理 |
| [AWS CLI](https://aws.amazon.com/cli/) | v2 | AWS リソースの操作・確認 |
| [Docker](https://www.docker.com/) | 最新版 | LocalStack の実行 |
| [LocalStack](https://localstack.cloud/) | 最新版 | AWS サービスのローカルエミュレーション |

> 各ツールの詳しいインストール手順は [環境セットアップガイド](docs/tutorials/00-prerequisites.md) を参照してください。

## クイックスタート

```bash
# 1. リポジトリをクローン
git clone <repository-url>
cd terra-handson

# 2. LocalStack を起動（AWS アカウント不要で学習可能）
docker run --rm -d -p 4566:4566 --name localstack localstack/localstack

# 3. Step 1 から開始
cd steps/01-hello-terraform
terraform init
terraform plan
terraform apply
```

## 学習パス

全 6 ステップで、Terraform の基礎から Terragrunt によるマルチ環境管理まで段階的に学びます。

| ステップ | テーマ | 学ぶこと | 所要時間目安 |
|---------|--------|---------|------------|
| [Step 1](docs/tutorials/01-hello-terraform.md) | Hello Terraform | HCL 構文、provider/resource、init/plan/apply/destroy | 30分 |
| [Step 2](docs/tutorials/02-variables-and-outputs.md) | 変数と出力 | variable、output、locals、tfvars | 30分 |
| [Step 3](docs/tutorials/03-state-and-backend.md) | ステートとバックエンド | tfstate、S3 バックエンド、DynamoDB ロック | 45分 |
| [Step 4](docs/tutorials/04-modules.md) | モジュール | モジュール作成・呼び出し、VPC/EC2/S3 構成 | 45分 |
| [Step 5](docs/tutorials/05-terragrunt-basics.md) | Terragrunt 入門 | terragrunt.hcl、generate、inputs | 30分 |
| [Step 6](docs/tutorials/06-terragrunt-multi-env.md) | マルチ環境管理 | include、環境分離、run-all | 45分 |

## ディレクトリ構造

```
terra-handson/
├── docs/                          # ドキュメント
│   ├── ARCHITECTURE.md            # アーキテクチャ設計書
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
│   ├── dev/                       # 開発環境
│   ├── staging/                   # ステージング環境
│   └── prod/                      # 本番環境
├── .gitignore
├── LICENSE
└── README.md
```

## 参考リンク

- [Terraform 公式ドキュメント](https://developer.hashicorp.com/terraform/docs)
- [Terragrunt 公式ドキュメント](https://terragrunt.gruntwork.io/docs/)
- [AWS プロバイダリファレンス](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [LocalStack ドキュメント](https://docs.localstack.cloud/)
- [コマンドチートシート](docs/cheatsheet.md)

## ライセンス

このプロジェクトは [Apache License 2.0](LICENSE) の下で公開されています。
