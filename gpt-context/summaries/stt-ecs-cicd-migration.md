# STT + ECS / Phase 2: CI/CD基盤移行

## 位置づけ

STT + ECSプロジェクトの続編として、既存のGitHub ActionsによるECSデプロイ経路を維持したまま、AWS CodePipeline / CodeBuildによる新しいCI/CD経路を構築した。

アプリ本体を新しく作ったものではなく、既存のSTT + ECSアプリを対象に、CI/CD基盤を段階移行した運用改善フェーズである。

## 概要

この移行の主題は、単純なCI/CDツールの置き換えではなく、既存の本番経路を壊さず、ユーザー影響と切り戻し可能性を考慮して段階移行した点にある。

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

## 学び

- CI/CD移行では、ECS、ALB、Secrets Manager、Security Groupまで含めて影響範囲を考える必要がある
- Deploy成功だけでなく、ユーザー経路でアプリと外部API連携まで確認することが重要
- 学習・検証環境では、完全性だけでなくコストと構成複雑性のバランスも設計判断に含める必要がある
