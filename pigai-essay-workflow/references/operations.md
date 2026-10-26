# 批改网工作流 — 操作手册 (operations.md)

Detailed, low-level operational knowledge for the `pigai-essay-workflow` skill. Read this before
the first run of each session. It captures the UI quirks and DOM patterns that naive automation
gets wrong.

## 1. Browser connection (Edge extension; browser_id 以 browsers_list 返回为准，下面示例中的 `=2` 请换成你自己的 id)

The user's 批改网 lives in the Microsoft Edge extension (browser_id=<id>, `user_tabs` capability).
Each new session the connection may need re-establishing:

```
mcp__browser__browsers_list                         # confirm browser_id=<id> exists
mcp__browser__user_open_tabs   browser_id=<id>         # list user-open tabs (may be empty)
mcp__browser__tabs_list        browser_id=<id>         # list controlled tabs
mcp__browser__tabs_claim       browser_id=<id> tab_id=1 # claim the target tab
```

- If `tabs_list` returns `[]` after a navigation, the tab briefly dropped. Re-run
  `user_open_tabs` (browser_id=<id>); the tab reappears as `state:"observed", claimed:false`. Claim
  it again — the URL is preserved (a transient display artifact may show only
  `https://www.pigai.org`).
- `tab_goto` to a pigai URL is the most reliable way to land on a known page.

### Reconnect routine (when the controlled tab drops)
After a save or navigation the controlled tab may momentarily disappear from `tabs_list`. Do NOT
start the whole flow over — recover in three steps:
1. `mcp__browser__browsers_list` (browser_id=<id>) — confirm the browser is still present.
2. `mcp__browser__user_open_tabs` (browser_id=<id>) — the tab reappears as
   `state:"observed", claimed:false` with its URL preserved (display may show only
   `https://www.pigai.org`).
3. `mcp__browser__tabs_claim` (browser_id=<id>, tab_id) — re-claim; continue.
Note: a tab created via `tabs_new` is usually **already controlled** (no claim needed); only
pre-existing user tabs surfaced by `user_open_tabs` require claiming.

## 2. Key pigai URL patterns

| Purpose | URL |
|---|---|
| 我的作文 (default landing, 已完成) | `https://www.pigai.org/index.php?c=write` |
| 未完成 list | `https://www.pigai.org/index.php?c=write&a=waitComplete` |
| Writing page (edit/compose) | `https://www.pigai.org/index.php?c=v2&a=write&rid=<rid>` |
| **Not-yet-open redirect (未开始)** | `...?c=v2&a=wait&rid=<rid>` — shows「开始时间为 … 距离写作开始时间还有 N天」；该作文还不能写，跳过选下一篇 |
| **Report page (批改报告)** | `https://www.pigai.org/index.php?c=v2&a=view&eid=<eid>&rid=<rid>` |
| Draft list (pre-submission only) | `https://www.pigai.org/?c=v2&a=caogao&rid=<rid>` |

- The `eid` (essay instance id, e.g. `235447901`) appears in the 已完成 list links alongside the
  `rid`. Copy it from there; do not guess it.
- **Report page is reached from 我的作文 → 已完成 → 查看** (node with
  `?c=v2&a=view&eid=...&rid=...`). This is the authoritative post-submission view.
- **"查看草稿" (`a=caogao`) shows autosave drafts from BEFORE submission**, not the live
  version with [修改] edits applied. Do not use it to judge the current state.

## 3. Locating each sentence's "修改" button

On the report page, every sentence has two paired links in order:

```
<a href="javascript:;" >修改</a>                                  # node N
<a href="http://rengong.pigai.org/...&con=<URL-encoded sentence>">去提问</a>  # node N+1
```

- The **修改** link immediately precedes the 去提问 link whose `con=` parameter holds that
  sentence's text. To find sentence X's button: snapshot the region, read the 去提问 `con=`
  value, match it to the target sentence, then click the 修改 link right before it.
- The popup opens a `<textarea name="now_snt">` pre-filled with the sentence (usually with a
  leading space). Buttons in the popup: 继续修改 / 保存分析 / 取消 / 在线答疑.

## 4. The edit-popup gotchas (cause of most failures)

1. **Stale node after typing.** After `dom_cua_type` into `now_snt`, the popup's button nodes go
   stale. Always re-run `dom_cua_get_visible_dom` to obtain the fresh "保存分析" node_id, then
   click it immediately. Clicking the stale node silently fails and the edit is lost.
2. **Leading space.** Select-all + retype the whole sentence. Keep the sentence's original leading
   space. Dropping it fuses the previous sentence's period with this one
   (`lecture.Minor steps`) → a 标点警示 (punctuation warning) appears.
