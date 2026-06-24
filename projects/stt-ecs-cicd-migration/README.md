# STT + ECS / Phase 2: CI/CD基盤移行

## 位置づけ

このプロジェクトは、`STT + ECS` シリーズのPhase 2です。

- [STT + ECS / Phase 1: ECSによる運用](../stt-ecs/)
  - ブラウザで録音した音声をFlaskバックエンドへ送り、OpenAI APIで文字起こしと要約を行うアプリを、Docker、ECR、ECS、ALBを使ってAWS上で動かす
- STT + ECS / Phase 2: CI/CD基盤移行
  - Phase 1で構築したAI音声文字起こしアプリを対象に、GitHub ActionsからAWS CodePipeline / CodeBuildへCI/CD基盤を段階移行する

Phase 2では、アプリ本体を新しく作り直したわけではありません。  
また、手動デプロイを初めて自動化したフェーズでもありません。

Phase 1時点で、GitHub ActionsによるECR pushとECS更新の自動デプロイ経路は構築済みでした。Phase 2では、その既存のGitHub Actions経路を前提に、AWS CodePipeline / CodeBuild中心のリリースフローへ段階移行した運用改善フェーズとして整理しています。

## 概要

既存のGitHub ActionsによるECSデプロイ経路を維持したまま、AWS CodePipeline / CodeBuildによる新しいCI/CD経路を構築しました。

この移行の主題は、自動化の有無ではなく、GitHub Actions側で実行していたECSデプロイを、AWS側のリリースフローとして管理できる形へ移すことです。

単純にデプロイツールを置き換えるのではなく、既存の本番経路を守りながら新しいデプロイ経路を並行構築し、検証、切替、Smoke Test、切り戻し可能性まで考慮した段階移行を行いました。

## 目的

このPhaseの目的は、Phase 1でAWS上に配置したAIアプリを、**安全に更新し続けられる状態へ進める**ことです。

Phase 1では、アプリをECS上で動かすための実行基盤を整理しました。Phase 2では、その実行基盤を前提に、デプロイ経路、切替手順、Smoke Test、切り戻し可能性を含めた更新基盤を整理しています。

AI APIを利用するWebアプリでは、アプリ本体だけでなく、APIキー管理、ECS Task Definition、ALBの入口設計、Target Group、Security Group、外部API連携まで含めて確認する必要があります。

そのため、CI/CD移行でも「Deployが成功したか」だけではなく、ユーザーがアクセスする本番URLからアプリと外部API連携まで正常に動くことを確認する方針にしました。

GitHub ActionsでもECS DeployやSmoke Testは実現可能でした。ただし、このSTTサービスは、ブラウザ録音のためのHTTPS入口、OpenAI APIキーのSecret注入、ALB / Target Group / ECS Taskの経路確認がサービス成立条件になります。

そのため、Build、ECR push、ECS Deploy、Deploy後の本番URL Smoke TestをCodePipeline / CodeBuildに寄せ、AWS側のリリースフローとして管理する構成にしました。

これにより、将来的に手動承認、失敗通知、追加のAPIテスト、Blue/Green Deployなどへ拡張しやすい構成として整理できます。

## 構成

- Source: GitHub / CodeStar Connections
- Build: AWS CodeBuild
- Image Registry: Amazon ECR
- Deploy: AWS CodePipeline ECS Deploy Action
- Runtime: Amazon ECS
- Traffic: Route 53 → ALB → Target Group → ECS Task
- Secret: AWS Secrets Manager
- Validation: CodeBuild Smoke Test

## 実施内容

- GitHub Actions側ServiceとCodePipeline側Serviceを別Target Groupで分離
- 本番入口のHTTPS:443を移行直前まで既存Actions側に維持
- HTTP:81の一時的な検証用ListenerでPipeline側を事前確認
- 切替時にALB Fixed responseでメンテナンス表示を実施
- HTTPS:443の向き先をPipeline側Target Groupへ切替
- 切替後にHTTPS本番URLでSmoke Testを実行
- 移行完了後に一時的な検証用Listenerを閉鎖

## 工夫した点

詳細な設計判断は [Design Decisions](design-decisions.md) に整理し、ここでは移行時の主なステップに絞って記載します。

### 1. 新旧デプロイ経路を分離した

既存のGitHub Actions経路をすぐに削除せず、CodePipeline側のECS ServiceとTarget Groupを別に構築しました。

これにより、既存の本番経路を残したまま、新しいデプロイ経路を検証できる状態にしました。

### 2. 本番入口を変えずにPipeline側を事前検証した

本番入口であるHTTPS:443は、移行直前まで既存のActions側Target Groupに維持しました。

Pipeline側は、HTTP:81の一時的な検証用Listenerで確認し、画面表示とSTT API応答を事前に確認しました。

### 3. 切替中はメンテナンス表示を返した

HTTPS:443の向き先を切り替えるタイミングでは、ALB Fixed responseで一時的なメンテナンス表示を返しました。

切替中の中途半端な状態をユーザーに見せないための対応です。

### 4. 切替後に本番URL経由でSmoke Testを実行した

HTTPS:443をPipeline側Target Groupへ切り替えた後、本番URL経由でSmoke Testを実行しました。

Deploy成功だけで完了とせず、ALB、ECS、Secret注入、OpenAI API連携を含むユーザー経路が成立していることを確認しました。

### 5. Smoke Test追加は切替後の運用品質改善として扱った

Smoke Testは、CI/CD基盤そのものの切替後に追加しました。

アプリ本体やユーザー向け経路を大きく変えるものではないため、切替後の運用品質改善として整理しています。

## 学び

- CI/CD移行では、ビルド・デプロイだけでなく、ALB、ECS、Secrets Manager、Security Groupまで含めて影響範囲を考える必要がある
- 新旧Target Groupを分離すると、本番経路を維持したまま新しい経路を検証しやすい
- Deploy成功だけではなく、本番URL経由でユーザー経路の動作確認を行うことが重要
- 学習・検証環境では、完全なBlue/Green構成に寄せすぎず、コストと構成複雑性のバランスを取る判断も必要

## 関連ドキュメント

- [STT + ECS / Phase 1: ECSによる運用](../stt-ecs/)
- [Architecture](architecture.md)
- [Design Decisions](design-decisions.md)
