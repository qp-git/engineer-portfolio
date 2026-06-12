# OdaiBox 実装メモ

このドキュメントでは、OdaiBoxのLambda実装から代表的な処理を抜粋し、どのような役割を持っているかを整理します。

公開用のため、URL、ID、トークン、秘密値は掲載していません。コードは説明しやすいように一部整形しています。

## Lambdaで担当している主な処理

OdaiBoxのLambdaは、主に以下を担当します。

- Discord Interactionの受け取り
- Discord署名の検証
- `/odai` などのコマンド振り分け
- DynamoDBからのお題取得
- 重み付き抽選
- 直近のお題履歴を使った連続回避
- `/admin-login` による一時ログイン情報の発行
- 管理画面APIの認証確認
- お題の追加・ON/OFF更新

## 1. Discordからのリクエストを検証する

Discord Interactionを受け取るLambdaでは、Discordから送られた署名ヘッダーを検証しています。

```python
def verify_discord_request(event):
    if not DISCORD_PUBLIC_KEY:
        print("DISCORD_PUBLIC_KEY is not set")
        return False

    headers = event.get("headers") or {}
    lower_headers = {k.lower(): v for k, v in headers.items()}

    signature = lower_headers.get("x-signature-ed25519")
    timestamp = lower_headers.get("x-signature-timestamp")

    if not signature or not timestamp:
        print("missing discord signature headers")
        return False

    body_bytes = raw_body_bytes(event)

    try:
        verify_key = VerifyKey(bytes.fromhex(DISCORD_PUBLIC_KEY))
        verify_key.verify(
            timestamp.encode("utf-8") + body_bytes,
            bytes.fromhex(signature)
        )
        return True
    except BadSignatureError:
        print("bad discord signature")
        return False
```

ここでは、HTTPリクエストが本当にDiscordから送られたものかを確認しています。

## 2. コマンドごとに処理を振り分ける

Discordから受け取ったコマンド名に応じて、実行する処理を分けています。

```python
def handle_discord_interaction(event):
    if not verify_discord_request(event):
        return {
            "statusCode": 401,
            "body": "invalid request signature"
        }

    data = parse_body(event)

    if data.get("type") == 1:
        return discord_response({"type": 1})

    if data.get("type") == 2:
        command_name = data.get("data", {}).get("name")

        if command_name in ["odai", "challenge"]:
            return handle_odai_command(data, mode="mix")

        if command_name in ["odai-status", "challenge-status"]:
            return handle_odai_status_command(data)

        if command_name in ["admin-login", "admin-password"]:
            return handle_admin_password_command(data)

    return discord_ephemeral("未対応のコマンドです。")
```

Lambda内でコマンド名を見て、通常のお題抽選、ステータス確認、管理画面ログイン発行に振り分けています。

## 3. `/odai` のお題抽選

`/odai` では、Discordサーバー（コミュニティ）ごとの有効なお題を取得し、直近の履歴や重みを考慮して抽選しています。

```python
def handle_odai_command(data, mode="mix"):
    guild_id = data.get("guild_id")

    if not is_allowed_guild(guild_id):
        return discord_ephemeral("このサーバーではこのBotは利用できません。")

    default_items = get_enabled_default_challenges(guild_id, include_hidden=True)
    custom_items = get_enabled_challenges(guild_id)
    items = default_items + custom_items

    if not items:
        return discord_public("出題できるお題がありません。管理画面でお題をONにしてください。")

    # 24時間上限のあるお題を除外する
    daily_limited_items = filter_daily_limited_challenges(guild_id, items)
    if daily_limited_items:
        items = daily_limited_items

    # 直近20分に出たお題はできるだけ避ける
    recent_challenge_ids = get_recent_challenge_ids(
        guild_id,
        DUPLICATE_AVOID_SECONDS
    )

    non_duplicate_items = [
        item for item in items
        if item.get("challenge_id") not in recent_challenge_ids
    ]

    candidate_items = non_duplicate_items if non_duplicate_items else items
    selected_item = weighted_choice(candidate_items)

    user_id, username = get_interaction_user(data)
    save_draw_history(guild_id, user_id, username, selected_item)

    return discord_public(
        format_challenge_content(selected_item, mode, user_id, username)
    )
```

