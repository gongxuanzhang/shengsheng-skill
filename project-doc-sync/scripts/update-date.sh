#!/usr/bin/env bash
# todo.md 更新"最后更新"日期
# 用法: bash update-date.sh <todo.md 路径>
#
# 功能: 将 todo.md 中的 "> 最后更新: YYYY-MM-DD" 更新为今天的日期

set -euo pipefail

TODO_FILE="${1:?用法: bash update-date.sh <todo.md路径>}"
TODAY=$(date +%Y-%m-%d)

if [[ ! -f "$TODO_FILE" ]]; then
    echo "错误: 文件不存在: $TODO_FILE"
    exit 1
fi

if grep -q '> 最后更新:' "$TODO_FILE"; then
    sed -i.bak "s/> 最后更新: [0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}/> 最后更新: ${TODAY}/" "$TODO_FILE"
    rm -f "${TODO_FILE}.bak"
    echo "✅ 已更新日期为 ${TODAY}"
else
    echo "⚠️  未找到 '> 最后更新:' 行，跳过"
fi
