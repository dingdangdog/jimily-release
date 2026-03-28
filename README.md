<div align="center" style="display:flex;align-items:center;justify-content:center;">
<img src="/public/logo.webp" width="80px" alt="Jimily" />
<h1>Jimily / 记米粒</h1>
</div>

<p align="center">
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

- docker-compose.yaml

```yaml
services:
  main:
    container_name: jimily
    image: dingdangdog/jimily:5.1.2
    restart: always
    # network_mode: "host"
    volumes:
      - ./data:/app/data # 数据挂载到本地
    environment:
      DATABASE_URL: "postgresql://postgres:123456@localhost:5432/jimily?schema=public" # 数据库链接，【账号密码请自行修改，与你的数据库一致！】
      NUXT_DATA_PATH: "/app/data" # 数据存储位置，不懂不要改，现在只有小票图片
      NUXT_AUTH_SECRET: "demo2026" # 前台登录加密使用的密钥 【自行修改！】
    ports:
      - 9090:9090
```
