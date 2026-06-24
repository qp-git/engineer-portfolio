# Design Decisions

## 1. 既存のGitHub Actions経路をすぐに削除しない

CI/CD基盤の移行は、アプリケーションの小規模修正よりも影響範囲が広いため、既存のGitHub Actions側Serviceをすぐに削除しませんでした。

新しいCodePipeline側Serviceを別に作成し、切替前に疎通確認できる状態を作りました。

## 2. ServiceとTarget Groupを分離する

Actions側ServiceとPipeline側Serviceを別Target Groupに分離しました。

これにより、本番入口を既存経路に維持したまま、新しいPipeline側経路を別Listenerで確認できるようにしました。

## 3. 本番HTTPS:443は移行直前まで既存経路に維持する

本番入口であるHTTPS:443は、移行直前までActions側Target Groupへ向けたままにしました。

Pipeline側はHTTP:81の一時的な検証用Listenerで確認し、ユーザー影響を抑えながら新経路を検証しました。

## 4. 切替時にALB Fixed responseを利用する

切替中にユーザーが古い経路と新しい経路の中途半端な状態を見ることを避けるため、ALB Fixed responseで一時的なメンテナンス表示を行いました。

そのうえで、HTTPS:443の転送先をPipeline側Target Groupへ切り替えました。

## 5. Smoke Testは切替後に追加する

Smoke Testは、CI/CD基盤そのものの切替後にローリングデプロイで追加しました。

CI/CD基盤の切替は、ECS Service、Task Definition、Target Group、ALB Listener、Security Group、Secrets Managerなどが関係するため、段階移行で慎重に進めました。

一方で、Smoke Testは運用品質を高めるための追加機能であり、アプリ本体やユーザー向け経路の大幅な変更ではなかったため、ローリングデプロイで許容可能と判断しました。

## 6. 完全なBlue/Green構成にはしない

より厳密に分離する場合、CodeDeploy Blue/Green、別ALB構成、CodeBuildのVPC実行、NAT GatewayとElastic IPによる送信元固定なども考えられます。

ただし、今回の学習・検証環境では、構成複雑化とコスト増を避けるため、Target Group分離と一時的な検証用Listenerによる段階移行を採用しました。

## まとめ

完全なBlue/Green構成ほどの厳密性はありませんが、コストと作業量を抑えつつ、ユーザー影響を限定し、切り戻し可能なCI/CD移行を実現しました。
