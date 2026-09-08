# 后端 Spring Boot 升级与 MyBatis-Plus 适配调研报告

| 项目 | 内容 |
|---|---|
| 文档名称 | 协流 Agile 后端 Spring Boot 版本升级与 MyBatis-Plus 适配调研(2026-08-25) |
| 版本 / 日期 | v1.0 / 2026-08-25 |
| 状态 | 调研结论(已实施:后端升级 Boot 4.1.1,见 §4) |
| 上游文档 | 《协流Agile_MVP开发文档_v1.0.md》§2.3 技术选型建议;《2026-08-25_前端技术栈选型调研.md》§1 |
| 调研方式 | 官方 wiki(Supported Versions / 4.1 Release Notes / System Requirements)+ GitHub Releases + 官方 Issue + Maven Central 版本实测核验 |
| 适用读者 | 后端、前端、DevOps、架构评审 |

---

## 0. 结论速览

**Spring Boot 从 3.3.13 升级到 4.1.1(Java 17 → 21),`spring-boot-starter-web` 换名为 `spring-boot-starter-webmvc`;MyBatis-Plus 已适配 Boot 4,后续持久层用 `mybatis-plus-spring-boot4-starter:3.5.17`(分页另加 `mybatis-plus-jsqlparser:3.5.17`)。**

一句话:**当前 pom 实际版本是 3.3.13(3.3 线最后一个补丁,OSS 已于 2025-06-30 停止维护),而 3.x 全线在 2026-06-30 已 OSS EOL;项目为纯脚手架、迁移成本趋零,直接上当前唯一"最新 GA + 长支持窗口"的 4.1.1。**

| 领域 | 决策 | 实测版本(2026-08-25 Maven Central 核验) | 一句话理由 |
|---|---|---|---|
| 框架版本 | Spring Boot **4.1.1**(parent) | 4.1.1(2026-08-20 发布) | 最新稳定 GA,OSS 支持至 2027-07-31;4.0.8 仅剩 ~4 个月支持期;4.2.0-M1 为里程碑勿用 |
| 语言 | Java **21** | 本机 21.0.8 Temurin | Boot 4.1 支持 17~26;21 为 LTS 且与本机/CI 工具链一致 |
| Web starter | `spring-boot-starter-web` → **`spring-boot-starter-webmvc`** | 4.1.1 | Boot 4 中旧 web starter 已弃用,官方改名 |
| ORM(后续) | MyBatis-Plus **3.5.17**(boot4 starter) | mybatis-plus-spring-boot4-starter 3.5.17 | 3.5.13 起支持 Boot 4;3.5.16 起内置 mybatis-spring 4.0.0,修复已知启动报错 |
| 分页(后续) | `mybatis-plus-jsqlparser` | 3.5.17 | 3.5.9 起分页依赖与主包拆分,需显式引入 |

---

## 1. 背景与现状

- **产品形态**:类 Jira/Linear 敏捷项目管理 SaaS(协流 Agile),模块化单体:后端 REST `/api/v1` + SSE,PostgreSQL(jsonb)+ Outbox 模式(见上游文档);
- **当前 pom 事实**:`spring-boot-starter-parent:3.3.13`(不是 3.2.2;3.2.2 为 2024-02 补丁版,3.3.13 是 3.3 线最后补丁,2025-06-19 发布),Java 17,依赖仅 web/actuator/validation/test 四个 starter —— **业务代码为零,纯脚手架**;
- **3.2.2 的历史合理性**:若脚手架生成于 2024 年初,3.2.x 是 Java 17 基线后的稳定线、中文生态资料最全,属当时合理默认;但该线 OSS 支持已于 2024-12-31 结束,现状不再成立;
- **触发点**:Initializr 官方页面已提供 4.2.0(M1/SNAPSHOT)、4.1.1、4.0.8 等选项,需要确定新项目基线。

## 2. Spring Boot 版本调研(2026-08-25)

### 2.1 官方支持策略

- 主版本从发布日起 OSS 支持 ≥3 年(必须运行受支持的次版本);次版本 OSS 支持 ≥12 个月(官方 wiki:Supported Versions);
- 官方建议:尽量迁移到"当前最新受支持版本"。

### 2.2 各版本支持现状

