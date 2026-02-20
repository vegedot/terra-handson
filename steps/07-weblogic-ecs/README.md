# Step 7: WebLogic on ECS Fargate + Oracle RDS SE2

## アーキテクチャ概要

```
Internet
    │
    ▼ (port 80)
┌─────────────────────────────────────────────────────────┐
│  パブリックサブネット (ap-northeast-1a / 1c)              │
│  ┌─────────────────────┐  ┌───────────────┐             │
│  │ Application Load    │  │ NAT Gateway   │             │
│  │ Balancer (ALB)      │  │ (EIP付き)     │             │
│  └─────────┬───────────┘  └──────┬────────┘             │
└────────────┼──────────────────────┼─────────────────────┘
             │ (port 7001)          │ (アウトバウンド)
┌────────────▼──────────────────────┼─────────────────────┐
│  プライベートAppサブネット          │                     │
│  ┌─────────────────────────────┐  │                     │
│  │ ECS Fargate                 │◄─┘                     │
│  │ WebLogic 14.1.1             │                        │
│  │ (2 vCPU / 4GB RAM)         │                        │
│  └─────────────┬───────────────┘                        │
└────────────────┼────────────────────────────────────────┘
                 │ (port 1521)
┌────────────────▼────────────────────────────────────────┐
│  プライベートDBサブネット                                  │
│  ┌─────────────────────────────┐                        │
│  │ RDS Oracle SE2 19c          │                        │
│  │ db.t3.medium                │                        │
│  └─────────────────────────────┘                        │
└─────────────────────────────────────────────────────────┘

補助サービス（AWSマネージド）:
  ECR      ... WebLogicコンテナイメージ保管
  Secrets Manager ... パスワード管理
  CloudWatch Logs  ... コンテナログ収集
```

## 作成されるリソース

| リソース | 用途 |
|---------|------|
| VPC / Subnets / IGW | ネットワーク基盤（既存VPCモジュール利用） |
| NAT Gateway + EIP | プライベートサブネットからのアウトバウンド通信 |
| Security Groups (3個) | ALB / ECS / RDS 間の通信制御 |
| ECR Repository | WebLogicコンテナイメージの保管 |
| ECS Cluster | Fargateタスクの実行環境 |
| ECS Task Definition | WebLogicコンテナの仕様定義 |
| ECS Service | タスクの常時稼働＋ALB連携 |
| ALB + Target Group | HTTPルーティング |
| RDS Oracle SE2 | Weblogicのデータストア |
| Secrets Manager (2個) | WebLogic管理パスワード / RDS接続情報 |
| CloudWatch Log Group | コンテナログ収集 |
| IAM Roles (2個) | ECSタスク実行ロール / タスクロール |

## 前提条件

- AWS CLI 設定済み (`aws configure`)
- Terraform >= 1.0
- Docker インストール済み（イメージビルド用）
- Oracle Container Registry アカウント（WebLogicイメージ取得用）
  - 登録: https://container-registry.oracle.com
  - 「Middleware」→「weblogic」のライセンスに同意が必要

## デプロイ手順

### Step 1: ECRリポジトリを先に作成する

`weblogic_image_uri` 変数は後から設定するため、まずECRだけを作成します。

```bash
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars を編集（weblogic_image_uri はコメントアウトのまま）

terraform init
terraform apply -target=aws_ecr_repository.weblogic
```

出力される `ecr_repository_url` をメモしておきます。

### Step 2: WebLogicイメージをビルドしてECRにpushする

```bash
# ECRリポジトリURLを変数に設定
ECR_URI=$(terraform output -raw ecr_repository_url)
AWS_REGION="ap-northeast-1"

# ECRにログイン
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${ECR_URI}

# Oracle Container Registryにログイン（Oracle アカウントが必要）
docker login container-registry.oracle.com

# WebLogicイメージをpull（初回は時間がかかります）
docker pull container-registry.oracle.com/middleware/weblogic:14.1.1.0

# ECRリポジトリ名に合わせてタグを付け直す
docker tag container-registry.oracle.com/middleware/weblogic:14.1.1.0 \
  ${ECR_URI}:14.1.1

# ECRにpush
docker push ${ECR_URI}:14.1.1

echo "イメージURI: ${ECR_URI}:14.1.1"
```

> **カスタムイメージを使う場合**
>
> 自前のアプリをデプロイしたい場合は、Oracleのベースイメージから `Dockerfile` を作成してください:
> ```dockerfile
> FROM container-registry.oracle.com/middleware/weblogic:14.1.1.0
> # アプリのWARファイルをデプロイディレクトリに追加
> COPY myapp.war /u01/oracle/user_projects/domains/base_domain/autodeploy/
> ```

### Step 3: 全リソースをデプロイする

```bash
# terraform.tfvars に weblogic_image_uri を設定
# weblogic_image_uri = "123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/terra-handson-dev-weblogic:14.1.1"

terraform apply
```

> **注意**: RDS Oracle の作成には**20〜30分程度**かかります。

### Step 4: 動作確認

```bash
# WebLogic管理コンソールのURLを確認
terraform output weblogic_console_url

# ブラウザで管理コンソールにアクセス
# http://<alb-dns-name>/console
# ユーザー名/パスワード: terraform.tfvars に設定した値
```

## ログの確認

```bash
# ECSサービスの状態確認
aws ecs describe-services \
  --cluster terra-handson-dev-cluster \
  --services terra-handson-dev-weblogic \
  --region ap-northeast-1

# CloudWatch Logsでコンテナログを確認
aws logs tail /ecs/terra-handson-dev/weblogic --follow --region ap-northeast-1
```

## コスト目安（東京リージョン / 1ヶ月）

| リソース | 料金目安 |
|---------|---------|
| ECS Fargate (2vCPU/4GB, 常時稼働) | 約 $70 |
| RDS Oracle SE2 (db.t3.small) | 約 $80 |
| NAT Gateway | 約 $45 + 転送量 |
| ALB | 約 $20 |
| **合計** | **約 $265〜** |

> 学習目的では使用しない時間帯に ECS サービスのタスク数を 0 にすることでコスト削減できます:
> ```bash
> aws ecs update-service --cluster <cluster> --service <service> --desired-count 0
> ```

## リソースの削除

```bash
terraform destroy
```

> **注意**: RDS削除時は `skip_final_snapshot = true` が設定されているため、
> スナップショットなしで削除されます（学習用設定）。本番では `false` に変更してください。

## 次のステップへ向けて

- **HTTPS化**: ACMで証明書を取得し、ALBにHTTPSリスナーを追加する
- **Auto Scaling**: ECSサービスにApplication Auto Scalingを設定する
- **カスタムWebLogicドメイン設定**: WLST（WebLogic Scripting Tool）でJDBCデータソースを設定する
- **マルチAZ化**: `db_multi_az = true` でRDSをHA構成にする

##
```
VPC_ID="vpc-xxxxxxxxxxxxxxxxx"
REGION="ap-northeast-1"

# Subnetの一覧取得
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "Subnets[].SubnetId" \
  --output text --region $REGION

# Security Groupの一覧取得
aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "SecurityGroups[].GroupId" \
  --output text --region $REGION

