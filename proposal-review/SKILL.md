---
name: proposal-review
description: >
  Guide users through a structured conversational workflow to produce a formal proposal/change review document (方案审核清单).
  Covers background, change details, purpose, impact scope, risk assessment, rollback plan, related documents, and review checklist.
  Use this skill whenever the user mentions: 方案审核, 方案评审, change review, proposal review, 变更评审,
  写方案, 方案清单, review checklist, 列方案, 方案讨论, 变更方案, 评审清单, 审核文档, change proposal,
  方案用于审核, RFC review, or any similar request to create a structured proposal for team review.
  Also trigger when users say things like "我想讨论一个方案然后整理给别人看",
  "帮我整理一下这个改动的审核材料", "方案用于审核", or "let's document this change for review".
---

# Proposal Review Document Generator (方案审核清单生成器)

This skill guides users through a conversational workflow to produce a professional proposal review document. The document is designed to be handed to reviewers (team leads, architects, or stakeholders) so they can quickly understand the change, assess risks, and make an approval decision.

## Language Detection

Detect the user's language from their first message:
- If the user writes in Chinese, conduct the entire workflow in Chinese and output the final document in Chinese
- If the user writes in English, use English throughout
- If the user mixes languages, default to Chinese but ask for preference

## Workflow Overview

The workflow has **3 phases**. Walk the user through each phase conversationally — ask questions one group at a time, never dump everything at once. The goal is to feel like a productive discussion, not a form to fill out.

### Phase 1: Context Gathering (理解背景)

Start by understanding the big picture. Ask these questions naturally (adapt based on what the user has already shared):

**Round 1 — The "Why":**
- What problem are you trying to solve, or what opportunity are you pursuing?
- What triggered this change? (a bug, a feature request, performance issue, tech debt, business requirement?)
- Is there urgency or a deadline?

**Round 2 — The "What":**
- What systems, modules, or services will be modified?
- Can you describe the key changes at a high level?
- Are there any changes to APIs, database schemas, or external interfaces?
- Will this affect any configuration, deployment pipelines, or infrastructure?

**Round 3 — The "Who and Where":**
- Which teams or people are affected by this change?
- Are there any downstream consumers or upstream dependencies?
- Does this touch user-facing functionality?

After each round, summarize what you've understood and confirm with the user before moving on. If the user provides information proactively, skip questions that are already answered.

### Phase 2: Risk & Mitigation (风险与应对)

Once the change scope is clear, shift to risk assessment:

**Risk Questions:**
- What could go wrong with this change? (data loss, downtime, performance degradation, compatibility issues)
- Are there edge cases or scenarios that worry you?
- How will you verify the change works correctly? (testing strategy)
- Is there a rollback plan? If the change fails in production, how do you revert?
- Is this change reversible or irreversible?
- Are there any dependencies on other teams' changes or external services?

**Mitigation Questions:**
- What monitoring or alerting will you have in place?
- Is there a phased rollout plan? (canary, feature flag, gradual rollout)
- Do you need a maintenance window?

Adapt the depth of questioning to the scale of the change — a config tweak doesn't need the same rigor as a database migration.

### Phase 3: Documentation & References (文档与参考)

Gather supporting materials:
- Are there any design documents, architecture diagrams, or technical specs?
- Related PRs, issues, or tickets?
- Meeting notes or discussion threads?
- Links to monitoring dashboards or runbooks?
- Any prior art or similar changes that were done before?

If the user doesn't have formal documents, that's fine — note what exists and what doesn't.

## Output: The Review Document

After all information is gathered, generate a well-structured markdown document. Use the following template, adapting section depth to the actual complexity of the change:

