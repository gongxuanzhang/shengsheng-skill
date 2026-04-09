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
| [project-doc-sync](./project-doc-sync) | 自动同步维护项目的 `todo.md`、`CLAUDE.md` 及其引用的关联文档，讨论出任务时追加、完成时删除、确认设计方案时更新架构文档并级联更新所有关联文档 |

## License

MIT
