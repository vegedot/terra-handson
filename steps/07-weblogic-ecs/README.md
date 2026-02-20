# Step 7: WebLogic on ECS Fargate + Oracle RDS SE2

インターネット非公開のPOC構成で、WebLogicをECS Fargate上で動かし、Oracle RDS SE2に接続する環境を構築します。
踏み台EC2にSSM Session Manager経由でRDP接続し、Internal ALB経由でWebLogic管理コンソールに到達します。

## アーキテクチャ

```
                    ┌─────────────────────────────────────────────────────┐
                    │ パブリックサブネット (ap-northeast-1a / 1c)           │
開発者PC             │  ┌──────────────┐                                   │
    │               │  │ NAT Gateway  │ ← ECSがECR/SecretsManager等に     │
    │ SSM           │  │ (EIP付き)    │   アクセスする際のアウトバウンド出口  │
    │ Session       │  └──────────────┘                                   │
    │ Manager       └─────────────────────────────────────────────────────┘
    │ (HTTPS)
    ▼                ┌─────────────────────────────────────────────────────┐
┌───────┐            │ プライベートAppサブネット (ap-northeast-1a / 1c)     │
│  SSM  │            │                                                     │
│ VPC   │◄──────────►│  ┌─────────────────┐   ┌───────────────────────┐   │
│ Endpoint│  HTTPS   │  │ 踏み台EC2        │   │ ECS Fargate           │   │
└───────┘  (443)     │  │ Windows 2022    ├──►│ WebLogic 14.1.1       │   │
                     │  │ (t3.medium)     │   │ (2 vCPU / 4GB RAM)    │   │
                     │  │                 │   └──────────┬────────────┘   │
                     │  │  ブラウザから    │              │                 │
                     │  │  Internal ALB   │   ┌──────────▼────────────┐   │
                     │  │  経由でWebLogic ├──►│ Internal ALB          │   │
                     │  │  コンソールへ   │   │ (port 80 → 7001)      │   │
                     │  └─────────────────┘   └───────────────────────┘   │
                     └─────────────────────────────────────────────────────┘
                                                          │ (port 1521)
                     ┌────────────────────────────────────▼────────────────┐
                     │ プライベートDBサブネット (ap-northeast-1a / 1c)       │
                     │  ┌──────────────────────────────┐                   │
                     │  │ RDS Oracle SE2 19c            │                   │
                     │  │ db.t3.small                   │                   │
                     │  └──────────────────────────────┘                   │
                     └─────────────────────────────────────────────────────┘

AWSマネージドサービス:
  ECR             ... WebLogicコンテナイメージ保管
  Secrets Manager ... パスワード管理（RDS接続情報 / WebLogic管理認証情報）
  CloudWatch Logs ... ECSコンテナログ収集
  VPC Endpoints   ... ssm / ssmmessages（Session Manager用）/ s3（ECRイメージpull用）
```

## 作成されるリソース

