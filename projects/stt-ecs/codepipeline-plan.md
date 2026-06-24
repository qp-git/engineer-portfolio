# Note

この内容は、STT + ECSプロジェクト時点でのCodePipeline移行計画メモです。

CI/CD移行の実施結果は、続編プロジェクト `../stt-ecs-cicd-migration/` に整理しています。

---

# STT + ECS CodePipeline Plan

## 目的

STT + ECSプロジェクトについて、AWS CodePipeline / CodeBuild / ECR / ECSを使ったCI/CD構成を検証する。

このドキュメントでは、実装前の構成案、処理の流れ、必要なIAM権限、Secrets管理、料金面の注意点を整理する。

## 背景

STT + ECSプロジェクトでは、FlaskアプリをDocker化し、ECR、ECS Fargate、ALBを使ってAWS上で動作させる構成を検証した。

この計画を踏まえて、GitHubリポジトリの変更を起点に、Dockerイメージのビルド、ECRへのpush、ECSサービス更新までをAWS CodePipeline / CodeBuildで自動化する構成を検証した。実施結果は続編プロジェクト `../stt-ecs-cicd-migration/` に整理している。

先に作成した `cicd-comparison.md` では、GitHub ActionsとAWS CodePipeline / CodeBuildの違いを整理した。このドキュメントでは、CodePipelineを使う場合の具体的な構成案を整理する。

## 想定構成

CodePipelineを中心に、以下のAWSサービスを利用する。

* CodePipeline
* CodeBuild
* ECR
* ECS Fargate
* ALB
* IAM
* Secrets Manager
* CloudWatch Logs

想定する流れは以下の通り。

1. GitHubリポジトリの変更をCodePipelineが検知する
2. CodeBuildがDockerイメージをビルドする
3. CodeBuildがECRへDockerイメージをpushする
4. ECSのTask Definitionを更新する
5. ECS Serviceを更新する
6. 新しいコンテナがECS Fargate上で起動する
7. ALB経由でアプリケーションへアクセスできることを確認する

## パイプライン構成案

### Source Stage

GitHubリポジトリをソースとして利用する。

対象リポジトリ:

* `qp-git/engineer-portfolio`

対象ディレクトリ:

* `projects/stt-ecs`

想定ブランチ:

* `main`

確認事項:

* GitHub連携方法
* CodePipelineが変更を検知する範囲
* STT + ECS以外のドキュメント変更でもパイプラインが動くか
* 必要に応じてディレクトリ単位で実行条件を制御できるか

### Build Stage

CodeBuildでDockerイメージをビルドし、ECRへpushする。

想定する処理:

1. ECRへログインする
2. Dockerイメージをビルドする
3. イメージにタグを付ける
4. ECRへpushする
5. ECSデプロイ用の成果物を出力する

想定する追加ファイル:

* `projects/stt-ecs/buildspec.yml`

### Deploy Stage

ECS Serviceを更新し、新しいTask Definitionでコンテナを起動する。

確認事項:

* Task Definitionの更新方法
* ECS Serviceの更新方法
* デプロイ後のヘルスチェック
* ALB Target Groupの状態確認
* CloudWatch Logsでの起動ログ確認

## buildspec.yml案

実装時には、以下のような流れを `buildspec.yml` に整理する。

```yaml
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
      - REPOSITORY_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$ECR_REPOSITORY_NAME
      - IMAGE_TAG=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)

  build:
    commands:
      - echo Building the Docker image...
      - docker build -t $ECR_REPOSITORY_NAME:$IMAGE_TAG .
      - docker tag $ECR_REPOSITORY_NAME:$IMAGE_TAG $REPOSITORY_URI:$IMAGE_TAG

  post_build:
    commands:
      - echo Pushing the Docker image...
      - docker push $REPOSITORY_URI:$IMAGE_TAG
      - echo Writing image definitions file...
      - printf '[{"name":"%s","imageUri":"%s"}]' "$ECS_CONTAINER_NAME" "$REPOSITORY_URI:$IMAGE_TAG" > imagedefinitions.json

artifacts:
  files:
    - imagedefinitions.json
```

この時点では実装前の案であり、実際のディレクトリ構成やECSコンテナ名に合わせて修正する。

## IAM権限の整理

CodePipeline / CodeBuildを使う場合、どのサービスがどのAWSリソースを操作するのかを明確にする。

### CodePipeline用IAM Role

CodePipelineには、主に以下の操作権限が必要になる。

* Source Stageの実行
* CodeBuildプロジェクトの開始
* Deploy Stageの実行
* Artifact Storeへのアクセス

