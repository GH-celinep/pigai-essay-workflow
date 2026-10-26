---
name: pigai-essay-workflow
description: Automate the full 批改网 (pigai.org) English-essay workflow. Triggered by "开始帮我写作文", it automatically opens the browser, navigates to pigai.org, picks the nearest-deadline unfinished assignment, writes the essay, submits it, then fixes every red error and applies every recommended expression via each sentence's per-sentence "修改" popup. Use this skill when the user says "开始帮我写作文" / "帮我写作文" / "提交批改网作文" or otherwise wants an essay drafted, submitted, and polished on pigai.org. Do NOT use this skill for the 体检报告 (health-report) statistics — fixes are applied only through per-sentence edit popups.
agent_created: true
---

# 批改网英文作文工作流 (Pigai Essay Workflow)

## Overview

On the trigger phrase **"开始帮我写作文"**, the agent auto-opens the browser — launching the browser app itself if no window is open — and navigates to pigai.org; the user does not need to pre-open anything. This skill encodes a fixed, repeatable browser workflow for 批改网 (pigai.org): draft an English
essay for the user's assignment, submit it, then iterate on the system's per-sentence feedback
(red errors + recommended expressions) using the "修改" popup beside each sentence. It is
operational knowledge distilled from a fully executed run, including the non-obvious DOM and
pigai-UI pitfalls that break naive automation.

## When to use

- User says "开始帮我写作文" (primary trigger), "帮我写作文", "帮我把这篇提交到批改网", or similar — the agent then auto-opens pigai.org and runs the full flow without any manual page setup.
- User wants an existing pigai essay re-checked / fixed via the per-sentence edit buttons.
- Do NOT trigger for general English writing help that has nothing to do with pigai.org.

## Prerequisites

- Browser control via the `mcp__browser__*` tools (DOM-CUA capable). 批改网 runs in the user's
  **Edge extension** (browser_id obtained from `browsers_list`; for this author it happens to be 2).
  Reconnect each session:
  1. `mcp__browser__browsers_list` → note YOUR browser_id (commonly 2, but use whatever id is returned).
  2. `mcp__browser__user_open_tabs` (browser_id=<id>) → list open tabs.
  3. `mcp__browser__tabs_list` / `mcp__browser__tabs_claim` → claim the target tab.
  4. **Reconnect routine (when the controlled tab drops):** after a save/navigation
     `tabs_list` may return `[]`. Do NOT restart — recover: `browsers_list` → `user_open_tabs`
     → `tabs_claim` again (URL preserved; display may show only the base domain). A tab created
     via `tabs_new` is usually already controlled (no claim needed); only pre-existing user tabs
     from `user_open_tabs` require claiming. See `references/operations.md` §1.
- Load `mcp__browser__dom_cua_get_visible_dom`, `dom_cua_click`, `dom_cua_type`,
  `dom_cua_keypress`, `cua_scroll`, `tab_goto`, `tab_screenshot`, `tabs_claim` as needed.
- Detailed pigai URL patterns, button-locating tricks, and gotchas live in
  `references/operations.md` — read it before the first run of a session.

## Workflow (7 steps + 2 branches)

> 分支：Step 2.5（今天没有可写作文时 → 必须询问"改已完成 / 设提醒"）、Step 2.6（用户选择改已完成时）。

### Step 1 — 自动打开浏览器并进入 批改网
- 目标：说出触发语后，agent 自己把浏览器打开并导航到批改网，**即使浏览器当前没有窗口也能自动启动程序**，用户无需预开任何页面。
- 1. `mcp__browser__browsers_list` 列出可用浏览器（记下 browser_id；**首选带 user_tabs 的 Edge 扩展**，因为它保存着你的登录态；其次才是内置浏览器 `browser_id=1`）。
- 2. 尝试拿到可操作标签：
  - 若浏览器支持 user_tabs：`user_open_tabs` 看是否已有批改网标签 → 有则 `tabs_claim` 复用。
  - 否则用 `tabs_new`（url=`https://www.pigai.org/index.php?c=write`）开一个 agent 控制的新标签。
