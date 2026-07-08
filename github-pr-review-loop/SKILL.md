---
name: github-pr-review-loop
description: >
  持续 review GitHub Pull Request，直到可以 approve、明确 request changes，或到达持续时间。
  Use this skill when the user asks to review, monitor, approve, request changes on, keep watching, create a
  background review loop for, or continuously loop over one PR or all open PRs in the current GitHub repository.
  The loop checks head SHA, commits, comments, review replies, latest reviews, and the bot's previous review state
  before deciding whether to skip or re-review. When running inside Codex, prefer heartbeat automation for real
  background polling.
---

# GitHub PR Review Loop

持续观察并 review GitHub PR。目标不是“尽快通过”，而是把每个 PR 推进到可信的结论：无阻断问题则 approve，有阻断问题则 request changes，不能自 approve 时明确 comment。

---

## 身份与工具约束

- GitHub 操作必须使用本地 `gh` 命令。
- 如果本机没有 `gh`，先安装 `gh`，再继续。
- GitHub 身份必须来自本地环境变量 `GITHUB_BOT_TOKEN`。
- 不使用本机已有的个人 `gh auth` 登录态。
- 不使用其他账号或 token。
- 不打印、不 echo、不暴露 token。
- 在 Codex 客户端中需要持续观察时，优先使用 heartbeat automation 做真正后台轮询，不只依赖一个前台 sleep loop。
- review 时不执行测试命令；默认 PR 提交流程或 CI 已经跑过必要测试，只从代码和 diff 判断测试覆盖是否足够。
- 推荐命令形式：

```bash
GH_TOKEN="$GITHUB_BOT_TOKEN" gh pr list --state open
GH_TOKEN="$GITHUB_BOT_TOKEN" gh pr view <pr>
GH_TOKEN="$GITHUB_BOT_TOKEN" gh pr review <pr> --approve --body "<body>"
```

如果 `GITHUB_BOT_TOKEN` 不存在，停止并要求用户提供；不要降级使用个人账号。

---

## Loop 参数

- 默认持续时间：用户未指定时运行 **2 小时**。
- 扫描范围：
  - 用户指定某个 PR：只持续处理该 PR。
  - 用户未指定 PR：每轮扫描当前仓库所有 open PR。
- 优先创建或更新挂在当前 Codex session 上的 heartbeat automation；每次唤醒执行一轮扫描，然后交回给 automation 调度下一轮。
- 当确定当前正在处理的 PR 后，根据 PR 内容更新当前 Codex session 标题；如果运行环境没有 session 标题控制能力，则跳过，不影响 review loop。
- 如果某轮执行了任何 review/comment，立刻开始下一轮扫描。
- 如果某轮没有执行任何 review/comment，等待 **5 分钟** 后再扫描。
- 到达持续时间后停止，并总结：
  - 本轮 review 过的 PR
  - 已 approve 的 PR
  - 仍阻断的 PR
  - 跳过或未 review 的 PR 及原因

---

## 每轮必须检查

每轮都重新查询当前仓库 open PR，不能因为上轮 PR 数量固定就提前停止；期间可能出现新 PR。

对每个 PR 收集：

- PR number、title、author、base branch、head branch、head SHA
- 最新 commit 列表和当前 head SHA
- 最新 issue comments
- 最新 review comments / review threads
- 最新 reviews
- bot 当前身份 login
- 我们上一次针对该 PR 的 review/comment
- 上次 review 之后是否出现新 commit、评论、回复、review 或其它需要复审的事件

常用命令示例：

```bash
GH_TOKEN="$GITHUB_BOT_TOKEN" gh api user --jq .login
GH_TOKEN="$GITHUB_BOT_TOKEN" gh pr list --state open --json number,title,author,headRefOid,headRefName,baseRefName,updatedAt
GH_TOKEN="$GITHUB_BOT_TOKEN" gh pr view <pr> --json number,title,body,author,headRefOid,headRefName,baseRefName,commits,comments,reviews,updatedAt
```

当 `gh pr view` 信息不足时，用 `gh api` 查询 timeline、review threads 或具体 review comments。

---

## Codex 后台轮询

当用户要求持续观察、后台监控、review loop 或 keep watching 时，不要只靠当前 turn 长时间 sleep。优先使用 Codex app 的 heartbeat automation，让当前 session 按固定节奏被唤醒。

执行规则：

