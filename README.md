# Engineer Portfolio

AWS、Linux、ネットワーク、Webアプリ周辺の自己学習・自作プロジェクトをまとめたポートフォリオです。  
公開可能な自作プロジェクトを中心に、構成、実装内容、学んだこと、運用上の工夫を整理しています。

## 扱った技術一覧

- [Skill Map](./SKILL_MAP.md) - 扱った技術と関連プロジェクトを一覧で整理しています。技術から先に確認したい方向けです。

## プロジェクト一覧

### 1. OdaiBox

Discord向けのお題Botです。AWS Lambda、API Gateway、DynamoDB、S3、CloudFrontを利用し、非エンジニアでもWeb管理画面からお題を追加・編集できる構成にしました。

- [詳細](./projects/odaibox/)

### 2. STT + ECS

STT（Speech to Text、音声をテキスト化する処理）を使い、録音した音声を文字起こしして要約するWebアプリを作成したプロジェクトです。ブラウザで録音した音声をFlaskバックエンドへ送り、OpenAI APIで文字起こしと要約を行う構成を検証しました。

また、この自作アプリをDockerコンテナ化し、ECR、ECS、ALBを使ってAWS上で動かす流れも確認しました。AI APIを使うアプリをECS上で扱う中で、コンテナ実行、ヘルスチェック、タスク定義、Secrets Manager、IAM権限、HTTPS化、ロールバックまでを整理しています。

- [詳細](./projects/stt-ecs/)

### 3. Alexa Skill

Alexaスキルを題材に、音声UIとAWS Lambda、外部API連携を学習したプロジェクトです。  
2地点の天気取得に加え、電車遅延情報APIの調査を通して、外部API制約や部分失敗時の設計も検証しました。

- [詳細](./projects/alexa-skill/)

### 4. Interview Knowledge Bridge

Custom GPT から、Private GitHub リポジトリ上の許可済み Markdown を参照できるようにする中継 API です。

公開ポートフォリオには人間向けに整理した概要や設計判断を置き、Private リポジトリにはより細かいコード解説、制作背景、判断理由、作業中の補足メモを残しています。AI にプロジェクト全体の把握や整理を補助させるため、`document_id` や `project_id` によるホワイトリスト制御で、必要な Markdown だけを取得できる構成を検証しました。

* [詳細](./projects/interview-knowledge-bridge/)
* [実装リポジトリ](https://github.com/qp-git/private-interview-knowledge-bridge)

## 今後追加予定

- Spotify API連携プロジェクト
