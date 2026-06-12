# Engineer Portfolio

AWS、Linux、ネットワーク、Webアプリ周辺の自己学習・自作プロジェクトをまとめたポートフォリオです。  
公開可能な自作プロジェクトを中心に、構成、実装内容、学んだこと、運用上の工夫を整理しています。

## 扱った技術一覧

- [Skill Map](./SKILL_MAP.md) - 扱った技術と関連プロジェクトを一覧で整理しています。「何ができるのか」を先に確認したい方向けです。

## プロジェクト一覧

### 1. OdaiBox

Discord向けのお題Botです。AWS Lambda、API Gateway、DynamoDB、S3、CloudFrontを利用し、非エンジニアでもWeb管理画面からお題を追加・編集できる構成にしました。

- [詳細](./projects/odaibox/)

### 2. STT + ECS

### 2. STT + ECS

STT（Speech to Text、音声をテキスト化する処理）を使い、録音した音声を文字起こしして要約するWebアプリを作成したプロジェクトです。ブラウザで録音した音声をFlaskバックエンドへ送り、OpenAI APIで文字起こしと要約を行う構成を検証しました。

また、この自作アプリをDockerコンテナ化し、ECR、ECS、ALBを使ってAWS上で動かす流れも確認しました。AI APIを使うアプリをECS上で扱う中で、コンテナ実行、ヘルスチェック、タスク定義、Secrets Manager、IAM権限、HTTPS化、ロールバックまでを整理しています。

- [詳細](./projects/stt-ecs/)

### 3. Alexa Skill

Alexaスキルを題材に、音声UIとAWS Lambda、外部API連携を学習したプロジェクトです。  
2地点の天気取得に加え、電車遅延情報APIの調査を通して、外部API制約や部分失敗時の設計も検証しました。

- [詳細](./projects/alexa-skill/)

### 4. Interview Knowledge Bridge

GitHubに整理した自主学習の成果物を、Custom GPTから参照できるようにする中継API構築プロジェクトです。  
API Gateway、Lambda、GitHub API、OpenAPI schemaを使い、許可済みMarkdownだけを取得できるようにしました。

- [詳細](./projects/interview-knowledge-bridge/)

## AI / Custom GPT向け要約

AIやCustom GPTから参照しやすいように、各プロジェクトの要約を `gpt-context/summaries/` に整理しています。

- [ポートフォリオ概要](./gpt-context/summaries/portfolio-index.md)
- [OdaiBox](./gpt-context/summaries/odaibox.md)
- [STT + ECS](./gpt-context/summaries/stt-ecs.md)
- [Alexa Skill](./gpt-context/summaries/alexa-skill.md)
- [Interview Knowledge Bridge](./gpt-context/summaries/interview-knowledge-bridge.md)

## 今後追加予定

- Spotify API連携プロジェクト