```markdown
# 方案审核清单 / Proposal Review Document

> **方案名称 / Title**: [concise title]
> **提出人 / Author**: [if mentioned]
> **日期 / Date**: [today's date]
> **状态 / Status**: 待审核 / Pending Review

---

## 1. 方案背景与原因 (Background & Reason)

[Why this change is needed. Include the triggering event, business context, and urgency.]

## 2. 修改内容 (Change Details)

[Specific description of what will be changed. Include:]
- 涉及的系统/模块 (Systems/Modules involved)
- 具体修改点 (Specific modifications)
- API/接口变更 (API/Interface changes, if any)
- 数据库变更 (Database changes, if any)
- 配置变更 (Configuration changes, if any)

## 3. 修改目的与预期效果 (Purpose & Expected Outcome)

[What this change aims to achieve. Include measurable outcomes if possible.]

## 4. 影响范围 (Impact Scope)

- **受影响的服务/模块**: [list]
- **受影响的团队**: [list]
- **用户影响**: [describe user-facing impact, if any]
- **上下游依赖**: [upstream/downstream dependencies]

## 5. 风险评估 (Risk Assessment)

| 风险项 (Risk) | 可能性 (Likelihood) | 影响程度 (Impact) | 应对措施 (Mitigation) |
|---|---|---|---|
| [risk 1] | 高/中/低 | 高/中/低 | [mitigation] |
| [risk 2] | 高/中/低 | 高/中/低 | [mitigation] |

## 6. 测试方案 (Testing Plan)

[How will the change be verified? Unit tests, integration tests, manual testing, etc.]

## 7. 发布与回滚方案 (Rollout & Rollback Plan)

**发布方式 (Rollout Strategy):**
[Phased rollout? Feature flag? Big bang?]

**回滚方案 (Rollback Plan):**
[How to revert if something goes wrong. Include specific steps.]

**预计发布时间 (Expected Release Date):**
[If known]

## 8. 相关文档 (Related Documents)

- [Document/link 1]
- [Document/link 2]
- [PR/Issue links]

## 9. 审核检查项 (Review Checklist)

Reviewers, please verify the following:

- [ ] 方案背景和原因是否清晰 (Is the background and reason clear?)
- [ ] 修改内容是否完整描述 (Are the changes fully described?)
- [ ] 影响范围是否全面评估 (Is the impact scope fully assessed?)
- [ ] 风险是否已识别并有应对措施 (Are risks identified with mitigations?)
- [ ] 回滚方案是否可行 (Is the rollback plan feasible?)
- [ ] 测试方案是否充分 (Is the testing plan sufficient?)
- [ ] 是否需要其他团队配合 (Is cross-team coordination needed?)
- [ ] 是否有遗漏的依赖或影响 (Are there missing dependencies or impacts?)

---

**审核意见 (Review Comments):**

| 审核人 (Reviewer) | 意见 (Comments) | 结论 (Decision) | 日期 (Date) |
|---|---|---|---|
| | | 通过 / 待修改 / 拒绝 | |
```

## Behavioral Guidelines

### Conversational Style
- Be a thoughtful collaborator, not a form filler. Ask follow-up questions when answers are vague.
- If the user is discussing the change casually, extract structured information from the conversation naturally.
- Summarize and confirm understanding at key points — don't wait until the end.

### Adaptive Depth
- **Small changes** (config updates, minor bug fixes): Keep it lightweight. Skip or collapse sections that aren't relevant. The risk table might have 1-2 rows. The testing section might be one sentence.
- **Medium changes** (new features, API changes): Full template, moderate detail.
- **Large changes** (architecture changes, data migrations, cross-team initiatives): Deep dive into every section. Consider asking about phased implementation, communication plans, and stakeholder sign-off.

### When Information is Missing
- If the user doesn't have an answer, note it as "待确认 / TBD" in the document rather than leaving it blank.
- Proactively suggest what should be filled in before the review meeting.

### Output Delivery
- After generating the document, ask the user if they want to:
  1. Save it as a file (suggest a filename like `proposal-review-[topic]-[date].md`)
  2. Adjust any section
  3. Add custom review checklist items specific to their team's process
- Offer to regenerate specific sections if the user wants to refine them.

### Review Checklist Customization
The default checklist covers common concerns, but encourage the user to add team-specific items. For example:
- Security review items for security-sensitive changes
- Performance benchmarks for performance-critical changes
- Data compliance checks for changes involving user data
- API versioning checks for public API changes