| カテゴリ | リソース | 用途 |
|---------|---------|------|
| **ネットワーク** | VPC / Subnets (3層) / IGW | 基盤ネットワーク（terraform-aws-modules/vpc） |
| | NAT Gateway + EIP | ECS→ECR等のアウトバウンド通信 |
| | VPC Endpoint: ssm / ssmmessages | SSM Session Manager（インターネット不要） |
| | VPC Endpoint: s3 (Gateway) | ECRイメージレイヤーのpull（無料・NAT GW費用削減） |
| **セキュリティ** | Security Group × 4 | 踏み台 / ALB / ECS / RDS / VPCエンドポイント |
| **踏み台** | EC2 (Windows Server 2022) | SSM経由でRDP接続し内部にアクセスする踏み台 |
| | IAM Role (AmazonSSMManagedInstanceCore) | SSM Session Manager管理用 |
| **コンテナ** | ECR Repository | WebLogicイメージ保管（ライフサイクルポリシー付き） |
| | ECS Cluster (Fargate) | コンテナ実行環境（terraform-aws-modules/ecs） |
| | ECS Task Definition | WebLogicコンテナ仕様（CPU/Memory/環境変数/シークレット） |
| | ECS Service | タスク常時稼働 + Internal ALB連携 |
| **ロードバランサー** | Internal ALB | VPC内からのHTTPルーティング（terraform-aws-modules/alb） |
| | Target Group | ECS FargateタスクへのIPベースルーティング |
| **データベース** | RDS Oracle SE2 19c | WebLogicデータストア（terraform-aws-modules/rds） |
| | DB Subnet Group / Parameter Group / Option Group | RDSモジュールが自動作成 |
| **機密管理** | Secrets Manager × 2 | RDS接続情報 / WebLogic管理者認証情報 |
| **監視** | CloudWatch Log Group | ECSコンテナログ（30日保持） |
| **IAM** | ECS Task Execution Role | ECR pull / CloudWatch Logs / Secrets Manager取得 |
| | ECS Task Role | コンテナ内アプリ用（必要に応じて権限追加） |

## 使用コミュニティモジュール

