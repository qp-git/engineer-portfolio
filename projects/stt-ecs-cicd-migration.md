# STT WebアプリのCI/CD基盤移行

## 概要

Flask製の音声文字起こしWebアプリについて、既存のGitHub ActionsによるECSデプロイ経路を維持したまま、AWS CodePipeline / CodeBuildによる新しいCI/CD経路を構築しました。

移行では、Actions側ServiceとPipeline側Serviceを別Target Groupに分離し、本番入口であるHTTPS:443は既存経路に維持したまま、HTTP:81の一時的な検証用ListenerでPipeline側を事前確認しました。

切替時にはALB Fixed responseでメンテナンス表示を行い、HTTPS:443の向き先をPipeline側Target Groupへ変更しました。切替後はHTTPS本番URL経由でSmoke Testを実行し、ALB、ECS、Secrets Manager、OpenAI APIまで含めたユーザー経路で動作確認しました。

## 設計判断

今回のCI/CD移行では、GitHub ActionsからCodePipelineへ単純にデプロイ手段を置き換えるのではなく、ユーザー影響と切り戻し可能性を考慮して段階的な移行方式を採用しました。

完全なBlue/Green構成や別ALB構成ほど厳密ではありませんが、学習・検証環境としてコストと構成複雑性を抑えつつ、ユーザー影響を限定し、切り戻し可能な移行方式を選択しました。

## 実施したこと

- GitHub Actions側ServiceとCodePipeline側Serviceを別Target Groupで分離
- 本番入口のHTTPS:443は移行直前までActions側に維持
- HTTP:81の一時的な検証用ListenerでPipeline側を事前確認
- 切替時にALB Fixed responseでメンテナンス表示を実施
- HTTPS:443の向き先をPipeline側Target Groupへ切替
- 切替後にHTTPS本番URLでSmoke Testを実行
- 移行完了後にHTTP:81の一時Listenerを閉鎖

## 学び

- CI/CD基盤の移行では、デプロイ手段だけでなく、ECS Service、Task Definition、Target Group、ALB Listener、Security Group、Secrets Managerまで含めて影響範囲を考える必要がある
- Deploy成功だけではなく、ユーザー経路でアプリ・Secret注入・外部API連携まで確認することが重要
- 学習・検証環境では、コストと構成複雑性を抑えながら、どこまで安全性を確保するかの判断が重要
