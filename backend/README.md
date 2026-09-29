# 项目任务看板后端

这是 MVP 的 Spring Boot 后端骨架，包含 PostgreSQL 连接和 Flyway 初始迁移。业务服务与 HTTP API 尚未实现。

## 环境

- Java 21、Maven 3.6.3 或更高版本
- PostgreSQL 16；可使用 Docker Compose 启动本地实例

默认数据库为 jdbc:postgresql://127.0.0.1:5432/task_board，用户名和密码均为 task_board。可通过 DB_URL、DB_USERNAME、DB_PASSWORD 覆盖。服务仅监听 127.0.0.1，端口默认 8080，可通过 SERVER_PORT 覆盖。Compose 中的固定密码仅用于本地开发。

## 启动

在 backend/ 下运行：

    docker compose up -d postgres
    mvn spring-boot:run

应用启动时 Flyway 自动执行 src/main/resources/db/migration/ 中的迁移。初始迁移创建项目、列、任务表及关联约束；建项目时自动创建三列的逻辑属于后续领域服务任务。

构建检查：mvn test。当前无业务测试，构建通过仅证明骨架可编译。
