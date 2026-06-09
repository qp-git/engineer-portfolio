# OdaiBox Architecture

## Component overview

| Component | Role |
|---|---|
| Discord | `/odai` や `/admin-login` などのスラッシュコマンドを実行するユーザー接点 |
| API Gateway | Discordおよび管理画面からのHTTPリクエストを受ける入口 |
| Lambda | コマンド処理、お題抽選、管理画面ログイン、DynamoDB更新を担当 |
| DynamoDB | サーバーごとのお題データ、ON/OFF状態、一時ログイン情報を保存 |
| S3 | 管理画面のHTML/CSS/JavaScriptを保存 |
| CloudFront | 管理画面をHTTPSで配信 |
| IAM | LambdaやGitHub Actionsの権限を制御 |

## Request flow: `/odai`

```text
1. User runs /odai in Discord
2. Discord sends an interaction request to API Gateway
3. API Gateway invokes Lambda
4. Lambda validates the request and reads challenge data from DynamoDB
5. Lambda selects one challenge
6. Lambda returns a response to Discord
7. Discord displays the challenge in chat
```

## Request flow: admin login

```text
1. Authorized user runs /admin-login in Discord
2. Lambda checks the user's Discord-side permission
3. Lambda generates a temporary password
4. Lambda stores the password with guild_id and expiration time in DynamoDB
5. User enters the temporary password in the admin UI
6. Admin UI sends the password to API Gateway
7. Lambda validates expiration and guild_id
8. Admin UI operations are allowed
```

## Request flow: admin UI edit

```text
1. User edits challenge data in the admin UI
2. Browser sends a request to API Gateway
3. Lambda validates the temporary login state
4. Lambda updates DynamoDB
5. Admin UI shows updated challenge data
```

## Design notes

- 管理画面は静的配信のため、画面表示そのものを認可とは見なさない
- 編集操作はAPI側で検証する
- サーバーIDを使い、Discordサーバーごとにお題データを分離する
- 音声やチャット本文は扱わない
