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
      ↓ document_id / project_id を検証
    Whitelist
      ↓ 許可済みパスに変換
    GitHub API
      ↓
    Private GitHub Markdown

## 各要素の役割

### Custom GPT

技術整理を補助する AI 側です。

ユーザーからの質問に対して、必要に応じて Bridge API を呼び出し、関連する Markdown を取得します。

Custom GPT 側には、必要に応じて `project_id` や `document_id` を指定して Bridge API を呼び出すように指示を設定します。ただし、GPT 側の指示は呼び出し方を安定させるための補助であり、参照範囲の制御そのものは API 側で行います。

### Actions / OpenAPI schema

Custom GPT が外部 API を呼び出すための定義です。

どのエンドポイントを呼べるか、どのようなパラメータを渡すか、どの形式でレスポンスを受け取るかを定義します。

### API Gateway

Custom GPT からの HTTP リクエストを受け付け、Lambda へ渡す入口です。

外部から呼び出す API のエンドポイントとして機能します。

### Lambda

Bridge API の中心となる処理です。

主に以下を行います。

- リクエストされた `document_id` または `project_id` を受け取る
- `document_id` や `project_id` がホワイトリストに含まれているか確認する
- 許可済みの場合のみ、対応する GitHub 上のパスに変換する
- GitHub API から対象 Markdown を取得する
- Markdown の内容を Custom GPT に返す
- 許可されていない文書やプロジェクトは返さない

### Whitelist

Custom GPT が参照してよい Markdown を管理する一覧です。

このホワイトリストにより、Private リポジトリ内のすべてのファイルを AI に読ませるのではなく、技術整理や回答生成に使ってよい文書だけを明示的に指定します。

ホワイトリストでは、文書単位の `document_id` だけでなく、プロジェクト単位の `project_id` も管理します。これにより、OdaiBox、STT + ECS、Interview Knowledge Bridge など、プロジェクトごとに関連する許可済み Markdown だけを取得できます。

### GitHub API

GitHub 上の許可済み Markdown を取得するために利用します。

リポジトリやトークンなどの詳細は API 側で管理し、Custom GPT からは直接 GitHub 上の任意パスを指定させない構成にします。

## データの流れ

文書単位で取得する場合の流れは以下です。

1. ユーザーが Custom GPT に質問する
2. Custom GPT が必要に応じて Bridge API を呼び出す
3. Custom GPT は `document_id` を Bridge API に渡す
4. Lambda が `document_id` をホワイトリストと照合する
5. 許可済み `document_id` の場合のみ、対応する GitHub パスに変換する
6. GitHub API から対象 Markdown を取得する
7. Bridge API が Markdown の内容を Custom GPT に返す
8. Custom GPT が取得した内容をもとに回答する

プロジェクト単位で取得する場合の流れは以下です。

1. Custom GPT が `project_id` を Bridge API に渡す
2. Lambda が `project_id` をホワイトリストと照合する
3. 許可済み `project_id` に紐づく Markdown の一覧を取得する
4. 対象プロジェクトに関係する Markdown だけを返す
5. Custom GPT がプロジェクト単位の補足情報をもとに回答する

## ホワイトリスト制御の位置づけ

この構成で重要なのは、ホワイトリストが単なる一覧ではなく、API の入力設計とセットで機能する点です。

たとえば、API が任意の GitHub パスや URL を直接受け取ってしまうと、ホワイトリストを用意していても、許可していないファイルを取得できる余地が残ります。

そのため、この構成では、Custom GPT から受け取る値を `document_id` または `project_id` に限定し、API 側でそれらと GitHub パスの対応を管理します。

    document_id / project_id
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
- Custom GPT からは `document_id` や `project_id` を受け取る
- `document_id` / `project_id` と GitHub パスの対応は API 側で管理する
- ホワイトリストにない ID は返さない
- GitHub への認証情報は API 側に閉じ込める
- Markdown 以外のファイルは参照対象にしない

この設計により、ホワイトリストが単なる目録ではなく、実際に参照範囲を制御する仕組みとして機能します。

## この構成で整理できること

この構成により、以下を分けて管理できます。

- 公開用に整理したポートフォリオ
- Private リポジトリ側に残した詳細な補足情報
- Custom GPT が参照してよい Markdown の一覧
- `document_id` / `project_id` と GitHub パスの対応
- API として外部から取得できる範囲

## 今後の拡張余地

今後の拡張としては、以下が考えられます。

- 文書一覧を返すエンドポイントの整備
- プロジェクト単位でのカテゴリ管理
- `document_id` / `project_id` と GitHub パスの対応表の整理
- 取得ログの記録
- 文書ごとの有効・無効切り替え
- 他の AI エージェントや社内ナレッジ検索への応用
