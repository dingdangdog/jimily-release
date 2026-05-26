#!/bin/bash
# 若从 Windows 复制导致 CRLF，首次运行会自动修复并重新执行
SCRIPT="$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")"
if grep -q $'\r' "$SCRIPT" 2>/dev/null; then
    sed -i 's/\r$//' "$SCRIPT"
    exec /bin/bash "$SCRIPT" "$@"
fi

set -eu

# 与 docker-compose.yml / docker-compose.yaml 放在同一目录即可，无需额外配置
DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="dingdangdog/jimily-release"
IMAGE_NAME="dingdangdog/jimily"
LOG_FILE="${DEPLOY_DIR}/update.log"

if [ -f "${DEPLOY_DIR}/docker-compose.yml" ]; then
    COMPOSE_FILE="${DEPLOY_DIR}/docker-compose.yml"
elif [ -f "${DEPLOY_DIR}/docker-compose.yaml" ]; then
    COMPOSE_FILE="${DEPLOY_DIR}/docker-compose.yaml"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 错误: 未找到 docker-compose.yml 或 docker-compose.yaml" >> "$LOG_FILE"
    exit 1
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

fetch_latest_release_tag() {
    curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
        | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
        | head -1
}

release_tag_to_image_tag() {
    local release_tag="$1"
    echo "${release_tag#v}"
}

get_image_line() {
    grep -E '^[[:space:]]*image:' "$COMPOSE_FILE" | head -1 | awk '{print $2}'
}

set_image_tag() {
    local image_name="$1"
    local new_tag="$2"
    sed -i -E "s|^([[:space:]]*image:[[:space:]]*)${image_name}:[^[:space:]]+|\1${image_name}:${new_tag}|" "$COMPOSE_FILE"
}

log "开始检查 Jimily 版本更新..."

LATEST_RELEASE_TAG="$(fetch_latest_release_tag)"
if [ -z "$LATEST_RELEASE_TAG" ]; then
    log "错误: 无法获取最新 Release，请检查 ${REPO} 是否已发布 Release 及网络。"
    exit 1
fi

if [[ ! "$LATEST_RELEASE_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log "错误: 最新 Release 标签格式无效: ${LATEST_RELEASE_TAG}（期望 vX.Y.Z，如 v5.1.4）"
    exit 1
fi

LATEST_IMAGE_TAG="$(release_tag_to_image_tag "$LATEST_RELEASE_TAG")"

IMAGE_LINE="$(get_image_line)"
if [ -z "$IMAGE_LINE" ]; then
    log "错误: 在 ${COMPOSE_FILE} 中未找到 image 行"
    exit 1
fi

COMPOSE_IMAGE_NAME="${IMAGE_LINE%%:*}"
CURRENT_IMAGE_TAG="${IMAGE_LINE##*:}"

if [ "$COMPOSE_IMAGE_NAME" != "$IMAGE_NAME" ]; then
    log "错误: compose 镜像应为 ${IMAGE_NAME}，当前为 ${COMPOSE_IMAGE_NAME}"
    exit 1
fi

if [ "$LATEST_IMAGE_TAG" = "$CURRENT_IMAGE_TAG" ]; then
    log "无更新: 当前版本 (${CURRENT_IMAGE_TAG}) 已是最新（Release ${LATEST_RELEASE_TAG}）。"
    exit 0
fi

log "发现新版本: ${LATEST_IMAGE_TAG}（Release ${LATEST_RELEASE_TAG}，当前: ${CURRENT_IMAGE_TAG}），开始更新..."
set_image_tag "$IMAGE_NAME" "$LATEST_IMAGE_TAG"

cd "$DEPLOY_DIR"
log "正在拉取镜像 ${IMAGE_NAME}:${LATEST_IMAGE_TAG} ..."
docker compose pull >> "$LOG_FILE" 2>&1

log "正在重启容器..."
docker compose up -d >> "$LOG_FILE" 2>&1

docker image prune -f >> /dev/null 2>&1
log "成功: 已升级至 ${LATEST_IMAGE_TAG}（Release ${LATEST_RELEASE_TAG}）"
