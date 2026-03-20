#!/bin/bash
# install.sh
# immich Quadletファイルを ~/.config/containers/systemd/ に配置するスクリプト

set -e

DEST="$HOME/.config/containers/systemd"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SECRET="$DEST/immich-secret.env"

echo "=== Immich Quadlet インストーラー ==="
echo ""

# シークレットファイルの確認
if [ ! -f "$SECRET" ]; then
    cp "$SCRIPT_DIR/immich-secret.env.example" "$SECRET"
    chmod 600 "$SECRET"
    echo "immich-secret.env を作成しました。"
    echo "以下のファイルを編集してから再実行してください:"
    echo "  $SECRET"
    exit 1
fi

# シークレットの読み込み
source "$SECRET"

# 必須変数の確認
MISSING=0
for VAR in UPLOAD_LOCATION DB_DATA_LOCATION EXTERNAL_PATH DB_PASSWORD POSTGRES_PASSWORD; do
    if [ -z "${!VAR}" ]; then
        echo "エラー: $VAR が設定されていません。"
        MISSING=1
    fi
    if [ "${!VAR}" = "changeme" ]; then
        echo "エラー: $VAR が changeme のままです。"
        MISSING=1
    fi
done
if [ "$MISSING" -eq 1 ]; then
    echo "$SECRET を確認してください。"
    exit 1
fi

# ディレクトリの作成
echo "ディレクトリを作成しています..."
mkdir -p "$UPLOAD_LOCATION"
mkdir -p "$DB_DATA_LOCATION"
mkdir -p "$EXTERNAL_PATH"
mkdir -p "$DEST"

# テンプレートから .container ファイルを生成
echo "テンプレートからファイルを生成しています..."
for TEMPLATE in "$SCRIPT_DIR"/*.template; do
    DEST_FILE="$DEST/$(basename "${TEMPLATE%.template}")"
    sed \
        -e "s|__UPLOAD_LOCATION__|$UPLOAD_LOCATION|g" \
        -e "s|__DB_DATA_LOCATION__|$DB_DATA_LOCATION|g" \
        -e "s|__EXTERNAL_PATH__|$EXTERNAL_PATH|g" \
        -e "s|__DB_PASSWORD__|$DB_PASSWORD|g" \
        -e "s|__POSTGRES_PASSWORD__|$POSTGRES_PASSWORD|g" \
        "$TEMPLATE" > "$DEST_FILE"
    echo "  生成: $(basename "$DEST_FILE")"
done

# テンプレートなしのファイルをコピー
echo "ファイルをコピーしています..."
for FILE in immich.pod \
            immich-machine-learning.container \
            immich-redis.container \
            immich-model-cache.volume; do
    cp "$SCRIPT_DIR/$FILE" "$DEST/$FILE"
    echo "  コピー: $FILE"
done

# systemd に認識させる
systemctl --user daemon-reload

echo ""
echo "=== 完了 ==="
echo ""
echo "以下のコマンドで起動してください:"
echo "  systemctl --user start immich-pod.service"
echo ""
echo "起動確認:"
echo "  podman ps"
echo ""
echo "WebUI:"
echo "  http://$(hostname -I | awk '{print $1}'):2283"
