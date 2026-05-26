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

请自行准备 Postgre 数据库，建议 17 版本。

一个简单的部署教程：https://www.lodenhu.com/post/cashbook-5-beta-ai-version-deployment-tutorial

### 环境要求

- Linux 服务器（脚本依赖 bash、cron、curl、GNU sed）
- 已安装 [Docker](https://docs.docker.com/engine/install/) 与 [Docker Compose V2](https://docs.docker.com/compose/install/)（命令为 `docker compose`）
- **服务器需能正常访问 [Docker Hub](https://hub.docker.com/)**（镜像托管于 `dingdangdog/jimily`）。若网络无法连通 Docker Hub，`docker compose pull` 会失败，容器将无法启动或升级。国内服务器若拉取缓慢或超时，请自行配置镜像加速、代理，或先在可访问 Docker Hub 的环境下载镜像后再导入部署机
- 使用自动更新脚本时，还需能访问 [GitHub](https://github.com/)（用于查询 Release 版本）

### 第一步：准备部署目录

在服务器上创建目录（示例 `/opt/jimily`），将以下文件放在**同一目录**：

| 文件 | 说明 |
|------|------|
| `docker-compose.yaml` | 服务定义（见下方示例，**需自行创建并修改**） |
| `start.sh` | 首次启动与注册定时更新（本仓库根目录） |
| `update.sh` | 检查 GitHub Release 并拉取新镜像（本仓库根目录） |

从 Windows 复制脚本到 Linux 后，若执行报错，可先运行 `sed -i 's/\r$//' start.sh update.sh`；脚本也会在首次运行时尝试自动去除 CRLF。

### 第二步：编写 docker-compose.yaml（务必固定版本号）

> **重要：请自行在 `image` 中写死你要部署的版本号，不要使用 `latest`！**
>
> 1. 打开 [Releases](https://github.com/dingdangdog/jimily-release/releases) 查看目标版本（标签形如 `v5.1.6`）
> 2. 将下方示例中的 `5.1.6` 改为你选定的版本（去掉前缀 `v`，即 `v5.1.6` → `5.1.6`）
> 3. 修改数据库连接、密钥等环境变量

```yaml
services:
  main:
    container_name: jimily
    image: dingdangdog/jimily:5.1.6   # ← 请改为你需要的固定版本号，勿用 latest
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

### 方式 A：手动部署（不自动更新）

```bash
cd /opt/jimily
docker compose pull
docker compose up -d
```

升级时：修改 `docker-compose.yaml` 中的版本号 → 再次执行 `docker compose pull && docker compose up -d`。

### 方式 B：自动检查更新（推荐）

`update.sh` 会轮询 [jimily-release Releases](https://github.com/dingdangdog/jimily-release/releases)，当 GitHub 最新 Release 高于 compose 中当前版本时，自动改写 `image` 标签、拉取镜像并重启容器。

```bash
cd /opt/jimily
chmod +x start.sh update.sh
./start.sh
```

`start.sh` 会：

1. 立即执行一次 `update.sh` 检查更新
2. 向 crontab 注册定时任务（**每 10 分钟**执行一次 `update.sh`）

手动触发一次更新检查：

```bash
./update.sh
```

查看更新日志：

```bash
tail -f update.log
```

取消自动更新：编辑 crontab（`crontab -e`），删除包含 `update.sh` 的那一行。

### 版本与镜像对应关系

| GitHub Release 标签 | Docker 镜像 tag | compose 中写法 |
|---------------------|-----------------|----------------|
| `v5.1.6`            | `5.1.6`         | `dingdangdog/jimily:5.1.6` |

自动更新脚本要求 Release 标签格式为 `vX.Y.Z`（如 `v5.1.4`），且 compose 中镜像名必须为 `dingdangdog/jimily`。
