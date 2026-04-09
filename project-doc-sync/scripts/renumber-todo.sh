#!/usr/bin/env bash
# todo.md 编号重排脚本
# 用法: bash renumber-todo.sh <todo.md 路径>
#
# 功能: 将 todo.md 中所有 "### N. " 格式的编号重新排列为连续编号
# 适用场景: 删除某个 TODO 条目后，手动运行此脚本修复编号

set -euo pipefail

TODO_FILE="${1:?用法: bash renumber-todo.sh <todo.md路径>}"

if [[ ! -f "$TODO_FILE" ]]; then
    echo "错误: 文件不存在: $TODO_FILE"
    exit 1
fi

# 计数器
counter=1

# 逐行处理，遇到 "### 数字. " 格式就重新编号
tmpfile=$(mktemp)
while IFS= read -r line; do
    if [[ "$line" =~ ^###\ [0-9]+\.\ (.+)$ ]]; then
        title="${BASH_REMATCH[1]}"
        echo "### ${counter}. ${title}" >> "$tmpfile"
        counter=$((counter + 1))
    else
        echo "$line" >> "$tmpfile"
    fi
done < "$TODO_FILE"

mv "$tmpfile" "$TODO_FILE"
echo "✅ 重新编号完成，共 $((counter - 1)) 个条目"
