#!/usr/bin/env bash
# 一键安装：把「自动加载协议」的引导块注入到两个工具的全局配置：
#   - Claude Code: ~/.claude/CLAUDE.md
#   - Codex:       ~/.codex/AGENTS.md
# 幂等：通过标记块实现，重复运行只会替换旧块，不会重复追加，也不破坏你已有的内容。
set -euo pipefail

KIT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
START="<!-- >>> AI-cross-agent >>> -->"
END="<!-- <<< AI-cross-agent <<< -->"

chmod +x "$KIT/add-project.sh" "$KIT/uninstall.sh" 2>/dev/null || true

block () {
  local terminal="$1"
  cat <<EOF
$START
# AI 终端跨工具协作协议（全局 · 自动加载）

本套件根目录：\`$KIT\`

当你在某个已接入的项目目录下工作时（该目录含指向本协议的 CLAUDE.md/AGENTS.md，
或项目已登记于 \`$KIT/INDEX.md\`），**必须**遵守 \`$KIT/PROTOCOL.md\`：

1. **会话开始**：读取 \`$KIT/PROTOCOL.md\`，再读取 \`$KIT/projects/<项目名>/\` 下全部 \`*.md\`
   （其他终端的历史摘要），并先向用户简述上次进展。
2. **每轮回复结束前（自动，无需用户说“结束”）**：把本轮进展摘要**追加**到
   \`$KIT/projects/<项目名>/$terminal.md\`（格式见 PROTOCOL.md）。每轮一条、保持简洁；
   纯闲聊未做实质操作可跳过。
3. **收到「接入新项目」请求**：直接运行 \`$KIT/add-project.sh "<项目真实路径>" ["简介"]\`。

> 完整规则以 \`$KIT/PROTOCOL.md\` 为准（唯一维护点）。项目索引见 \`$KIT/INDEX.md\`。
$END
EOF
}

inject () {
  local file="$1" terminal="$2"
  mkdir -p "$(dirname "$file")"
  [ -f "$file" ] || : > "$file"
  # 1) 删除旧的标记块（若存在）
  awk -v s="$START" -v e="$END" '
    $0==s {skip=1}
    skip!=1 {print}
    $0==e {skip=0}
  ' "$file" > "$file.tmp"
  # 2) 去掉文件尾部多余空行后，追加新块
  awk 'NF{p=NR} {a[NR]=$0} END{for(i=1;i<=p;i++) print a[i]}' "$file.tmp" > "$file.tmp2" || cp "$file.tmp" "$file.tmp2"
  if [ -s "$file.tmp2" ]; then printf '\n' >> "$file.tmp2"; fi
  block "$terminal" >> "$file.tmp2"
  mv "$file.tmp2" "$file"
  rm -f "$file.tmp"
  echo "✅ 已写入 $file"
}

echo "📦 安装 AI-cross-agent，套件目录：$KIT"
inject "$HOME/.claude/CLAUDE.md" "claude-code"
inject "$HOME/.codex/AGENTS.md" "codex"
echo
echo "🎉 安装完成。接下来："
echo "   1) 接入一个项目：  $KIT/add-project.sh \"/路径/到/你的项目\""
echo "   2) 用 Claude Code 或 Codex 打开该项目目录，即自动遵守协议。"
echo "   卸载：$KIT/uninstall.sh"
