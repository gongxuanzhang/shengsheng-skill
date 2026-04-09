# shengsheng-skill

个人维护的 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) Skills 集合。

每个子文件夹是一个独立的 Skill，可以直接复制到 `~/.claude/skills/` 下使用。

---

## 安装方式

```bash
# 克隆仓库
git clone https://github.com/gongxuanzhang/shengsheng-skill.git

# 将需要的 skill 复制（或软链接）到 Claude Code skills 目录
cp -r shengsheng-skill/<skill-name> ~/.claude/skills/

# 或者使用软链接（方便 git pull 更新）
ln -s $(pwd)/shengsheng-skill/<skill-name> ~/.claude/skills/<skill-name>
```

安装后重启 Claude Code 会话即可生效。

---

## Skills 列表

### project-doc-sync

> 自动同步维护项目的 `todo.md` 和 `CLAUDE.md`，让文档与开发进度始终一致。

**核心能力：**

| 场景 | 自动动作 |
|------|---------|
| 对话中讨论出新的待办任务 | 追加到 `todo.md` 对应分区（🔴上线必需 / 🟡应修复 / 🟢优化） |
| 某个 TODO 确认完成 | 从 `todo.md` 删除该条目，自动重新编号 |
| 确认了新的设计方案 / 架构决策 | 更新 `CLAUDE.md` 对应章节 |

**触发方式：** 自动触发（`user-invocable: false`），无需手动调用。对话中涉及任务规划、完成确认、架构设计时自动执行。

**文件结构：**

```
project-doc-sync/
├── SKILL.md                              # 职责定义、触发场景、执行步骤、输出标准
├── reference/
│   ├── todo-format.md                    # todo.md 格式规范（条目格式、编号规则、分区标准）
│   ├── claude-md-format.md               # CLAUDE.md 更新规范（章节定位、更新原则）
│   └── trigger-rules.md                  # 触发判定细则（强触发 / 弱触发 / 不触发）
├── scripts/
│   ├── renumber-todo.sh                  # 删除条目后重新编号
│   ├── update-date.sh                    # 更新 todo.md 的"最后更新"日期
│   └── check-todo.sh                     # 健康检查（编号连续性、日期过旧）
└── assets/
    ├── todo-template.md                  # 新项目 todo.md 初始模板
    └── claude-md-section-templates.md    # CLAUDE.md 新增章节的各类模板
```

---

## 贡献

欢迎提 Issue 或 PR 添加新的 Skill。每个 Skill 需要包含：

1. `SKILL.md` — 完整的职责、触发场景、执行步骤、输出标准
2. `reference/` — 格式规范和判定规则（可选）
3. `scripts/` — 可自动化执行的脚本（可选）
4. `assets/` — 模板文件（可选）

## License

MIT