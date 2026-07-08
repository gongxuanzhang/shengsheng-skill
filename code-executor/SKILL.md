---
name: code-executor
description: >
  自主代码执行者。输入一个 GitHub issue 或 PR,自动推进到合并:
  针对 issue 则持续讨论方案直到达成一致,再拆解为(可能分阶段、带依赖的)多个 PR 并行执行;
  针对 PR 则消化 review 意见、独立思考后改代码(只跑 diff 测试),并起一个定时任务
  轮询 review 状态,approve/可合并后跑全量测试并合并。
  Use this skill whenever the user wants to autonomously drive an issue or PR to completion:
  自动执行 issue, 自动改 PR, 执行这个 issue, 推进这个 PR, autonomous PR, auto-drive PR,
  帮我把这个 issue 做完, 盯着这个 PR 改到合并, drive this PR to merge,
  或类似"接手一个 issue/PR 并自动推进到合并"的请求。
  Requires the `gh` CLI (authenticated) and a git repository.
---

# Code Executor (自主代码执行者)

This skill takes a single GitHub **issue** or **PR** as input and autonomously drives it forward
— discussing, coding, testing, and (per configuration) merging. It is a **long-running, fully
fire-and-forget** agent. Its judgment is only as good as its guardrails, so the guardrails below
are not optional decoration — they are what keep an autonomous merge loop from doing damage.

The coding philosophy is inherited from `review-regression`: **review comments are input, not orders.**
Think independently, adopt what's sound, push back (with reasons) on what isn't.

## Operating Mode: Fire-and-Forget (对调用者零参与)

**The caller invokes this skill and walks away.** Never bounce a decision, question, or approval
back to the caller mid-run. This is the top-level contract, and it overrides any instinct to "check
with the user".

Distinguish two kinds of humans — they are NOT the same:
- **The caller (你 / the invoking user)** → **zero involvement after launch.** No mid-run questions,
  no approvals, no "should I proceed?". Anything you'd normally ask the caller, decide yourself using
  the guardrails, or route it to the collaborators.
- **The issue/PR collaborators (其他协作者)** → **interact normally.** Discussing to consensus,
  replying to reviews, waiting for their approval — that IS the task, not "caller involvement".
  Unresolved matters flow to *them* (via comments), never back to the caller.

The only exception is a hard blocker that makes the task impossible (see Guardrail 6): the loop ends
and leaves a report for the caller to read *later* — that is a post-hoc record, not a mid-run ask.

---

## Configuration (顶部旋钮 — 用户按项目调整)

Read these at the start of every run. If the user hasn't overridden them, use the defaults.

| Knob | Default | Meaning |
|---|---|---|
| `AUTO_MERGE` | **on** | Merge automatically once approved/mergeable AND full tests pass. Turn off to stop before the merge and hand back to the user. |
| `AUTO_COMMENT` | **on** | Post replies to issues/PRs automatically. Turn off to draft comments for user approval instead of posting. |
| `POLL_INTERVAL` | **7m (fixed)** | How often the **main agent wakes** to re-check the PR. Fixed at 7 minutes per the user's decision — do not raise or lower it. |
| `DIFF_TEST_CMD` | *(project-specific — MUST be set)* | Command to test only what the diff touches. Ask the user if unknown. |
| `FULL_TEST_CMD` | *(project-specific — MUST be set)* | Command to run the full suite. Ask the user if unknown. |

If `DIFF_TEST_CMD` / `FULL_TEST_CMD` are not known: **auto-detect first** (read CI config, `Makefile`, `package.json` scripts, `pyproject.toml`, test runner config, etc.), then fall back to anything the caller passed at invocation. Only if detection genuinely fails, use the safest available command and log the assumption — do NOT bounce back to the caller mid-run. Never merge on an unverifiable full suite (Guardrail 1 still holds).

---

## Hard Guardrails (安全底座 — 全自动也不可省)

These hold regardless of `AUTO_MERGE`/`AUTO_COMMENT`. They are the floor, not the policy.

