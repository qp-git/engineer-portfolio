# Skill Map

このページは、各プロジェクトを通して扱った技術・学習領域を整理したものです。

単に使用技術を列挙するのではなく、「どのプロジェクトで、どの技術を、どのような目的で使ったか」が分かるように整理しています。

## AWS / Cloud

| 技術・サービス | 関連プロジェクト | 扱った内容 |
|---|---|---|
| AWS Lambda | [OdaiBox](./projects/odaibox/) / [Alexa Skill](./projects/alexa-skill/) / [Interview Knowledge Bridge](./projects/interview-knowledge-bridge/) | サーバーレス処理、外部サービス連携、APIバックエンド |
| API Gateway | [OdaiBox](./projects/odaibox/) / [Interview Knowledge Bridge](./projects/interview-knowledge-bridge/) | Discord・Custom GPT・管理画面からのHTTP入口 |
| DynamoDB | [OdaiBox](./projects/odaibox/) | サーバーごとのお題、履歴、一時ログイン情報の保存 |
| S3 | [OdaiBox](./projects/odaibox/) | 静的管理画面の配置 |
| CloudFront | [OdaiBox](./projects/odaibox/) | 管理画面の配信 |
| ECS / Fargate / ECS on EC2 | [STT + ECS](./projects/stt-ecs/) | コンテナ化したWebアプリの実行、タスク・サービス・配置の理解 |
| ALB | [STT + ECS](./projects/stt-ecs/) | Webアプリの入口、HTTPS、ヘルスチェック |
| Secrets Manager | [STT + ECS](./projects/stt-ecs/) | APIキーをコードに直書きしない構成の検討 |
| IAM | [Interview Knowledge Bridge](./projects/interview-knowledge-bridge/) | GitHub参照権限、APIキー、認証・認可の分離 |

## Server / Linux

| 技術・領域 | 関連プロジェクト | 扱った内容 |
|---|---|---|
| Linux | [STT + ECS](./projects/stt-ecs/) / dev-marathon / リプレイス演習 | サービス確認、ログ確認、ファイル配置、環境差分の確認 |
| Nginx | [STT + ECS](./projects/stt-ecs/) / dev-marathon | Web入口、リバースプロキシ、画面配信 |
| PM2 | dev-marathon | Node.js APIプロセスの起動・再起動・管理 |
| systemctl / journalctl | リプレイス演習 / 障害対応演習 | サービス状態確認、ログ確認 |
| cron | 障害対応演習 | 自動実行ジョブの整理、危険な自動化の見直し |

## Application / API

| 技術・領域 | 関連プロジェクト | 扱った内容 |
|---|---|---|
| Node.js | [Alexa Skill](./projects/alexa-skill/) / dev-marathon | Lambda実装、APIバックエンド |
| Python / Flask | [STT + ECS](./projects/stt-ecs/) | 音声ファイル受け取り、OpenAI API呼び出し、結果返却 |
| REST API | [Interview Knowledge Bridge](./projects/interview-knowledge-bridge/) / dev-marathon | 文書取得API、画面からのAPI呼び出し |
| OpenAPI schema | [Interview Knowledge Bridge](./projects/interview-knowledge-bridge/) | Custom GPT Actions用のAPI定義 |
| 外部API連携 | [Alexa Skill](./projects/alexa-skill/) / [STT + ECS](./projects/stt-ecs/) | 天気API、OpenAI API、交通系API調査 |

## Database

| 技術・DB | 関連プロジェクト | 扱った内容 |
|---|---|---|
| DynamoDB | [OdaiBox](./projects/odaibox/) | サーバー別データ、ユーザー履歴、一時ログイン情報 |
| PostgreSQL | dev-marathon / リプレイス演習 | APIからのDB接続、データ登録・取得、検証 |
| RDBの基本 | dev-marathon / DB案件学習 | テーブル、SQL、接続、件数確認、移行確認 |
| データ移行観点 | リプレイス演習 / DB案件学習 | バックアップ、リストア、件数確認、接続確認 |

## Test / Verification

