#!/usr/bin/env bash
# 一键安装 pigai-essay-workflow 到 WorkBuddy 用户级 skills 目录
# 用法：
#   ./install.sh                      # 从本仓库（已 clone）安装
#   bash <(curl -sSL <原始install.sh链接>)   # 远程直接装（需脚本托管在 GitHub raw）
set -euo pipefail

SKILL_NAME="pigai-essay-workflow"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/$SKILL_NAME"
DEST="$HOME/.workbuddy/skills/$SKILL_NAME"

if [ ! -d "$SRC_DIR" ]; then
  echo "❌ 找不到 $SKILL_NAME 目录，请确认 install.sh 与 skill 文件夹在同一目录。" >&2
  exit 1
fi

mkdir -p "$HOME/.workbuddy/skills"
rm -rf "$DEST"
cp -R "$SRC_DIR" "$DEST"

echo "✅ 已安装到：$DEST"
echo "请重开 WorkBuddy，然后说「开始帮我写作文」即可自动运行该 skill。"
echo "（也可在 WorkBuddy 的 skill 列表中找到 pigai-essay-workflow 后手动触发。）"
