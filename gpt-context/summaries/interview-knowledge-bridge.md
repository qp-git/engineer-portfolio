# Interview Knowledge Bridge

## 概要

Interview Knowledge Bridge は、Custom GPTからGitHub上の許可済みMarkdownを参照するための中継APIです。

自主学習で作成した成果物やプロジェクト記録をGitHub上のMarkdownとして整理し、その内容をCustom GPTから参照できるようにすることを目的として構築しました。

Custom GPTにGitHubの権限を直接持たせるのではなく、API GatewayとLambdaを中継させ、許可されたMarkdownだけを取得できる構成にしています。

## 作成背景

自主学習で作成したプロジェクトが増えると、README、構成メモ、学習内容、実装時の判断理由などの情報が複数のMarkdownに分かれていきます。

それらの情報をAIに参照させることができれば、成果物の整理、説明文の作成、学習内容の振り返りを効率化できます。

一方で、Repository内のすべてのファイルをAIに自由に参照させるのではなく、参照してよいMarkdownだけを明示的に制御する必要があると考えました。

そこで、Custom GPTとGitHubの間にAPI GatewayとLambdaを置き、許可されたMarkdownだけを取得できる仕組みを作りました。

## 構成

    Custom GPT
      ↓ Bearer Auth
    API Gateway
      ↓
    Lambda
      ↓
    GitHub Repository

Custom GPTは、API GatewayのURLにHTTPリクエストを送ります。

API GatewayがLambdaを呼び出し、LambdaがGitHub APIを使ってMarkdownを取得します。

取得したMarkdownは、LambdaからCustom GPTへ返します。

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
- LambdaからGitHub APIを利用してMarkdownを取得
- allowed-documents.jsonによるホワイトリスト制御を実装
- document_idベースで取得対象を制限し、任意パス指定を防止
- /health、/documents、/documents/{document_id} のエンドポイントを用意

## 設計で工夫した点

このAPIでは、Custom GPTから直接GitHubのファイルパスを指定させないようにしました。

代わりに、Custom GPTは document_id という文書IDを指定します。

Lambdaは allowed-documents.json を確認し、許可された document_id の場合だけ、対応するMarkdownファイルをGitHubから取得してCustom GPTへ返します。

このようにすることで、Custom GPTにRepository全体を開放するのではなく、必要なMarkdownだけを参照できる構成にしました。

## 学び

このプロジェクトで特に学びになったのは、AIに外部情報を参照させる仕組みでは、単に中継APIを作るだけでは不十分だという点です。

LambdaはGitHub APIを呼び出すための権限を持つため、設計が甘いと、本来返すべきではない情報まで取得・返却できてしまう可能性があります。

そのため、Lambdaを単なる中継役ではなく、認証・認可・取得対象制御を行う門番として設計しました。

この経験を通して、AIエージェントに外部情報を参照させる仕組みでは、利便性だけでなく、どの情報を返してよいかを制御する設計が重要だと学びました。

## 公開用リンク

- Portfolio page: ./projects/interview-knowledge-bridge.md
- Repository: https://github.com/qp-git/interview-knowledge-bridge
