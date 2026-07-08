---
name: github-pr-review-loop
description: >
  持续 review GitHub Pull Request，直到可以 approve、明确 request changes，或到达持续时间。
  Use this skill when the user asks to review, monitor, approve, request changes on, or continuously loop over
  one PR or all open PRs in the current GitHub repository. The loop checks head SHA, commits, comments,
  review replies, latest reviews, and the bot's previous review state before deciding whether to skip or re-review.
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
- review 时不需要跑测试；提交 PR 的流程会保证测试通过。
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