- 3. **若 `tabs_new` 返回 "No current window"（目标浏览器没有活动窗口）**——这是最常见的中断点，自动处理，不要停：
  - 用 `Bash` / `PowerShell` 启动浏览器程序：
    - Windows (Edge): `cmd /c start msedge` 或 `PowerShell: Start-Process msedge`
    - macOS: `open -a "Microsoft Edge"`
    - Linux: `microsoft-edge`
  - 等待 3–5 秒让扩展连上，再 `browsers_list` 重新探测，回到第 2 步。⚠️ 首轮重试可能仍报
    "No current window"（扩展尚未连上），再等 2–3 秒重试一次即可。`tabs_new` 成功后该标签通常
    已是**受控标签**，无需再 `tabs_claim`，直接操作。
  - 若启动后 `tabs_new` 仍失败，回退到内置浏览器（`browser_id=1`，desktop 类型）：`tabs_new` 开标签 goto pigai.org。注意内置浏览器**没有你的登录态**，会停在登录页——此时提示用户在该浏览器登录批改网后再继续。
- 4. 进入后页面有两个 tab：**已完成** (`/index.php?c=write`) 和 **未完成** (`/index.php?c=write&a=waitComplete`)。
- 备选（当直接 URL 不可达时）：用搜索引擎搜"批改网"，从结果进入官网 `pigai.org`，再走上面的"我的作文"路径。

### Step 2 — Pick the assignment & select the class (algorithm)
- Go to **未完成** (`a=waitComplete`). ⚠️ The visible-DOM snapshot often **omits the deadline
  text** (it gets truncated). Take a `tab_screenshot` and read the 作业号 / 标题 / 截止时间
  columns from the image to get the full list.
- Sort candidates by deadline ascending. Then, from the nearest, verify each one is open:
  `tab_goto` `?c=v2&a=write&rid=<rid>`.
  - If it redirects to `?c=v2&a=wait&rid=<rid>` ("开始时间为 … 距离写作开始时间还有 N天"),
    the essay is **not open yet** — record its start time and move to the next-nearest deadline.
  - The first `rid` whose writing page actually loads (title + requirements + body textarea
    visible) is the target. Proceed with it.
  - ⚠️ 开始时间 ≈ 截止前 6 天, so an essay can have the nearest deadline yet still be locked.
    Never assume "nearest deadline = writable"; always confirm via the redirect check.
- **2.4 选择班级（必做，漏掉必卡）** — 写作页底部「提交作文」左侧有一个班级下拉框，旁边显示
  「班级：[下拉] 学号:xxx, 姓名:xxx。若不存在您的班级请选择"其他"或者联系我们客服」。
  - 快照里形如：
    `<select value="请选择班级" ...>请选择班级 <你的班级> 其他</select>`
  - **判断是否已选好**：看 `selected-options` 的 label。是真实班级名（形如「XX班（20XX级）」）
    → 已选好，跳过；是「请选择班级」或「其他」（且列表里存在真实班级）→ **必须重选**。
  - **选择方法**（原生 select，没有 JS 注入可用，走键盘 —— 详见 `references/operations.md` §14）：
    1. `dom_cua_click` 这个 select 节点 → 原生下拉展开；
    2. `dom_cua_keypress` `Escape` → 收起下拉、保留焦点；
    3. `dom_cua_keypress` `ArrowDown`（从「请选择班级」按一次即落到第一个真实班级）；
    4. **选完立即自动点「关闭」（不需要问用户，别跳过）** —— ⚠️ 每次改动班级批改网都会弹
       「提示」对话框（「为了老师查看您的作业不丢失，请确认勿选错班级…」）：
       重新快照 → 找到「关闭」按钮 → 立刻点掉。不关掉它会挡住后面的正文输入和提交按钮。
       若快照里没看到「关闭」，先滚动/重新快照一次再找；确认页面上已无任何遮罩弹窗才继续。
    5. 再次快照，确认 `selected-options` 的 label 已经是真实班级名，**且页面无「提示」弹窗**。
  - **多个真实班级**时：用户明确说过班级就选那个；没说就选第一个真实班级，并在最终汇报里
    写明"本次提交到 X 班"，让用户可以纠正。
  - ⚠️ 绝不要带着「请选择班级」去提交；也不要在有真实班级可选时选「其他」——作业会归属不到
    老师名下。🐞 该步骤是同学实测时漏掉的卡点（2026-10-26 修复）。