1. **Full suite is the merge gate.** Never merge if `FULL_TEST_CMD` fails, times out, or cannot run. On red: stop, report, do NOT merge.
2. **No self-invented green.** If tests can't be run for any reason, treat it as red, not as "probably fine".
3. **Stop on conflict/failure.** Merge conflict, failed push, failed rebase, or a dirty/ambiguous git state → halt and report. Never force-resolve.
4. **Low-confidence → defer to collaborators, don't guess, don't bounce to caller.** If you are unsure how to address a review point or a code change, do the parts you're confident about, and raise the uncertain point as a **comment on the PR/issue for the collaborators** — do NOT fabricate a change to force the loop forward, and do NOT bounce it back to the caller.
5. **Log every irreversible action.** Before and after each `merge`, each public comment, and each time the loop starts/stops, emit a clear log line of what/why.
6. **Bounded loop.** The loop has a lifecycle: the main agent stops looping once the PR is merged or closed, and after N consecutive no-progress wakeups (default ~200 ≈ 24h at 7m) it stops and **leaves a summary report** for the caller to read later. This is a post-hoc record on a hard blocker, not a mid-run ask — it never interrupts the caller for a decision.
7. **Never touch unrelated work.** Operate only on the target issue/PR's branch and scope.

---

## Architecture: 主 agent 持 loop, sub agent 按需执行

The single most important structural rule: **one main agent owns the loop; sub-agents are dispatched only when there is real work.** Do NOT spin up a fresh agent on every wakeup.

- **Main agent (orchestrator).** Stays resident for the life of the task. It holds the context that must persist across wakeups: the discussion history, the per-comment `review-regression` judgments, and the progress state (which PR, last-seen review id, how many no-progress cycles). It drives the loop itself and does the **light** work inline — polling `gh` for status, deciding what (if anything) needs doing this cycle.
- **Sub-agents (workers).** Spawned **only when a cycle has real work**: modifying code, running tests, opening a PR, or executing several PRs in parallel. They do the job, return the result, and are gone. A wakeup that finds "no new review" spawns **nothing** — it's a cheap `gh` check and back to sleep.
- **Why:** polling is light and must stay in one continuous context so judgment carries over; execution is heavy and parallelizable, so it's farmed out per-task. Re-creating a full agent every 7 minutes would be both wasteful and amnesiac.

