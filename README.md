# shengsheng-skill

个人维护的 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) Skills 集合。

每个子文件夹是一个独立的 Skill，复制到 `~/.claude/skills/` 即可使用。

## 安装

```bash
git clone https://github.com/gongxuanzhang/shengsheng-skill.git

# 复制或软链接到 Claude Code skills 目录
cp -r shengsheng-skill/<skill-name> ~/.claude/skills/
```

## Skills

| Skill | 说明 |
|-------|------|
| [code-executor](./code-executor) | 自主代码执行者：输入一个 GitHub issue 或 PR，自动推进到合并——issue 先讨论方案至一致再拆解为多个 PR 并行执行，PR 则消化 review 意见后独立改代码并轮询至可合并。依赖 [review-regression](./review-regression)，建议一并安装 |
| [github-pr-review-loop](./github-pr-review-loop) | 持续观察并 review GitHub PR，按 head SHA、提交、评论、review 回复等变化决定是否复审，无阻断则 approve，有阻断则 request changes |
| [github-issue-solution-loop](./github-issue-solution-loop) | 持续 review 和讨论 GitHub issue，先在 issue 中对齐方案，方案认可后等待作者/维护者提交关联 PR，再 review PR |
| [project-doc-sync](./project-doc-sync) | 自动同步维护项目的 `todo.md`、`CLAUDE.md` 及其引用的关联文档，讨论出任务时追加、完成时删除、确认设计方案时更新架构文档并级联更新所有关联文档 |
| [proposal-review](./proposal-review) | 通过对话式工作流生成方案审核清单，覆盖方案背景、修改内容、影响范围、风险评估、回滚方案、相关文档及审核检查项，适用于交给团队评审 |
| [review-regression](./review-regression) | 审核意见回归讨论——对返回的评审意见逐条批判性分析，取其精华弃其糟粕，不盲从权威，不明确时反问用户，最终输出修订方案与回复意见 |

> **Review 测试约定**：`github-pr-review-loop` 和 `github-issue-solution-loop` 在 review 时不执行测试命令，默认 PR 提交流程或 CI 已经跑过必要测试。它们只基于代码、diff 和上下文判断是否存在语义问题，以及是否缺少必要测试覆盖。

## 三个 GitHub 自动化 Skill 怎么选

`code-executor`、`github-issue-solution-loop`、`github-pr-review-loop` 都围绕 GitHub issue/PR 自动化，但定位不同：

| 维度 | code-executor | github-issue-solution-loop | github-pr-review-loop |
|---|---|---|---|
| 一句话 | 接手 issue/PR 一路干到合并 | 盯着 issue 把方案讨论到一致 | 盯着 PR 给出 review 结论 |
| 会写代码 | 会 | 不会 | 不会 |
| 会合并 | 会（`AUTO_MERGE`） | 不会 | 不会 |
| 会 review | 会（消化意见并改代码） | 会（只 review 外部 PR） | 会（核心职责） |
| GitHub 身份 | 本机个人 `gh` 登录态 | 机器人 `GITHUB_BOT_TOKEN` | 机器人 `GITHUB_BOT_TOKEN` |
| 运行边界 | 直到合并/关闭，或无进展上限 | 默认 2 小时 | 默认 2 小时 |
| 并行多 PR | 会（`Workflow` + worktree） | 不会 | 不会 |
| 个人使用习惯（作者） | 用来**编写** issue 和 PR | 用来**评审**（只讨论对齐 + 等待并评审外部 PR） | 用来**评审** PR |

> 💡 **作者的组合用法**：`code-executor` 负责“写”（编写并推进 issue/PR 到合并），两个 loop 负责“审”。这套组合可以**完全 0 人参与托管**——但前提是 **issue 里必须把验证/验收标准写清楚**，否则自动执行缺少可信的“完成判据”，容易跑偏或误合并。

## License

MIT
