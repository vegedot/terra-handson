# Step 4: モジュール - コードの再利用

[<- 前のステップ: ステートとバックエンド](03-state-and-backend.md) | [次のステップ: Terragrunt 入門 ->](05-terragrunt-basics.md)

---

## 学習目標

- Terraform モジュールの構造を理解する
- `module` ブロックでモジュールを呼び出す方法を覚える
- モジュール間の依存関係を理解する
- `modules/` ディレクトリの共有モジュールを活用する

---

## 概念の説明

### なぜモジュールが重要か？

Step 1〜3 では、リソース定義を直接 `.tf` ファイルに書いてきました。しかし、同じ構成を複数の環境で使いたい場合、コードをコピー&ペーストすると:

- コードが重複する
- 修正時にすべてのコピーを変更する必要がある
- 環境間で設定が不整合になるリスクがある

モジュールを使えば、**一度書いたコードを異なるパラメータで何度でも再利用** できます。

### モジュールの構造

モジュールは通常 3 つのファイルで構成されます:

```
modules/s3-bucket/
├── main.tf        # リソース定義（モジュールの本体）
├── variables.tf   # 入力変数（モジュールに渡すパラメータ）
└── outputs.tf     # 出力値（モジュールから返す値）
```

---

## ハンズオン手順

### 1. モジュールの中身を確認

まず `modules/` ディレクトリ配下のモジュールを確認しましょう。

#### S3 バケットモジュール (`modules/s3-bucket/main.tf`)

```hcl
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  tags = merge(
    {
      Name        = var.bucket_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

バージョニングの有効/無効を `var.versioning_enabled` で切り替えられる汎用的な設計になっています。

#### VPC モジュール (`modules/vpc/main.tf`)

VPC、パブリック/プライベートサブネット、インターネットゲートウェイ、ルートテーブルを一括作成します。`count` を使って複数のサブネットを動的に作成しています。

#### EC2 インスタンスモジュール (`modules/ec2-instance/main.tf`)

セキュリティグループと EC2 インスタンスを作成します。SSH と HTTP の通信を許可するセキュリティグループが自動的に設定されます。

### 2. 作業ディレクトリに移動

```bash
cd steps/04-modules
```

### 3. モジュール呼び出しの確認 (`main.tf`)

```hcl
# VPCモジュールの呼び出し
module "vpc" {
  source = "../../modules/vpc"

  name                 = "${var.project_name}-${var.environment}"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  environment          = var.environment
  tags                 = var.tags
}

# EC2インスタンスモジュールの呼び出し
# VPCモジュールの出力を参照して配置先を決定
module "ec2" {
  source = "../../modules/ec2-instance"

  name          = "${var.project_name}-${var.environment}-web"
  ami_id        = var.ami_id
  instance_type = var.instance_type
  vpc_id        = module.vpc.vpc_id            # VPCモジュールの出力を参照
  subnet_id     = module.vpc.public_subnet_ids[0]  # 最初のパブリックサブネットに配置
  environment   = var.environment
  tags          = var.tags
}

# S3バケットモジュールの呼び出し
module "s3" {
  source = "../../modules/s3-bucket"

  bucket_name        = "${var.project_name}-${var.environment}-app-data"
  environment        = var.environment
  versioning_enabled = true
  tags               = var.tags
}
```

**注目ポイント**:
- `source` でモジュールのパスを指定する
- `module.vpc.vpc_id` のようにモジュールの出力を他のモジュールで参照できる
- Terraform が依存関係を自動的に解決する（VPC -> EC2 の順に作成される）

### 4. 出力定義の確認 (`outputs.tf`)

```hcl
output "vpc_id" {
  description = "VPCのID"
  value       = module.vpc.vpc_id
}

output "instance_id" {
  description = "EC2インスタンスのID"
  value       = module.ec2.instance_id
}