| 版本线 | 发布 | OSS 维护截止 | 最后补丁 | 2026-08 状态 |
|---|---|---|---|---|
| 3.2.x | 2023-11 | 2024-12-31 | 3.2.12 | ❌ EOL |
| 3.3.x | 2024-05 | 2025-06-30 | 3.3.13(当前 pom) | ❌ EOL |
| 3.4.x | 2024-11 | 2025-12-31 | 3.4.13 | ❌ EOL |
| 3.5.x | 2025-05 | 2026-06-30 | 3.5.16 | ❌ 刚 EOL |
| **4.0.x** | 2025-11 | **2026-12-31** | 4.0.8(2026-08-20) | ⚠️ 仅剩 4 个月 |
| **4.1.x** | 2026-06 | **2027-07-31** | **4.1.1(2026-08-20)** | ✅ 当前最新 GA |
| 4.2.0-M1 | 开发中 | — | — | ⚠️ 里程碑,勿用于生产 |

### 2.3 升级到 4.1.1 的兼容性要点(官方 System Requirements / 4.1 Release Notes)

- **Java**:要求 ≥17,兼容至 Java 26(上限);内部使用 Spring Framework **7.0.9**;
- **构建**:Maven ≥3.6.3(本机 3.9.11 ✓)、Gradle 8.14+/9.x;
- **Servlet**:Servlet 6.1,内嵌 Tomcat **11.0.x** / Jetty 12.1.x;
- **技术栈底座**:Jakarta EE 11、Jackson **3**(BOOT 4 默认使用 Jackson 3.x);
- **starter 调整**:`spring-boot-starter-web` 已弃用,官方新名为 `spring-boot-starter-webmvc`;
- **官方迁移路径**:存量项目建议 3.5 → 4.0 → 4.1 逐级迁移;本项目为零业务脚手架,直升 4.1.1 成本仅改 poc 配置。

### 2.4 Initializr 选项的取舍

| 选项 | 结论 |
|---|---|
| 4.2.0 (SNAPSHOT / M1) | 开发中版本,不稳定,不选 |
| 4.1.1 | ✅ 唯一推荐:最新 GA + OSS 支持至 2027-07-31 |
| 4.0.8 | 可用但 2026-12-31 即 EOL,新项目不值得 |
| 3.5.16(3.x 最后补丁) | OSS 已 EOL;仅在第三方生态未适配 Boot 4 时作为过渡兜底 |

---

## 3. MyBatis-Plus 对 Spring Boot 4 的适配调研

### 3.1 结论:已正式适配,当前版本 3.5.17

| 版本 | 日期 | 关键内容 |
|---|---|---|
| 3.5.13 | 2025-08-28 | 首次新增 spring-boot4 支持(`mybatis-plus-spring-boot4-starter` 诞生) |
| 3.5.14 | 2025-08-29 | BOM 统一管理 boot4 starter 及 test starter |
| 3.5.15 | 2025-11-30 | 官方声明"支持 SpringBoot 4.0.0",支持 Jackson 3.0 |
| 3.5.16 | 2026-01-11 | **mybatis-spring 升级至 4.0.0**(关键修复,见 3.2);spring-boot3 升 3.5.9 |
| **3.5.17** | **2026-07-08** | **当前最新**,官方文档推荐版本(含 mybatis-plus-spring 模块包名调整等) |

### 3.2 已知坑与修复(官方 Issue #7009)

- **现象**:Spring Boot 4.0.1 + MyBatis-Plus 3.5.15,启动失败:`Invalid value type for attribute 'factoryBeanObjectType': java.lang.String`;
- **根因**:mybatis-spring 3.x 与 Spring Framework 7(及 6.1+)不兼容,BeanDefinition 解析器拒绝 String 形态的 `factoryBeanObjectType`;
- **修复**:mybatis-spring 官方 **4.0.0**(支持 Spring Framework 7 / Spring Batch 6),MyBatis-Plus **3.5.16 起内置**;
- **结论**:使用 ≥3.5.16 即无此问题,推荐直接 3.5.17。

### 3.3 正确用法(官方 Install 文档)

- Boot 4 必须用独立 artifact:`com.baomidou:mybatis-plus-spring-boot4-starter:3.5.17`(与 Boot 3 的 `mybatis-plus-spring-boot3-starter` 是两个独立坐标,不可混用;旧 `mybatis-plus-boot-starter` 只支持 Boot 2);
- **分页插件**:3.5.9 起 jsqlparser 相关依赖从主包拆分,使用 `PaginationInnerInterceptor` 需显式引入 `mybatis-plus-jsqlparser`(版本与 MP 主线一致,3.5.17);
- **Jackson 3**:3.5.15+ 已支持;3.5.16 修复 `Jackson3TypeHandler` 自定义 ObjectMapper 的问题;
- 注意:boot4-starter 主要针对 Boot 4.0.x 构建验证;截至本调研日,官方无 Boot 4.1 相关排障报告,集成后以启动冒烟验证为准。

---

