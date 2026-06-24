# STT + ECS CI/CD Comparison

## 目的

STT + ECSプロジェクトのCI/CDについて、GitHub Actionsを使う構成と、AWS CodePipeline / CodeBuildを使う構成を比較する。

単にデプロイを自動化するだけでなく、GitHub側で管理するCI/CDと、AWS側で管理するCI/CDの違いを整理し、IAM権限、Secrets管理、ECR/ECS連携の観点から理解を深める。

## 背景

STT + ECSプロジェクトでは、FlaskアプリをDocker化し、ECR、ECS Fargate、ALBを使ってAWS上で動作させる構成を検証した。

この比較を踏まえて、続編プロジェクトとしてAWS CodePipeline / CodeBuildを使ったCI/CD基盤移行を実施した。実施結果は `../stt-ecs-cicd-migration/` に整理している。

CI/CDの実装方法として、GitHub Actionsを使う方法と、AWS CodePipeline / CodeBuildを使う方法が考えられるため、それぞれの特徴を比較する。

## GitHub Actionsを使う構成

GitHub Actionsでは、GitHubリポジトリ内のWorkflowからビルドやデプロイを実行する。

想定する流れは以下の通り。

1. mainブランチへのpushをトリガーにWorkflowを実行する
2. Dockerイメージをビルドする
3. ECRへログインする
4. DockerイメージをECRへpushする
5. ECSのTask Definitionを更新する
6. ECS Serviceを更新する

## CodePipeline / CodeBuildを使う構成

CodePipelineでは、AWS側にパイプラインを作成し、GitHubリポジトリの変更をトリガーとしてCodeBuildやECS Deployを実行する。

想定する流れは以下の通り。

1. GitHubリポジトリの変更をCodePipelineが検知する
2. CodeBuildでDockerイメージをビルドする
3. CodeBuildからECRへイメージをpushする
4. CodePipelineがECS Serviceを更新する
5. ECSが新しいTask Definitionでコンテナを起動する

## 比較観点

| 観点 | GitHub Actions | CodePipeline / CodeBuild |
|---|---|---|
| 管理場所 | GitHub側 | AWS側 |
| 設定ファイル | `.github/workflows/*.yml` | CodePipeline / CodeBuild / buildspec.yml |
| AWS連携 | OIDCまたはアクセスキーでAWSへ接続 | AWSサービス間連携が中心 |
| 権限管理 | GitHub Actions用IAM Roleが重要 | CodePipeline / CodeBuild用IAM Roleが重要 |
| Secrets管理 | GitHub SecretsまたはOIDC | Secrets Manager / Parameter Store / IAM Role |
| 学習効果 | GitHub中心のCI/CDを学べる | AWSサービス間連携とIAMを学びやすい |
| ポートフォリオ観点 | 一般的で見せやすい | AWSインフラ寄りの理解を示しやすい |

## IAM権限の整理

CodePipeline / CodeBuildを使う場合、主に以下の権限が必要になる。

- CodePipelineがCodeBuildを実行する権限
- CodeBuildがECRへイメージをpushする権限
- CodeBuildまたはCodePipelineがECS Serviceを更新する権限
- ECS TaskがSecrets ManagerからAPIキーを取得する権限
- CloudWatch Logsへログを出力する権限

どのサービスが、どの権限で、どのAWSリソースを操作するのかを明確にする。

## Secrets管理の比較

GitHub Actionsでは、GitHub SecretsやOIDCを使ってAWS認証を行う。

CodePipeline / CodeBuildでは、AWS側のIAM Role、Secrets Manager、Parameter Storeを使うことで、AWS内で認証情報を管理しやすい。

STT + ECSプロジェクトではOpenAI APIキーを扱うため、Secrets Managerに保存し、ECS Task Roleから参照する構成を基本とする。

## Codexの利用範囲

Codexは、CI/CDそのものを代替するものではなく、実装やドキュメント作成を補助するものとして利用する。

想定する利用範囲は以下の通り。

- Issueの分解
- buildspec.ymlやWorkflow案の作成
- DockerfileやREADMEの改善
- PR本文の作成
- 差分レビューの補助

最終的なmerge判断やAWS権限の確認は人間が行う。

## CI/CD移行の実施結果

1. STT + ECSの再開手順を確認する
2. CodePipeline / CodeBuildの構成案を作成する
3. buildspec.ymlを作成する
4. ECRへのpushを検証する
5. ECS Service更新を検証する
6. GitHub Actions構成との違いをREADMEに反映する
