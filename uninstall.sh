#!/usr/bin/env bash
# 卸载：仅移除本套件注入到全局配置的标记块，保留你自己的其它内容。
# 不会删除 projects/ 下的摘要，也不会删除各项目里的 CLAUDE.md/AGENTS.md
# （如需清理项目内文件，请手动删除对应项目根的 CLAUDE.md / AGENTS.md）。
set -euo pipefail

START="<!-- >>> AI-cross-agent >>> -->"
END="<!-- <<< AI-cross-agent <<< -->"

strip () {
  local file="$1"
  [ -f "$file" ] || { echo "⏭  不存在: $file"; return; }
  awk -v s="$START" -v e="$END" '
    $0==s {skip=1}
    skip!=1 {print}
    $0==e {skip=0}
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  echo "✅ 已从 $file 移除协议块"
}

strip "$HOME/.claude/CLAUDE.md"
strip "$HOME/.codex/AGENTS.md"
echo "🎉 卸载完成（projects/ 摘要与项目内 CLAUDE.md/AGENTS.md 已保留）。"
