# Interview Knowledge Bridge 構成メモ

Interview Knowledge Bridge は、Custom GPT から GitHub 上の許可済み Markdown を取得するための中継 API です。

Custom GPT に GitHub Repository への自由なアクセス権限を持たせるのではなく、API Gateway と Lambda を間に置き、取得できる文書を `allowed-documents.json` で制御します。

## 全体構成

    Custom GPT
      ↓ Custom GPT Actions
      ↓ Bearer Token
    API Gateway
      ↓
    Lambda
      ↓
    GitHub API
      ↓
    GitHub Repository
      ↓
    許可済み Markdown

Custom GPT は、OpenAPI schema に定義されたエンドポイントだけを呼び出します。

API Gateway がリクエストを受け、Lambda が `document_id` をもとに許可済み Markdown を探し、GitHub API から本文を取得して返します。

## この構成で実現したいこと

この構成で実現したいことは、AI が参照できる情報を明示的に制御することです。

通常、GitHub Repository には README、詳細メモ、設定ファイル、作業途中のファイルなど、さまざまな情報が混在します。

そのすべてを AI に自由に参照させるのではなく、以下のように制御します。

- AIが取得してよい Markdown だけを一覧化する
- ファイルパスを直接指定させない
- `document_id` で取得対象を管理する
- Public / Private の情報を分ける
- Custom GPT には GitHub Token を直接持たせない
- APIキーで中継APIへのアクセスを制限する

## 使用サービス・構成要素

| 要素 | 役割 |
|---|---|
| Custom GPT | 面接対策や成果物整理のために Markdown を参照するAI |
| Custom GPT Actions | OpenAPI schema に基づいて外部APIを呼び出す仕組み |
| OpenAPI schema | Custom GPT が呼び出せるエンドポイントとパラメータを定義する |
| API Gateway | Custom GPT からのHTTPリクエストを受ける入口 |
| Lambda | document_id の検証、GitHub API呼び出し、Markdown返却を行う |
| GitHub API | Repository上のMarkdown本文を取得する |
| allowed-documents.json | 取得を許可するMarkdownの一覧 |
| Bearer Token | 中継APIの呼び出しを制限するための認証情報 |

## 取得対象の管理

取得可能な Markdown は、`allowed-documents.json` で管理します。

Custom GPT が任意のファイルパスを指定するのではなく、事前に許可した `document_id` を指定して取得します。

    document_id
      ↓
    allowed-documents.json で照合
      ↓
    許可されたRepository / pathを取得
      ↓
    GitHub APIでMarkdown本文を取得

この方式により、AI が想定外のファイルを読みに行くことを防ぎやすくなります。

## document_id 方式にした理由

ファイルパスをそのままAPIのパラメータにすると、呼び出し側が任意のパスを指定できてしまいます。

そのため、このプロジェクトでは `document_id` を使っています。

たとえば、Custom GPT は次のようなIDを指定します。

- `public-portfolio-index`
- `public-odaibox`
- `public-stt-ecs`
- `public-alexa-skill`
- `public-interview-knowledge-bridge`

Lambda 側では、そのIDが `allowed-documents.json` に存在するかを確認し、対応する Markdown だけを取得します。

この設計により、取得対象をコードや設定ファイル側で管理できます。

## Public / Private の分離

このプロジェクトでは、公開用のポートフォリオ情報と、面接深掘り用の非公開メモを分けて扱う前提にしています。

Public 側には、GitHub上で誰に見せてもよい内容を整理します。

Private 側には、面接で深掘りされたときに参照したい、より具体的な作業記録や反省点を整理します。

    public documents
      ↓
    公開可能な成果物・概要・構成

    private documents
      ↓
    面接用の詳細メモ・深掘り回答材料

Custom GPT からは、必要な文書だけを `document_id` で取得します。

Public と Private を分けることで、外向けに見せる情報と、自分用・面接用の情報を整理しやすくなります。

## リクエストの流れ

Markdown本文を取得する流れは以下です。

    1. Custom GPT が document_id を指定してAPIを呼び出す
    2. API Gateway がリクエストを受ける
    3. Lambda が Bearer Token を確認する
    4. Lambda が document_id を検証する
    5. allowed-documents.json から対象Repositoryとpathを取得する
    6. Lambda が GitHub API を呼び出す
    7. GitHub API からMarkdown本文を取得する
    8. Lambda がMarkdown本文をCustom GPTへ返す

この流れにより、Custom GPT は GitHub の詳細な構成を知らなくても、許可済み文書を取得できます。

## 文書一覧取得の流れ

Custom GPT が利用可能な文書一覧を確認する場合は、一覧取得用のAPIを呼び出します。

    1. Custom GPT が文書一覧APIを呼び出す
    2. API Gateway がLambdaを呼び出す
    3. Lambda が allowed-documents.json を読み込む
    4. 取得可能な document_id と説明を返す

これにより、Custom GPT は現在参照できる資料を把握できます。

## Markdown本文取得の流れ

特定の文書を取得する場合は、`document_id` を指定します。

    1. Custom GPT が document_id を指定する
    2. Lambda が document_id を allowed-documents.json と照合する
    3. 許可されていればGitHub APIからMarkdownを取得する
    4. 許可されていなければエラーを返す

この方式により、AIが任意のファイルパスを直接指定する構成を避けています。

## 認証と権限の境界

この構成では、認証と権限の境界を以下のように分けています。

| 対象 | 扱い |
|---|---|
| Custom GPT | 中継APIを呼び出す。GitHub Tokenは持たない |
| API Gateway | 外部からの入口。Bearer Tokenで制限する |
| Lambda | GitHub API呼び出しと document_id 検証を行う |
| GitHub Token | Lambda側でのみ扱う |
| allowed-documents.json | AIが取得できる文書を制御する |

Custom GPT に GitHub Token を直接持たせないことで、AI が Repository 全体へ自由にアクセスする構成を避けています。

## OpenAPI schema の役割

Custom GPT Actions からAPIを呼び出すために、OpenAPI schema を用意します。

OpenAPI schema には、以下を定義します。

- 呼び出せるエンドポイント
- HTTPメソッド
- 必要なパラメータ
- `document_id` の候補
- 認証方式
- レスポンス形式

この定義により、Custom GPT は自然文の会話から、必要なAPI呼び出しを選択できます。

また、`document_id` を enum として定義することで、AI が想定外の文書IDを指定しにくくなります。

## エラー時の考え方

このAPIでは、エラー時の切り分けも重要です。

| 状態 | 主な原因 |
|---|---|
| 401 / 403 | APIキー未設定、Bearer Token不一致 |
| 404 | document_id が未登録、または対象Markdownが存在しない |
| 500 | Lambda内の例外、GitHub API呼び出し失敗 |
| schema検証エラー | OpenAPI schema の定義不備 |

Custom GPT Actions では、schemaを貼り直した後にAPIキーの再入力が必要になる場合があります。

そのため、APIが動かない場合は、Lambdaコードだけでなく、Custom GPT側の認証設定やOpenAPI schemaも確認対象になります。

## セキュリティ上の意識

このプロジェクトで意識したのは、AIから参照できる情報を広げすぎないことです。

特に以下を意識しました。

- GitHub Token を Custom GPT 側に持たせない
- 任意パス指定を避ける
- 取得対象を `allowed-documents.json` で管理する
- Public / Private の資料を分ける
- APIキーで中継APIへのアクセスを制限する
- OpenAPI schema で呼び出せる操作を限定する

AI連携では、便利さだけでなく、どこまで情報を渡すかを設計することが重要だと考えました。

## 関連ドキュメント

- [設計判断メモ](./design-decisions.md)
