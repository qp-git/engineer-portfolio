# Engineer Portfolio

AWS、Linux、ネットワーク、Webアプリ周辺の自己学習・自作プロジェクトをまとめたポートフォリオです。

公開可能な自作プロジェクトを中心に、構成、実装内容、学んだこと、運用上の工夫を整理しています。

## 扱った技術一覧

- [Skill Map](./SKILL_MAP.md)
  - 扱った技術と関連プロジェクトを一覧で整理しています。技術から先に確認したい方向けです。

## プロジェクト一覧

### 1. OdaiBox

Discord のボイスチャット中に使える、お題出題 Bot と Web 管理画面を作成したプロジェクトです。

Bot 側では Discord のスラッシュコマンドからお題を出題し、管理画面側では利用者がお題を追加・編集・ON/OFFできるようにしました。Lambda、API Gateway、DynamoDB、S3、CloudFront を使ったサーバーレス構成です。技術的な構成だけでなく、利用者が触る管理画面、操作権限、プライバシー説明など、コミュニティ向けツールとして実際に使ってもらうための設計も整理しました。

- [詳細](./projects/odaibox/)

### 2. STT + ECS

STT（Speech to Text、音声をテキスト化する処理）を使い、録音した音声を文字起こしして要約する Web アプリを作成したプロジェクトです。

ブラウザで録音した音声を Flask バックエンドへ送り、OpenAI API で文字起こしと要約を行う構成を検証しました。また、この自作アプリを Docker コンテナ化し、ECR、ECS、ALB を使って AWS 上で動かす流れも確認しました。

- [詳細](./projects/stt-ecs/)
  - [STT + ECS / Phase 2: CI/CD基盤移行](projects/stt-ecs-cicd-migration/) - Phase 1で構築したAI音声文字起こしアプリを対象に、CI/CD基盤を段階移行した運用改善フェーズ
  - [STT + ECS / Phase 2: CI/CD基盤移行](projects/stt-ecs-cicd-migration/) - STT + ECSの続編として、CI/CD基盤を段階移行した運用改善フェーズ

### 3. Alexa Skill

Alexa スキルを題材に、音声入力から AWS Lambda を呼び出し、外部 API の結果を音声で返す構成を検証したプロジェクトです。

Alexa Skill、Lambda、外部 API の役割を整理し、API Gateway を使わずに Alexa から Lambda を直接呼び出す流れを確認しました。音声 UI では、データをそのまま返すのではなく、聞き取りやすい読み上げ文に整形する必要があることも学びました。

- [詳細](./projects/alexa-skill/)

### 4. Interview Knowledge Bridge

Custom GPT から、GitHub 上の許可済み Markdown を参照できるようにする中継 API です。

公開用のポートフォリオには、初見でも読みやすい概要や設計判断を整理しています。一方で、Private リポジトリには、より細かいコード解説、制作背景、判断理由、作業中の補足メモを残しています。AI にプロジェクト全体の把握や整理を補助させるため、`document_id` や `project_id` によるホワイトリスト制御で、必要な Markdown だけを取得できる構成を検証しました。

- [詳細](./projects/interview-knowledge-bridge/)
- [実装リポジトリ](https://github.com/qp-git/interview-knowledge-bridge)


## 継続的な改善テーマ

既存プロジェクトは、実装済みの内容・設計判断・学びを中心に整理しています。

STT + ECSについては、元プロジェクトに加えて、続編としてCI/CD基盤移行を別プロジェクトに分けて整理しました。SQL / BigQueryを使ったデータ分析や、Lubuntu端末とクラウドを組み合わせた検証は、別テーマとして整理します。
