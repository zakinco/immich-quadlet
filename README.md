# immich-quadlet

[Immich](https://immich.app/) を [Podman Quadlet](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html) で動かすための設定ファイル集です。

## ファイル構成

| ファイル | 役割 |
|---|---|
| `immich.pod` | Pod定義（ポート公開） |
| `immich-server.container.template` | Immichメインサーバー（テンプレート） |
| `immich-machine-learning.container` | 機械学習サービス |
| `immich-redis.container` | Valkey (Redis互換) キャッシュ |
| `immich-database.container.template` | PostgreSQL + VectorChord（テンプレート） |
| `immich-model-cache.volume` | MLモデルキャッシュ用ボリューム |
| `immich-secret.env.example` | シークレットファイルのサンプル |
| `install.sh` | インストールスクリプト |

## セットアップ手順

### 1. リポジトリのクローン

```bash
git clone https://github.com/yourname/immich-quadlet.git
cd immich-quadlet
```

### 2. シークレットファイルの作成

```bash
cp immich-secret.env.example ~/.config/containers/systemd/immich-secret.env
chmod 600 ~/.config/containers/systemd/immich-secret.env
nano ~/.config/containers/systemd/immich-secret.env
```

以下の項目を編集してください：

| 項目 | 説明 |
|---|---|
| `UPLOAD_LOCATION` | 写真の保存先（絶対パス） |
| `DB_DATA_LOCATION` | PostgreSQLデータの保存先（絶対パス） |
| `EXTERNAL_PATH` | 外部ライブラリのパス（絶対パス） |
| `DB_PASSWORD` | データベースパスワード |
| `POSTGRES_PASSWORD` | データベースパスワード（DB_PASSWORDと同じ値） |

### 3. インストール

```bash
bash install.sh
```

### 4. 起動

```bash
systemctl --user start immich-pod.service
```

### 5. 動作確認

```bash
podman ps
```

ブラウザで `http://[ホストのIPアドレス]:2283` にアクセスしてください。

---

## 運用手順

### 起動

```bash
systemctl --user start immich-pod.service
```

### 停止

```bash
systemctl --user stop immich-pod.service
```

### 再起動

```bash
systemctl --user restart immich-pod.service
```

### 設定変更後の再起動

```bash
systemctl --user daemon-reload
systemctl --user restart immich-pod.service
```

### ログ確認

```bash
journalctl --user -u immich-server.service -f
podman logs immich_server
```

---

## アップデート手順

```bash
podman pull ghcr.io/immich-app/immich-server:release
podman pull ghcr.io/immich-app/immich-machine-learning:release
systemctl --user restart immich-pod.service
```

---

## 完全初期化手順

**⚠️ 写真・データベースが完全に削除されます。必ずバックアップを取ってから実行してください。**

```bash
# 停止
systemctl --user stop immich-pod.service

# libraryの削除
rm -rf $UPLOAD_LOCATION/*

# postgresの削除（フォルダごと削除して再作成）
sudo rm -rf $DB_DATA_LOCATION
mkdir $DB_DATA_LOCATION

# 再起動
systemctl --user start immich-pod.service
```

---

## 注意事項

- `immich-secret.env` は `.gitignore` に含まれており、GitHubには公開されません
- `DB_PASSWORD` と `POSTGRES_PASSWORD` は必ず同じ値にしてください
- `DB_DATA_LOCATION` にネットワーク共有（NFS等）は使用できません
- Podman 6.0.0-dev用です。
