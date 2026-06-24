# Design Decisions

## 位置づけ

この設計判断は、STT + ECS / Phase 1で構築したアプリを、より安全に更新し続けるためのPhase 2のCI/CD基盤移行に関するものです。

評価ポイントは、CodePipelineを使ったこと自体ではありません。

既存の本番経路を壊さず、新しいデプロイ経路を並行して構築し、検証、切替、Smoke Test、切り戻し可能性まで考慮した点が中核です。

## 1. 既存のGitHub Actions経路をすぐに削除しない

CI/CD基盤の移行は、アプリケーションの小規模修正よりも影響範囲が広くなります。

ECS Service、Task Definition、Target Group、ALB Listener、Security Group、Secrets Manager、IAM Roleが関係するため、既存のGitHub Actions側Serviceをすぐに削除せず、切り戻し可能な状態を残しました。

これにより、新しいCodePipeline側Serviceに問題があった場合でも、本番入口を既存Target Groupへ戻すことで復旧できる構成にしました。

## 2. ServiceとTarget Groupを分離する

Actions側ServiceとPipeline側Serviceを別Target Groupに分離しました。

同じTarget Groupに混在させると、どちらのデプロイ経路で起動したTaskに到達しているのか分かりにくくなります。

Target Groupを分離することで、Actions側とPipeline側を明確に切り分け、本番経路を維持したままPipeline側だけを検証できるようにしました。

## 3. 本番HTTPS:443は移行直前まで既存経路に維持する

本番入口であるHTTPS:443は、移行直前までActions側Target Groupへ向けたままにしました。

Pipeline側は、HTTP:81の一時的な検証用Listenerで確認しました。

これにより、ユーザー向けの入口を変えずに、Pipeline側のService、Task Definition、Secret注入、アプリ応答を確認できる状態を作りました。

## 4. 切替時にALB Fixed responseを利用する

切替時には、ALB Fixed responseで一時的なメンテナンス表示を行いました。

目的は、ユーザーが古い経路と新しい経路の中途半端な状態を見ることを避けるためです。

小規模な学習・検証環境であっても、切替中の状態を利用者にそのまま見せないことは、運用を意識した設計判断として重要だと考えました。

## 5. Deploy成功ではなくユーザー経路の成功を見る

CodePipelineのDeploy Actionが成功しても、ユーザーが実際に使う経路でアプリが動くとは限りません。

ALBの向き先、Target GroupのHealth Check、ECS Taskの起動、Secrets ManagerからのAPIキー注入、OpenAI API連携のどこかに問題があれば、ユーザー体験としては失敗になります。

そのため、切替後に本番URL経由でSmoke Testを実行し、ALB、ECS、Secrets Manager、OpenAI APIまで含めた経路で動作確認しました。

## 6. APIキー注入は値ではなく動作で確認する

OpenAI APIキーは、コードやDockerイメージに含めず、Secrets ManagerからECS Taskへ注入する構成にしました。

公開用の説明では、APIキーの値そのものを確認したとは表現しません。確認したのは、Secrets ManagerからECS TaskへSecretが注入され、その値を使ってアプリがOpenAI APIを呼び出せる状態になっていることです。

具体的には、切替後にCodeBuildからHTTPS本番URLへSmoke Testを実行し、STT APIが成功することを確認しました。

このSmoke Testが成功するためには、以下がすべて成立している必要があります。

- ALB HTTPS:443 がPipeline側Target Groupへ転送していること
- Target Groupに正常なECS Taskが登録されていること
- ECS Task上でFlaskアプリが起動していること
- Task Definition経由でSecrets Managerの値が環境変数として注入されていること
- アプリがそのAPIキーを使ってOpenAI APIへリクエストできること
- STT APIが期待した応答を返すこと

つまり、Smoke TestはAPIキーの値を直接確認するものではなく、Secret注入と外部API連携を含むユーザー経路の成立を確認するものです。

## 7. Smoke Test追加は切替後の運用品質改善として扱う

Smoke Testは、CI/CD基盤そのものの切替後にローリングデプロイで追加しました。

CI/CD基盤の切替は、ECS Service、Task Definition、Target Group、ALB Listener、Security Group、Secrets Managerなどが関係するため、段階移行で慎重に進めました。

一方で、Smoke Testは運用品質を高めるための追加機能であり、アプリ本体やユーザー向け経路の大幅な変更ではなかったため、ローリングデプロイで許容可能と判断しました。

## 8. 完全なBlue/Green構成にはしない

より厳密に分離する場合、CodeDeploy Blue/Green、別ALB構成、CodeBuildのVPC実行、NAT GatewayとElastic IPによる送信元固定なども考えられます。

ただし、今回の学習・検証環境では、構成複雑化とコスト増を避ける判断をしました。

完全なBlue/Green構成ほどの厳密性はありませんが、Target Group分離、一時的な検証用Listener、ALB Fixed response、本番URL Smoke Testを組み合わせることで、コストと作業量を抑えつつ、ユーザー影響と切り戻し可能性を考慮した移行を実現しました。

## まとめ

今回の判断は、CI/CDツールの置き換えではなく、既存の本番経路を守りながら新しい運用基盤へ移行するための設計判断です。

AI APIを利用するWebアプリでは、アプリ本体だけでなく、Secret管理、外部API連携、ALB経路、ECS Task、CI/CDの実行環境まで含めて確認する必要があります。

この移行を通して、ECS上のAIアプリを安全に更新し続けるためには、デプロイ成功だけでなく、ユーザー経路での動作確認と切り戻し可能性を設計に含めることが重要だと学びました。