| モジュール | バージョン | 担当リソース |
|-----------|----------|------------|
| [terraform-aws-modules/vpc/aws](https://github.com/terraform-aws-modules/terraform-aws-vpc) | ~> 5.0 | VPC / サブネット3層 / NAT GW / ルートテーブル |
| [terraform-aws-modules/security-group/aws](https://github.com/terraform-aws-modules/terraform-aws-security-group) | ~> 5.0 | 踏み台 / ECS / RDS / VPCエンドポイント用SG |
| [terraform-aws-modules/alb/aws](https://github.com/terraform-aws-modules/terraform-aws-alb) | ~> 9.0 | Internal ALB / ターゲットグループ / リスナー |
| [terraform-aws-modules/rds/aws](https://github.com/terraform-aws-modules/terraform-aws-rds) | ~> 6.0 | RDS Oracle / サブネットグループ / パラメータグループ |
| [terraform-aws-modules/ecs/aws](https://github.com/terraform-aws-modules/terraform-aws-ecs) | ~> 5.0 | ECSクラスター / Fargateキャパシティプロバイダー |

## 前提条件

- AWS CLI 設定済み（`aws configure`）
- Terraform >= 1.0
- Docker インストール済み（イメージビルド用）
- SSM Session Manager Plugin インストール済み（RDP接続に使用）
  ```bash
  # インストール確認
  aws ssm start-session --version
  ```
- Oracle Container Registry アカウント（WebLogicベースイメージ取得用）
  - 登録: https://container-registry.oracle.com
  - 「Middleware」→「weblogic」のライセンス同意が必要

## デプロイ手順

### Step 1: 設定ファイルを準備する

```bash
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` を編集します。`weblogic_image_uri` はこの時点ではコメントアウトのままにします。

```bash
# terraform.tfvars の必須設定項目
#   weblogic_admin_password = "..."   # 8文字以上
#   weblogic_image_uri      = (後で設定)
```

### Step 2: ECRリポジトリだけ先に作成する

イメージのpush先が必要なため、最初にECRのみを作成します。

```bash
terraform init
terraform apply -target=aws_ecr_repository.weblogic
```

出力される `ecr_repository_url` をメモします。

```bash
ECR_URI=$(terraform output -raw ecr_repository_url)
echo $ECR_URI
# 例: 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/terra-handson-dev-weblogic
```

### Step 3: WebLogicイメージをビルドしてECRにpushする

```bash
AWS_REGION="ap-northeast-1"

# ECRにログイン
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${ECR_URI}

# Oracle Container Registryにログイン（Oracleアカウントが必要）
docker login container-registry.oracle.com

# WebLogicベースイメージをpull（初回は数GB、時間がかかります）
docker pull container-registry.oracle.com/middleware/weblogic:14.1.1.0

# ECR用にタグを付け替えてpush
docker tag container-registry.oracle.com/middleware/weblogic:14.1.1.0 \
  ${ECR_URI}:14.1.1
docker push ${ECR_URI}:14.1.1

echo "設定するURI: ${ECR_URI}:14.1.1"
```

> **自前アプリをデプロイする場合**
>
> OracleのベースイメージからDockerfileを作成し、WARをデプロイディレクトリに配置します:
> ```dockerfile
> FROM container-registry.oracle.com/middleware/weblogic:14.1.1.0
> COPY myapp.war /u01/oracle/user_projects/domains/base_domain/autodeploy/
> ```
> ビルドしてECRにpushする手順は同様です。

### Step 4: 全リソースをデプロイする

`terraform.tfvars` に `weblogic_image_uri` を設定してから `apply` します。

```bash
# terraform.tfvars を編集
# weblogic_image_uri = "123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/terra-handson-dev-weblogic:14.1.1"

terraform apply
```

> **所要時間の目安**
> - VPC / Security Groups / ECR / IAM: 約2分
> - VPC Endpoints (Interface型 × 2): 約3分
> - RDS Oracle: **約20〜30分**（最も時間がかかります）
> - ECS Service（ヘルスチェック含む): 約5分

### Step 5: 踏み台EC2にRDP接続してWebLogicを確認する

```bash
# 踏み台のインスタンスIDを確認
BASTION_ID=$(terraform output -raw bastion_instance_id)
echo "踏み台ID: ${BASTION_ID}"

# ① SSMポートフォワーディングを開始（このターミナルは開いたまま）
aws ssm start-session \
  --target ${BASTION_ID} \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["3389"],"localPortNumber":["13389"]}'
```

```bash
# ② 別ターミナルでWindowsの初期パスワードを取得（初回のみ）
aws ec2 get-password-data \
  --instance-id ${BASTION_ID} \
  --region ap-northeast-1
```

③ RDPクライアントで `localhost:13389` に接続します。
   - ユーザー名: `Administrator`
   - パスワード: 上記コマンドで取得した値

④ 踏み台EC2のブラウザから管理コンソールにアクセスします。

```bash
# WebLogicコンソールのURLを確認（踏み台EC2のブラウザに入力）
terraform output weblogic_internal_url
# 例: http://terra-handson-dev-alb-xxxx.ap-northeast-1.elb.amazonaws.com/console
```

## 操作リファレンス

### ログの確認

```bash
# ECSサービスの状態確認
aws ecs describe-services \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --services $(terraform output -raw ecs_service_name) \
  --region ap-northeast-1 \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount,Events:events[0:3]}'

# WebLogicコンテナのログをリアルタイムで確認
aws logs tail $(terraform output -raw cloudwatch_log_group) \
  --follow \
  --region ap-northeast-1
```

### ECSタスクのIPアドレスを確認する

Internal ALBを使わずに踏み台から直接タスクに接続したい場合:

```bash
CLUSTER=$(terraform output -raw ecs_cluster_name)
SERVICE=$(terraform output -raw ecs_service_name)

# 実行中タスクのARNを取得
TASK_ARN=$(aws ecs list-tasks \
  --cluster ${CLUSTER} \
  --service-name ${SERVICE} \
  --region ap-northeast-1 \
  --query 'taskArns[0]' --output text)

# タスクのプライベートIPを確認
aws ecs describe-tasks \
  --cluster ${CLUSTER} \
  --tasks ${TASK_ARN} \
  --region ap-northeast-1 \
  --query 'tasks[0].attachments[0].details[?name==`privateIPv4Address`].value' \
  --output text
```

### タスク数の変更（コスト削減）

使用しない時間帯はECSタスクを停止してコストを削減できます。

```bash
CLUSTER=$(terraform output -raw ecs_cluster_name)
SERVICE=$(terraform output -raw ecs_service_name)

# 停止
aws ecs update-service --cluster ${CLUSTER} --service ${SERVICE} --desired-count 0 --region ap-northeast-1

# 再開
aws ecs update-service --cluster ${CLUSTER} --service ${SERVICE} --desired-count 1 --region ap-northeast-1
```

### RDS接続情報の確認

RDSのパスワードはSecrets Managerに保存されています。踏み台EC2からSQL*Plusや
SQL Developerで接続する場合は以下で確認できます。

```bash
aws secretsmanager get-secret-value \
  --secret-id $(terraform output -raw rds_secret_arn) \
  --region ap-northeast-1 \
  --query SecretString --output text | jq .
```

## コスト目安（東京リージョン / 1ヶ月・常時稼働）

| リソース | 料金目安 | 備考 |
|---------|---------|------|
| ECS Fargate (2vCPU/4GB) | 約 $70 | 停止可能（タスク数0で課金なし） |
| RDS Oracle SE2 (db.t3.small) | 約 $80 | 停止可能（最大7日まで） |
| NAT Gateway | 約 $45 + 転送量 | 起動中は常時課金 |
| Internal ALB | 約 $20 | 起動中は常時課金 |
| VPC Endpoints (Interface × 2) | 約 $14 | ssm + ssmmessages |
| 踏み台EC2 (t3.medium) | 約 $30 | 停止可能 |
| **合計** | **約 $260〜** | |

> **POC期間のコスト削減ヒント**
> - 作業しない日は `terraform destroy` か ECS/RDS/踏み台EC2を停止
> - RDSは停止ができます（最大7日。7日後に自動再起動）:
>   ```bash
>   aws rds stop-db-instance --db-instance-identifier terra-handson-dev-oracle --region ap-northeast-1
>   ```

## トラブルシューティング

### SSM Session Managerで踏み台に接続できない

1. VPCエンドポイントが正常に作成されているか確認
   ```bash
   aws ec2 describe-vpc-endpoints \
     --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)" \
     --query 'VpcEndpoints[*].{Service:ServiceName,State:State}' \
     --output table --region ap-northeast-1
   ```
2. 踏み台EC2のIAMロールに `AmazonSSMManagedInstanceCore` がアタッチされているか確認
3. SSMエージェントが起動しているか確認（EC2起動直後は数分かかることがある）

### ECSタスクが起動しない / ヘルスチェックに失敗する

```bash
# タスクの停止理由を確認
aws ecs describe-tasks \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --tasks <TASK_ARN> \
  --region ap-northeast-1 \
  --query 'tasks[0].{StopCode:stopCode,StoppedReason:stoppedReason,Containers:containers[*].{Name:name,Reason:reason,ExitCode:exitCode}}'
```

WebLogicの起動には最大3分かかるため、ヘルスチェックの `startPeriod = 180` を
超えても失敗する場合はCloudWatch Logsでコンテナのエラーログを確認してください。

### RDSに接続できない

踏み台EC2からRDSへの直接接続は現在のセキュリティグループ設定では許可されていません。
ECSコンテナ（WebLogicのデータソース）経由でのみ接続可能です。
踏み台からRDSに直接接続したい場合は `rds_sg` に踏み台SGからの1521ポートを許可するルールを追加してください。

## リソースの削除

```bash
terraform destroy
```

> **注意**: `skip_final_snapshot = true` のため、RDS削除時にスナップショットは作成されません（POC用設定）。
> 本番環境では `false` に変更し、削除前に手動スナップショットを取得してください。

## 次のステップ

| やること | 概要 |
|---------|------|
| **自前Javaアプリのデプロイ** | WebLogicベースイメージからDockerfileを作成しWARをデプロイ |
| **JDBCデータソース設定** | WLST（WebLogic Scripting Tool）でRDS接続のデータソースを設定 |
| **HTTPS化** | ACMで証明書を取得しALBにHTTPSリスナーを追加 |
| **マルチAZ化** | `db_multi_az = true` でRDSをHA構成に変更 |
| **Auto Scaling** | ECSサービスにApplication Auto Scalingを設定 |
