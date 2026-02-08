# レビュー結果

Terraform/Terragrunt 初学者の視点でリポジトリ全体をレビューした結果です。

## 修正済みの問題

### 1. `.gitignore` が `terraform.tfvars.example` をブロックしていた
- `*.tfvars` パターンが `terraform.tfvars.example` にもマッチしていたため、サンプルファイルが Git に追跡されない状態だった
- `!*.tfvars.example` の否定パターンを追加して修正

### 2. 不要な `nul` ファイルの削除
- プロジェクトルートに Windows のリダイレクト先 `nul` が誤ってファイルとして作成されていた
- 削除済み

### 3. 不要な `.gitkeep` ファイルの削除
- `steps/`、`modules/`、`environments/` 配下の全ディレクトリに `.gitkeep` が残っていたが、各ディレクトリには既に実ファイルが存在するため不要
- 全 12 個の `.gitkeep` を削除

### 4. `ARCHITECTURE.md` のディレクトリツリーが不完全
- `docs/tutorials/` および `docs/cheatsheet.md` が記載されておらず、`environments/terragrunt.hcl` も欠落していた
- ディレクトリツリーを更新して修正

### 5. Step 1 の LocalStack 切り替え手順が不明確
- `main.tf` に「providers.tf の設定を参照してください」とだけ書かれていたが、具体的に何をすべきか分かりにくかった
- 「main.tf の provider ブロックを削除し、providers.tf のコメントを外す」と明記
- チュートリアル（01-hello-terraform.md）にも LocalStack 切り替えの具体的な手順を追記

### 6. Step 3 チュートリアルの Windows 非対応コマンド
- `python -m json.tool | head -50` は Windows では動作しない
- Windows（PowerShell）用のコマンドを併記

### 7. Step 1 チュートリアルの `rm -rf` コマンド
- `.terraform/` 削除手順が Linux/macOS 専用だった
- Windows（PowerShell）用の `Remove-Item` コマンドを併記

### 8. Step 4 に `terraform.tfvars.example` を追加
- Step 2 にはサンプルがあったが、変数が多い Step 4 にはなかった
- VPC、EC2、タグの設定例を含むサンプルファイルを追加

## 改善提案

### 1. LocalStack 対応の統一的な仕組みの検討
- 現状: 各ステップで provider ブロック内のコメントを手動で外す必要がある
- 提案: 環境変数 `TF_VAR_use_localstack` のような仕組みか、`-var-file` で LocalStack 用設定を切り替えられるようにする。または Step 0 の手順で LocalStack 用の `provider_override.tf` を一括配置するスクリプトを提供する
- 理由: 初学者がステップを進めるたびに手動でコメントを外すのは手間がかかり、戻し忘れのリスクもある

### 2. Step 5 の provider ブロック重複問題への事前注意
- 現状: Step 5 の `main.tf` に `terraform {}` ブロックはあるが `provider` ブロックがなく、`terragrunt.hcl` の `generate` で生成される設計
- 提案: チュートリアル（05-terragrunt-basics.md）内の「よくあるエラー」セクションに記載はあるが、ハンズオン手順の中でも「main.tf に provider ブロックがないことに注意。Terragrunt が自動生成します」と明示的に言及するとよい
- 理由: Step 1-4 では常に main.tf に provider があったため、初学者は provider が無いことに不安を感じる可能性がある

### 3. Step 6 のモジュールパスの解決に関する補足
- 現状: `main.tf` 内の `source = "../../modules/vpc"` は、Terragrunt の `.terragrunt-cache` を通して実行される際にパス解決が異なる場合がある
- 提案: チュートリアルに「Terragrunt はソースコードを `.terragrunt-cache` にコピーして実行するため、相対パスは `terraform { source }` で指定した起点から解決される」という補足を加える
- 理由: パス解決の仕組みを理解していないとデバッグが困難になる

### 4. `environments/` ディレクトリの位置づけの明確化
- 現状: `environments/` は「参考用」とされているが、Step 6 との違いが分かりにくい
- 提案: `environments/README.md` を作成し、Step 6 との違い（`remote_state` を使ったより実践的な構成であること）を説明する
- 理由: 初学者が Step 6 と `environments/` のどちらを見るべきか迷う可能性がある

### 5. AMI ID のデフォルト値に関する注意
- 現状: Step 4 と Step 6 で `ami-0d52744d6551d851e` がデフォルトだが、AMI ID はリージョンや時期により無効になる
- 提案: チュートリアルに「LocalStack では任意の AMI ID で動作するが、実際の AWS では最新の AMI ID を確認してください」という注意を追加する。または data source (`aws_ami`) で動的に取得する発展課題を提案する
- 理由: 実 AWS アカウントで試す学習者がエラーに遭遇する可能性が高い

### 6. 各ステップのクリーンアップ手順の強調
- 現状: 各チュートリアルの最後に `terraform destroy` の手順がある
- 提案: クリーンアップ手順を目立つ警告ボックス（`> **重要**`）で強調する
- 理由: 実 AWS で学習している場合、リソースを削除し忘れると課金が発生する

## 良い点

### 1. 段階的な難易度設計が優れている
- Step 1（S3 バケット 1 つ）から始まり、Step 6（マルチ環境管理）まで自然に難易度が上がる
- 各ステップで前のステップの知識を前提としており、学習パスが論理的

### 2. 日本語コメントが充実している
- 全ての `.tf` ファイルにヘッダーコメントで学習内容が明記されている
- 変数の `description` も日本語で統一されており、初学者に分かりやすい
- コード内のコメントがリソースの役割を的確に説明している

### 3. よくあるエラーと対処法のセクション
- 各チュートリアルに「よくあるエラーと対処法」があり、初学者がつまずきやすいポイントを事前にカバーしている
- エラーメッセージの実例と具体的な対処法が対になっており実用的

### 4. 発展課題の提供
- 各ステップに 3 つの発展課題があり、意欲のある学習者がさらに深く学べる
- 課題の難易度も適切に設定されている

### 5. チートシートの完成度
- `docs/cheatsheet.md` が HCL 構文、よく使う関数まで網羅しており、日常的なリファレンスとして使える

### 6. LocalStack 対応
- AWS アカウントなしで学習を始められる設計は、初学者のハードルを大幅に下げている
- 環境セットアップガイド（00-prerequisites.md）が Windows/macOS/Linux の 3 プラットフォームに対応

### 7. コードの一貫性
- 全ステップで `required_version`、`required_providers` が統一されている
- タグの付け方（`ManagedBy`、`Environment`）が一貫している
- モジュールの構造（main.tf / variables.tf / outputs.tf）が統一されている
