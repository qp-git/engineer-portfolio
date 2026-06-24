# Architecture

## 移行前

移行前は、GitHub Actionsによるデプロイ経路でECS Serviceを更新していました。

```text
User
  ↓ HTTPS:443
ALB
  ↓
Actions側 Target Group
  ↓
Actions側 ECS Service
  ↓
STT Flask App
事前検証時

CodePipeline側のECS Serviceを別に作成し、Actions側Serviceとは別のTarget Groupに紐づけました。

本番入口であるHTTPS:443は既存のActions側Target Groupへ向けたまま、HTTP:81の一時的な検証用ListenerをPipeline側Target Groupへ向けました。

User
  ↓ HTTPS:443
ALB
  ↓
Actions側 Target Group
  ↓
Actions側 ECS Service
Validation
  ↓ HTTP:81
ALB
  ↓
Pipeline側 Target Group
  ↓
Pipeline側 ECS Service
切替時

切替時はALB Fixed responseを利用して、一時的なメンテナンス表示を返しました。

その間に、HTTPS:443の転送先をActions側Target GroupからPipeline側Target Groupへ変更しました。

切替後
User
  ↓ HTTPS:443
ALB
  ↓
Pipeline側 Target Group
  ↓
Pipeline側 ECS Service
  ↓
STT Flask App
  ↓
OpenAI API

切替後は、HTTPS本番URL経由でSmoke Testを実行し、ALB、ECS、Secrets Manager、OpenAI APIまで含めたユーザー経路で動作確認しました。

補足

この構成は、CodeDeployを使った厳密なBlue/Green Deployではありません。

学習・検証環境として、Target Group分離、一時的な検証用Listener、ALB Fixed response、本番URL Smoke Testを組み合わせた段階移行です。
