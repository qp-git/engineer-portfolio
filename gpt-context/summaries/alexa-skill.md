# Alexa Skill

## 概要

Alexaスキルを題材に、音声UIとAWS Lambdaを連携させた朝の情報取得プロジェクト。

自宅と勤務地の2地点の天気を取得し、Alexaに読み上げさせる仕組みを作成した。

当初は電車の遅延情報も読み上げる想定だったが、個人開発で利用できる運行情報APIの制約により、実証は天気取得を中心に整理している。

## 使用技術

- Alexa Skills Kit
- AWS Lambda
- Node.js
- Open-Meteo
- 外部API連携
- CloudWatch Logs
- Lambda環境変数

## 構成

    Alexa
      ↓ カスタムスキル
    AWS Lambda
      ├─ 天気API
      └─ 遅延情報API 調査
      ↓
    読み上げ文を生成
      ↓
    Alexaが読み上げ

## 実装内容

- Alexaカスタムスキルを作成
- LambdaをAlexa Skills Kitのエンドポイントとして設定
- Lambdaから外部APIを呼び出し、2地点の天気を取得
- 取得結果を読み上げ文に整形
- Lambda環境変数で地点情報を管理
- CloudWatch Logsで実行確認
- 開発中はInvocation Name、実運用は定型アクションで起動する方針を整理

## 学び

- Alexa、Lambda、外部APIの役割分担を理解した
- 音声UIでは起動しやすさ、聞き取りやすさ、情報量の調整が重要
- 外部API連携では、コードだけでなく利用条件や契約条件の確認が必要
- 遅延情報APIでは、実装ではなく個人利用可能なデータ提供条件がボトルネックになった
- 技術検証では、成功しなかった理由を切り分けて説明できることにも価値がある