確認する権限:

* `codebuild:StartBuild`
* `codebuild:BatchGetBuilds`
* `s3:GetObject`
* `s3:PutObject`
* `s3:GetBucketVersioning`
* `ecs:DescribeServices`
* `ecs:DescribeTaskDefinition`
* `ecs:RegisterTaskDefinition`
* `ecs:UpdateService`
* `iam:PassRole`

### CodeBuild用IAM Role

CodeBuildには、Dockerイメージのビルド、ECRへのpush、ログ出力の権限が必要になる。

確認する権限:

* `ecr:GetAuthorizationToken`
* `ecr:BatchCheckLayerAvailability`
* `ecr:InitiateLayerUpload`
* `ecr:UploadLayerPart`
* `ecr:CompleteLayerUpload`
* `ecr:PutImage`
* `logs:CreateLogGroup`
* `logs:CreateLogStream`
* `logs:PutLogEvents`
* `s3:GetObject`
* `s3:PutObject`

### ECS Task Role / Task Execution Role

ECSでは、Task Execution RoleとTask Roleの役割を分けて整理する。

Task Execution Role:

* ECRからイメージをpullする
* CloudWatch Logsへログを出力する
* Secrets Managerからコンテナ起動時のSecretを取得する

Task Role:

* アプリケーションがAWS APIを呼び出す場合に利用する
* 今回のSTT + ECSでは、必要最小限にする

## Secrets管理

STT + ECSではOpenAI APIキーを扱うため、SecretをGitHubやDockerイメージに含めない。

想定する管理方針:

* APIキーはSecrets Managerに保存する
* ECS Task Definitionの環境変数としてSecretを参照する
* GitHubリポジトリには `.env` やAPIキーをcommitしない
* CodeBuildの環境変数にもSecretを直接書かない
* 必要に応じてParameter Storeとの違いも確認する

## GitHub Actionsとの比較観点

CodePipeline検証後に、以下の観点でGitHub Actionsとの違いを整理する。

| 観点        | GitHub Actions        | CodePipeline / CodeBuild   |
| --------- | --------------------- | -------------------------- |
| 管理場所      | GitHub側               | AWS側                       |
| 実行定義      | Workflow YAML         | Pipeline設定 + buildspec.yml |
| AWS認証     | OIDCまたはGitHub Secrets | IAM Role中心                 |
| Dockerビルド | GitHub Runner         | CodeBuild                  |
| ECR連携     | AWS認証後にpush           | AWS内の権限でpush               |
| ECS更新     | WorkflowからAWS CLI実行   | Deploy Stageで実行            |
| 学習効果      | GitHub中心のCI/CDを学べる    | AWSサービス間連携とIAMを学びやすい       |

## 検証ステップ

実装時は、以下の順番で進める。

1. `restart-guide.md` を確認し、STT + ECSのAWSリソースを再作成する
2. ECRリポジトリを確認する
3. ECS Cluster / Service / Task Definitionを確認する
4. CodeBuildプロジェクトを作成する
5. `buildspec.yml` を追加する
6. CodeBuild単体でDockerビルドとECR pushを確認する
7. CodePipelineを作成する
8. Source StageとBuild Stageを接続する
9. Deploy StageでECS Service更新を確認する
10. ALB経由でアプリケーション動作を確認する
11. CloudWatch Logsで起動ログを確認する
12. 検証後、料金が発生するリソースを削除する

## コスト面の注意点

検証後は、料金が発生しやすいリソースを確認して削除する。

特に注意するリソース:

* ALB
* NAT Gateway
* ECS Fargate Task
* CodeBuildの実行時間
* CloudWatch Logs
* Secrets Manager
* ECRイメージ容量

残す可能性があるリソース:

* IAM Role
* Security Group
* ECRリポジトリ
* ドキュメント
* buildspec.yml

ただし、残す場合も不要な権限や古いイメージが残らないように確認する。

## 完了条件

この検証は、以下を満たしたら完了とする。

* CodePipeline / CodeBuild / ECR / ECSの連携構成を説明できる
* CodeBuildからECRへDockerイメージをpushできる
* ECS Serviceを更新する流れを確認できる
* CodePipeline用IAM RoleとCodeBuild用IAM Roleの違いを説明できる
* Secrets Managerを利用したSecret管理方針を整理できる
* GitHub Actionsとの違いを実体験ベースで説明できる
* 検証後に料金が発生するリソースを削除できる

## 関連ドキュメント

* `restart-guide.md`
* `cicd-comparison.md`

