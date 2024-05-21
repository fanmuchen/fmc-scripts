#!/bin/bash

# 这个脚本的目的是将当前目录及其子目录中所有符合特定模式的源代码文件合并到一个 Markdown 文件中，
# 并排除特定的目录。生成的文件包括一个文件树结构和每个文件的内容。用户可以选择将生成的文本复制到剪贴板。

# 输出文件名
output_file="merged_code.md"

# 清空输出文件
> "$output_file"

# 描述文件内容
cat <<EOF >> "$output_file"
这是一个合并的代码文件，包含项目中的所有源代码文件。
您可以在此文件中查看每个文件的内容以及它们在项目中的位置。
EOF

echo "" >> "$output_file"

# 定义要包含的文件模式
file_patterns=(
    "*.js"
    "*.html"
)

# 定义要排除的目录模式
exclude_patterns=(
    "node_modules"
    ".git"
    ".github"
)

# 构建 find 命令的参数
find_args=()

# 添加要包含的文件模式
for pattern in "${file_patterns[@]}"; do
    find_args+=(-name "$pattern" -o)
done
# 移除最后一个 -o
unset 'find_args[${#find_args[@]}-1]'

# 添加要排除的目录模式
for pattern in "${exclude_patterns[@]}"; do
    find_args+=(-not -path "*/$pattern/*")
done

# 查找符合条件的文件
files=$(find . "${find_args[@]}")

# 生成文件树并写入输出文件
echo "## 文件树" >> "$output_file"
echo '```' >> "$output_file"
# 使用 tree 命令生成文件树
tree -I "$(IFS='|'; echo "${exclude_patterns[*]}")" --noreport | sed 's|^\./||' >> "$output_file"
echo '```' >> "$output_file"
echo "" >> "$output_file"

# 遍历所有文件
for file in $files; do
    # 获取文件的相对路径
    relative_path=$(echo "$file" | sed 's|^\./||')
    
    # 将文件路径写入输出文件
    echo "## $relative_path" >> "$output_file"
    echo '```' >> "$output_file"
    
    # 将文件内容写入输出文件
    cat "$file" >> "$output_file"
    
    # 确保代码块结束标记正确换行
    echo -e '\n```' >> "$output_file"
    echo "" >> "$output_file"
done

echo "合并完成，输出文件为 $output_file"

# 询问用户是否将生成的文本复制到剪贴板
read -p "是否将生成的文本复制到剪贴板？按回车同意，否则取消: " response

if [[ -z "$response" ]]; then
    if command -v xclip &> /dev/null; then
        cat "$output_file" | xclip -selection clipboard
        echo "文本已复制到剪贴板。"
    elif command -v pbcopy &> /dev/null; then
        cat "$output_file" | pbcopy
        echo "文本已复制到剪贴板。"
    else
        echo "未找到适合的剪贴板工具 (xclip 或 pbcopy)。请手动复制文件内容。"
    fi
else
    echo "未将文本复制到剪贴板。"
fi

