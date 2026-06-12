# Interview Knowledge Bridge アーキテクチャ

## このドキュメントの目的

このドキュメントでは、Interview Knowledge Bridge の構成を整理します。

README ではプロジェクト概要を、[設計判断メモ](./design-decisions.md) では設計理由を説明しています。ここでは、Custom GPT、Bridge API、ホワイトリスト、GitHub 上の Markdown がどのように関係するかを中心にまとめます。

## 全体構成

Interview Knowledge Bridge は、Custom GPT から GitHub 上の Markdown を直接無制限に参照させるのではなく、Bridge API を通して許可済み文書だけを返す構成です。

    Custom GPT
      ↓
    Actions / OpenAPI schema
      ↓
    Bridge API
      ↓
    Whitelist
      ↓
    GitHub Markdown

## 各要素の役割

### Custom GPT

面接練習や回答生成を行う AI 側です。

ユーザーからの質問に対して、必要に応じて Bridge API を呼び出し、関連する Markdown を取得します。

### Actions / OpenAPI schema

Custom GPT が外部 API を呼び出すための定義です。

どのエンドポイントを呼べるか、どのようなパラメータを渡すか、どの形式でレスポンスを受け取るかを定義します。

### Bridge API

Custom GPT と GitHub 上の Markdown の間に入る中継 API です。

主に以下の処理を行います。

- リクエストされた文書がホワイトリストに含まれているか確認する
- 許可済み文書であれば GitHub 上の Markdown を取得する
- Markdown の内容を Custom GPT に返す
- 許可されていない文書へのアクセスは返さない

### Whitelist

Custom GPT が参照してよい Markdown を管理する一覧です。

このホワイトリストにより、GitHub 上のすべてのファイルを AI に読ませるのではなく、面接練習や回答生成に使ってよい文書だけを明示的に指定します。

### GitHub Markdown

公開ポートフォリオや面接深掘り用の補足メモなど、AI に参照させたい情報を Markdown として管理します。

Markdown にすることで、人間も読みやすく、AI にも渡しやすい形式になります。

## データの流れ

1. ユーザーが Custom GPT に質問する
2. Custom GPT が必要に応じて Bridge API を呼び出す
3. Bridge API がリクエストされた文書 ID やパスを確認する
4. ホワイトリストに含まれていれば、対象 Markdown を取得する
5. Bridge API が Markdown の内容を Custom GPT に返す
6. Custom GPT が取得した内容をもとに回答する

## ホワイトリスト制御の位置づけ

この構成で重要なのは、ホワイトリストが単なるセキュリティ対策ではなく、AI に読ませる情報の範囲を設計するための仕組みである点です。

公開されている情報であっても、すべてを AI に読ませると、回答に関係ない情報や古い情報が混ざる可能性があります。

そのため、Bridge API 側で参照可能な Markdown を制限し、AI が使う情報の範囲を明確にします。

## この構成で整理できること

この構成により、以下を分けて管理できます。

- 人間向けに読みやすく整理した公開ポートフォリオ
- AI 面接官向けに残した詳細な補足情報
- Custom GPT が参照してよい Markdown の一覧
- GitHub 上の文書構成
- API として外部から取得できる範囲

## 今後の拡張余地

今後の拡張としては、以下が考えられます。

- 文書一覧を返すエンドポイントの整備
- プロジェクト単位でのカテゴリ管理
- 文書 ID と GitHub パスの対応表の整理
- 取得ログの記録
- 公開メモと非公開メモの参照範囲を同じ仕組みで管理
