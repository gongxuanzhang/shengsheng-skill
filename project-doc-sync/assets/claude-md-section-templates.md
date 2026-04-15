# CLAUDE.md 章节模板

当需要在 CLAUDE.md 中新增或更新内容时，使用以下模板。所有模板均采用**指令风格**——告诉 Claude "做什么"，而非"是什么"。

---

## 行为指令条目模板

用于 Code Style、Core Principles、Development Workflow、Gotchas 等章节。

```markdown
- {做某事}时，必须{具体要求}
- 不要{禁止的做法}，改用{推荐的做法}
- {场景}下，优先使用{方案}而非{替代方案}
```

**示例：**

```markdown
- 新增 API 端点时，必须同时编写对应的集成测试
- 不要直接拼接 SQL，使用 QueryDSL 构建查询
- 日期时间统一使用 LocalDateTime，不要用 Date
- 提交消息使用 Conventional Commits 格式（feat/fix/chore）
```

---

## 架构决策简述模板

用于 Key Architectural Decisions 章节。只记录**影响日常开发行为**的决策，不展开完整设计。

```markdown
### {决策名称}

- **决策**：{一句话描述选择了什么方案}
- **原因**：{一句话说明为什么}
- **影响**：{对日常开发的具体影响，即 Claude 需要知道的行为指令}
```

**示例：**

```markdown
### 订单状态采用状态机模式

- **决策**：使用 Spring Statemachine 管理订单状态流转
- **原因**：防止非法状态跳转，集中管理转换规则
- **影响**：修改状态流转时，编辑 StateMachineConfig 而非在 Service 中硬编码 if-else
```

---

## 常用命令模板

用于 Common Commands 章节。

```markdown
## Common Commands

```bash
# 构建
{构建命令}

# 测试
{测试命令}              # 全量测试
{单测命令}              # 单个测试

# 代码检查
{lint 命令}

# 本地运行
{启动命令}

# 部署
{部署命令}
```
```

---

## 外置引用模板

当某个话题需要详细说明时，CLAUDE.md 中只放一行引用。

```markdown
- {话题的行为指令摘要}，详细规格见 @{docs/xxx.md}
```

**示例：**

```markdown
- API 遵循 RESTful 风格，路径使用 kebab-case，详细规格见 @docs/api-spec.md
- 部署流程和环境变量配置见 @docs/deployment.md
- 已知问题和临时解决方案见 @docs/known-issues.md
```

---

## 踩坑记录模板

用于 Gotchas & Known Issues 章节。

```markdown
- ⚠️ {容易犯错的操作}：{会导致什么问题}。正确做法是{怎么做}
```

**示例：**

```markdown
- ⚠️ 不要在 @Transactional 方法中调用外部 HTTP 接口：会导致长事务锁表。应先提交事务再发起调用
- ⚠️ Redis key 必须加项目前缀：多个服务共用同一 Redis 实例，裸 key 会冲突
- ⚠️ 本地开发时 H2 的 JSON 函数与 MySQL 不兼容：涉及 JSON 查询的功能需连真实数据库测试
```

---

## 代码约定模板

用于 Code Style 章节。只记录**非默认**的约定。

```markdown
- **{约定名称}**：{具体规则}
```

**示例：**

```markdown
- **异常处理**：Controller 层不捕获异常，统一由 GlobalExceptionHandler 处理
- **命名约定**：DTO 统一后缀 `Dto`（非 `DTO`），VO 统一后缀 `Vo`
- **工具类**：统一使用 `XxxUtil.method()`，不要在各处重复实现
```