3. **Save scrolls to top.** "保存分析" increments 提交次数 by 1 and jumps the page to the top.
   After saving, re-scroll to locate the next sentence's 修改 button.
4. **No paste.** Body editor and popups both reject paste. Always `dom_cua_type`.
5. **Key-chord syntax (实测坑).** `dom_cua_keypress` 的组合键必须写成**数组和弦**：
   `keys=["Control","A"]`、`["Control","V"]`。字符串写法 `"Ctrl+A"` / `"Control+A"` /
   `"Control+a"` 都会报 `unsupported key`。单键仍然用字符串：`"Escape"`、`"ArrowDown"`。

## 5. Recommended-expression judgment (do not apply blindly)

The recommender sometimes suggests a swap that is ungrammatical in context:

- Example hit: sentence `...twenty minutes set aside with a professor can save us weeks of
  confusion.` The system recommended `save → set aside` (because the sentence already contains
  "set aside" earlier). Literal application yields `can set aside us weeks of confusion` — broken
  ("set aside" does not take the double-object `us weeks`).
- Correct handling: rephrase to remove the flagged verb while keeping meaning, e.g.
  `can spare us weeks of confusion` (spare + double object is grammatical). This clears the
  推荐表达 count without breaking the sentence.
- General rule: when a recommended swap would produce an awkward/ungrammatical construction,
  rephrase the sentence instead of a literal word swap.

## 6. Status checks

- Issue dropdown `name="error_type"` on the report page lists live counts, e.g.
  `学习提示(10) 闪光短语(1) 拓展辨析(1) 推荐表达(1)`. **When 推荐表达 and all error categories
  are absent, the essay is clean.** 学习提示 / 闪光短语 / 拓展辨析 are informational/praise and
  are NOT in scope.
- Score/ranking/word-count panel sits at the top of the report. A solid run: score ~90.5, ranking
  ~top 15% of class (e.g. 188/1189), word count within the assignment's required range.

## 7. Word-count refresh workaround

The editor's word counter updates only on keyup events. After `dom_cua_type` insertion the count
may not refresh. Fix: click the body textarea once, type a space, then press Backspace. The count
recomputes.

## 8. AI-generation detection (standalone caveat)

The assignment has "AI生成检测" enabled. The essay produced by this workflow is AI-generated, so
the teacher's side may flag generation traces. The workflow does NOT attempt to evade detection;
final submission is the user's decision, and they perform a manual final review after the run.

## 9. 自动启动浏览器（无窗口回退）

`user_open_tabs` 返回空、`tabs_new` 返回 "No current window" 时，说明目标浏览器没有活动窗口。agent 应直接用系统命令启动浏览器程序，再重连，而非停下来等用户：

- Windows (Edge): `cmd /c start msedge` 或 PowerShell `Start-Process msedge`
- macOS: `open -a "Microsoft Edge"`
- Linux: `microsoft-edge`

启动后等 3–5 秒让扩展连上，重新 `browsers_list` 探测，然后继续 `tabs_new` / `user_open_tabs`。若 Edge 仍不可用，回退到内置浏览器 `browser_id=1`（desktop 类型）：`tabs_new` 开标签 goto pigai.org；该浏览器无你的登录态，会停在登录页，需提示用户登录后再继续。

## 10. 搜批改网（URL 不可达时的备选）

直接 goto `pigai.org` 失败时，可用搜索引擎（百度/Google）搜"批改网"，从结果进入官网
`https://www.pigai.org`，再走「我的作文 → 未完成」路径。日常用固定 URL 即可，搜索仅作兜底。

## 11. Per-sentence edit protocol (do this for EVERY fix)

This is the single most failure-prone part. Follow exactly, in order:

1. **Re-scroll** the report to the target sentence. ⚠️ Every "保存分析" jumps the page to the
   top and re-renders, invalidating all prior button node_ids. Always re-scroll, THEN
   re-snapshot, before locating the next 修改 button.
2. **Snapshot** `dom_cua_get_visible_dom`; find the sentence's 修改 button by matching its paired
   去提问 `con=` text (see §3).
3. **Click 修改.** If the popup does not appear, re-snapshot and click 修改 again — it
   occasionally needs two clicks due to a render race.
4. In the popup `<textarea name="now_snt">`: click it, select all with `dom_cua_keypress`
   keys=`["Control","A"]`（数组和弦写法，见 §4.5）, then `dom_cua_type` the corrected sentence.
   **Keep the original leading space** (e.g. type `" Minor steps…"`, not `"Minor steps…"`).
