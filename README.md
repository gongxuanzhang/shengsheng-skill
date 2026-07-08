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
| [github-issue-solution-loop](./github-issue-solution-loop) | 持续处理 GitHub issue，先在 issue 中讨论并对齐方案，方案认可后推进实现或关联 PR review |
| [project-doc-sync](./project-doc-sync) | 自动同步维护项目的 `todo.md`、`CLAUDE.md` 及其引用的关联文档，讨论出任务时追加、完成时删除、确认设计方案时更新架构文档并级联更新所有关联文档 |
| [proposal-review](./proposal-review) | 通过对话式工作流生成方案审核清单，覆盖方案背景、修改内容、影响范围、风险评估、回滚方案、相关文档及审核检查项，适用于交给团队评审 |
| [review-regression](./review-regression) | 审核意见回归讨论——对返回的评审意见逐条批判性分析，取其精华弃其糟粕，不盲从权威，不明确时反问用户，最终输出修订方案与回复意见 |

## License

MIT
