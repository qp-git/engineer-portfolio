# STT + ECS / Phase 2: CI/CD基盤移行

## 位置づけ

このプロジェクトは、`STT + ECS` シリーズのPhase 2です。

- [STT + ECS / Phase 1: ECSによる運用](../stt-ecs/)
  - Flask製の音声文字起こしWebアプリをDocker化し、ECS、ALB、ECR、Secrets Managerを使ってAWS上で動かす
- STT + ECS / Phase 2: CI/CD基盤移行
  - 既存のSTT + ECSアプリを対象に、GitHub ActionsからAWS CodePipeline / CodeBuildへCI/CD基盤を段階移行する

Phase 2では、アプリ本体を新しく作り直したわけではありません。  
Phase 1で構築したAI音声文字起こしアプリを、より安全に更新し続けるための運用改善フェーズとして整理しています。

## 概要

既存のGitHub ActionsによるECSデプロイ経路を維持したまま、AWS CodePipeline / CodeBuildによる新しいCI/CD経路を構築しました。

単純にデプロイツールを置き換えるのではなく、既存の本番経路を守りながら新しいデプロイ経路を並行構築し、検証、切替、Smoke Test、切り戻し可能性まで考慮した段階移行を行いました。

## 目的

このPhaseの目的は、AIアプリを「作って動かす」段階から、**安全に更新し続ける**段階へ進めることです。

AI APIを利用するWebアプリでは、アプリ本体だけでなく、API Key管理、ECS Task Definition、ALBの入口設計、Target Group、Security Group、外部API連携まで含めて確認する必要があります。

そのため、CI/CD移行でも「Deployが成功したか」だけではなく、ユーザーがアクセスする本番URLから、アプリと外部API連携まで正常に動くことを確認する方針にしました。

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

### 1. 新旧デプロイ経路を分離した

CI/CD基盤の移行は、アプリケーションの小規模修正よりも影響範囲が広くなります。

今回の移行では、ECS Service、Task Definition、Target Group、ALB Listener、Security Group、Secrets Manager、IAM Roleが関係するため、既存のGitHub Actions経路をすぐに削除せず、CodePipeline側の経路を別に構築しました。

Actions側ServiceとPipeline側Serviceを別Target Groupに分けることで、既存経路を残したまま新しい経路を検証できるようにしました。

### 2. 本番入口を変えずにPipeline側を事前検証した

本番入口であるHTTPS:443は、移行直前まで既存のActions側Target Groupに維持しました。

そのうえで、HTTP:81の一時的な検証用ListenerをPipeline側Target Groupへ向け、Pipeline側Serviceの画面表示とSTT API応答を確認しました。

これにより、ユーザー向けの本番入口に影響を出さずに、新しいCI/CD経路を事前確認できる状態を作りました。

### 3. 切替中はメンテナンス表示を返した

Pipeline側の事前確認後、本番入口であるHTTPS:443の向き先を切り替えるタイミングでは、ALB Fixed responseで一時的なメンテナンス表示を返しました。

これは、ユーザーが古い経路と新しい経路の中途半端な状態を見ることを避けるためです。

小規模な学習・検証環境であっても、切替中の状態をそのまま見せないようにした点は、運用を意識した設計判断として整理しています。

### 4. 切替後に本番URL経由でSmoke Testを実行した

HTTPS:443をPipeline側Target Groupへ切り替えた後、本番URL経由でSmoke Testを実行しました。

Smoke Testでは、ALB、Target Group、ECS Task、Flaskアプリ、Secrets ManagerからのAPI Key注入、OpenAI API連携まで含めて確認しました。APIキーの値を直接確認するのではなく、本番URL経由でSTT APIが成功することで、Secret注入と外部API連携を含むユーザー経路が成立していることを確認しました。

CodePipelineのDeploy成功だけで完了とせず、ユーザーが実際に通る経路でAPIが成功することを確認した点を重視しました。

### 5. Smoke Test追加は切替後の運用品質改善として扱った

Smoke Testは、CI/CD基盤そのものの切替後にローリングデプロイで追加しました。

CI/CD基盤の切替は複数のAWSリソースが関係するため慎重に段階移行しましたが、Smoke Testは運用品質を高めるための追加機能であり、アプリ本体やユーザー向け経路を大きく変えるものではありません。

そのため、切替後の改善としてローリングデプロイで反映可能と判断しました。

## 学び

- CI/CD移行では、ビルド・デプロイだけでなく、ALB、ECS、Secrets Manager、Security Groupまで含めて影響範囲を考える必要がある
- 新旧Target Groupを分離すると、本番経路を維持したまま新しい経路を検証しやすい
- Deploy成功だけではなく、本番URL経由でユーザー経路の動作確認を行うことが重要
- 学習・検証環境では、完全なBlue/Green構成に寄せすぎず、コストと構成複雑性のバランスを取る判断も必要

## 関連ドキュメント

- [STT + ECS / Phase 1: ECSによる運用](../stt-ecs/)
- [Architecture](architecture.md)
- [Design Decisions](design-decisions.md)
