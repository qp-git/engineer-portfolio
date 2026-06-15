# Alexa Skill アーキテクチャ

## このドキュメントの目的

このドキュメントでは、Alexa Skill、AWS Lambda、外部 API がどのように連携するかを整理します。

README ではプロジェクト全体の概要を、[設計判断メモ](./design-decisions.md) では設計上の判断理由を説明しています。

## 全体構成

このプロジェクトでは、Alexa Skill から AWS Lambda を呼び出し、Lambda 側で外部 API を利用して、Alexa に読み上げ用の応答を返す構成を検証しました。

~~~text
ユーザー
  ↓ 音声入力
Alexa 端末
  ↓
Alexa Skill
  ↓ リクエストを送信
AWS Lambda
  ├─ リクエスト種別を確認
  ├─ 外部 API を呼び出し
  ├─ 取得結果を読み上げ文に整形
  └─ Alexa 向けのレスポンスを返却
  ↓
Alexa 端末が音声で読み上げ
~~~

## 使用技術・サービスと役割

### Alexa Skill

ユーザーの音声入力を受け取り、Alexa Skills Kit の設定に基づいて Lambda を呼び出します。

主に以下を設定します。

- スキル名
- Invocation Name
- サンプル発話
- エンドポイント
- Lambda 連携設定

### AWS Lambda

Alexa Skill から呼び出されるバックエンド処理です。

主に以下を行います。

- Alexa からのリクエストを受け取る
- 外部 API を呼び出す
- API レスポンスを読み上げ用の文章に整形する
- Alexa のレスポンス形式に合わせて結果を返す
- エラー内容を CloudWatch Logs に出力する

### 外部 API

天気情報など、Alexa に返す内容を取得するために利用します。

このプロジェクトでは、天気情報の取得に Open-Meteo API を利用しました。また、電車の遅延情報については、個人開発で利用できる API の提供範囲や契約条件を調査しました。

### CloudWatch Logs

Lambda の実行ログやエラー内容を確認するために利用します。

Alexa Skill では、ユーザーから見ると「うまく反応しない」だけに見えることがあります。そのため、CloudWatch Logs で Lambda 側の挙動を確認し、Alexa 側の問題なのか、Lambda の実装問題なのか、外部 API の問題なのかを切り分けます。

## 通信の流れ

### 1. 音声入力を受け取る

ユーザーが Alexa に話しかけると、Alexa Skill 側で発話内容が処理されます。

~~~text
ユーザー
  ↓ 音声入力
Alexa Skill
~~~

### 2. Alexa Skill から Lambda を呼び出す

Alexa Skill では、エンドポイントとして Lambda 関数の ARN を指定できます。

通常の Web API では API Gateway を入口にすることがありますが、この構成では Alexa Skill から Lambda を直接呼び出します。

~~~text
Alexa Skill
  ↓ Lambda ARN
AWS Lambda
~~~

### 3. Lambda から外部 API を呼び出す

Lambda 側では、Open-Meteo API から自宅と勤務地の天気情報を取得します。

~~~text
AWS Lambda
  ↓ 外部 API 呼び出し
Open-Meteo API
  ↓ JSON レスポンス
AWS Lambda
~~~

### 4. 取得結果を読み上げ文に整形する

外部 API から返ってきたデータをそのまま Alexa に返すのではなく、Alexa が自然に読み上げられる文章に整形します。

~~~text
API レスポンス
  ↓
読み上げ文に整形
  ↓
Alexa 向けレスポンス
~~~

### 5. Alexa が音声で読み上げる

Lambda から Alexa 向けのレスポンスを返し、Alexa がユーザーへ音声で読み上げます。

~~~text
AWS Lambda
  ↓ レスポンス返却
Alexa Skill
  ↓
Alexa 端末が音声で読み上げ
~~~

## 複数 API 呼び出しと部分失敗

天気情報と遅延情報のように複数の外部 API を扱う場合、一部の API だけが失敗する可能性があります。

このプロジェクトでは、天気情報を朝レポートの本体、遅延情報を追加情報として扱う方針を検討しました。

~~~text
天気 API 成功
  ↓
遅延情報 API 失敗
  ↓
天気情報は返し、遅延情報だけ取得失敗として扱う
~~~

この考え方により、一部の外部 API が失敗しても、取得できた情報はユーザーへ返す構成にできます。

## エラー確認とログ

Alexa Skill の開発では、ユーザーから見ると「Alexa がうまく反応しない」だけに見えることがあります。

そのため、Lambda 側のログを CloudWatch Logs で確認し、以下を切り分けます。

- Alexa Skill から Lambda が呼ばれているか
- 外部 API 呼び出しに失敗していないか
- Lambda のレスポンス形式が Alexa の期待する形式になっているか
- 読み上げ文が生成されているか
- タイムアウトが発生していないか
- API の利用条件やプラン制約による失敗ではないか

## 遅延情報 API を調査止まりにした位置づけ

当初は、天気情報だけでなく鉄道の遅延情報も扱うことを検討しました。

ただし、遅延情報は天気情報と比べて個人開発で利用できる API が限られ、提供範囲や契約条件の制約が大きいことが分かりました。

そのため、遅延情報は実装完了扱いにはせず、以下を学習成果として整理しました。

- 遅延情報を追加する場合の構成方針
- 一部失敗時のフォールバック方針
- 外部 API の利用条件確認
- コードの問題と API 提供条件の問題の切り分け

## 関連ドキュメント

- [README](./README.md)
- [設計判断メモ](./design-decisions.md)
