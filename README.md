# Engineer Portfolio

インフラエンジニア / クラウドエンジニアとしての研修・個人開発・検証内容を整理した公開用ポートフォリオです。

このリポジトリでは、コードや構築手順そのものだけでなく、**構成をどう考えたか、どのように切り分けたか、何を学んだか**を重視してまとめています。

## 目的

- 研修・個人開発で扱った技術内容を、後から説明できる形で整理する
- AWS / Linux / ネットワーク / CI/CD / 監視 / セキュリティ設計の学習成果を可視化する
- 面接や技術説明で、構成・設計判断・トラブル対応を具体的に説明できるようにする

## Projects

| Project | Summary | Main Skills |
|---|---|---|
| [OdaiBox](projects/odaibox/README.md) | Discordでゲーム用のお題を出すサーバーレスBot。非エンジニアでもWeb管理画面からカスタム可能にした。 | Lambda, API Gateway, DynamoDB, S3, CloudFront, IAM |
| [Amazon Linux 2023 Migration](projects/al2023-replace/README.md) | Amazon Linux 2からAmazon Linux 2023へのリプレイス演習。Web/AP/DB/DNS/ALBを含む構成を再構築。 | AL2023, Nginx, Tomcat, PostgreSQL, ALB, DNS |
| [dev-marathon](projects/dev-marathon/README.md) | 顧客情報管理Webアプリの構築・デプロイ・テスト。静的HTML、Node.js API、PostgreSQLを連携。 | Nginx, Node.js, PostgreSQL, PM2, GitHub Actions |
| [Physical Network Infrastructure](projects/nw-infra/README.md) | 実機スイッチとESXiを使った冗長ネットワーク構築。 | Cisco Catalyst, HSRP, VLAN, ESXi, NIC Teaming |
| [Incident Response Practice](projects/incident-response/README.md) | Web/AP/DB/DNS/ネットワークを対象にした障害切り分け演習。 | Linux, Nginx, Tomcat, PostgreSQL, DNS, Logs |
| [SQL Grading Load Test](projects/sql-grading-loadtest/README.md) | SQL採点サービスの負荷試験・監視観点整理。 | Playwright, CloudWatch, EC2, Nginx, PostgreSQL |

## What I focus on

- 通信経路を分解した原因切り分け
- サーバー・ミドルウェア・DB・ネットワークを横断した構成理解
- 必要最小限の権限設計と、公開情報/非公開情報の分離
- 利用者や運用者が扱いやすい形にするための設計判断
- 構築後のコスト・監視・再発防止まで含めた運用視点

## Public information policy

このリポジトリには、公開して問題ない粒度に抽象化した情報のみを掲載します。

- 実名入りスキルシート、メールアドレス、企業名、顧客名は掲載しません
- 認証情報、APIキー、秘密鍵、環境変数は掲載しません
- 面接練習ログ、弱点管理、採点結果などの非公開情報は別管理にします

詳しくは [Publication Guidelines](docs/publication-guidelines.md) を参照してください。