| 技術・領域 | 関連プロジェクト | 扱った内容 |
|---|---|---|
| Playwright | dev-marathon | E2Eテスト、ブラウザ操作の自動確認 |
| Cypress | dev-marathon | 画面操作・API連携の検証 |
| 負荷試験 | dev-marathon | Playwrightを使った複数ユーザー相当の検証、負荷生成側の切り分け |
| curl | [Interview Knowledge Bridge](./projects/interview-knowledge-bridge/) / dev-marathon | API疎通確認、レスポンス確認 |
| CloudWatch Logs | [Alexa Skill](./projects/alexa-skill/) / [STT + ECS](./projects/stt-ecs/) | Lambdaやアプリのログ確認 |

## Network / Infrastructure

| 技術・領域 | 関連プロジェクト | 扱った内容 |
|---|---|---|
| VLAN / Trunk | 実機ネットワーク演習 | ネットワーク分離、複数VLANの通信 |
| HSRP | 実機ネットワーク演習 | デフォルトゲートウェイ冗長化、切替確認 |
| VPC / Subnet / Route Table | リプレイス演習 / AWS学習 | AWS上のネットワーク構成 |
| Security Group | 複数プロジェクト | 通信許可、疎通確認、ヘルスチェック許可 |
| Route 53 Health Check | 障害対応演習 | 外形監視、異常検知 |
| CloudWatch Alarm / SNS | 障害対応演習 | 監視通知、復旧後改善 |

## Security / Design

| 技術・観点 | 関連プロジェクト | 扱った内容 |
|---|---|---|
| Bearer認証 | [Interview Knowledge Bridge](./projects/interview-knowledge-bridge/) | Custom GPT ActionsからのAPI呼び出し認証 |
| Allowlist設計 | [Interview Knowledge Bridge](./projects/interview-knowledge-bridge/) | document_idで取得対象を制限 |
| 一時パスワード | [OdaiBox](./projects/odaibox/) | Discord権限確認後の管理画面ログイン |
| 保存情報の整理 | [OdaiBox](./projects/odaibox/) | ユーザーID、サーバーID、保存しない情報の明確化 |
| Privacy Policy | [OdaiBox](./projects/odaibox/) | 利用者向けに保存情報・用途を説明 |
| APIキー管理 | [Alexa Skill](./projects/alexa-skill/) / [STT + ECS](./projects/stt-ecs/) | 環境変数、Secrets Manager、漏えい防止 |

## AI / Automation

| 技術・領域 | 関連プロジェクト | 扱った内容 |
|---|---|---|
| Custom GPT Actions | [Interview Knowledge Bridge](./projects/interview-knowledge-bridge/) | GitHub上の許可済みMarkdown参照 |
| OpenAI API | [STT + ECS](./projects/stt-ecs/) | 音声文字起こし、要約 |
| STT | [STT + ECS](./projects/stt-ecs/) | 音声をテキスト化する処理 |
| GitHub Actions | [OdaiBox](./projects/odaibox/) / dev-marathon | デプロイ自動化、更新手順の整理 |

## プロジェクト別に見る

| プロジェクト | 主な学習領域 |
|---|---|
| [OdaiBox](./projects/odaibox/) | Lambda、DynamoDB、API Gateway、S3、CloudFront、Discord Bot、管理UI、認証設計、プライバシーポリシー |
| [STT + ECS](./projects/stt-ecs/) | Flask、OpenAI API、STT、Docker、ECS、ALB、HTTPS、Secrets Manager、タスク定義、ロールバック |
| [Alexa Skill](./projects/alexa-skill/) | Alexa Custom Skill、Lambda直接連携、音声UI向けレスポンス設計、外部API、CloudWatch Logs、部分失敗設計 |
| [Interview Knowledge Bridge](./projects/interview-knowledge-bridge/) | Custom GPT Actions、OpenAPI、API Gateway、Lambda、GitHub API、Bearer認証、Allowlist設計 |
| dev-marathon | Node.js、Nginx、PostgreSQL、Playwright、Cypress、PM2、E2Eテスト、負荷試験 |
| リプレイス演習 | Amazon Linux 2 から Amazon Linux 2023、ALB、Web/AP/DB、移行、検証、チームリーダー |
| 障害対応演習 | 障害切り分け、監視、Route 53 Health Check、CloudWatch Alarm、SNS、cron見直し |
| 実機ネットワーク演習 | Catalyst、VLAN、Trunk、HSRP、Ubuntu VM、Nginx、疎通確認 |
