# CLAUDE.md 更新规范

本文件定义 `CLAUDE.md` 更新时的内容标准、章节结构和质量控制规则。

> **核心定位**：CLAUDE.md 是**行为指令集**（类似给新工程师的 onboarding checklist），而非架构知识库。
> 写的每一行都应该是"指令"——告诉 Claude **做什么、怎么做**，而不是"知识"——描述系统是什么。

---

## 章节结构（通用模型）

CLAUDE.md 应遵循以下通用章节结构，项目按需裁剪，但不应新增超出此范围的章节：

| 序号 | 章节 | 内容要求 | 典型行数 |
|------|------|---------|---------|
| 1 | Overview | 项目一句话描述 + 技术栈 | 3-5 行 |
| 2 | Common Commands | 构建、测试、lint、部署命令 | 10-20 行 |
| 3 | Code Style | **仅非默认**的代码约定（语言/框架默认约定不需要写） | 5-15 行 |
| 4 | Core Principles | 3-5 条团队开发原则 | 5-10 行 |
| 5 | Project Structure | 简要目录说明（顶层 1-2 级即可，非完整文件树） | 10-20 行 |
| 6 | Development Workflow | 分支策略、提交规范、PR 约定 | 10-15 行 |
| 7 | Key Architectural Decisions | **仅影响日常开发行为**的决策（Claude 无法从代码推断的） | 10-20 行 |
| 8 | Gotchas & Known Issues | 容易踩坑的点、已知限制 | 5-15 行 |

**总行数上限：≤ 200 行**。超过时必须精简或将详细内容外置。

---

## 内容筛选标准

### 添加前必问

> **"没有这行，Claude 读代码后还会犯错吗？"**
> 答案是"不会"就不加。

### 应该放入 CLAUDE.md 的内容

- 构建/测试/部署命令（Claude 无法猜到）
- 非常规代码约定（与语言/框架默认不同的规则）
- 容易混淆的设计决策（代码中不明显的 why）
- 团队特有的工作流（分支策略、PR 模板、发布流程）
- Claude 反复犯错的行为模式（踩坑记录）

### 不该放入 CLAUDE.md 的内容

- API 详细规格（路径、请求/响应体）→ Claude 可以读代码
- DTO/Entity 字段列表 → Claude 可以读代码
- 状态机完整定义 → Claude 可以读代码
- 配置 YAML 示例 → Claude 可以读配置文件
- 完整的项目文件树 → Claude 可以用 Glob/ls 查看
- 框架/语言的默认约定 → Claude 已经知道

---

## 渐进式披露规则

当某个话题需要详细说明（超过 5 行）时，不要全部写进 CLAUDE.md，而是：

1. CLAUDE.md 中只写**一行指令 + 引用**
2. 详细内容放到 `docs/`、`.claude/rules/` 或独立文档中

### 引用方式

```markdown
<!-- 推荐：使用 @import 引用（Claude 会自动加载） -->
@docs/api-conventions.md

<!-- 备选：使用 Markdown 链接 -->
API 设计约定详见 [docs/api-conventions.md](docs/api-conventions.md)
```

### 示例

**错误** — 把详细 API 规格塞进 CLAUDE.md：
```markdown
## API 设计
### POST /api/orders — 创建订单
请求体：{ "productId": "...", "quantity": 1 }
响应体：{ "orderId": "...", "status": "created" }
### GET /api/orders/:id — 查询订单
...（继续列举所有端点）
```

**正确** — CLAUDE.md 只保留指令 + 引用：
```markdown
## Key Architectural Decisions
- API 遵循 RESTful 风格，所有端点使用 camelCase 命名
- 详细 API 规格见 @docs/api-spec.md
```

---

## 指令风格要求

CLAUDE.md 中的每一条都应该是**可执行的指令**，而非知识描述。

### 正确写法（指令型）

```markdown
- 新增 API 端点时，必须同时添加对应的集成测试
- 数据库迁移文件命名格式：`V{版本号}__{描述}.sql`
- 提交消息使用 Conventional Commits 格式
- 不要直接修改 generated/ 目录下的文件
```

### 错误写法（知识描述型）

```markdown
- 项目使用 Spring Boot 3.2 框架（← Claude 读 pom.xml 就知道）
- OrderDTO 包含 orderId、status、createdAt 字段（← Claude 读代码就知道）
- 状态机支持 PENDING → CONFIRMED → SHIPPED 转换（← Claude 读代码就知道）
```

---

## 不应更新 CLAUDE.md 的场景

- 纯粹的 bug 修复（不涉及设计变更）
- 变量重命名、import 整理
- 测试代码的修改
- 注释的修改
- 不影响架构的局部重构
- 新增了 API 端点、DTO、Entity（Claude 可以从代码读取）
- 新增了配置项（Claude 可以从配置文件读取）

---

## 长度检查规则

每次更新 CLAUDE.md 后，必须检查总行数：

| 行数 | 动作 |
|------|------|
| ≤ 150 行 | 正常，无需处理 |
| 151-200 行 | 提醒用户"接近上限，建议审视是否有可外置的内容" |
| > 200 行 | **必须**精简——将详细内容外置到 `docs/` 并用 `@` 引用 |

---

## 关联文档发现与级联更新

### 方向原则

> **详细内容应该在外部文档中，CLAUDE.md 只引用它们。**
>
> 不是"CLAUDE.md → 同步到外部文档"，而是"外部文档承载详情，CLAUDE.md 保持精简引用"。

### 引用识别规则

更新 CLAUDE.md 时，需扫描以下形式的文档引用：

| 引用形式 | 示例 |
|---------|------|
| @import | `@docs/api-spec.md` |
| Markdown 链接 | `[已知问题](docs/known-issues.md)` |
| 指向性描述 | `详见 docs/xxx.md` |
| 代码块路径 | `` `docs/xxx.md` `` |

### 引用过滤规则

- ✅ **处理**：项目内的相对路径，指向 `.md`、`.yaml`、`.yml`、`.json` 等文本文件
- ❌ **忽略**：外部 URL（`http://`、`https://`）
- ❌ **忽略**：不存在的文件路径
- ❌ **忽略**：二进制文件、源代码文件

### 关联文档更新原则

- **保持原文档风格**：每个文档可能有不同的格式，不要强制统一
- **最小化变更**：只修改与本次变更直接相关的部分
- **内容外置建议**：当发现 CLAUDE.md 中内容过于详细时，建议用户将其移到外部文档并用 `@` 引用
