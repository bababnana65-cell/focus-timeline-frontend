# Timeliness Backend

面向“事件时间轴”App 的后端起步工程。当前实现采用模块化单体：

- `FastAPI`
- `SQLAlchemy 2.0`
- 正式环境优先 `PostgreSQL`
- 本地开发默认允许用 `SQLite`

## 目录

- `app/main.py` 应用入口
- `app/config.py` 环境配置
- `app/database.py` 数据库连接与会话
- `app/models.py` SQLAlchemy 数据模型
- `app/schemas.py` API 请求/响应模型
- `app/services.py` 领域服务、鉴权、时间线聚合、种子数据
- `app/api.py` 路由定义

## 快速启动

```powershell
cd C:\Codex\Test\Timelinesss\backend
py -3 -m venv .venv
.venv\Scripts\Activate.ps1
pip install -e .
copy .env.example .env
uvicorn app.main:app --reload
```

默认配置会：

- 自动建表
- 在空库中写入一组标准专题与标准节点
- 演示同一 `EventNode` 关联多个 `Topic`

## 推荐环境变量

- `TIMELINESS_DATABASE_URL=postgresql+psycopg://user:password@localhost:5432/timeliness`
- `TIMELINESS_AUTO_CREATE_SCHEMA=true`
- `TIMELINESS_SEED_DEMO_DATA=true`

## 当前已实现的核心能力

- 手机号验证码登录骨架
- 会话鉴权
- 用户偏好、关注、置顶、浏览历史
- 标准专题和自建专题
- 标准节点和多专题关联
- 时间线查询与时间桶聚合
- 分享链接与快照分享
- 热门 / 随机 / 历史推荐

## 生产化下一步

- 接入真实短信服务
- 用 `Redis` 处理验证码、限流、热点缓存
- 接入 `Alembic` 管理迁移
- 增加后台审核与数据接入任务
