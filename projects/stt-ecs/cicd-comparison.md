# CI/CD方式比較メモ

## 位置づけ

このドキュメントは、STT + ECSプロジェクトにおけるCI/CD方式の比較メモです。

STT + ECS本体では、AI音声文字起こしアプリをECS上で動かす構成を整理しました。その後の運用改善フェーズとして、GitHub ActionsからAWS CodePipeline / CodeBuildへのCI/CD基盤移行を行いました。

実施結果は、続編である [`../stt-ecs-cicd-migration/`](../stt-ecs-cicd-migration/) に整理しています。

## 比較した方式

| 方式 | 特徴 | 評価 |
|---|---|---|
| 手動デプロイ | Docker build、ECR push、ECS更新を手動で行う | 学習初期には理解しやすいが、再現性と運用性に課題がある |
| GitHub Actions | GitHub上の変更を起点にECR pushやECS更新を自動化できる | GitHub中心の構成として扱いやすい |
| AWS CodePipeline / CodeBuild | Source、Build、DeployをAWS側のCI/CDサービスでつなげる | ECS、ECR、IAM、CodeBuild、CodePipelineの関係をAWS内で整理しやすい |

## 採用した方向性

最終的に、既存のGitHub Actions経路をすぐに削除せず、AWS CodePipeline / CodeBuildによる新しいデプロイ経路を並行して構築しました。

移行では、Actions側ServiceとPipeline側Serviceを別Target Groupに分離し、本番入口を維持したまま一時的な検証用ListenerでPipeline側を確認しました。

その後、ALB Fixed responseで一時的なメンテナンス表示を行い、HTTPS:443の向き先をPipeline側Target Groupへ切り替えました。

## 学び

CI/CD方式の比較では、ツール単体の使いやすさだけでなく、ECS Service、Target Group、ALB Listener、Security Group、Secrets Manager、IAM Roleまで含めた運用上の影響範囲を考える必要があると分かりました。

今回の移行は、完全なBlue/Green構成ではありませんが、学習・検証環境としてコストと構成複雑性を抑えながら、ユーザー影響と切り戻し可能性を考慮した段階移行として整理しています。
