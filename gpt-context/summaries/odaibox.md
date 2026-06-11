# OdaiBox

## 概要

OdaiBoxは、Discordで `/odai` を実行すると、ゲーム用のお題をランダムに返すBot。

単なるランダム抽選ではなく、非エンジニアでもWeb管理画面からお題を追加・編集・ON/OFFできるようにした点が特徴。

## 使用技術

- AWS Lambda
- Amazon API Gateway
- Amazon DynamoDB
- Amazon S3
- Amazon CloudFront
- Discord API
- Discord Slash Commands
- GitHub Actions
- JavaScript / HTML / CSS

## 構成

    Discord
      ↓ /odai
    API Gateway
      ↓
    Lambda
      ↓
    DynamoDB

    Browser
      ↓
    CloudFront
      ↓
    S3

    Admin UI
      ↓ 保存・編集
    API Gateway
      ↓
    Lambda
      ↓
    DynamoDB

## 実装内容

- `/odai` コマンドでランダムなお題を返すBotを作成
- DynamoDBでサーバーごとのお題を管理
- Web管理画面からお題の追加・編集・ON/OFFを可能にした
- S3 + CloudFrontで管理画面を静的配信
- `/admin-login` による一時パスワード方式を検討・実装
- 保存する情報と保存しない情報を整理し、プライバシーポリシーを作成

## 学び

- サーバーレス構成は、常時起動が不要なBotに向いている
- コード内固定データではなくDynamoDBと管理UIに分けると、非エンジニアでもカスタムしやすい
- 管理画面を作る場合は、表示できることと編集できることを分けて考える必要がある
- 個人開発でも、サーバーIDやユーザーIDの扱い、保存する情報、保存しない情報を説明する必要がある
- 技術的に正しいだけでなく、利用者に伝わる説明の粒度も重要
