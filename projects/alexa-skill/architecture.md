# Alexa Skill アーキテクチャ

## このドキュメントの目的

このドキュメントでは、Alexa Skill プロジェクトの構成を整理します。

README ではプロジェクト概要を、[設計判断メモ](./design-decisions.md) では設計理由を説明しています。ここでは、Alexa Skill、AWS Lambda、外部 API がどのように連携するかを中心にまとめます。

## 全体構成

このプロジェクトでは、Alexa Skill から AWS Lambda を呼び出し、Lambda 側で外部 API を利用して、Alexa に読み上げ用の応答を返す構成を検証しました。

    ユーザー
      ↓ 音声入力
    Alexa 端末
      ↓
    Alexa Skill
      ↓ Intent Request
    AWS Lambda
      ↓ 必要に応じて外部 API を呼び出し
    外部 API
      ↓
    AWS Lambda
      ↓ 読み上げ文を返却
    Alexa Skill
      ↓
    Alexa 端末が音声で読み上げ

## 使用技術・サービスと役割

### Alexa Skill

ユーザーの音声入力を受け取り、定義したインテントに応じて Lambda を呼び出します。

Alexa Skill 側では、起動フレーズ、インテント、サンプル発話などを定義します。

### AWS Lambda

Alexa Skill から呼び出されるバックエンド処理です。

主に以下を行います。

- Alexa からのリクエストを受け取る
- インテントに応じて処理を分岐する
- 必要に応じて外部 API を呼び出す
- Alexa が読み上げる文を生成する
- レスポンス形式に合わせて結果を返す

### 外部 API

天気情報など、Alexa に返す内容を取得するために利用します。

Lambda から外部 API を呼び出し、取得した結果を Alexa 向けの読み上げ文に整形します。

### CloudWatch Logs

Lambda の実行ログやエラー内容を確認するために利用します。

Alexa Skill では画面上に処理の途中経過が見えにくいため、CloudWatch Logs で Lambda 側の挙動を確認することが重要になります。

## Alexa Skill から Lambda が呼ばれる流れ

ユーザーが Alexa に話しかけると、Alexa Skill 側で発話内容が解析され、該当するインテントが判定されます。

その後、Alexa Skill から Lambda に対して Intent Request が送られます。

Lambda では、リクエスト内のインテント名を確認し、該当する処理を実行します。

    音声入力
      ↓
    Alexa Skill がインテントを判定
      ↓
    Lambda に Intent Request を送信
      ↓
    Lambda がインテント名に応じて処理
      ↓
    Alexa にレスポンスを返却

## Lambda から外部 API を呼ぶ流れ

Lambda 側では、インテントに応じて外部 API を呼び出します。

外部 API から返ってきたデータをそのまま Alexa に返すのではなく、Alexa が自然に読み上げられる文章に整形してから返します。

    Lambda
      ↓ 外部 API 呼び出し
    外部 API
      ↓ JSON などのレスポンス
    Lambda
      ↓ 読み上げ文に整形
    Alexa Skill

この流れにより、音声入力をきっかけに外部 API を呼び出し、その結果を音声で返す構成を確認できます。

## API Gatewayを使わない構成

このプロジェクトでは、Alexa Skill から Lambda を直接呼び出す構成を確認しました。

通常の Web API では、外部から Lambda を呼び出す入口として API Gateway を使うことがあります。しかし Alexa Skill では、Alexa Skills Kit 側から Lambda を呼び出せるため、API Gateway を前段に置かなくても構成できます。

    Alexa Skill
      ↓
    AWS Lambda

この構成により、Alexa Skill が Lambda の入口となり、Lambda が処理結果を Alexa に返す流れを整理できました。

## 読み上げ文の生成

Alexa に返すレスポンスでは、単にデータを返すだけでなく、音声で聞いて分かりやすい文に整える必要があります。

たとえば、API のレスポンスが数値や短い文字列であっても、そのまま読み上げると不自然になる場合があります。

そのため Lambda 側で、取得したデータをユーザーが聞き取りやすい日本語の文章に整形します。

## エラー確認とログ

Alexa Skill の開発では、ユーザーから見ると「うまく反応しない」だけに見えることがあります。

そのため、Lambda 側のログを CloudWatch Logs で確認し、以下を切り分けます。

- Alexa Skill から Lambda が呼ばれているか
- インテント名が想定通りか
- 外部 API 呼び出しに失敗していないか
- Lambda のレスポンス形式が Alexa の期待する形式になっているか
- 読み上げ文が生成されているか

## 遅延情報APIを調査止まりにした構成上の位置づけ

当初は、天気情報だけでなく鉄道の遅延情報なども扱うことを検討しました。

ただし、利用できる API の制約や、安定して取得できる情報の範囲を考えると、実装対象としては整理が必要でした。

そのため、遅延情報 API は調査対象として扱い、実装の中心は Alexa Skill から Lambda を呼び出し、外部 API の結果を読み上げる構成の理解に置きました。

## 関連ドキュメント

- [設計判断メモ](./design-decisions.md)
  - API Gateway を使わなかった理由、Invocation Name、外部 API の制約など
