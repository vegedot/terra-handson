# Step 0: 環境セットアップ

[次のステップ: Step 1 - Hello Terraform ->](01-hello-terraform.md)

---

このガイドでは、ハンズオンを進めるために必要なツールのインストールと設定を行います。

## 必要なツール一覧

- **Terraform** (>= 1.0) - インフラをコードで管理するツール
- **Terragrunt** (>= 0.50) - Terraform の設定を DRY に管理するラッパーツール
- **AWS CLI** (v2) - AWS リソースの操作・確認用
- **Docker** - LocalStack の実行に必要
- **LocalStack** - AWS サービスをローカルでエミュレートするツール

---

## 1. Terraform のインストール

### Windows

```powershell
# Chocolatey を使用する場合
choco install terraform

# または winget を使用する場合
winget install Hashicorp.Terraform
```

### macOS

```bash
# Homebrew を使用する場合
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

### Linux (Ubuntu/Debian)

```bash
# HashiCorp の GPG キーと APT リポジトリを追加
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor | \
  sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

# インストール
sudo apt-get update && sudo apt-get install terraform
```

### 動作確認

```bash
terraform version
# 出力例: Terraform v1.x.x
```

---

## 2. Terragrunt のインストール

### Windows

[GitHub Releases](https://github.com/gruntwork-io/terragrunt/releases) から `terragrunt_windows_386.exe` をダウンロードして手動でインストールします。

1. [GitHub Releases](https://github.com/gruntwork-io/terragrunt/releases) から `terragrunt_windows_386.exe` をダウンロード
2. 任意のフォルダ（例: `C:\tools\terragrunt`）に配置し、`terragrunt.exe` にリネーム
3. 配置先フォルダを環境変数 PATH に追加

コマンドプロンプトから以下を実行して PATH を追加します。

```cmd
rem 1. 現在の PATH を確認
echo %PATH%

rem 2. PATH に追加（配置先フォルダを指定）
setx PATH "%PATH%;C:\tools\terragrunt"

rem 3. コマンドプロンプトを再起動後、PATH が追加されたことを確認
echo %PATH%
```

> **注意**: `setx` の反映にはコマンドプロンプトの再起動が必要です。

### macOS

```bash
brew install terragrunt
```

### Linux

```bash
# GitHub Releases からダウンロード（バージョンは適宜変更）
TERRAGRUNT_VERSION="v0.55.0"
curl -sL "https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_amd64" \
  -o /usr/local/bin/terragrunt
chmod +x /usr/local/bin/terragrunt
```

### 動作確認

```bash
terragrunt --version
# 出力例: terragrunt version v0.55.x
```

---

## 3. AWS CLI の設定

### インストール

各 OS のインストール方法は [AWS 公式ドキュメント](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) を参照してください。

### 動作確認

```bash
aws --version
# 出力例: aws-cli/2.x.x Python/3.x.x ...
```

### クレデンシャルの設定

LocalStack を使用する場合はダミーの値で OK です。

```bash
aws configure
# AWS Access Key ID: test
# AWS Secret Access Key: test
# Default region name: ap-northeast-1
# Default output format: json
```

> **注意**: 実際の AWS アカウントを使う場合は、IAM ユーザーの正しいクレデンシャルを設定してください。

---

## 4. Docker のインストール

### Windows

[Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/) をインストールしてください。

### macOS

```bash
brew install --cask docker
```

インストール後、Docker Desktop アプリケーションを起動してください。

### Linux (Ubuntu/Debian)

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# ログアウト・ログインして反映
```

### 動作確認

```bash
docker --version
# 出力例: Docker version 24.x.x, build xxxxxxx

docker run hello-world
# 正常にコンテナが起動すれば OK
```

---

## 5. LocalStack のセットアップ

LocalStack を使えば AWS アカウントがなくてもハンズオンを進められます。

### 起動方法（Docker コマンド）

```bash
docker run --rm -d -p 4566:4566 --name localstack localstack/localstack
```

### 起動方法（Docker Compose）

プロジェクトルートに以下の `docker-compose.yml` を作成しても利用できます。

```yaml
version: "3.8"
services:
  localstack:
    image: localstack/localstack
    ports:
      - "4566:4566"
    environment:
      - SERVICES=s3,ec2,iam,sts,dynamodb
      - DEFAULT_REGION=ap-northeast-1
```

```bash
docker compose up -d
```

### 動作確認

```bash
# LocalStack の状態を確認
curl http://localhost:4566/_localstack/health

# AWS CLI で LocalStack に接続してテスト
aws --endpoint-url=http://localhost:4566 s3 ls
# エラーなく空のリストが返れば OK
```

### LocalStack 使用時の Terraform 設定

各ステップの `main.tf` にはコメントアウトされた LocalStack 用の設定があります。
LocalStack を使用する場合は、プロバイダ設定のコメントを外してください。

```hcl
provider "aws" {
  region                      = "ap-northeast-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3       = "http://localhost:4566"
    sts      = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    ec2      = "http://localhost:4566"
    iam      = "http://localhost:4566"
  }
}
```

---

## セットアップ完了チェックリスト

以下のコマンドがすべて正常に実行できれば、環境構築は完了です。

```bash
terraform version        # Terraform >= 1.0
terragrunt --version     # Terragrunt >= 0.50
aws --version            # AWS CLI v2
docker --version         # Docker
curl http://localhost:4566/_localstack/health  # LocalStack が起動していること
```

すべて確認できたら、[Step 1: Hello Terraform](01-hello-terraform.md) に進みましょう。

---

[次のステップ: Step 1 - Hello Terraform ->](01-hello-terraform.md)
