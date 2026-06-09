# OdaiBox Design Decisions

## 1. Lambda instead of EC2

OdaiBoxは、ユーザーが `/odai` を実行したときだけ動けばよいBotです。常時メッセージを監視する必要がないため、EC2を常時起動するよりも、Lambdaによるイベント駆動構成が適していると判断しました。

## 2. DynamoDB instead of a relational database

お題データはサーバーIDごとに分けて保存できればよく、複雑なJOINを必要としません。アクセスパターンも「対象サーバーの有効なお題を取得する」「お題を追加・更新する」が中心であるため、DynamoDBを選びました。

## 3. Admin UI instead of code-only customization

最初はLambda内に固定のお題リストを持たせるだけでも実現できます。しかし、それではお題変更のたびにコード修正とデプロイが必要になります。非エンジニアでも運用できるように、Web管理画面からDynamoDB上のお題データを変更できる構成にしました。

## 4. Temporary password instead of shared fixed password

固定ID・固定パスワード方式では、パスワード共有、退会者のアクセス、操作主体の追跡しづらさが課題になります。そこで、Discordの `/admin-login` を入口にし、権限確認後に一時パスワードを発行する方式にしました。

## 5. Public information and private information separation

Bot運用に必要なサーバーIDやユーザーIDは保存しますが、音声通話、チャット本文、DM、Discordのパスワードは保存しません。機能に必要な情報と不要な情報を分けることで、利用者に説明しやすい設計にしました。
