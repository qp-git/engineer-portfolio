# Interview Knowledge Bridge アーキテクチャ

## このドキュメントの目的

このドキュメントでは、Interview Knowledge Bridge の構成を整理します。

README ではプロジェクト概要を、[設計判断メモ](./design-decisions.md) では設計理由を説明しています。ここでは、Custom GPT、Bridge API、ホワイトリスト、GitHub API がどのように関係するかを中心にまとめます。

## 全体構成

Interview Knowledge Bridge は、Custom GPT から Private GitHub リポジトリ上の Markdown を直接無制限に参照させるのではなく、Bridge API を通して許可済み文書だけを返す構成です。

    Custom GPT
      ↓
    Actions / OpenAPI schema
      ↓
    API Gateway
      ↓
    Lambda
      ↓
    Whitelist
      ↓
    GitHub API
      ↓
    Private GitHub Markdown

## 各要素の役割

### Custom GPT

技術整理を補助する AI 側です。

ユーザーからの質問に対して、必要に応じて Bridge API を呼び出し、関連する Markdown を取得します。

### Actions / OpenAPI schema

Custom GPT が外部 API を呼び出すための定義です。

どのエンドポイントを呼べるか、どのようなパラメータを渡すか、どの形式でレスポンスを受け取るかを定義します。

### API Gateway

Custom GPT からの HTTP リクエストを受け付け、Lambda へ渡す入口です。

外部から呼び出す API のエンドポイントとして機能します。

### Lambda

Bridge API の中心となる処理です。

主に以下を行います。

- リクエストされた document_id を受け取る
- document_id がホワイトリストに含まれているか確認する
- 許可済み document_id であれば、対応する GitHub 上のパスに変換する
- GitHub API から対象 Markdown を取得する
- Markdown の内容を Custom GPT に返す
- 許可されていない document_id は返さない

### Whitelist

Custom GPT が参照してよい Markdown を管理する一覧です。

このホワイトリストにより、Private リポジトリ内のすべてのファイルを AI に読ませるのではなく、回答生成や技術整理に使ってよい文書だけを明示的に指定します。

### GitHub API

Private GitHub リポジトリ上の Markdown を取得するために利用します。

リポジトリやトークンなどの詳細は API 側で管理し、Custom GPT からは直接 GitHub 上の任意パスを指定させない構成にします。

## データの流れ

1. ユーザーが Custom GPT に質問する
2. Custom GPT が必要に応じて Bridge API を呼び出す
3. Custom GPT は document_id を Bridge API に渡す
4. Lambda が document_id をホワイトリストと照合する
5. 許可済み document_id の場合のみ、対応する GitHub パスに変換する
6. GitHub API から対象 Markdown を取得する
7. Bridge API が Markdown の内容を Custom GPT に返す
8. Custom GPT が取得した内容をもとに回答する

## ホワイトリスト制御の位置づけ

この構成で重要なのは、ホワイトリストが単なる一覧ではなく、API の入力設計とセットで機能する点です。

たとえば、API が任意の GitHub パスや URL を直接受け取ってしまうと、ホワイトリストを用意していても、許可していないファイルを取得できる余地が残ります。

そのため、この構成では、Custom GPT から受け取る値を document_id に限定し、API 側で document_id と GitHub パスの対応を管理します。

    document_id
      ↓ ホワイトリストで検証
    許可済み GitHub path
      ↓ GitHub API で取得
    Markdown response

この流れにすることで、Custom GPT は任意のファイルパスを指定できず、Bridge API が許可した Markdown だけを取得できます。

## 中継API設計で注意した点

ホワイトリストを機能させるためには、中継 API の設計が重要です。

特に以下の点を意識しました。

- 任意の GitHub URL を直接受け取らない
- 任意のファイルパスを直接受け取らない
- Custom GPT からは document_id だけを受け取る
- document_id と GitHub パスの対応は API 側で管理する
- ホワイトリストにない document_id は返さない
- GitHub への認証情報は API 側に閉じ込める
- Markdown 以外のファイルは参照対象にしない

この設計により、ホワイトリストが単なる目録ではなく、実際に参照範囲を制御する仕組みとして機能します。

## この構成で整理できること

この構成により、以下を分けて管理できます。

- 人間向けに読みやすく整理した公開ポートフォリオ
- Private リポジトリ側に残した詳細な補足情報
- Custom GPT が参照してよい Markdown の一覧
- document_id と GitHub パスの対応
- API として外部から取得できる範囲

## 今後の拡張余地

今後の拡張としては、以下が考えられます。

- 文書一覧を返すエンドポイントの整備
- プロジェクト単位でのカテゴリ管理
- document_id と GitHub パスの対応表の整理
- 取得ログの記録
- 文書ごとの有効・無効切り替え
- 他の AI エージェントや社内ナレッジ検索への応用
