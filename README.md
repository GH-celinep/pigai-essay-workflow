# pigai-essay-workflow

一个 WorkBuddy Skill：说一句「开始帮我写作文」，它就**自动打开浏览器 → 进批改网 → 找截止最近且已开始的未完成作文 → 看要求 → 代写 → 逐字键入并提交 → 按每句右侧「修改」弹窗清掉红色错误和推荐表达 → 改完汇报**。全部基于一次完整跑通提炼，内置了浏览器掉线重连、未开始作文跳过、逐句修改协议等坑点处理。

> ⚠️ 该作业通常开启「AI 生成检测」。本 skill 不规避检测；最终是否提交由使用者决定，跑完请自己终审一遍。

---

## 给你的朋友：一条命令安装并运行

### macOS / Linux（一条命令）

把下面 `GH-celinep` 换成你实际的 GitHub 用户名，整行复制运行：

```bash
git clone --depth 1 https://github.com/GH-celinep/pigai-essay-workflow.git /tmp/pigai && bash /tmp/pigai/install.sh && rm -rf /tmp/pigai
```

### Windows（一条 PowerShell 命令）

```powershell
git clone --depth 1 https://github.com/GH-celinep/pigai-essay-workflow.git $env:TEMP/pigai; powershell -ExecutionPolicy Bypass -File $env:TEMP/pigai/install.ps1; Remove-Item -Recurse -Force $env:TEMP/pigai
```

安装脚本会把 `pigai-essay-workflow/` 复制到 `~/.workbuddy/skills/`（Windows 为
`%USERPROFILE%\.workbuddy\skills\`）。

### 装好后怎么运行（两种方式都行）

1. **说触发语**：重开 WorkBuddy，直接说「开始帮我写作文」——skill 会自动加载并跑全流程。
2. **手动选 skill**：在 WorkBuddy 的 skill 列表里找到 `pigai-essay-workflow`，选中后再说触发语或任意相关指令即可。

---

## 运行前必须满足的前提

- 已安装 WorkBuddy 的**浏览器扩展**（Edge / Chrome）并在 WorkBuddy 里连上浏览器控制；
- 浏览器里**登录着批改网**（pigai.org），且开着批改网标签页；
- 联网。

第一次运行建议先让 WorkBuddy 跑一下 `browsers_list` 确认它探测到的 `browser_id`
（skill 已改为运行时自动获取，不再写死，所以不同机器都能用）。

---

## 文件结构

```
pigai-essay-workflow/
├── SKILL.md            # 触发语 + 7 步主流程 + 卡壳速查表
└── references/
    └── operations.md   # 浏览器连接/重连、URL 模式、逐句修改协议、核验
install.sh              # macOS / Linux 一键安装
install.ps1             # Windows 一键安装
README.md
```
