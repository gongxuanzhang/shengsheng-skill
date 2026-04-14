---
name: review-regression
description: >
  当审核意见/评审结果返回后，引导用户对审核意见进行批判性回归讨论，取其精华弃其糟粕，
  理性分析每条意见的合理性，最终输出修订后的方案或回复意见。
  Use this skill whenever the user mentions: 审核意见回来了, 评审结果, review feedback,
  审核回归, 方案回归, 评审意见讨论, 审核结果分析, review regression, feedback review,
  方案修订, 评审返回, 审核反馈, post-review discussion, 回归讨论, address review comments,
  or any similar request to discuss and process review feedback on a proposal.
  Also trigger when users say things like "审核意见来了我们讨论一下",
  "评审结果出来了帮我分析一下", "reviewer 提了一些意见我们过一下",
  or "let's go through the review feedback".
---

# Review Regression (审核意见回归讨论)

This skill helps users critically process review feedback on a proposal. The core philosophy is: **review opinions are input, not orders**. Each piece of feedback should be evaluated on its merits — accepted when insightful, pushed back on when unreasonable, and clarified when ambiguous. The goal is a thoughtful, rational discussion that produces a better proposal, not blind compliance.

## Language Detection

Detect the user's language from their first message:
- If the user writes in Chinese, conduct the entire workflow in Chinese
- If the user writes in English, use English throughout
- If the user mixes languages, default to Chinese but ask for preference

## Core Principles

These principles guide every interaction in this skill. They exist because review processes often go wrong in predictable ways — people either rubber-stamp everything a senior reviewer says, or defensively reject all feedback. Neither produces good outcomes.

### 1. Don't Blindly Trust Review Opinions

Review feedback is one person's perspective, shaped by their context, assumptions, and biases. A reviewer might:
- Misunderstand the original intent or constraints
- Apply standards from a different domain that don't fit here
- Raise valid concerns but suggest poor solutions
- Focus on stylistic preferences rather than substantive issues
- Miss context that the proposal author has

Treat every opinion as a hypothesis to evaluate, not a directive to follow.

### 2. Focus on the Problem, Not the Authority

Evaluate feedback based on:
- Is the **underlying concern** valid? (separate the problem from the proposed solution)
- Does the reviewer provide **concrete reasoning**? (opinions without reasons need clarification)
- Is the feedback **actionable and specific**? (vague "this feels wrong" needs to be unpacked)
- Does it **conflict with stated requirements** or constraints the reviewer may not know about?

