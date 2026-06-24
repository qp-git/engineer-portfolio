# CodePipeline移行計画メモ

## 位置づけ

このドキュメントは、STT + ECSプロジェクトでCodePipeline移行を検討した時点の計画メモです。

実際のCI/CD基盤移行の結果は、続編である [`../stt-ecs-cicd-migration/`](../stt-ecs-cicd-migration/) に整理しています。

## 当初の目的

手動でのDockerビルドやECS更新ではなく、GitHubリポジトリの変更を起点として、Dockerイメージのビルド、ECRへのpush、ECS Service更新までを自動化することを目的としていました。

## 検討した構成

- Source: GitHub / CodeStar Connections
- Build: AWS CodeBuild
- Image Registry: Amazon ECR
- Deploy: AWS CodePipeline ECS Deploy Action
- Runtime: Amazon ECS
- Secret: AWS Secrets Manager

## 実施後の整理

実際の移行では、既存のGitHub Actions側Serviceをすぐに削除せず、新しいCodePipeline側Serviceを別Target Groupとして構築しました。

本番入口であるHTTPS:443は移行直前まで既存Actions側に維持し、一時的な検証用ListenerでPipeline側を確認したうえで、本番入口をPipeline側Target Groupへ切り替えました。

切替後は本番URL経由でSmoke Testを実行し、ALB、ECS、Secrets Manager、OpenAI APIまで含めたユーザー経路で動作確認しました。

## 関連

- 実施結果: [`../stt-ecs-cicd-migration/`](../stt-ecs-cicd-migration/)
- 設計判断: [`../stt-ecs-cicd-migration/design-decisions.md`](../stt-ecs-cicd-migration/design-decisions.md)
