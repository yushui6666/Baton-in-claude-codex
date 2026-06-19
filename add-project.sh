#!/usr/bin/env bash
# 新项目接入：在本套件内创建摘要目录 + project.md，
# 并在目标项目根写入 Claude Code / Codex 的自动加载文件，最后登记到 INDEX.md。
#
# 用法: add-project.sh <项目真实路径> [简介]
# 幂等：已存在的文件不会被覆盖；可重复运行。
set -euo pipefail

# 本套件根目录（脚本所在目录）——无论套件放在哪都能正确定位
KIT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PROTOCOL="$KIT/PROTOCOL.md"
INDEX="$KIT/INDEX.md"
PROJECTS="$KIT/projects"

path="${1:-}"
if [ -z "$path" ]; then
  echo "用法: add-project.sh <项目真实路径> [简介]" >&2
  exit 1
fi
# 规范化为绝对路径
path="$(cd -- "$path" >/dev/null 2>&1 && pwd)" || { echo "❌ 目录不存在或无法进入: ${1}" >&2; exit 1; }

proj="$(basename "$path")"
ctxdir="$PROJECTS/$proj"
desc="${2:-}"

# 简介：未提供则尝试从 README 第一个一级标题提取
if [ -z "$desc" ] && [ -f "$path/README.md" ]; then
  desc="$(grep -m1 -E '^#[[:space:]]+' "$path/README.md" | sed -E 's/^#+[[:space:]]*//' || true)"
fi
[ -z "$desc" ] && desc="（待补充）"

mkdir -p "$ctxdir"

# 1) project.md
if [ ! -f "$ctxdir/project.md" ]; then
  cat > "$ctxdir/project.md" <<EOF
# $proj

- **真实路径**: $path
- **技术栈**: （待补充）
- **当前目标**: $desc
- **关键文件**: （待补充）
- **注意事项**: （待补充）
- **协议文件**: $PROTOCOL
EOF
  echo "✅ 创建 $ctxdir/project.md"
else
  echo "⏭  已存在 $ctxdir/project.md，跳过"
fi

# 2) 目标项目根的自动加载文件（Claude Code=CLAUDE.md, Codex=AGENTS.md）
write_bootstrap () {
  cat > "$1" <<EOF
# AI 终端跨工具协作协议（自动加载 · 强制指令）

⚠️ 本文件在会话启动时自动加载，优先级高于默认行为。当前项目名：\`$proj\`

## 会话开始时（必须先做，再回答用户）
1. 读取协议全文：\`$PROTOCOL\`
2. 读取本项目所有历史摘要：\`$ctxdir/\` 下全部 \`*.md\`
3. 向用户简述：上次哪个终端、在什么时间、做了什么，然后再开始工作。

## 每轮回复结束前（自动执行，无需用户说"结束"）
把本轮进展摘要**追加**（勿覆盖）到：
\`$ctxdir/<终端名>.md\`
- 终端名：Claude Code=\`claude-code\`，Codex=\`codex\`。
- 每轮一条、保持简洁；纯闲聊未做实质操作时可跳过。摘要格式见 PROTOCOL.md。

> 完整规则以 \`$PROTOCOL\` 为准（唯一维护点）。
EOF
}

for f in CLAUDE.md AGENTS.md; do
  if [ ! -f "$path/$f" ]; then
    write_bootstrap "$path/$f"
    echo "✅ 创建 $path/${f}"
  else
    echo "⏭  已存在 $path/${f}，跳过"
  fi
done

# 3) 登记到 INDEX.md（去重，插入到锚点之前）
if grep -qE "^\| +$proj +\|" "$INDEX"; then
  echo "⏭  INDEX.md 已收录 ${proj}，跳过"
elif grep -q '<!-- ADD-PROJECT-HERE -->' "$INDEX"; then
  row="| $proj | $path | $desc | [$proj/](./projects/$proj/) |"
  awk -v r="$row" '/<!-- ADD-PROJECT-HERE -->/{print r} {print}' "$INDEX" > "$INDEX.tmp" \
    && mv "$INDEX.tmp" "$INDEX"
  echo "✅ INDEX.md 登记 $proj"
else
  echo "⚠️  INDEX.md 缺少 <!-- ADD-PROJECT-HERE --> 锚点，未自动登记，请手动添加：" >&2
  echo "    | $proj | $path | $desc | [$proj/](./projects/$proj/) |" >&2
fi

echo "🎉 完成：$proj 已接入跨终端协作协议（摘要目录 ${ctxdir}）"