Do NOT evaluate feedback based on:
- Who said it (seniority doesn't make an opinion correct)
- How strongly it was worded (emphasis doesn't equal correctness)

### 3. Ask, Don't Assume

When a review comment is unclear or ambiguous:
- **Ask the user** what the reviewer likely meant
- **Do NOT guess** or infer intent — wrong assumptions lead to wrong responses
- **Do NOT fabricate** technical context you don't have
- If the user doesn't know either, mark it as "needs clarification from reviewer" — that's a perfectly valid outcome

## Workflow

### Phase 1: Intake (接收审核意见)

Ask the user to share the review feedback. It could come in many forms:
- Pasted text from a review tool
- A list of comments
- Screenshots or documents
- Verbal summary ("reviewer said X, Y, Z")
- A link to a PR or review thread

If the user already shared the original proposal (from `proposal-review` or otherwise), great — reference it. If not, ask for enough context to understand what was being reviewed.

**After receiving the feedback, immediately do this:**

1. Parse and number each distinct review comment (even if they came as a wall of text)
2. Present the numbered list back to the user to confirm nothing was missed or misunderstood
3. Ask: "Is this the complete set of feedback, or is there more?"

### Phase 2: Triage (分类评估)

Go through each comment and classify it. Present your analysis for **each comment individually** — do not batch them. For each one:

**Step 1: Understand the comment**
- Restate the reviewer's concern in your own words
- If the meaning is unclear, **stop and ask the user** rather than guessing

**Step 2: Evaluate its merit**

Assign one of these classifications:

| Classification | Meaning | Action |
|---|---|---|
| ✅ **Adopt (采纳)** | The concern is valid AND the suggested change is reasonable | Incorporate into the revised proposal |
| 🔧 **Partially Adopt (部分采纳)** | The concern is valid but the suggested solution isn't ideal, or only part of the feedback applies | Accept the problem, propose a better solution |
| 💬 **Needs Discussion (需要讨论)** | The comment raises a point worth exploring, but you need more info from the user to decide | Ask the user specific questions |
| ❓ **Needs Clarification (需要澄清)** | The comment is vague or ambiguous — you genuinely don't understand what the reviewer means | Mark for follow-up with the reviewer |
| ❌ **Decline (不采纳)** | The concern is based on a misunderstanding, doesn't apply to this context, or conflicts with stated requirements | Prepare a reasoned explanation for why |

**Step 3: Explain your reasoning**

For every classification, explain **why**. This is non-negotiable. Examples:

- ✅ "The reviewer correctly identified that our rollback plan doesn't cover the database migration case. We should add a specific rollback step for this."
- 🔧 "The reviewer's concern about performance is valid, but their suggestion to add a cache adds complexity we don't need. A simpler index optimization achieves the same goal."
- ❌ "The reviewer suggests switching to a different framework, but this conflicts with the team's existing tech stack constraints mentioned in Section 2 of the proposal."

**Step 4: Get user input**

After presenting the analysis for each comment, ask the user:
- Do you agree with this assessment?
- Do you have additional context that changes things?
- For "Needs Discussion" items: provide the specific questions

**Move to the next comment only after the current one is resolved.**

### Phase 3: Synthesis (综合修订)

After all comments are processed, produce a summary:

```markdown
# 审核意见回归结果 / Review Regression Summary

> **原方案 / Original Proposal**: [title]
> **审核人 / Reviewer(s)**: [if known]
> **回归日期 / Date**: [today's date]

---

## 意见处理总览 (Feedback Overview)

| # | 审核意见摘要 (Feedback Summary) | 处理结论 (Decision) | 理由 (Reasoning) |
|---|---|---|---|
| 1 | [summary] | ✅ 采纳 | [reason] |
| 2 | [summary] | 🔧 部分采纳 | [reason] |
| 3 | [summary] | ❌ 不采纳 | [reason] |
| 4 | [summary] | ❓ 需澄清 | [reason] |

## 采纳的修改 (Accepted Changes)

[List specific changes that will be made to the proposal, grouped by section]

### [Section Name] 修改点:
- [Change 1]: [what was changed and why]
- [Change 2]: [what was changed and why]

## 不采纳的意见及理由 (Declined Feedback with Reasoning)

### 意见 #N: [summary]
- **审核人建议**: [what they suggested]
- **不采纳理由**: [clear, respectful explanation]
- **替代方案 (如有)**: [alternative approach, if any]

## 需要与审核人进一步确认的问题 (Questions for Reviewer)

- [ ] 意见 #N: [specific question to ask the reviewer]
- [ ] 意见 #N: [specific question to ask the reviewer]

## 下一步 (Next Steps)

- [ ] 修订方案文档 (Update proposal document)
- [ ] 回复审核意见 (Respond to reviewer)
- [ ] 安排复审 (Schedule re-review, if needed)
- [ ] [any other follow-up items]
```

### Phase 4: Revision (修订方案)

Ask the user if they want to:

1. **Update the original proposal** — incorporate all accepted changes and generate a revised version with change markers
2. **Draft a response to the reviewer** — write a professional reply addressing each comment with the decision and reasoning
3. **Both** — usually the right answer
4. **Neither for now** — just keep the summary for reference

If updating the proposal, clearly mark what changed:
- Use `[新增]` / `[Added]` for new content
- Use `[修改]` / `[Modified]` for changed content
- Use `~~strikethrough~~` for removed content (in a change log, not in the clean version)

If drafting a response to the reviewer, the tone should be:
- Professional and respectful, even when declining feedback
- Specific — reference the exact concern and explain the reasoning
- Constructive — when declining, offer alternative perspectives, not just "no"
- Grateful — acknowledge the reviewer's time and effort

## Behavioral Guidelines

### What to Do When You're Unsure

This is the most important guideline. When processing a review comment and you're not sure about something:

- **Technical context you don't have** → Ask the user: "I don't have enough context about [X] to evaluate this comment. Can you tell me [specific question]?"
- **Ambiguous review wording** → Ask the user: "This comment could mean [A] or [B]. Which interpretation do you think the reviewer intended?"
- **Domain-specific knowledge** → Ask the user: "Is [reviewer's claim] accurate in your system's context?"
- **Conflicting information** → Point it out: "The reviewer says X, but the original proposal says Y. Which is correct?"

**Never fill gaps with assumptions.** A wrong assumption leads to a wrong decision about whether to accept or reject feedback.

### Maintaining Objectivity

- If the user is emotionally reactive to negative feedback ("this reviewer doesn't understand anything"), gently steer back to specifics: "Let's look at each point individually — some might be valid even if the overall tone is frustrating."
- If the user wants to accept everything uncritically ("just do whatever they say"), push back: "Let's make sure each change actually improves the proposal. Accepting feedback you disagree with can make the proposal internally inconsistent."
- Present both sides when there's legitimate disagreement. The user makes the final call.

### Handling Contradictory Reviews

If feedback from multiple reviewers contradicts:
- Flag the contradiction explicitly
- Present each reviewer's reasoning
- Ask the user which direction aligns with the project's goals
- Don't try to merge incompatible opinions into a compromise — sometimes one side is simply right

### Output Delivery

After generating the summary:
- Ask if the user wants to save it as a file (suggest `review-regression-[topic]-[date].md`)
- Offer to update the original proposal document if it exists in the workspace
- If the user used the `proposal-review` skill earlier, reference that document structure
