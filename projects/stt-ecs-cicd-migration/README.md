# STT + ECS / Phase 2: CI/CD基盤移行

## 概要

このプロジェクトは、[STT + ECS](../stt-ecs/) の続編です。

Phase 1では、Flask製の音声文字起こしWebアプリをDocker化し、ECS、ALB、ECR、Secrets Managerを使ってAWS上で動かしました。

Phase 2では、その既存アプリを対象に、GitHub Actionsで行っていたECSデプロイ経路を、AWS CodePipeline / CodeBuild中心のCI/CD基盤へ段階移行しました。

単純にデプロイツールを置き換えるのではなく、既存の本番経路を維持したまま新しいデプロイ経路を並行構築し、ALB Listenerで事前検証したうえで本番入口を切り替えました。切替後は本番URL経由のSmoke Testを追加し、ALB、ECS、Secrets Manager、OpenAI APIまで含めたユーザー経路で動作確認しました。

## 目的

このPhaseの目的は、AIアプリを「作って動かす」段階から、**安全に更新し続ける**段階へ進めることです。

AI APIを利用するWebアプリでは、アプリ本体だけでなく、API Key管理、ECS Task Definition、ALBの入口設計、Target Group、Security Group、外部API連携まで含めて確認する必要があります。

そのため、CI/CD移行でも「Deployが成功したか」だけではなく、ユーザーがアクセスする本番URLからアプリと外部API連携まで正常に動くことを確認する方針にしました。

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

CI/CD基盤の移行は、アプリケーションの小規模修正よりも影響範囲が広くなります。

今回の移行では、ECS Service、Task Definition、Target Group、ALB Listener、Security Group、Secrets Manager、IAM Roleが関係するため、既存のデプロイ経路をすぐに削除せず、新旧の経路を並行させました。

本番入口であるHTTPS:443は移行直前まで既存経路に維持し、Pipeline側は一時的な検証用Listenerで確認しました。これにより、ユーザー影響を出さずに新しいCI/CD経路を検証できるようにしました。

切替時にはALB Fixed responseで一時的なメンテナンス表示を行い、ユーザーに中途半端な状態を見せないようにしました。その後、HTTPS:443の向き先をPipeline側Target Groupへ切り替えました。

## 学び

- CI/CD移行では、ビルド・デプロイだけでなく、ALB、ECS、Secrets Manager、Security Groupまで含めて影響範囲を考える必要がある
- 新旧Target Groupを分離すると、本番経路を維持したまま新しい経路を検証しやすい
- Deploy成功だけではなく、本番URL経由でユーザー経路の動作確認を行うことが重要
- 学習・検証環境では、完全なBlue/Green構成に寄せすぎず、コストと構成複雑性のバランスを取る判断も必要

## 関連ドキュメント

- [親プロジェクト: STT + ECS](../stt-ecs/)
- [Architecture](architecture.md)
- [Design Decisions](design-decisions.md)
