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
- LambdaからGitHub APIを利用してPrivate Repositoryを参照
- Public Repository側のポートフォリオ情報も参照対象に追加
- allowed-documents.jsonによるホワイトリスト制御を実装
- document_idベースで取得対象を制限し、任意パス指定を防止

## 工夫した点

LambdaはGitHub PATを持つため、権限上はPrivate Repository内のファイルを読むことができます。

そのため、API利用者から任意のファイルパスを受け取らず、allowed-documents.jsonに定義されたdocument_idのみ取得できる設計にしました。

これにより、Custom GPTにPrivate Repository全体を開放せず、必要なMarkdownだけを参照させる構成にしています。

## 学び

API Gatewayは、外部からLambdaをHTTPで呼び出す入口として利用できることを学びました。

また、Lambdaに強い権限を持たせる場合は、認証だけでなく、外部へ返す情報をアプリケーション側で制御する認可設計が重要だと分かりました。

## リポジトリ

- https://github.com/qp-git/interview-knowledge-bridge
