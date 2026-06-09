# Discordお題Bot / OdaiBox

## 概要
Discord上でゲーム用のお題をランダムに出すBotです。  
非エンジニアでもブラウザからお題を管理できるように、管理画面も作成しました。

## 作った理由
Discordのボイスチャット中に、ゲームのお題を毎回手作業で決めるのが手間だったため、自動で出題できるBotを作りました。

## 使用技術
- AWS Lambda
- API Gateway
- DynamoDB
- S3
- CloudFront
- Discord API
- Python
- JavaScript / HTML / CSS
- GitHub Actions

## 構成
ここに構成図を貼る。

## 工夫した点
- Discordコマンドから簡単にお題を取得できるようにした
- S3 + CloudFrontで管理画面を配信した
- DynamoDBでサーバーごとのお題を管理できるようにした
- 管理者以外が編集できないように権限制御を考慮した
- ユーザーIDなど、必要最小限の情報だけを扱う方針にした

## 苦労した点
- Discord APIの署名検証
- API GatewayとLambdaの連携
- CORS設定
- CloudFront経由での管理画面配信
- GitHub Actionsによるデプロイ設定

## 学んだこと
- サーバーレス構成の基本
- API GatewayとLambdaの役割分担
- DynamoDBの設計
- 静的サイト配信とCloudFront
- 外部サービス連携時のセキュリティ・運用観点