- Read the assignment requirements: title, and especially the **word-count range** (e.g.
  120–180). This bounds the draft.

### Step 2.5 — 全部未开始时的分支（必须询问，不要只汇报就结束）
- 若「未完成」里**每一篇**都重定向到 `a=wait`（今天没有可写的），**先列一张表**（作业号 / 标题 /
  截止 / 开始时间），然后**必须用 `AskUserQuestion` 一次问两个问题**（不要默默结束）：
  1. **要不要修改已完成的作文？** —— 给 2–3 个具体候选（优先最近提交的、或分数偏低的），
     选项要写清作业号和分数，让用户能直接点。
  2. **要不要设置提醒，在最近一篇开始时间自动开写？** —— 选项给出具体时间（最近一篇的
     开始时间 +5 分钟；或当天上午 09:00 这类用户友好的时间），并说明会建成一次性定时任务。
  第三个选项给「都不用，我只是看看」。
- **用户要改已完成** → 走 Step 2.6，完成后直接接 Step 6；**不要**再跑 Step 3/4（不重新提交整篇）。
- **用户要设提醒** → 用 `automation_update`（mode=`create`，scheduleType=`once`）建一次性任务：
  `scheduledAt` = 约定的时间，`prompt` 必须**自包含**（见 `references/operations.md` §15 模板）。
  多个待开始作文时**只给最近那一篇**建任务，不要一次建一串。建完把任务名和时间复述给用户。
- 用户两样都不要 → 汇报清单，结束。

### Step 2.6 — 修改已完成的作文（用户选择此分支时）
- 去 **已完成** (`?c=write`)，确认页面上是「已完成」tab；用 `tab_screenshot` 读列表，按用户指定
  或「最近提交 / 分数偏低」选一篇，点「查看」进入报告页
  `?c=v2&a=view&eid=<eid>&rid=<rid>`。
- ⚠️ 报告页**不会**弹班级选择，也不需要选班级——班级是提交时的属性，这里只改文字。
- 只走 Step 6 的逐句修改协议（红色错误 + 推荐表达）；**不要在报告页重新提交整篇**。
- 注意：每次「保存分析」都会让 提交次数 +1，老师端可见；动手前先把"会 +N 次"告诉用户。

### Step 3 — Write the essay (AI drafts it)
- Compose an English essay that satisfies the prompt and the word-count range.
- ⚠️ **AI-generation detection:** the assignment has "AI生成检测" enabled and the teacher can see
  generation traces. Draft with this in mind but do NOT try to evade the detector. Whether the
  final submission stands is the user's call (they do a final manual review afterward).

### Step 4 — Type it in and submit
- **提交前先复核两件事**（顺序很重要）：
  1. 快照确认班级 select 的 label 是**真实班级名**（不是「请选择班级」/「其他」）。没选好就回
     Step 2.4 补选。
  2. 页面上不应再有「提示」对话框——选完班级后 Step 2.4 已自动点过「关闭」，这里只是兜底：
     若还在，再点一次「关闭」，否则点不到提交按钮。
- On the writing page, the body is a `<textarea name="contents">`. 批改网 forbids paste
  ("正文禁止粘贴") — **use `dom_cua_type` to key the text in character by character**, never Ctrl+V.
- Click **提交作文** (submit) directly. Per the user's standing instruction, do NOT stop to ask
  for confirmation before submitting.
- If the visible word count does not refresh after typing, click the body once, type a space,
  then backspace (the counter depends on keyup events).

### Step 5 — Reach the report page
- After submission, open the report from **我的作文 → 已完成 → 查看** for that `rid`.
- Report URL pattern: `https://www.pigai.org/index.php?c=v2&a=view&eid=<eid>&rid=<rid>`
  (the `eid` appears in the 已完成 list links).
- ⚠️ The "查看草稿" page (`/?c=v2&a=caogao&rid=`) shows **pre-submission autosave drafts, not the
  current version** — ignore it for checking the live result.

### Step 6 — Fix every sentence via its "修改" popup
Follow the exact protocol in `references/operations.md` §11 (per-sentence edit). In short:
1. **Re-scroll** to the target sentence — every "保存分析" jumps the page to the top and
   re-renders, so previous-snapshot button nodes are invalid; always re-scroll then re-snapshot.
