# Interview Knowledge Bridge

## 概要

Interview Knowledge Bridge は、Custom GPTからGitHub上の許可済みMarkdownを参照するための中継APIです。

公開ポートフォリオ情報と、非公開の面接準備メモをCustom GPTから参照できるようにしつつ、参照できる文書をホワイトリストで制限することを目的としています。

## 構成

    Custom GPT
      ↓ Bearer Auth
    API Gateway
      ↓
    Lambda
      ├─ GitHub Public Repository
      └─ GitHub Private Repository

## 使用技術

- Custom GPT Actions
- OpenAPI schema
- Amazon API Gateway
- AWS Lambda
- GitHub REST API
- GitHub fine-grained PAT
- Bearer認証
- Markdown

## 実装内容

- Custom GPT ActionsからAPI Gateway経由でLambdaを呼び出す構成を作成
- LambdaでBearer形式のAPIキーを検証
- LambdaからGitHub APIを呼び出してMarkdownを取得
- Public RepositoryとPrivate Repositoryの両方を参照対象に追加
- allowed-documents.jsonで許可済み文書のみ返すように制御
- document_idベースで文書を取得し、任意パス指定を防止

## 工夫した点

Custom GPTにGitHubの権限を直接持たせず、API GatewayとLambdaを中継させる構成にしました。

LambdaはGitHub PATを持つため、Private Repository内のファイルを読む権限があります。そのため、API利用者から任意のファイルパスを受け取らず、allowed-documents.jsonに定義されたdocument_idのみ取得できるようにしました。

これにより、Custom GPTにPrivate Repository全体を開放せず、必要なMarkdownだけを参照できる構成にしています。

## 学び

API Gatewayを外部公開の入口として使い、LambdaをHTTP APIとして呼び出す構成を学びました。

また、APIキーによる認証だけでなく、認証後にどの文書を返してよいかを制御する認可設計の重要性を学びました。

## 公開用リンク

- Portfolio page: ./projects/interview-knowledge-bridge.md
- Repository: https://github.com/qp-git/interview-knowledge-bridge