1. 根据用户指定的持续时间计算绝对截止时间；未指定时默认为 2 小时。
2. 如果 Codex app 提供 automation 工具，创建或更新挂在当前 session 上的 heartbeat automation。
3. heartbeat 每 5 分钟唤醒当前 session 一次。
4. heartbeat prompt 必须包含完整 loop 状态：仓库、PR 范围、截止时间、GitHub 身份规则、`gh` 命令规则、独立目录规则、不跑测试规则、当前总结状态，以及“每次唤醒只执行一轮扫描/review”的要求。
5. 每次唤醒时先检查是否超过截止时间；超过则输出最终总结并暂停或删除 heartbeat。
6. 如果本轮提交了 review/comment，则在同次唤醒中立刻额外扫描一轮，然后结束本次唤醒，等待下一次 heartbeat。
7. 如果当前环境没有 automation 工具，才退回当前 session 内的前台轮询。

不要在回复里手写原始 automation 指令；创建、更新、暂停或删除后台轮询时，使用 Codex app 提供的 automation 工具。

---

## Codex Session 标题

如果当前运行在 Codex 客户端中，并且可以修改当前 session 标题，则用当前关联 PR 生成标题，方便侧边栏识别这个 session 正在处理什么。

标题规则：

- 单 PR loop：使用 `PR #<number>: <PR title>`。
- 全量 open PR loop：还没有进入具体 PR 前使用 `PR review: <owner>/<repo>`；开始 review 某个 PR 时切换为 `PR #<number>: <PR title>`。
- 标题过长时截断到大约 80 个字符，保证 Codex 侧边栏可读。
- 不要把 secret、敏感客户信息、过长 issue 正文或异常长分支名放进 session 标题。
- 如果 PR title 为空或不可用，回退到 `PR #<number>: <head branch>`。

在 Codex desktop app 中，优先使用可用的 thread title 控制能力和当前 thread id。没有该能力时静默跳过，不要中断 review。

---

## 跳过规则

只有同时满足以下条件，当前扫描轮才可以跳过某个 PR：

- PR 当前 head SHA 未变化。
- 我们已经针对当前 head SHA 发出有效 review。
- 该 review 之后没有新 commit、评论、review 回复、其它 review 或相关 timeline 更新。
- 没有 unresolved thread、维护者回复、作者追问或其它需要 bot 回应的信息。

以下情况必须重新 review：

- 新开的 PR
- head SHA 变化
- 没有我们针对当前 head SHA 的 review
- 我们上次 review 后有人评论、回复、提交或 review
- 任何信息让当前结论不再确定

---

## 本地检查规则

- 每个 PR 使用独立 review 目录，例如 `/tmp/github-pr-review/<repo>/pr-<number>-<head-sha>`。
- 禁止使用 `git worktree`。
- review 过程中不要修改代码或仓库文件。
- review 时不执行测试命令；默认 PR 提交流程或 CI 已经跑过必要测试。
- 可以基于代码和 diff 判断是否缺少必要测试，但不要自己运行测试。
- 阅读 diff 和必要上下文，优先判断语义正确性，而不是格式偏好。

阻断问题包括但不限于：

- 行为错误、边界条件错误、兼容性破坏
- 安全、权限、认证、数据泄露风险
- 数据损坏、迁移、并发、幂等性问题
- API contract 破坏或错误处理缺失
- 缺少必要测试导致关键行为无法可信验证

不要因为风格偏好、可选重构或主观命名 request changes。

---

## Review 输出

### 无阻断问题

直接 approve：

```bash
GH_TOKEN="$GITHUB_BOT_TOKEN" gh pr review <pr> --approve --body "<concise approval>"
```

### 因 GitHub 限制不能 approve

例如 PR 作者就是当前 bot，GitHub 拒绝 self-approve，则改用 comment，并明确写出：

```text
代码层面可通过，但无法 self approve。
```

命令示例：

```bash
GH_TOKEN="$GITHUB_BOT_TOKEN" gh pr review <pr> --comment --body "代码层面可通过，但无法 self approve。"
```

### 有阻断问题

提交 `CHANGES_REQUESTED`：

```bash
GH_TOKEN="$GITHUB_BOT_TOKEN" gh pr review <pr> --request-changes --body "<blocking findings>"
```

每个阻断问题必须包含：

- 具体文件和行号
- 问题原因
- 失败场景
- 修复建议

优先使用 line comment；如果 GitHub API 不方便定位，就在 review body 里写清楚文件和行号。

---

## 结束总结

到达持续时间后，输出简短总结：

```markdown
## PR Review Loop Summary

- Reviewed:
- Approved:
- Blocked:
- Skipped:
- Not reviewed:
```

每个 skipped / not reviewed 都要写明原因。
