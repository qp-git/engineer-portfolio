# Interview Knowledge Bridge

Interview Knowledge Bridge は、KGPT（Custom GPT）からPrivate GitHubリポジトリ内の面接準備メモを安全に参照するための中継APIです。

## 構成

KGPT はPrivate GitHubリポジトリを直接参照せず、API Gateway と Lambda を経由して、許可済みのMarkdownのみ取得します。

```text
KGPT
  ↓ Bearer Auth
API Gateway
  ↓
Lambda
  ↓ GitHub API
GitHub Private Repository



使用技術
ChatGPT Custom GPT Actions
OpenAPI schema
Amazon API Gateway
AWS Lambda
GitHub REST API
GitHub fine-grained PAT
Markdown
Bearer認証
実装したこと
KGPT Actions からAPI Gateway経由でLambdaを呼び出す構成を作成
LambdaでBearer形式のBRIDGE_API_KEYを検証
LambdaからGitHub APIを利用してPrivate repositoryを参照
allowed-documents.json によるホワイトリスト制御を実装
document_id ベースで取得対象を制限し、任意パス指定を防止
学び

LambdaはGitHub PATを持つため、権限上はPrivate repository内のファイルを読むことができます。
そのため、API利用者へ何を返すかはLambda側の実装で制御する必要があります。

今回の構成では、allowed-documents.json に定義された document_id のみを取得対象とし、API利用者が任意のファイルパスを指定できないようにしました。

ただし、Lambdaコードに不備があると、PATの権限内で本来返すべきでないファイルを返してしまうリスクがあります。
そのため、任意パスを受け取らない設計、取得可能なディレクトリ制限、拡張子制限が重要だと学びました。

今後の改善案
GitHub PATをSecrets Managerへ移行
GitHub App方式への変更
CloudWatch Logsの整理
Public repository側のポートフォリオ情報も参照対象に追加
