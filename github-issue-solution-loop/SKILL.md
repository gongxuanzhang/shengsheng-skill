---
name: github-issue-solution-loop
description: >
  持续处理 GitHub issue：先在 issue 中和发起者/维护者讨论并对齐方案，方案认可后推进实现或关联 PR review。
  Use this skill when the user asks to solve, monitor, discuss, or continuously loop on a GitHub issue until
  the solution is agreed, implementation is allowed, related PRs are reviewed, or the requested duration ends.
---

# GitHub Issue Solution Loop

持续推进 GitHub issue，从问题理解到方案一致，再进入实现或关联 PR review。核心原则：先讨论方案，获得明确认可后再进入代码或 PR 阶段。

---

## 身份与工具约束

- GitHub 操作必须使用本地 `gh` 命令。
- 如果本机没有 `gh`，先安装 `gh`，再继续。
- GitHub 身份必须来自本地环境变量 `GITHUB_BOT_TOKEN`。
- 不使用本机已有的个人 `gh auth` 登录态。
- 不使用其他账号或 token。
- 不打印、不 echo、不暴露 token。
- 推荐命令形式：

```bash
GH_TOKEN="$GITHUB_BOT_TOKEN" gh issue view <issue>
GH_TOKEN="$GITHUB_BOT_TOKEN" gh issue comment <issue> --body "<body>"
GH_TOKEN="$GITHUB_BOT_TOKEN" gh pr view <pr>
```

如果 `GITHUB_BOT_TOKEN` 不存在，停止并要求用户提供；不要降级使用个人账号。

---

## Loop 参数

- 默认持续时间：用户未指定时运行 **2 小时**。
- 默认范围：用户指定的 issue。
- 如果用户要求扫描多个 issue，每轮都重新查询目标范围，不能因为上轮数量固定就提前停止。
- 根据当前 active issue 或关联 PR 更新当前 Codex session 标题；如果运行环境没有 session 标题控制能力，则跳过，不影响 loop。
- 如果某轮发布了 issue comment、更新了 PR、执行了 PR review/comment，立刻开始下一轮扫描。
- 如果某轮没有任何动作，等待 **5 分钟** 后再扫描。
- 到达持续时间后停止，并总结：
  - issue 当前状态
  - 方案是否已达成一致
  - 已处理的相关 PR
  - 已 approve 的 PR
  - 仍阻断的问题
  - 跳过或未执行动作的原因

---

## 每轮必须检查

对 issue 收集：

- issue number、title、body、author、labels、assignees、state、updatedAt
- 最新 issue comments
- bot 上一次 issue comment/action
- linked PR、closing references、timeline events
- 是否有新评论、维护者信号、作者回复、label 变化或其它更新

对相关 PR 收集：

- PR head SHA、commit 列表、评论、review comments、reviews
- bot 针对当前 head SHA 的上次 review 状态
- 上次 review 之后是否有新提交、评论、回复或 review

常用命令示例：

```bash
GH_TOKEN="$GITHUB_BOT_TOKEN" gh api user --jq .login
GH_TOKEN="$GITHUB_BOT_TOKEN" gh issue view <issue> --json number,title,body,author,comments,labels,assignees,state,updatedAt
GH_TOKEN="$GITHUB_BOT_TOKEN" gh api repos/<owner>/<repo>/issues/<issue>/timeline
```

当 `gh issue view` 信息不足时，用 `gh api` 查询 timeline 或 linked PR。

---

## Codex Session 标题

如果当前运行在 Codex 客户端中，并且可以修改当前 session 标题，则用当前 active GitHub 目标生成标题，方便侧边栏识别这个 session 正在处理什么。

标题规则：

- 还没有关联 PR 前，使用 `Issue #<number>: <issue title>`。
- 一旦有关联 PR 成为当前 active 目标，使用 `PR #<number>: <PR title>`。
- 如果存在多个关联 PR，使用当前正在讨论、实现或 review 的 PR；如果没有明确 active PR，则继续使用 issue 标题。
- 标题过长时截断到大约 80 个字符，保证 Codex 侧边栏可读。
- 不要把 secret、敏感客户信息、过长 issue 正文或异常长分支名放进 session 标题。
- 如果标题为空或不可用，回退到 `Issue #<number>` 或 `PR #<number>: <head branch>`。

在 Codex desktop app 中，优先使用可用的 thread title 控制能力（例如 `set_thread_title`）和当前 thread id。没有该能力时静默跳过，不要中断 issue/PR loop。

---

## 先讨论方案

不要一上来写代码。先在 issue 中推进以下内容：

- 复述问题和期望行为
- 明确当前行为、失败场景、影响范围
- 识别兼容性、迁移、数据、安全、性能风险
- 提出具体实现方案和取舍
- 明确验收标准
- 有歧义时提出聚焦问题

方案只有在以下情况才算可以进入下一阶段：

- issue 作者或维护者明确认可方案；或
- issue 已经包含足够清晰的验收标准和实现边界；且
- 关键开放问题已经解决或明确延期。

如果认可不明确，继续在 issue 中讨论，不要自行假设。

---

## 写代码闸门

写代码前必须检查当前用户指令和仓库指令。

- 如果指令要求“写代码前必须询问”，先询问用户。
- 如果用户已经明确授权“方案一致后可自主实现”，则在方案被认可后可以实现。
- 如果没有代码授权，loop 只推进 issue 讨论和相关 PR review。

实现被允许时：

- 每个 issue 使用独立目录，例如 `/tmp/github-issue-loop/<repo>/issue-<number>`。
- 禁止使用 `git worktree`。
- 创建普通分支，提交 PR，并在 PR body 中关联 issue。
- 之后对相关 PR 应用 `github-pr-review-loop` 的 review 标准。

---

## 相关 PR Review 标准

一旦 issue 有相关 PR，就按 PR review loop 处理：

- 检查 PR head SHA、最新评论、最新 review、最新提交和 bot 上一次 review 状态。
- 如果当前最新有效状态已经是 bot 针对当前 head SHA 发出的 review，且之后没有新提交、评论、review 回复或其它需要复审的更新，则本轮跳过。
- 没有阻断问题时 approve。
- 有阻断问题时 request changes。
- 如果因为 GitHub 限制不能 approve，例如 PR 作者就是当前 bot，则 comment 明确写出：

```text
代码层面可通过，但无法 self approve。
```

request changes 必须说明：

- 具体文件和行号
- 问题原因
- 失败场景
- 修复建议

---

## Issue 评论风格

在 issue 中回复时保持明确、可执行：

- 先给结论，再列理由。
- 问题不清楚时只问关键问题，不一次性抛出过长清单。
- 提方案时写清楚为什么这样做、风险是什么、如何验证。
- 如果等待对方确认，明确说明需要对方确认什么。

---

## 结束总结

到达持续时间后，输出简短总结：

```markdown
## Issue Solution Loop Summary

- Issue:
- Solution status:
- Related PRs:
- Approved:
- Blocked:
- Pending external response:
- Skipped / not executed:
```

每个 skipped / not executed 都要写明原因。
