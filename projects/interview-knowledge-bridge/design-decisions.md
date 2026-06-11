# Interview Knowledge Bridge 設計判断メモ

Interview Knowledge Bridge は、Custom GPT から GitHub 上の許可済み Markdown を参照できるようにする中継 API です。

このプロジェクトでは、単に API を作ることではなく、AI が参照できる情報の範囲を制御しながら、自主学習の成果物を面接対策や説明文作成に活用できるようにすることを重視しました。

## 中継APIを作った理由

Custom GPT に GitHub 上の情報を参照させたい場合、単純には Repository のURLやMarkdownのURLを渡す方法も考えられます。

しかし、その方法では以下の課題があります。

- AIにどのファイルを読ませるか制御しにくい
- Public / Private の情報を分けにくい
- Repository 内の構成変更に弱い
- 面接用に読ませたい資料だけを選びにくい
- AIが毎回必要なファイルを探す必要がある

そこで、Custom GPT と GitHub の間に API Gateway + Lambda の中継APIを置きました。

この構成により、AIが参照できるMarkdownを事前に許可したものに限定できます。

## Custom GPTにGitHub Tokenを直接持たせない理由

このプロジェクトでは、Custom GPT に GitHub Token を直接持たせない構成にしました。

GitHub Token を Custom GPT 側に持たせると、Repository へのアクセス権限がAI側に寄りすぎます。

また、Repository内には公開したい情報だけでなく、作業途中のメモや非公開前提の情報が含まれる可能性もあります。

そのため、GitHub Token は Lambda 側だけで扱い、Custom GPT は中継APIを呼び出すだけの構成にしました。

この設計により、Custom GPT は GitHub の認証情報を知らずに、許可されたMarkdownだけを取得できます。

## allowed-documents.json を使った理由

取得可能なMarkdownは、`allowed-documents.json` で管理しています。

このファイルには、Custom GPT から参照してよい文書ID、説明、Repository、pathなどを定義します。

この方式にした理由は以下です。

- 取得可能な文書を明示できる
- 任意のファイルパス指定を避けられる
- document_id でAIが必要な文書を選びやすくなる
- Public / Private の文書を整理しやすい
- 文書の追加・削除を設定ファイルで管理できる
- OpenAPI schema の enum と対応させやすい

AI連携では、「何を読ませるか」を曖昧にしないことが重要だと考えました。

## document_id 方式にした理由

APIのパラメータとしてファイルパスを直接受け取る構成にはしませんでした。

たとえば、`path=projects/xxx.md` のような指定を許すと、呼び出し側が想定外のファイルを指定できる余地が生まれます。

そのため、このプロジェクトでは `document_id` を使っています。

Custom GPT は、以下のような文書IDを指定します。

- `public-portfolio-index`
- `public-odaibox`
- `public-stt-ecs`
- `public-alexa-skill`
- `public-interview-knowledge-bridge`

Lambda 側は、その `document_id` が `allowed-documents.json` に存在するかを確認し、対応するMarkdownだけを取得します。

この方式により、API利用者がRepository内のパス構造を意識しなくてもよくなり、取得範囲も制御しやすくなります。

## Public / Private を分けた理由

このプロジェクトでは、公開用のポートフォリオ情報と、面接深掘り用の非公開メモを分けて扱う前提にしています。

Public 側には、GitHub上で誰に見せてもよい成果物・構成・学びを整理します。

Private 側には、面接で深掘りされたときに使う詳細な作業記録、反省点、判断理由を整理します。

この分離により、以下を実現できます。

- 外部公開してよい情報だけをPublicに置ける
- 面接用の深掘り材料をPrivateに残せる
- Custom GPTが用途に応じて文書を参照できる
- 公開情報と非公開情報の境界を意識できる
- AIに渡す情報の粒度を調整できる

ポートフォリオでは、すべての情報を公開することが正解ではありません。

公開用と自分用を分けた上で、必要な範囲だけAIに参照させることを重視しました。

## API Gateway + Lambda にした理由

中継APIは、API Gateway + Lambda で構成しました。

この構成にした理由は以下です。

- 小規模なAPIを低コストで作りやすい
- HTTPリクエストを受けてLambdaで処理できる
- Custom GPT Actions から呼び出しやすい
- GitHub API呼び出しや認証処理をLambda側に閉じ込められる
- 常時起動サーバーを持たなくてよい
- AWSのサーバーレス構成を学習できる

このプロジェクトでは、高頻度アクセスや大規模処理ではなく、Custom GPT が必要なときにMarkdownを取得できればよい用途です。

そのため、常時起動のEC2ではなく、リクエスト時だけ動くLambda構成が合っていると判断しました。