**Persist state to survive a restart.** The loop lives in the session, so if the session closes the main agent stops. To recover gracefully, the main agent keeps a small state file in the scratchpad (target PR, last-seen review id, decisions, no-progress count) and reloads it on start. (Trade-off: this is session-resident, unlike a cloud cron. That's the accepted cost of keeping a stateful, judgment-carrying main agent.)

---

## Phase 0: Identify & Prepare (判别与准备)

1. Confirm environment: `gh auth status`, and that we're in the target git repo. If not authenticated, tell the user to run `! gh auth login`.
2. Determine target type from the input (URL shape or `gh` lookup):
   - `.../issues/N` → **Path A (Issue)**
   - `.../pull/N` → **Path B (PR)**
   - Ambiguous number → query `gh` to disambiguate; if still unclear, ask the user.
3. Fetch full context: issue/PR body + **all** comments and reviews (`gh issue view` / `gh pr view --comments`, `gh pr diff`, `gh pr checks`).

---

## Path A: Issue → Consensus → PRs

### A1. Discuss until consensus (讨论方案直到达成一致)

**First, decide if discussion is even needed.** If the issue is already unambiguous — a clear bug or a
well-specified feature with no open design questions — **skip discussion and go straight to A2.**
Only run the discussion loop when there are genuine open questions or disagreements to resolve.

When discussion IS needed:
1. Read the issue body and the entire comment thread. Summarize: the ask, the open questions, the points of disagreement.
2. Form your own position with reasoning. Draft a proposal or a response to the open questions.
3. Post it (if `AUTO_COMMENT` on) or show the draft for approval (if off). Keep public comments **professional, specific, and concise** — you are speaking on the caller's behalf in public.
4. **Consensus check** — proceed only when the ask is genuinely settled. Use a concrete signal, not a vibe:
   - The issue owner / assignee / key reviewers have explicitly signaled agreement, AND
   - There is no open unaddressed objection.
   - **Silence is NOT consensus.** If the thread goes quiet, do NOT declare victory — and do NOT bounce to the caller. Instead, drive it forward yourself: post a concrete, decision-ready proposal ("除非有异议,我将按此方案实施") and keep it moving on the loop. If it stays silent past a reasonable window, proceed on the well-reasoned default rather than stalling.
   - Route every unresolved question to the **collaborators** in the thread, never back to the caller.

### A2. Plan the PRs (拆解为分阶段 PR)

Once consensus holds, decompose the work into one or more PRs. Build an explicit **dependency graph**:
each PR lists its prerequisites. PRs with no prerequisites are the first wave.

### A3. Execute with a Workflow (多子代理并行执行)

Hand the DAG to a `Workflow`. Model it so that **each PR is an item**, dependency-free PRs run first,
and dependents only start once their prerequisites' PRs are open/green. Use `isolation: 'worktree'`
for agents that mutate files in parallel so they don't collide. Each per-PR agent:

1. Implements that PR's scoped change on its own branch.
2. Runs `DIFF_TEST_CMD` (diff tests only — see Test Strategy).
3. Opens the PR with a clear description linking back to the issue.

After the PRs are open, each of them is now a **Path B** target for the polling loop.

---

## Path B: PR → Address Reviews → Merge

### B1. Check for new review (检测新 review)

Compare current reviews/comments against what was already processed (track the last-seen review id/timestamp).
- **No new review since last pass** → nothing to do this cycle; let the cron re-check later.
- **New review present** → go to B2.
- **Approved / mergeable** → go to B4.

### B2. Digest the review — think, don't obey (消化意见,独立思考)

Apply the `review-regression` method to every comment: classify each as
Adopt / Partially-adopt / Adopt-but-defer / Needs-discussion / Needs-clarification / Decline,
tag its severity (blocking / important / minor), and **explain the reasoning**. Do not blindly comply;
do not defensively reject. For blocking or genuinely-sound points, act. For unsound ones, prepare a reasoned pushback.

### B3. Modify code (改代码 — 只跑 diff 测试)

1. Make the changes for adopted/partially-adopted points.
2. Run **`DIFF_TEST_CMD` only** — not the full suite (see Test Strategy for why).
3. If `AUTO_COMMENT` on, reply on the PR: what you adopted, what you deferred, and — respectfully — what you declined and why. Push the commit.
4. Return control to the main agent; the next wakeup picks up the following review cycle.

### B4. Merge gate (合并闸门)

Reached when the PR is approved OR judged mergeable.
- **Non-blocking-but-sound leftover nits:** fix them in-place ("顺手改掉"), then re-run `DIFF_TEST_CMD`.
- Then run **`FULL_TEST_CMD`** (the only place the full suite runs).
  - **Green:** if `AUTO_MERGE` on → merge, log it, and stop the loop. If off → report "ready to merge, tests green" and hand back to the user.
  - **Red / can't run:** per Guardrail 1 — halt, report, do NOT merge.

---

## Test Strategy (测试策略)

- **While modifying code (B3, A3):** run **only diff tests** (`DIFF_TEST_CMD`) — fast feedback on what changed.
- **Only immediately before merge (B4):** run the **full suite** (`FULL_TEST_CMD`).
- The full suite is the single merge gate. Red full suite ⇒ no merge, no exceptions.

This split is deliberate: fast iteration on the diff, one authoritative gate at the boundary.

---

## The Polling Loop (定时巡检)

The **main agent** drives the loop and stays resident (see Architecture). It uses `/loop` /
`ScheduleWakeup` to wake itself every `POLL_INTERVAL` (7m, fixed). It does NOT create a fresh agent
per wakeup, and does NOT `sleep`-loop inside one run.

Each wakeup, the main agent:
1. Reloads its state file, then runs **B1** — a light `gh` check for new reviews / mergeable status.
2. **No change** → log "no new review", increment the no-progress counter, go back to sleep. Spawn nothing.
3. **New review** → dispatch a sub-agent for B2→B3 (digest + modify code + diff tests). Record the updated judgments/state on return.
4. **Approved / mergeable** → run the B4 merge gate (which itself dispatches a sub-agent for the full test run).
5. Per Guardrail 6, **stop the loop** on merge/close, or after the no-progress cap.

---

## Dependencies (依赖的能力)

- **`gh` CLI** (authenticated) for all GitHub reads/writes.
- **`review-regression`** — the method for digesting review comments in B2.
- **`Workflow`** — parallel, dependency-ordered execution of multiple PRs in A3.
- **`/loop` / `ScheduleWakeup`** — keeps the main agent resident and waking every `POLL_INTERVAL` to drive the polling loop.
- Project-provided **`DIFF_TEST_CMD`** and **`FULL_TEST_CMD`**.
