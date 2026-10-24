# 一键安装 pigai-essay-workflow 到 WorkBuddy 用户级 skills 目录（Windows PowerShell）
# 用法：在该仓库目录下运行  powershell -ExecutionPolicy Bypass -File install.ps1
$skillName = "pigai-essay-workflow"
$src = Join-Path $PSScriptRoot $skillName
$dest = Join-Path $env:USERPROFILE ".workbuddy\skills\$skillName"

if (-not (Test-Path $src)) {
    Write-Error "❌ 找不到 $skillName 目录，请确认 install.ps1 与 skill 文件夹在同一目录。"
    exit 1
}

New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
Copy-Item -Recurse $src $dest

Write-Host "✅ 已安装到：$dest"
Write-Host "请重开 WorkBuddy，然后说「开始帮我写作文」即可自动运行该 skill。"
Write-Host "（也可在 WorkBuddy 的 skill 列表中找到 pigai-essay-workflow 后手动触发。）"