## OpenAPI schema を用意した理由

Custom GPT Actions から外部APIを呼び出すには、OpenAPI schema が必要です。

OpenAPI schema には、APIのエンドポイント、メソッド、パラメータ、認証方式、レスポンス形式を定義します。

このプロジェクトでは、`document_id` を enum として定義することで、Custom GPT が選べる文書IDを明示しました。

OpenAPI schema を用意したことで、Custom GPT は自然文の会話の中から、必要に応じて文書一覧取得や本文取得のAPIを呼び出せます。

一方で、schemaを更新すると、Custom GPT Actions 側でAPIキーの再入力が必要になる場合がありました。

この経験から、外部APIそのものだけでなく、Custom GPT Actions 側の設定や認証状態も運用上の確認対象になると学びました。

## Bearer認証を使った理由

中継APIは、Bearer Token による簡易的な認証を行う構成にしました。

このAPIは、公開インターネットから呼び出せる入口になります。

そのため、誰でも自由にMarkdownを取得できる状態にはしない方がよいと考えました。

Bearer認証を使うことで、少なくともAPIキーを持つCustom GPTだけが中継APIを呼び出せるようにします。

本格的な認可基盤ではありませんが、学習プロジェクトとしては、外部公開APIに認証を付ける基本を確認できました。

## GitHubをMarkdownの保管場所にした理由

自主学習の成果物は、MarkdownとしてGitHubに整理しています。

GitHubを使う理由は以下です。

- 変更履歴を残せる
- READMEや構成メモをプロジェクトごとに管理できる
- Public Repositoryとして成果物を見せやすい
- Private Repositoryに面接用メモを分けられる
- MarkdownはAIにも人間にも読みやすい
- GitHub上の内容をそのままポートフォリオとして使える

AIに読ませるためだけの専用DBを作るのではなく、GitHub上で管理しているMarkdownを一次情報として使う構成にしました。

これにより、人間が見るポートフォリオと、AIが参照する情報源を近づけられます。

## AIに読ませる資料を要約ファイルとして分けた理由

このポートフォリオでは、各プロジェクトの詳細READMEとは別に、`gpt-context/summaries/` にAI向け要約を置いています。

これは、AIが毎回長いREADMEや詳細メモをすべて読むのではなく、要点をまとめた文書を参照しやすくするためです。

AI向け要約には、以下を整理します。

- プロジェクト概要
- 使用技術
- 構成
- 特に強調したい学び
- 面接で説明しやすいポイント

この方式により、人間向けの詳細ページと、AI向けの要約を分けて運用できます。

## エラー切り分けで学んだこと

このプロジェクトでは、API自体の実装だけでなく、Custom GPT Actions 側の設定も含めて切り分ける必要がありました。

特に、以下のような切り分けが必要でした。

- 403の場合、Bearer Tokenが送られているか
- 404の場合、document_idが登録されているか
- document_idがOpenAPI schemaのenumに入っているか
- `allowed-documents.json` に対象文書があるか
- GitHub側に実際のMarkdownが存在するか
- schema更新後にAPIキーを再入力しているか

この経験から、AI連携APIでは、バックエンドのコードだけでなく、OpenAPI schema、Custom GPT Actions設定、認証情報、許可文書リストを一体で確認する必要があると学びました。

## このプロジェクトで学べたこと

このプロジェクトを通して、AIと既存の情報資産をつなぐときには、単に接続するだけでなく、参照範囲の制御が重要だと学びました。

特に大きかった学びは以下です。

- Custom GPTにGitHub Tokenを直接持たせない設計
- 中継APIで参照範囲を制御する考え方
- `allowed-documents.json` による許可リスト管理
- `document_id` による取得対象の抽象化
- Public / Private の情報分離
- OpenAPI schema と Custom GPT Actions の連携
- Bearer認証によるAPI呼び出し制限
- AI向け要約ファイルの運用
- 403 / 404 / schema / 認証設定の切り分け

このプロジェクトは、単なるAPI作成ではなく、AIが安全に必要な情報だけを参照できるようにするための設計練習になりました。

## 今後の改善余地

今後改善するなら、以下を検討します。

- document_id の命名ルール整理
- allowed-documents.json の検証スクリプト追加
- OpenAPI schema と allowed-documents.json の整合性チェック
- APIレスポンス形式の改善
- エラー時メッセージの整理
- ログ出力の改善
- APIキー管理の見直し
- キャッシュによるGitHub API呼び出し回数削減
- Public / Private 文書の棚卸し手順整備
- Qiita記事や静的Webページとの導線整理

## 関連ドキュメント

- [構成メモ](./architecture.md)
