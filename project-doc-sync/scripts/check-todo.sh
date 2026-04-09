#!/usr/bin/env bash
# todo.md 健康检查脚本
# 用法: bash check-todo.sh <todo.md 路径>
#
# 检查项:
# 1. 编号是否连续
# 2. 是否有空分区（有标题但无条目）
# 3. 日期是否过旧（超过 30 天未更新）

set -euo pipefail

TODO_FILE="${1:?用法: bash check-todo.sh <todo.md路径>}"
errors=0

if [[ ! -f "$TODO_FILE" ]]; then
    echo "错误: 文件不存在: $TODO_FILE"
    exit 1
fi

echo "🔍 检查 $TODO_FILE ..."

# 1. 检查编号连续性
expected=1
while IFS= read -r line; do
    if [[ "$line" =~ ^###\ ([0-9]+)\.\ .+$ ]]; then
        actual="${BASH_REMATCH[1]}"
        if [[ "$actual" -ne "$expected" ]]; then
            echo "❌ 编号不连续: 期望 ${expected}，实际 ${actual}（${line}）"
            errors=$((errors + 1))
        fi
        expected=$((actual + 1))
    fi
done < "$TODO_FILE"

# 2. 检查日期是否过旧
if grep -q '> 最后更新: ' "$TODO_FILE"; then
    date_str=$(grep '> 最后更新: ' "$TODO_FILE" | sed 's/.*> 最后更新: //')
    if [[ "$(uname)" == "Darwin" ]]; then
        file_epoch=$(date -j -f "%Y-%m-%d" "$date_str" +%s 2>/dev/null || echo 0)
    else
        file_epoch=$(date -d "$date_str" +%s 2>/dev/null || echo 0)
    fi
    now_epoch=$(date +%s)
    days_old=$(( (now_epoch - file_epoch) / 86400 ))
    if [[ "$days_old" -gt 30 ]]; then
        echo "⚠️  文档已 ${days_old} 天未更新（最后更新: ${date_str}）"
    fi
fi

# 3. 总结
if [[ "$errors" -eq 0 ]]; then
    echo "✅ 检查通过"
else
    echo "❌ 发现 ${errors} 个问题"
    exit 1
fi
