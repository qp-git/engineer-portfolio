# Interview Knowledge Bridge

## 概要

Custom GPTからGitHub上の許可済みMarkdownを参照するための中継APIを構築しました。

Private Repositoryに整理した面接準備メモや、Public Repositoryに公開しているポートフォリオ情報を、Custom GPTから安全に参照できるようにすることを目的としています。

Custom GPTにGitHubの権限を直接持たせず、API GatewayとLambdaを中継させ、許可済みの文書のみ取得できる構成にしました。

## 使用技術

- Custom GPT Actions
- OpenAPI schema
- Amazon API Gateway
- AWS Lambda
- GitHub REST API
- GitHub fine-grained PAT
- Bearer認証
- Markdown

## 構成

    Custom GPT
      ↓ Bearer Auth
    API Gateway
      ↓
    Lambda
      ├─ GitHub Private Repository
      └─ GitHub Public Repository

## 実装内容

- Custom GPT ActionsからAPI Gateway経由でLambdaを呼び出す構成を作成
- LambdaでBearer形式のAPIキーを検証
- LambdaからGitHub APIを利用してMarkdownを取得
- Public RepositoryとPrivate Repositoryの両方を参照対象に追加
- allowed-documents.jsonによるホワイトリスト制御を実装
- document_idベースで取得対象を制限し、任意パス指定を防止

## 工夫した点

LambdaはGitHub APIを呼び出す権限を持つため、権限上は参照対象のRepository内にあるファイルを読むことができます。

そのため、API利用者から任意のファイルパスを受け取らず、allowed-documents.jsonに定義されたdocument_idのみ取得できる設計にしました。

これにより、Custom GPTにRepository全体を開放するのではなく、必要なMarkdownだけを参照させる構成にしています。

## 学び

このプロジェクトで特に学びになったのは、AIエージェントから外部の情報を参照させる場合、単に中継APIを作るだけでは不十分だという点です。

LambdaはGitHub APIを呼び出すための権限を持つため、設計が甘いと、本来返すべきではない情報まで取得できてしまう可能性があります。

そのため、Lambdaを単なる中継役ではなく、認証・認可・取得対象制御を行う門番として設計しました。

具体的には、API利用者から任意のファイルパスを受け取らず、document_idのみを受け取り、allowed-documents.jsonで許可されたMarkdownだけを返す構成にしました。

この経験を通して、AIエージェントに外部情報を参照させる仕組みでは、利便性だけでなく、どの情報を返してよいかを制御する設計が重要だと学びました。

## リポジトリ

- https://github.com/qp-git/interview-knowledge-bridge
