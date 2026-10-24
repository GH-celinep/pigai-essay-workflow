# pigai-essay-workflow

一个 WorkBuddy Skill：说一句「开始帮我写作文」，它就**自动打开浏览器 → 进批改网 → 找截止最近且已开始的未完成作文 → 看要求 → 代写 → 逐字键入并提交 → 按每句右侧「修改」弹窗清掉红色错误和推荐表达 → 改完汇报**。全部基于一次完整跑通提炼，内置了浏览器掉线重连、未开始作文跳过、逐句修改协议等坑点处理。


---

## 给你的朋友：一条命令安装并运行

### Windows（一条 PowerShell 命令，不需要 git）

整行复制运行：

```powershell
$d="$env:TEMP\pigai"; $s="$env:USERPROFILE\.workbuddy\skills"; New-Item -ItemType Directory -Force -Path $s | Out-Null; Invoke-WebRequest "https://codeload.github.com/GH-celinep/pigai-essay-workflow/zip/refs/heads/main" -OutFile "$d.zip"; Expand-Archive "$d.zip" -DestinationPath $d -Force; Copy-Item -Recurse -Force "$d\pigai-essay-workflow-main\pigai-essay-workflow" "$s\"; Remove-Item -Recurse -Force "$d.zip",$d
```

### macOS / Linux（一条命令）

```bash
mkdir -p ~/.workbuddy/skills && curl -L https://codeload.github.com/GH-celinep/pigai-essay-workflow/zip/refs/heads/main -o /tmp/pigai.zip && unzip -q /tmp/pigai.zip -d /tmp/pigai && cp -r /tmp/pigai/pigai-essay-workflow-main/pigai-essay-workflow ~/.workbuddy/skills/ && rm -rf /tmp/pigai /tmp/pigai.zip
```

（没有 `unzip` 可先装：`brew install unzip` 或 `apt install unzip`；也可以改用 git clone：
`git clone --depth 1 https://github.com/GH-celinep/pigai-essay-workflow.git /tmp/pigai && cp -r /tmp/pigai/pigai-essay-workflow ~/.workbuddy/skills/ && rm -rf /tmp/pigai`）

两条命令都会把 `pigai-essay-workflow/` 直接放进 `~/.workbuddy/skills/`（Windows 为
`%USERPROFILE%\.workbuddy\skills\`）。仓库里的 `install.sh` / `install.ps1` 是手动下载仓库目录后的备选安装脚本，日常用上面的命令即可。

### 怎么确认装好了

**Windows**（跑下面这条，能看到 `SKILL.md`、`references\`、`references\operations.md` 三样就是装好了）：

```powershell
Get-ChildItem -Recurse "$env:USERPROFILE\.workbuddy\skills\pigai-essay-workflow"
```

**macOS / Linux**：

```bash
ls -R ~/.workbuddy/skills/pigai-essay-workflow
```

最直接的验证：**重开 WorkBuddy，说一句「开始帮我写作文」**——skill 被自动加载并开始跑流程，就说明装好了。

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
install.sh              # macOS / Linux 一键安装（备选）
install.ps1             # Windows 一键安装（备选）
README.md
```