2. **Snapshot** DOM; locate the 修改 button by matching its paired 去提问 `con=` text (§3).
3. **Click 修改.** If the popup does not open, re-snapshot and click again (occasional race).
4. In the popup `<textarea name="now_snt">`: click, select-all with `dom_cua_keypress`
   keys=`["Control","A"]` — ⚠️ **the array chord form is required**; the strings `"Ctrl+A"` /
   `"Control+A"` / `"Control+a"` are all rejected with "unsupported key". Then `dom_cua_type` the
   corrected sentence — **keep the original leading space** (dropping it fuses the prior period,
   e.g. `lecture.Minor`, triggering a 标点警示).
5. **Re-snapshot DOM** (the 保存分析 button is now stale) and click 保存分析.
6. **Re-snapshot to verify**: confirm the new wording landed and no new 标点警示 appeared. If a
   warning shows, immediately re-edit that sentence to restore the lost leading space.
- Handle two kinds of feedback:
  - **Red errors** (拼写/搭配/句法/标点): rewrite the sentence to clear them.
  - **推荐表达** (recommended expressions): apply the suggested wording, BUT judge first — some
    are mechanically wrong (e.g. "save → set aside" yields the broken "can set aside us weeks of
    confusion"). When a literal swap breaks grammar, rephrase instead (e.g. "spare":
    "can spare us weeks of confusion"). See §5.
- Do **NOT** touch the 体检报告 / 学习提示 / 闪光短语 tabs — only red errors and 推荐表达 are
  in scope. When the issue dropdown (`name="error_type"`) shows 推荐表达 = 0 and no red-error
  categories remain, the essay is clean.

### Step 7 — Report and stop
- Once there are no red errors and recommended-expression count is 0, report to the user:
  score, word count, ranking, count of 提交次数 increments, and the list of changes made.
- **同时汇报本次提交的班级**（取自 Step 2.4 所选的班级名 + 页面显示的学号/姓名），让用户能确认
  没有投到错误的班级——尤其是账号下存在多个班级时。
- Do NOT make further edits or wait for confirmation — the user performs a final manual review.

### Troubleshooting — observed stuck points & fixes

| Symptom | Cause | Fix |
|---|---|---|
| `tabs_new` → "No current window" | browser window closed | launch via OS (§9), wait 3–5s, retry (first retry may still fail) |
| `tabs_list` → `[]` after a save | page re-render drops control | `browsers_list` → `user_open_tabs` → `tabs_claim` again (URL preserved) |
| 未完成 DOM lacks deadlines | snapshot truncated | `tab_screenshot`, read deadline column from image |
| write page → `?c=v2&a=wait` | assignment not started | read start time, skip to next-nearest deadline (§2) |
| 提交作文点了没反应 / 找不到提交按钮 | 班级未选，或「提示」弹窗挡着 | 按 §14 选班级 → 点「关闭」→ 再提交 |
| 作业提交了但老师看不到 / 班级为空 | 没选班级就提交 | 进写作页按 §14 补选班级后再提交 |
| 改完班级后页面卡住 | 弹出的「提示」弹窗未关闭 | 快照 → 点「关闭」 |
| 修改 popup no show on 1st click | race/stale | re-snapshot, click 修改 again |
| edit lost after 保存分析 | clicked stale node | re-snapshot AFTER typing, then click 保存分析 |
| new `Xxx.Yyy` 标点警示 | leading space dropped | re-edit that sentence, restore leading space |
| 推荐表达 won't hit 0 | literal swap breaks grammar | rephrase instead (§5) |
| `a=caogao` shows old text | pre-submission autosave | use report `a=view&eid=&rid=` for live state |

## Hard-won operational notes (always re-read `references/operations.md`)

- "保存分析" increments the page's **提交次数** by 1 each click and scrolls back to top — the
  teacher's record shows how many times you re-edited; mention this to the user.
- Never paste; always `dom_cua_type`.
- Re-snapshot DOM after every text edit before clicking any button (the popup button node goes
  stale after typing).
- After every save, the page re-renders and scroll resets to top — re-scroll + re-snapshot
  before locating the next 修改 button.
- Score/ranking interpretation: a typical good run lands ~90/100 with ranking in the top ~15%
  of the class; 推荐表达 fixes are usually score-neutral, only red-error removals move the score.