単純なランダム抽選ではなく、以下の条件を加えています。

- Discordサーバー（コミュニティ）ごとにお題を分ける
- 有効なお題だけを対象にする
- 直近20分に出たお題をできるだけ避ける
- 一部のお題は24時間あたりの出現回数を制限する
- weightによって出題されやすさを調整する

## 4. 重み付き抽選

お題には `weight` を持たせ、出題されやすさを調整できるようにしています。

```python
def weighted_choice(items):
    weighted_items = []
    total_weight = 0

    for item in items:
        try:
            weight = int(item.get("weight", 20))
        except Exception:
            weight = 20

        if weight <= 0:
            continue

        weighted_items.append((item, weight))
        total_weight += weight

    if not weighted_items:
        return random.choice(items) if items else None

    pick = random.randint(1, total_weight)
    current = 0

    for item, weight in weighted_items:
        current += weight
        if pick <= current:
            return item

    return weighted_items[-1][0]
```

デフォルトお題を多めに出し、レアお題を低確率で出す、といった調整に使っています。

## 5. 管理画面用の一時パスワードを発行する

`/admin-login` では、Discord側の権限確認後、一時パスワードを発行しています。

```python
def generate_admin_password(guild_id, guild_name, created_by):
    session_id = secrets.token_urlsafe(8)
    secret = secrets.token_urlsafe(18)
    password = f"{session_id}.{secret}"

    current_time = now_unix()
    expires_at_unix = current_time + ADMIN_PASSWORD_TTL_SECONDS

    item = {
        "session_id": session_id,
        "guild_id": guild_id,
        "guild_name": guild_name or "Discordサーバー",
        "password_hash": hash_secret(secret),
        "created_by": created_by or "unknown",
        "created_at": now_iso(),
        "expires_at_unix": expires_at_unix,
        "ttl": expires_at_unix,
    }

    admin_session_table.put_item(Item=item)

    return password, item
```

実際に保存するのはパスワードそのものではなく、ハッシュ化した値です。

## 6. 管理画面APIで一時ログイン情報を確認する

管理画面からお題を追加・更新するときは、HTTPヘッダーの一時パスワードを確認しています。

```python
def require_admin_session(event):
    password = get_admin_password_from_header(event)
    session = verify_admin_password(password)

    if not session:
        return None, api_response(401, {
            "message": "unauthorized"
        })

    return session, None
```

ログイン済みの管理者だけが、対象Discordサーバー（コミュニティ）のお題を変更できるようにしています。

## 7. 管理画面からお題を追加する

管理画面から登録されたお題は、DiscordサーバーIDと紐づけてDynamoDBに保存しています。

```python
def create_challenge(data, guild_id, created_by):
    title = data.get("title")

    if not guild_id or not title:
        return api_response(400, {"message": "title is required"})

    challenge_id = str(uuid.uuid4())
    timestamp = now_iso()

    item = {
        "guild_id": guild_id,
        "challenge_id": challenge_id,
        "type": "custom",
        "title": title,
        "description": data.get("description", ""),
        "category": data.get("category", "未分類"),
        "difficulty": int(data.get("difficulty", 1)),
        "weight": int(data.get("weight", 20)),
        "enabled": bool(data.get("enabled", True)),
        "created_by": created_by or "web",
        "created_at": timestamp,
        "updated_at": timestamp,
    }

    challenge_table.put_item(Item=item)

    return api_response(201, {
        "message": "created",
        "item": item
    })
```

お題はコード内固定ではなく、利用者がWeb管理画面から追加できるようにしています。

## 実装面で意識したこと

- Discordからのリクエストであることを署名で確認する
- Discordサーバー（コミュニティ）ごとにお題データを分ける
- 管理画面URLを知っているだけでは編集できないようにする
- 一時ログイン情報には有効期限を持たせる
- パスワードそのものではなくハッシュを保存する
- お題履歴にTTLを持たせ、必要以上に長く残さない
- 音声通話、チャット本文、DM、Discordパスワードは扱わない
