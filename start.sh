#!/bin/bash

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATE_SCRIPT="${DEPLOY_DIR}/update.sh"
SELF_SCRIPT="${DEPLOY_DIR}/start.sh"

# 去掉 Windows 复制带来的 CRLF（避免 update.sh 报 set: pipefail 等错误）
for f in "$SELF_SCRIPT" "$UPDATE_SCRIPT"; do
    [ -f "$f" ] && sed -i 's/\r$//' "$f" 2>/dev/null || true
done

echo "=========================================="
echo "       记米粒 Jimily 自动更新部署脚本       "
echo "=========================================="
echo "本目录应包含: docker-compose.yml（或 .yaml）、update.sh"
echo "镜像: dingdangdog/jimily"
echo "Release: https://github.com/dingdangdog/jimily-release/releases"
echo "=========================================="

if [ ! -f "$UPDATE_SCRIPT" ]; then
    echo "错误: 未找到 update.sh"
    exit 1
fi

if [ ! -f "${DEPLOY_DIR}/docker-compose.yml" ] && [ ! -f "${DEPLOY_DIR}/docker-compose.yaml" ]; then
    echo "错误: 未找到 docker-compose.yml / docker-compose.yaml"
    echo "可参考本仓库 README 中的 docker-compose 示例创建部署文件"
    exit 1
fi

chmod +x "$SELF_SCRIPT" "$UPDATE_SCRIPT"

echo "正在执行首次同步检查..."
bash "$UPDATE_SCRIPT"
echo "完成，请查看 ${DEPLOY_DIR}/update.log"

CRON_JOB="*/10 * * * * /bin/bash ${UPDATE_SCRIPT}"
if (crontab -l 2>/dev/null | grep -F "$UPDATE_SCRIPT") >/dev/null 2>&1; then
    echo "提示: 定时任务（每 10 分钟）已存在，跳过。"
else
    echo "正在写入 crontab（每 10 分钟轮询 GitHub Release）..."
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "定时任务已添加。"
fi

echo "=========================================="
echo "查看日志: tail -f ${DEPLOY_DIR}/update.log"
echo "=========================================="
