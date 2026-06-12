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

## `/admin-login` 実行時の流れ

管理画面は、URLを知っているだけでは編集できないようにしています。

1. 権限のあるユーザーがDiscordで `/admin-login` を実行する
2. DiscordがAPI GatewayへInteractionリクエストを送る
3. LambdaがDiscord署名を検証する
4. LambdaがDiscord側の権限または許可ロールを確認する
5. Lambdaが一時パスワードを生成する
6. 一時パスワードのハッシュと有効期限をDynamoDBに保存する
7. 管理画面URLと一時パスワードを、本人だけに見えるメッセージで返す

```text
Discord /admin-login
  -> API Gateway
  -> Lambda
  -> 権限確認
  -> 一時ログイン情報をDynamoDBへ保存
  -> ephemeral messageで本人にだけ返答
```

## 管理画面表示の流れ

管理画面は静的ファイルとしてS3に配置し、CloudFront経由で配信します。

1. ユーザーがブラウザで管理画面URLを開く
2. CloudFrontがリクエストを受ける
3. S3からHTML / CSS / JavaScriptを取得する
4. ブラウザに管理画面が表示される

```text
Browser
  -> CloudFront
  -> S3
  -> HTML / CSS / JavaScript
```

## 管理画面からお題を編集する流れ

管理画面からの保存・編集処理は、API Gateway + Lambda経由でDynamoDBに反映します。

1. ユーザーが管理画面で一時パスワードを入力する
2. ブラウザがAPI Gatewayへログイン確認リクエストを送る
3. LambdaがDynamoDBの一時ログイン情報を確認する
4. 認証に成功すると、対象Discordサーバー（コミュニティ）のお題一覧を取得する
5. ユーザーがお題を追加・ON/OFF切り替えする
6. ブラウザがAPI Gatewayへ保存リクエストを送る
7. Lambdaが一時ログイン情報を再確認する
8. LambdaがDynamoDBのお題データを更新する
9. 更新結果を管理画面へ返す

```text
Browser管理画面
  -> API Gateway
  -> Lambda
  -> 一時ログイン確認
  -> DynamoDBのお題データを参照・更新
```

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

