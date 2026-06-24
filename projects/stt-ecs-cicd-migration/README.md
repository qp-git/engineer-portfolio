# STT + ECS / Phase 2: CI/CD基盤移行

## 位置づけ

このプロジェクトは、`STT + ECS` の続編です。

アプリ本体を新しく作ったものではなく、既存のSTT + ECSアプリを対象に、CI/CD基盤をGitHub ActionsからAWS CodePipeline / CodeBuildへ段階移行した運用改善フェーズです。

大きなテーマは、AI音声文字起こしアプリをAWS ECS上で安全に運用することです。

- Phase 1: STT + ECS
  - AI音声文字起こしアプリ本体
  - Docker / ECS / ALB / Secrets Manager / HTTPS
- Phase 2: STT + ECS CI/CD基盤移行
  - GitHub ActionsからCodePipeline / CodeBuildへの移行
  - Target Group分離
  - ALB Listenerによる段階検証
  - ALB Fixed responseによる切替時のメンテナンス表示
  - 本番URL Smoke Test

## 概要

既存のGitHub ActionsによるECSデプロイ経路を維持したまま、AWS CodePipeline / CodeBuildによる新しいCI/CD経路を構築しました。

単純なCI/CDツールの置き換えではなく、ユーザー影響と切り戻し可能性を考慮し、ECS Service / Target Groupを分離した段階的な移行方式を採用しました。

## 背景

元のSTT + ECSプロジェクトでは、Flask製の音声文字起こしWebアプリをDocker化し、ECS、ALB、ECR、Secrets Managerなどを使ってAWS上で動かしました。

今回のPhase 2では、そのアプリのデプロイ基盤をGitHub ActionsからAWS CodePipeline / CodeBuildへ移行し、AWS上でSource、Build、DeployをつなぐCI/CD構成を検証しました。

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

CI/CD基盤の移行は、アプリケーションの小規模修正よりも影響範囲が広いため、既存経路をすぐに削除せず、新旧のデプロイ経路を並行させました。

本番入口のHTTPS:443は移行直前まで既存経路に維持し、別ListenerでPipeline側を事前検証することで、ユーザー影響を抑えながら新しいCI/CD経路を確認しました。

切替後は、Deploy成功だけで完了とせず、本番URL経由でSmoke Testを実行し、ALB、ECS、Secrets Manager、OpenAI APIまで含めたユーザー経路で動作確認しました。

## 学び

- CI/CD移行では、デプロイツールだけでなく、ECS Service、Target Group、ALB Listener、Security Group、Secrets Managerまで含めて影響範囲を考える必要がある
- 本番経路を守りながら新経路を検証するには、Target Group分離や一時的な検証用Listenerが有効
- Deploy成功だけではなく、ユーザー経路でアプリと外部API連携まで確認することが重要
- 学習・検証環境では、完全なBlue/Green構成に寄せすぎず、コストと構成複雑性のバランスを取る判断も必要

## 関連

- 親プロジェクト: `../stt-ecs/`
- アーキテクチャ: `architecture.md`
- 設計判断: `design-decisions.md`
