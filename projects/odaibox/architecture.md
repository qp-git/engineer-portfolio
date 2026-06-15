# OdaiBox アーキテクチャ

このドキュメントでは、OdaiBoxの通信経路、各コンポーネントの責務、データの流れを整理します。

設計判断の理由は [設計判断メモ](./design-decisions.md) に、保存情報の説明は [プライバシーポリシー](./docs/privacy-policy.md) に分けています。

## 全体像

OdaiBoxには、大きく分けて3つの処理ルートがあります。

1. Discordからお題を取得するルート
2. Web管理画面を表示するルート
3. Web管理画面からお題を追加・編集するルート

```text
[Discord]
  │ /odai, /admin-login
  ▼
[API Gateway]
  ▼
[Lambda]
  ├─ お題抽選
  ├─ 管理画面ログイン発行
  ├─ 管理画面API処理
  ▼
[DynamoDB]
  ├─ お題データ
  ├─ 一時ログイン情報
  └─ お題履歴

[Browser]
  ▼
[CloudFront]
  ▼
[S3]
  └─ Web管理画面のHTML / CSS / JavaScript
```

## コンポーネントの役割

| 要素 | 役割 |
|---|---|
| Discord Slash Commands | `/odai` や `/admin-login` の実行入口 |
| API Gateway | Discordや管理画面からのHTTPリクエストを受ける入口 |
| Lambda | お題抽選、ログイン発行、管理画面API処理 |
| DynamoDB | お題、一時ログイン情報、お題履歴の保存 |
| S3 | 管理画面の静的ファイル配置 |
| CloudFront | 管理画面の配信 |
| ブラウザ | 管理画面の表示とAPI呼び出し |

## `/odai` 実行時の流れ

`/odai` は、DiscordのInteractionとしてAPI Gatewayに送信されます。

1. ユーザーがDiscordで `/odai` を実行する
2. DiscordがAPI GatewayへInteractionリクエストを送る
3. API GatewayがLambdaを呼び出す
4. LambdaがDiscord署名を検証する
5. Lambdaが対象のDiscordサーバー（コミュニティ）を確認する
6. LambdaがDynamoDBから有効なお題を取得する
7. 直近のお題履歴や出現重みを考慮してお題を選ぶ
8. お題履歴をDynamoDBに保存する
9. LambdaがDiscordへレスポンスを返す
10. Discordのチャットにお題が表示される

```text
Discord /odai
  -> API Gateway
  -> Lambda
  -> DynamoDBからお題取得
  -> 抽選
  -> DynamoDBへ履歴保存
  -> Discordへ返答
```

## 管理画面ログインと編集の流れ

管理画面は静的サイトとして公開していますが、URLを知っているだけではお題を編集できない構成にしています。

管理画面の利用は、以下の4つの流れに分けて整理できます。

### 1. `/admin-login` のリクエストを検証する流れ

管理画面のログイン情報は、Discord 上で `/admin-login` を実行したユーザーに対して発行します。

このとき、まず Discord から送られてきた Interaction リクエストの署名を検証し、正規の Discord リクエストであることを確認します。そのうえで、実行したユーザーが管理操作を許可されたユーザーかを確認します。

```text
Discord /admin-login
  -> API Gateway
  -> Lambda
  -> Discord署名を検証
  -> 管理操作の許可を確認
```

この流れにより、API Gateway のエンドポイントを直接呼び出してログイン情報を発行することを防ぎつつ、許可されたユーザーだけが管理画面のログイン情報を取得できるようにしています。

### 2. サーバー専用の一時ログイン情報を発行する流れ

リクエスト検証と管理操作の許可確認に成功すると、Lambda が一時パスワードを生成します。

この一時パスワードは、対象の Discord サーバーに紐づくログイン情報として扱います。Lambda は、一時パスワードそのものではなく、ハッシュ化した値と有効期限を DynamoDB に保存します。

その後、管理画面URLと一時パスワードを、Discord の ephemeral message で本人にだけ見える形で返します。

```text
Lambda
  -> 一時パスワードを生成
  -> パスワードハッシュと有効期限をDynamoDBへ保存
  -> 対象Discordサーバーに紐づける
  -> ephemeral messageで本人にだけ返答
```

この構成により、ログイン情報を知っていても対象サーバー以外のお題は編集できないようにし、複数サーバーで利用する場合でも管理範囲を分離できます。

### 3. 管理画面を表示する流れ

管理画面は、HTML / CSS / JavaScript で作成した静的ファイルとして S3 に配置し、CloudFront 経由で配信します。

ユーザーが管理画面URLを開くと、CloudFront がリクエストを受け、S3 から静的ファイルを取得してブラウザに返します。

```text
Browser
  -> CloudFront
  -> S3
  -> HTML / CSS / JavaScript
```

この時点では、管理画面の表示だけが行われます。お題の取得・保存など、DynamoDB を操作する処理は、API Gateway + Lambda 経由で行います。

### 4. ログイン後にお題を取得・保存する流れ

ユーザーが管理画面で一時パスワードを入力すると、ブラウザから API Gateway へログイン確認リクエストを送ります。

Lambda は DynamoDB に保存された一時ログイン情報を確認し、有効期限や対象サーバーを検証します。認証に成功すると、その Discord サーバーに紐づくお題一覧を取得します。

ユーザーがお題を追加・編集・ON/OFF切り替えすると、ブラウザから保存リクエストを送ります。保存時にも Lambda が一時ログイン情報を再確認し、問題がなければ DynamoDB のお題データを更新します。

```text
Browser 管理画面
  -> API Gateway
  -> Lambda
  -> 一時ログイン情報を確認
  -> 対象Discordサーバーのお題を取得
  -> お題の追加・編集・ON/OFFを保存
  -> DynamoDBを更新
```

この流れにより、管理画面は静的サイトとして配信しつつ、編集処理は認証済みの API 経由に限定できます。


## DynamoDBで扱う主なデータ

| データ | 用途 |
|---|---|
| DiscordサーバーID | コミュニティごとにお題や設定を分ける |
| お題データ | デフォルトお題・カスタムお題の管理 |
| 有効 / 無効状態 | 出題対象に含めるかを切り替える |
| お題の重み | 出題されやすさを調整する |
| 一時ログイン情報 | 管理画面へのログイン制御 |
| お題履歴 | 直近で同じお題が続きにくくするために利用 |
| ユーザーID | お題履歴や管理画面ログイン発行者の記録に利用 |

## 保存しない情報

OdaiBoxでは、以下の情報は保存しません。

- 音声通話
- チャット本文
- DM
- 会話内容
- Discordのパスワード

## 実装の補足

Lambdaの実装では、Discord署名検証、スラッシュコマンドごとのルーティング、お題抽選、一時ログイン情報の検証、管理画面APIの処理を行っています。

コード全体ではなく代表的な処理だけを抜粋し、処理の意図が分かるように [Lambdaコード解説](./docs/lambda-code-notes.md) に整理しています。
