<div align="center" style="display:flex;align-items:center;justify-content:center;">
<img src="/public/logo.webp" width="80px" alt="Jimily" />
<h1>Jimily / 记米粒</h1>
</div>

<p align="center">
  <img alt="release" src="https://img.shields.io/github/v/release/dingdangdog/jimily-release" />
  <img alt="Docker Pulls" src="https://img.shields.io/docker/pulls/dingdangdog/jimily.svg" />
</p>

- 在线体验：[jimily.oldmoon.top](https://jimily.oldmoon.top/) (体验账号: `jimilydemo`/`jimily2026`)
- QQ交流群：`564081656`

## 简述（Description）

记米粒是支持 AI 助手 Jimi 的个人记账本。

- 在数据记录上追求简单、易用、自主可控；
- 在统计分析上力求清晰、美观、简洁有效。

**重要提示：如果需要部署到公网，请自行修改各类环境变量！！！**  

### 为什么直接就是V5？

早期项目名为`Cashbook`，增加AI功能后，独立建设并改名为`Jimily`，并继续沿用版本号。Cashbook已经更新至 V4，所以Jimily的首个版本从V5开始。

## 部署（docker-compose）

请自行准备Postgre数据库，建议17版本！

一个简单的部署教程：https://www.lodenhu.com/post/cashbook-5-beta-ai-version-deployment-tutorial

**服务器需能正常访问 [Docker Hub](https://hub.docker.com/)**，镜像托管于 `dingdangdog/jimily`。若无法连通 Docker Hub，`docker compose pull` 会失败，容器无法正确下载与启动。国内服务器若拉取缓慢或超时，请自行配置镜像加速、代理，或先在可访问 Docker Hub 的环境下载镜像后再导入部署机。

- docker-compose.yaml

```yaml
services:
  main:
    container_name: jimily
    image: dingdangdog/jimily:5.1.3
    restart: always
    # network_mode: "host"
    volumes:
      - ./data:/app/data # 数据挂载到本地
    environment:
      DATABASE_URL: "postgresql://postgres:123456@localhost:5432/jimily?schema=public" # 数据库链接，【账号密码请自行修改，与你的数据库一致！】
      # NUXT_DATA_PATH: "/app/data" # 数据存储位置，现在只有小票图片，没有特别的需求不建议修改，因为与数据卷配置需要同步修改
      NUXT_AUTH_SECRET: "demo2026" # 前台登录加密使用的密钥 【自行修改！】
      NUXT_ENV: "development" # 如果使用公网+域名部署，建议改为 production，修改为 production 后只能通过 https 登录
    ports:
      - 9090:9090

```

## 自动更新脚本（可选）

本仓库提供 `start.sh`、`update.sh`，用于在 Linux 服务器上**可选地**轮询 [GitHub Releases](https://github.com/dingdangdog/jimily-release/releases)，发现新版本后自动更新 `docker-compose.yaml` 中的镜像版本并重启容器。**不使用脚本、手动部署完全没问题。**

### 前提

- Linux 服务器（依赖 bash、cron、curl、GNU sed）
- 已安装 Docker 与 Docker Compose V2（`docker compose`）
- 能访问 [Docker Hub](https://hub.docker.com/)（拉取镜像）
- 能访问 [GitHub](https://github.com/)（查询 Release 版本）

### 用法

将 `start.sh`、`update.sh` 与你的 `docker-compose.yaml` 放在**同一目录**（示例 `/opt/jimily`）。

> **重要：请自行在 compose 的 `image` 中写死当前部署的版本号，不要使用 `latest`。**  
> 打开 [Releases](https://github.com/dingdangdog/jimily-release/releases) 查看版本，标签 `v5.1.6` 对应镜像 `dingdangdog/jimily:5.1.6`（去掉前缀 `v`）。镜像名必须为 `dingdangdog/jimily`。

从 Windows 复制脚本到 Linux 后若执行报错，可先运行 `sed -i 's/\r$//' start.sh update.sh`；脚本首次运行也会尝试自动去除 CRLF。

```bash
cd /opt/jimily
chmod +x start.sh update.sh
./start.sh
```

`start.sh` 会立即执行一次 `update.sh`，并向 crontab 注册定时任务（每 10 分钟检查一次）。

手动检查更新：

```bash
./update.sh
```

查看日志：

```bash
tail -f update.log
```

取消自动更新：编辑 crontab（`crontab -e`），删除包含 `update.sh` 的那一行。
