# OdaiBox

## 概要

OdaiBoxは、Discordで通話しながらゲームをするコミュニティ向けに、お題をランダムに出すBotです。

Discordで `/odai` を実行すると、次の試合で使うお題をランダムに返します。

単なるランダム抽選ではなく、非エンジニアでもWeb管理画面からお題を追加・編集・ON/OFFできるようにした点が特徴です。

## 作成背景

Discordで通話しながらゲームをするとき、同じ遊び方が続くとマンネリ化しやすい課題がありました。

コミュニティ内で毎回お題を考えるのではなく、Botによってランダムにお題を出すことで、遊び方に変化をつけることを目的としました。

また、お題をLambdaのコード内に固定すると、変更のたびに開発者が修正・デプロイする必要があります。

そのため、利用者側でDiscordサーバー（コミュニティ）の雰囲気に合わせてお題を管理できるWeb管理画面を重視しました。

## 使用技術

- Discord Slash Commands
- Discord Interaction
- AWS Lambda
- Amazon API Gateway
- Amazon DynamoDB
- Amazon S3
- Amazon CloudFront
- HTML / CSS / JavaScript

## 構成概要

主な処理は、Discordコマンドからのお題取得と、Web管理画面からのお題編集です。

詳しい通信経路は `projects/odaibox/architecture.md` に整理しています。

## 実装内容

- `/odai` コマンドでランダムなお題を返すBotを作成
- DynamoDBでDiscordサーバー（コミュニティ）ごとのお題を管理
- Web管理画面からお題の追加・編集・ON/OFFを可能にした
- S3 + CloudFrontで管理画面を静的配信
- `/admin-login` による一時パスワード方式を検討・実装
- 保存する情報と保存しない情報を整理し、プライバシーポリシーを作成

## 特に強調したい学び

このプロジェクトで特に重要なのは、Bot本体だけでなく、利用者が操作するWeb管理画面を用意すると、認証・認可・プライバシー説明も設計対象になると学んだ点です。

お題をコード内に固定するだけであれば構成は単純です。しかし、利用者がブラウザからお題を追加・編集できるようにすると、誰が管理画面を操作できるのか、どのDiscordサーバー（コミュニティ）のお題を編集できるのか、どの情報を保存するのかを明確にする必要があります。

そのため、`/admin-login` による一時ログイン方式や、保存する情報・保存しない情報を整理したプライバシーポリシーを用意しました。

## 関連ドキュメント

- `projects/odaibox/README.md`
- `projects/odaibox/architecture.md`
- `projects/odaibox/design-decisions.md`
- `projects/odaibox/privacy-policy.md`