5. **Re-snapshot DOM** — the 保存分析 button node is now stale — then click 保存分析.
6. **Re-snapshot to verify**: confirm the new wording landed in the body and that no new
   标点警示 appeared (e.g. `lecture.Minor` = prior period fused with this sentence because the
   leading space was dropped). If a warning shows, immediately re-edit that sentence to restore
   the space.

## 12. Verification before reporting

After fixing everything:
- Re-get the report DOM and open the issue dropdown (`name="error_type"`). Confirm 推荐表达 = 0
  and no red-error categories remain.
- Take a **full-page screenshot** as evidence of the final state (score, 0 errors, 0 推荐表达).
- Confirm the score did not drop vs. before the run. (推荐表达 fixes are usually score-neutral;
  only red-error removals move the score.)
- Report to user: score, word count, ranking, 提交次数 increments, and the change list.

## 13. Stuck-point → fix quick table

| Symptom | Cause | Fix |
|---|---|---|
| `tabs_new` → "No current window" | browser window closed | launch via OS (§9), wait 3–5s, retry (first retry may still fail) |
| `tabs_list` → `[]` after a save | page re-render drops control | `browsers_list` → `user_open_tabs` → `tabs_claim` again (URL preserved) |
| 未完成 DOM lacks deadlines | snapshot truncated | `tab_screenshot`, read deadline column from image |
| write page → `?c=v2&a=wait` | assignment not started | read start time, skip to next-nearest deadline (§2) |
| 提交作文点了没反应 / 找不到提交按钮 | 班级未选，或「提示」弹窗挡着 | select class (§14) → click 「关闭」 → submit |
| 提交后老师看不到 / 班级为空 | submitted without selecting class | re-enter write page, select class (§14), resubmit |
| 改完班级页面像"卡住" | 「提示」modal still open | re-snapshot → click 「关闭」 |
| 修改 popup no show on 1st click | race/stale | re-snapshot, click 修改 again |
| edit lost after 保存分析 | clicked stale node | re-snapshot AFTER typing, then click 保存分析 |
| new `Xxx.Yyy` 标点警示 | leading space dropped | re-edit, restore leading space |
| 推荐表达 won't hit 0 | literal swap breaks grammar | rephrase instead (§5) |
| `a=caogao` shows old text | pre-submission autosave | use report `a=view&eid=&rid=` for live state |

## 14. 班级选择（写作页必做 — 2026-10-26 修复同学实测卡点）

**症状**：点进作文后直接写正文、点「提交作文」，会卡住——提交按钮点了没反应，或者提交成功但
班级为空（老师端看不到这份作业）。根因是写作页的「班级」下拉没选。

**页面位置**：写作页**底部、「提交作文」按钮左侧**：

```
班级：[请选择班级 ▾]   学号:<学号>, 姓名:<姓名>。若不存在您的班级请选择"其他"或者联系我们客服
```

**DOM 特征**（可见 DOM 快照里）：

```html
<select node_id=N value="请选择班级" selected-options="[{...label:"请选择班级"}]">
  请选择班级 <你的班级名> 其他
</select>
```

- 选项顺序固定：`请选择班级`（占位）→ 真实班级（可能多个）→ `其他`。
- ⚠️ 占位项和「其他」的 `value` 都可能是空字符串——**不要只靠 value 判断，要看
  `selected-options` 里的 label**。
- 若快照里没有这个 select，先把页面滚到底部（「提交作文」附近）再抓一次快照。

**选择流程（键盘法，已在本机实测）**：

1. `dom_cua_click` 这个 select 节点 → 展开原生下拉。
2. `dom_cua_keypress` `["Escape"]` → 收起下拉，select 保持焦点。
3. `dom_cua_keypress` `["ArrowDown"]` → 从「请选择班级」下移一项 = 第一个真实班级。
   （如果当前停在「其他」，用 `ArrowUp` 回到真实班级。）
4. ⚠️ **每次改动班级都会弹出「提示」对话框**：
   「为了老师查看您的作业不丢失，请确认勿选错班级；若不存在您的班级请选择其他」
   → 重新快照 → 点「关闭」。**不关掉会挡住后面的提交按钮。**
5. 重新快照，确认 `selected-options` 的 label 已经是真实班级名
   （例如 `<你的班级名>`）。

**多班级时怎么选**：用户明确说过班级名 → 选它；没说 → 选第一个真实班级，并在最终汇报里写明
「本次提交到 X 班」，让用户可以纠正。

**红线**：

- 绝不要带着「请选择班级」去提交。
- 有真实班级可选时不要选「其他」。
- 只有学生确实不属于任何班级时，才按官网提示选「其他」。

**顺带核对账号**：班级旁边会显示「学号:xxx, 姓名:xxx」。在同学的机器上运行时，可以用它确认
当前登录的是同学本人，而不是别人的账号。
