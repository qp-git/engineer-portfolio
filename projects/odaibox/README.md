# OdaiBox - Discord お題Bot

## Overview

OdaiBox は、Discord のスラッシュコマンド `/odai` を実行すると、ゲーム用のお題をランダムに返すBotです。

単なるランダムBotではなく、非エンジニアでもWeb管理画面からお題の追加・編集・ON/OFFができるように設計しました。

## Background

Discordで通話しながらゲームをする際、同じ遊び方が続いてマンネリ化しやすいという課題がありました。そこで、試合ごとにランダムなお題を出し、遊び方に変化をつけるBotを作成しました。

また、サーバーごとにノリや難易度が違うため、Bot作成者だけがコードを修正するのではなく、利用者側でお題を調整できる管理UIを重視しました。

## Architecture

### `/odai` command

```text
Discord
  ↓ /odai
API Gateway
  ↓
Lambda
  ↓
DynamoDB
```

### Admin UI

```text
Browser
  ↓
CloudFront
  ↓
S3
```

### Save / edit challenges

```text
Admin UI
  ↓
API Gateway
  ↓
Lambda
  ↓
DynamoDB
```

## Main Skills

- AWS Lambda
- Amazon API Gateway
- Amazon DynamoDB
- Amazon S3
- Amazon CloudFront
- IAM
- Discord Slash Commands
- GitHub Actions

## What I built

- `/odai` コマンドでランダムなお題を返すBot
- サーバーごとのお題管理
- Web管理画面によるお題の追加・編集・ON/OFF
- 静的管理画面のS3 + CloudFront配信
- API Gateway + Lambda + DynamoDB によるサーバーレス構成
- 管理画面を安全に使うための一時パスワード方式
- 保存する情報・保存しない情報の整理

## Design Decisions

### Why serverless

OdaiBoxは、ユーザーが `/odai` を実行したタイミングで短時間だけ処理すればよいBotです。常時接続やメッセージ監視が必要ないため、常時起動のEC2ではなく、API Gateway + Lambda + DynamoDB のイベント駆動構成を選びました。

### Why DynamoDB

お題データは、サーバーID、お題ID、タイトル、説明、有効フラグなどのシンプルな構造です。複雑なJOINを必要としないため、DynamoDBでサーバーごとに管理する構成が適していると判断しました。

### Why admin UI

Lambda内にお題リストを固定すると、お題を変更するたびにコード修正とデプロイが必要になります。非エンジニアでも運用できるよう、Web管理画面からDynamoDB上のお題を変更できるようにしました。

## Technical Challenge

一番の技術的な課題は、S3 + CloudFrontで配信する静的管理画面からのAPI操作に、どう認可を持たせるかでした。

管理画面を表示できることと、編集権限があることは別です。URLを知っているだけでAPIを叩ける状態にすると、お題を書き換えられたり、想定外のリクエストが発生したりする可能性があります。

そのため、Discord上の `/admin-login` コマンドを入口にして、権限のあるユーザーだけにサーバーIDへ紐づいた一時パスワードを発行する方式を考えました。管理画面側では、その一時パスワードをAPI Gateway経由でLambdaに送り、LambdaがDynamoDB上の情報を確認してから操作を許可する構成です。

## Privacy / Security Policy

### 保存する情報

- DiscordサーバーID
- DiscordユーザーID
- お題データ
- 管理画面ログイン用の一時情報
- 一時的なお題履歴

### 保存しない情報

- 音声通話
- チャット本文
- DM
- Discordのパスワード

## What I learned

- サーバーレス構成は、処理特性に合わせて選定する必要がある
- 静的Web画面でも、裏側のAPI認可設計が重要
- コードと運用上変更されるデータを分離すると、非エンジニアにも扱いやすくなる
- 個人開発でも、保存する情報・保存しない情報を明確にする必要がある
- 技術的に正しいだけでなく、利用者に伝わる説明が必要

## Future Improvements

- TerraformまたはAWS CDKによるIaC化
- CloudWatchによるエラー監視
- 管理画面の認可方式の強化
- 複数サーバー対応の運用整理
- GitHub Actionsによるデプロイ自動化の整備
