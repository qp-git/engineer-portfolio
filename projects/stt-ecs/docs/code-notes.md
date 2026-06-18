# STT + ECS Code Notes

## このドキュメントの目的

このドキュメントでは、STT + ECSプロジェクトの実装上の要点を、公開可能な範囲で整理する。

アプリケーション本体のコード、APIキー、AWS設定、音声アップロードファイルなどはPrivateリポジトリで管理しているため、本ポートフォリオでは実装の全量ではなく、設計意図、処理の流れ、インフラ上の注意点を中心にまとめる。

## 実装リポジトリの扱い

STT + ECSのアプリケーション本体はPrivateリポジトリで管理している。

理由は以下の通り。

* OpenAI APIキーを扱うため
* AWS ECS / ECR / Secrets Manager などの設定情報を含むため
* 音声アップロードファイルを扱うため
* Publicリポジトリに実データや環境固有情報を含めないため

Publicポートフォリオでは、構成概要、設計判断、再開手順、CI/CD比較、CodePipeline検証計画を公開する。

## アプリケーション概要

このプロジェクトでは、ブラウザから音声を録音し、Flaskアプリケーションへ送信する。
Flask側ではアップロードされた音声ファイルを受け取り、OpenAI APIを使って文字起こしを行い、結果をブラウザへ返す。

主な処理の流れは以下の通り。

1. ブラウザで音声を録音する
2. 音声ファイルをFlaskアプリケーションへ送信する
3. Flaskが音声ファイルを一時保存する
4. OpenAI APIへ音声ファイルを送信する
5. 文字起こし結果を受け取る
6. ブラウザへ結果を返す

## Flaskアプリケーションで意識した点

Flaskアプリケーションでは、音声アップロードを受け付けるAPIと、ブラウザ画面を返す処理を分けて実装した。

実装時に意識した点は以下の通り。

* ブラウザから音声ファイルを送信できること
* サーバー側で一時的に音声ファイルを保存できること
* OpenAI APIキーをコードに直書きしないこと
* APIキーが設定されていない場合は明確にエラーにすること
* APIキーの値や断片をログに出さないこと
* ECS上で動かすことを前提に、環境変数から設定を読み込むこと

特にAPIキーについては、値そのものをログに出さず、設定有無のみを確認する方針とした。

## Docker化で意識した点

このプロジェクトでは、FlaskアプリケーションをDockerコンテナとして実行できるようにした。

Docker化で意識した点は以下の通り。

* ローカル環境とECS環境で同じアプリケーションを動かせること
* `requirements.txt` でPython依存関係を管理すること
* コンテナ起動時にFlaskアプリケーションが起動すること
* アプリケーションが待ち受けるポートを明確にすること
* ECS Task Definitionから利用しやすい構成にすること

Docker化により、ローカルで動作確認したアプリケーションを、ECRへpushし、ECS Fargate上で実行する流れを検証できるようにした。

## ECSでの実行方針

ECSでは、DockerイメージをECRから取得し、Fargateタスクとしてアプリケーションを起動する構成とした。

ECS構成で意識した点は以下の通り。

* ECRにDockerイメージを保存する
* ECS Task Definitionでコンテナ定義を管理する
* ALB経由でアプリケーションへアクセスする
* CloudWatch Logsへアプリケーションログを出力する
* OpenAI APIキーはSecrets Managerから参照する
* ECS Task Execution RoleとTask Roleの役割を分けて理解する

## Secrets管理

OpenAI APIキーは、コードやDockerイメージに含めない方針とした。

想定する管理方針は以下の通り。

* OpenAI APIキーはSecrets Managerに保存する
* ECS Task DefinitionではSecrets Managerの値を環境変数として参照する
* `.env` ファイルはGit管理しない
* GitHub ActionsやCodeBuildにAPIキーを直接書かない
* アプリケーションログにAPIキー本体や断片を出力しない

この方針により、アプリケーションコード、コンテナイメージ、GitHubリポジトリのいずれにもAPIキーを含めない構成を目指す。

## CI/CDとの関係

Privateリポジトリでは、GitHub Actionsを使ってECRへのpushやECSデプロイを検証していた。

今後は、AWS CodePipeline / CodeBuildを使ったCI/CD構成も検証する予定である。

比較観点は以下の通り。

* GitHub ActionsでECRへpushする構成
* CodeBuildでDockerイメージをビルドする構成
* CodePipelineでECS Service更新まで行う構成
* GitHub Secrets / OIDC と IAM Role の違い
* Secrets Managerとの連携
* CodeBuild用IAM RoleとCodePipeline用IAM Roleの違い

## Publicリポジトリに載せないもの

以下はPublicリポジトリには載せない。

* OpenAI APIキー
* AWSアクセスキー
* AWSアカウントIDを含む実設定
* Secrets Managerの実ARN
* `.env`
* 音声アップロードファイル
* ローカルバックアップ
* `.venv`
* `__pycache__`
* 実環境のTask Definition全文

必要に応じて、公開用にはダミー値を使ったサンプルや、設計上の説明のみを掲載する。

## 学んだこと

このプロジェクトでは、単にOpenAI APIを呼び出すWebアプリを作るだけでなく、AI APIをAWS上で運用する場合の追加観点を学んだ。

主な学びは以下の通り。

* APIキーをコードに直書きしない設計
* Secrets ManagerとECS Task Definitionの関係
* Docker化したアプリケーションをECSで動かす流れ
* ECR、ECS、ALB、CloudWatch Logsの役割
* CI/CD導入時のIAM権限設計
* PublicポートフォリオとPrivate実装リポジトリの分離
* 実装コードを公開しない場合でも、設計意図や運用上の判断を説明する重要性

## 関連ドキュメント

* [README](../README.md)
* [Architecture](../architecture.md)
* [Design Decisions](../design-decisions.md)
* [Restart Guide](../restart-guide.md)
* [CI/CD Comparison](../cicd-comparison.md)
* [CodePipeline Plan](../codepipeline-plan.md)