output "s3_bucket_name" {
  description = "S3バケット名"
  value       = module.s3.bucket_name
}
```

モジュールの出力は `module.<モジュール名>.<出力名>` で参照します。

### 5. 初期化と実行

```bash
terraform init
terraform plan
terraform apply
```

期待される出力:
```
Apply complete! Resources: 9 added, 0 changed, 0 destroyed.

Outputs:

instance_id       = "i-xxxxxxxxxxxxxxxxx"
instance_public_ip = "xx.xx.xx.xx"
public_subnet_ids  = [
  "subnet-xxxxxxxxxxxxxxxxx",
  "subnet-xxxxxxxxxxxxxxxxx",
]
s3_bucket_arn  = "arn:aws:s3:::handson-dev-app-data"
s3_bucket_name = "handson-dev-app-data"
vpc_id         = "vpc-xxxxxxxxxxxxxxxxx"
```

### 6. モジュールの依存関係を確認

```bash
# 作成されたリソースの一覧
terraform state list
```

期待される出力:
```
module.ec2.aws_instance.this
module.ec2.aws_security_group.this
module.s3.aws_s3_bucket.this
module.s3.aws_s3_bucket_server_side_encryption_configuration.this
module.s3.aws_s3_bucket_versioning.this
module.vpc.aws_internet_gateway.this
module.vpc.aws_route_table.public
module.vpc.aws_route_table_association.public[0]
module.vpc.aws_route_table_association.public[1]
module.vpc.aws_subnet.private[0]
module.vpc.aws_subnet.private[1]
module.vpc.aws_subnet.public[0]
module.vpc.aws_subnet.public[1]
module.vpc.aws_vpc.this
```

リソース名が `module.xxx.` のプレフィックス付きで管理されていることを確認してください。

### 7. クリーンアップ

```bash
terraform destroy
```

---

## 確認ポイント

- `terraform init` でモジュールが初期化されたか
- モジュール間の依存関係（VPC -> EC2）が自動解決されたか
- `terraform state list` でモジュール単位でリソースが管理されているか
- 出力値が `module.<名前>.<出力名>` で参照できたか

---

## よくあるエラーと対処法

### 1. `Error: Module not installed`

```
Error: Module not installed
  module.vpc: This module is not yet installed.
```

**原因**: `terraform init` を実行していない、またはモジュールのパスが間違っている。

**対処法**: `terraform init` を実行してください。パスが正しいか（`../../modules/vpc` など相対パス）も確認してください。

### 2. `Error: Unsupported attribute`

```
Error: Unsupported attribute
  module.vpc.xxx is not defined in the module's outputs.
```

**原因**: モジュールに存在しない出力値を参照している。

**対処法**: モジュールの `outputs.tf` に定義された出力名を確認してください。

### 3. `Error: Invalid AMI ID`

```
Error: creating EC2 Instance: InvalidAMIID.NotFound
```

**原因**: 指定した AMI ID が存在しないか、リージョンが異なる。

**対処法**: `variables.tf` の `ami_id` のデフォルト値を、使用するリージョンで有効な AMI ID に変更してください。LocalStack を使用している場合はダミー ID でも動作します。

---

## 発展課題

1. **モジュールにパラメータを追加してみよう**: `modules/ec2-instance/` に `key_name` 変数を追加し、SSH キーペアを指定できるようにしてみましょう。

2. **モジュールを複数回呼び出してみよう**: `module "ec2_api"` と `module "ec2_web"` のように同じモジュールを異なるパラメータで 2 回呼び出して、2 台の EC2 インスタンスを作成してみましょう。

3. **`terraform graph` を試してみよう**: `terraform graph | dot -Tpng > graph.png` でリソースの依存関係グラフを可視化してみましょう（Graphviz が必要です）。

---

[<- 前のステップ: ステートとバックエンド](03-state-and-backend.md) | [次のステップ: Terragrunt 入門 ->](05-terragrunt-basics.md)
