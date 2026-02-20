方法B 詳細手順
全体の流れ
```
① AWS CLIでリソースID収集
        ↓
② import.tf を生成（スクリプト）
        ↓
③ generate-config-out でHCLコード生成
        ↓
④ コード整理 → plan差分なし確認 → apply
```
Step1: 対象リソースのID収集
まずVPC内のリソースIDをAWS CLIで洗い出します。

```
VPC_ID="vpc-xxxxxxxxxxxxxxxxx"
REGION="ap-northeast-1"
PROFILE="your-profile"

# VPC本体
echo "=== VPC ==="
aws ec2 describe-vpcs \
  --vpc-ids $VPC_ID \
  --query "Vpcs[].VpcId" \
  --output text --region $REGION --profile $PROFILE

# Subnet
echo "=== Subnets ==="
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "Subnets[].[SubnetId,Tags[?Key=='Name'].Value|[0]]" \
  --output table --region $REGION --profile $PROFILE

# Security Group
echo "=== Security Groups ==="
aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "SecurityGroups[].[GroupId,GroupName]" \
  --output table --region $REGION --profile $PROFILE

# Internet Gateway
echo "=== Internet Gateway ==="
aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
  --query "InternetGateways[].InternetGatewayId" \
  --output text --region $REGION --profile $PROFILE

# Route Table
echo "=== Route Tables ==="
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "RouteTables[].[RouteTableId,Tags[?Key=='Name'].Value|[0]]" \
  --output table --region $REGION --profile $PROFILE

# EC2インスタンス
echo "=== EC2 Instances ==="
aws ec2 describe-instances \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running,stopped" \
  --query "Reservations[].Instances[].[InstanceId,Tags[?Key=='Name'].Value|[0]]" \
  --output table --region $REGION --profile $PROFILE

# NAT Gateway
echo "=== NAT Gateways ==="
aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=$VPC_ID" \
  --query "NatGateways[?State!='deleted'].[NatGatewayId]" \
  --output text --region $REGION --profile $PROFILE
```

Step2: import.tf をスクリプトで自動生成
Step1の結果を元にimportブロックを生成するスクリプトです。
```
#!/bin/bash
# generate_import.sh

VPC_ID="vpc-xxxxxxxxxxxxxxxxx"
REGION="ap-northeast-1"
PROFILE="your-profile"
OUTPUT="import.tf"

echo "# Auto-generated import blocks" > $OUTPUT
echo "" >> $OUTPUT

# VPC
echo 'import {' >> $OUTPUT
echo "  to = aws_vpc.main" >> $OUTPUT
echo "  id = \"$VPC_ID\"" >> $OUTPUT
echo '}' >> $OUTPUT
echo "" >> $OUTPUT

# Subnets
SUBNET_IDS=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "Subnets[].SubnetId" \
  --output text --region $REGION --profile $PROFILE)

i=1
for SUBNET_ID in $SUBNET_IDS; do
  echo "import {" >> $OUTPUT
  echo "  to = aws_subnet.subnet_${i}" >> $OUTPUT
  echo "  id = \"$SUBNET_ID\"" >> $OUTPUT
  echo "}" >> $OUTPUT
  echo "" >> $OUTPUT
  i=$((i+1))
done

# Security Groups（defaultは除外）
SG_IDS=$(aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "SecurityGroups[?GroupName!='default'].GroupId" \
  --output text --region $REGION --profile $PROFILE)

i=1
for SG_ID in $SG_IDS; do
  echo "import {" >> $OUTPUT
  echo "  to = aws_security_group.sg_${i}" >> $OUTPUT
  echo "  id = \"$SG_ID\"" >> $OUTPUT
  echo "}" >> $OUTPUT
  echo "" >> $OUTPUT
  i=$((i+1))
done

# Internet Gateway
IGW_ID=$(aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
  --query "InternetGateways[0].InternetGatewayId" \
  --output text --region $REGION --profile $PROFILE)

if [ "$IGW_ID" != "None" ]; then
  echo "import {" >> $OUTPUT
  echo "  to = aws_internet_gateway.main" >> $OUTPUT
  echo "  id = \"$IGW_ID\"" >> $OUTPUT
  echo "}" >> $OUTPUT
  echo "" >> $OUTPUT
fi

# EC2インスタンス
INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running,stopped" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text --region $REGION --profile $PROFILE)

i=1
for INSTANCE_ID in $INSTANCE_IDS; do
  echo "import {" >> $OUTPUT
  echo "  to = aws_instance.instance_${i}" >> $OUTPUT
  echo "  id = \"$INSTANCE_ID\"" >> $OUTPUT
  echo "}" >> $OUTPUT
  echo "" >> $OUTPUT
  i=$((i+1))
done

echo "✅ $OUTPUT を生成しました"
cat $OUTPUT
```

```
chmod +x generate_import.sh
./generate_import.sh
```
生成される import.tf のイメージ：
```hcl
# Auto-generated import blocks

import {
  to = aws_vpc.main
  id = "vpc-xxxxxxxxxxxxxxxxx"
}

import {
  to = aws_subnet.subnet_1
  id = "subnet-aaa111"
}

import {
  to = aws_subnet.subnet_2
  id = "subnet-bbb222"
}

import {
  to = aws_security_group.sg_1
  id = "sg-ccc333"
}

import {
  to = aws_instance.instance_1
  id = "i-ddd444"
}
```
Step3: HCLコードを自動生成
```bash
# プロバイダー設定が必要（なければ作成）
cat > versions.tf << 'EOF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "ap-northeast-1"
  profile = "your-profile"
}
EOF

terraform init

# HCLを自動生成（既存のresourceブロックがない状態でOK）
terraform plan -generate-config-out=generated.tf
generated.tf にすべてのresourceブロックが生成されます。
```
Step4: コード整理 → 差分なし確認 → apply
```bash
# 生成されたコードを確認
cat generated.tf

# 必要に応じてリソース名をわかりやすく修正
# subnet_1 → public_subnet など

# 差分を確認（ここでno changesになるのが理想）
terraform plan

# 差分があればgenerated.tfを修正して再度plan
# ※ 差分なしを確認できたらapply
terraform apply

# apply後はimport.tfのimportブロックは削除してOK
```
よくある差分の原因と対処
差分の原因対処タグの順序違いlifecycle { ignore_changes = [tags] } を追加デフォルト値の差異AWSのデフォルト値をコードに明示管理外の属性ignore_changes で除外ENIなどの自動生成リソースimportの対象から外す
```hcl
# 差分が出やすい箇所の対処例
resource "aws_instance" "instance_1" {
  # ... 生成されたコード ...

  lifecycle {
    ignore_changes = [
      tags,
      user_data,
    ]
  }
}
```