## 4. 实施变更(2026-08-25 已落地)

### 4.1 pom.xml 变更

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>4.1.1</version>          <!-- 3.3.13 → 4.1.1 -->
    <relativePath/>
</parent>

<properties>
    <java.version>21</java.version>   <!-- 17 → 21(本机/CI JDK 21) -->
</properties>

<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-webmvc</artifactId>  <!-- 原 spring-boot-starter-web -->
</dependency>
```

其余(actuator / validation / test / maven-plugin)坐标不变,`application.yml` 无需调整(management endpoints 配置在 Boot 4 兼容)。

### 4.2 后续持久层引入模板(待 DB 相关任务时启用)

```xml
<dependency>
    <groupId>com.baomidou</groupId>
    <artifactId>mybatis-plus-spring-boot4-starter</artifactId>
    <version>3.5.17</version>
</dependency>
<!-- 使用分页插件时追加 -->
<dependency>
    <groupId>com.baomidou</groupId>
    <artifactId>mybatis-plus-jsqlparser</artifactId>
    <version>3.5.17</version>
</dependency>
```

## 5. 风险清单与应对

| # | 风险 | 概率 | 影响 | 应对 |
|---|---|---|---|---|
| R-1 | Boot 4 生态变化(Jackson 3、Jakarta EE 11、Servlet 6.1/Tomcat 11)影响第三方库 | 中 | 中 | 逐库核验;MyBatis-Plus 已确认(3.5.17);Flyway/其他库引入前复查;关键依赖以 Maven Central + 官方 release notes 为准 |
| R-2 | 4.1.x 是相对较新的 GA 线,潜在补丁级回归 | 低 | 低 | 跟随官方补丁流(4.1.2 即将发布,按需升级);集成期以冒烟测试 + `spring-boot-starter-test` 兜底 |
| R-3 | 迁移路径(3.5→4.0→4.1)被跳级 | 低 | 低 | 本项目无业务代码,跳级成本 ≈0;若非空项目再走官方逐级迁移 |
| R-4 | boot4-starter 仅对 4.0.x 明确验证 | 低 | 低 | W1 启动冒烟(含 mapper 初始化)验证 4.1.1 组合;异常则回退 4.0.8 或反馈上游 |
| R-5 | 团队对 Boot 3 习惯(配置/属性名、Jackson API)的迁移成本 | 中 | 低 | 规模小、文档显式记录差异点;培训/评审时提示 Jackson 3 与 property 重命名类差异 |

## 6. 版本锁定清单(2026-08-25 Maven Central 实测)

| 坐标 | 版本 |
|---|---|
| org.springframework.boot:spring-boot-starter-parent | 4.1.1 |
| org.springframework.boot:spring-boot-starter-webmvc | 4.1.1 |
| org.springframework.boot:spring-boot-starter-actuator | 4.1.1 |
| org.springframework.boot:spring-boot-starter-validation | 4.1.1 |
| org.springframework.boot:spring-boot-starter-test | 4.1.1 |
| com.baomidou:mybatis-plus-spring-boot4-starter(后续) | 3.5.17 |
| com.baomidou:mybatis-plus-jsqlparser(后续) | 3.5.17 |
| Java | 21(LTS,Temurin 21.0.8) |
| Maven | 3.9.11(≥3.6.3 满足) |

> 注:以上版本已在 Maven Central 核验存在;实施前如隔较久,建议以 `mvn versions:display-parent-updates` 复核。

## 7. 调研来源(保留的核心来源)

**官方/一手**:github.com/spring-projects/spring-boot/wiki/Supported-Versions(支持策略)、.../wiki/Spring-Boot-4.1-Release-Notes、.../wiki/Spring-Boot-4.0-Migration-Guide、docs.spring.io/spring-boot/system-requirements.html、github.com/spring-projects/spring-boot/releases(4.1.1)、github.com/baomidou/mybatis-plus/releases(v3.5.13~3.5.17)、github.com/baomidou/mybatis-plus/issues/7009(factoryBeanObjectType)、github.com/mybatis/spring/releases(4.0.0)、baomidou.com/getting-started/install(boot4-starter 用法)

**版本事实核验**:repo1.maven.org 目录列表(spring-boot-starter-webmvc、mybatis-plus-spring-boot4-starter、mybatis-plus-jsqlparser)、endoflife.date/spring-boot(各线 OSS 截止日)、start.spring.io(2026-08-25 可用版本快照)

---

*本文档与《协流Agile_MVP开发文档_v1.0.md》冲突时,技术实现以本文档调研结论与 P-4 技术评审为准;业务决策以上游 PRD 为准。*
