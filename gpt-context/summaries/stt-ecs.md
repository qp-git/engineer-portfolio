# STT + ECS

## 概要

録音した音声を文字起こしして要約するWebアプリを作成し、そのアプリをコンテナ化してAWS ECS関連サービスで動かす検証プロジェクト。

ブラウザで録音した音声をFlaskバックエンドへ送り、OpenAI APIで文字起こしと要約を行う。その後、Docker、ECR、ECS、ALBなどを使い、AWS上で動かす構成を検証した。

## 使用技術

- Python
- Flask
- OpenAI API
- STT
- Docker
- Amazon ECR
- Amazon ECS
- AWS Fargate
- ECS on EC2
- Application Load Balancer
- Auto Scaling Group
- Secrets Manager

## 構成

    Browser
      ↓ 音声ファイル送信
    Flask App
      ↓
    OpenAI API
      ├─ 文字起こし
      └─ 要約
      ↓
    Flask App
      ↓
    Browserに結果表示

## 実装内容

- ブラウザで音声を録音して送信する画面を作成
- Flaskで音声ファイルを受け取り、OpenAI APIへ渡すバックエンドを作成
- STTで文字起こしし、そのテキストを要約モデルへ渡す処理を実装
- アプリをDockerコンテナ化
- ECRにコンテナイメージを保存
- ECS FargateとECS on EC2で実行方式を検証
- ALB、タスク定義、desired tasks、ASG、revision、ロールバックの考え方を確認

## 学び

- AIを使うWebアプリは、ブラウザ、バックエンド、外部APIが役割分担する構成になる
- STTとLLMは役割が異なり、音声を文字にしてから要約する流れになる
- ECSでは、タスクを動かすだけでなく、どこに配置するか、入口をどう作るか、どう戻すかまで考える必要がある
- FargateはECSの全体像をつかみやすく、ECS on EC2ではリソースや配置条件の理解が重要になる
- ブラウザで音声を扱う場合はHTTPSやALBの設計も重要

## 特に強調したい学び

このプロジェクトで特に重要なのは、**AI APIを使うWebアプリをECSで動かすことで、単なるコンテナ実行だけでなく、AI APIを運用環境に載せるための周辺設計を学べた**点です。

OpenAI APIを利用するため、APIキーをコードやDockerイメージに含めず、環境変数やSecrets Managerなどを通してECSタスクへ渡す必要があります。また、ECSタスクがシークレットを参照するためのIAM権限も設計対象になります。

さらに、ブラウザで音声を録音して送信する構成では、マイク入力や音声データを扱うため、HTTPSも実用上重要になります。ALBは単なる負荷分散だけでなく、安全な入口を用意する役割も持ちます。

このため、STT + ECS プロジェクトは、AI API、APIキー管理、Secrets Manager、IAM権限、HTTPS、ALB、ECSタスク定義をまとめて考える学習になりました。

