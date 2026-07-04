#!/bin/bash

#Develop by Gemini

# 初始化统计列表
success_list=()
failed_list=()

# 启用 nullglob 避免没有匹配文件时把 *.patch 当作字符串处理
shopt -s nullglob
patches=(*.patch)

# 检查当前目录下是否有 .patch 文件
if [ ${#patches[@]} -eq 0 ]; then
    echo "❌ 错误: 未在当前目录下找到任何 .patch 文件。"
    exit 0
fi

echo "🚀 开始自动应用补丁..."
echo "=========================================="

# 检查是否处于 Git 仓库中，决定使用的命令
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "ℹ️ 检测到 Git 仓环境，将使用 [git apply] 尝试打补丁..."
    IS_GIT=true
else
    echo "ℹ️ 未检测到 Git 仓，将使用标准 [patch -p1] 尝试打补丁..."
    IS_GIT=false
fi
echo "=========================================="

for patch in "${patches[@]}"; do
    echo "正在尝试应用: $patch ..."
    
    if [ "$IS_GIT" = true ]; then
        git apply "$patch" > /dev/null 2>&1
        STATUS=$?
    else
        patch -p1 < "$patch" > /dev/null 2>&1
        STATUS=$?
    fi

    if [ $STATUS -eq 0 ]; then
        echo "  ✅ 成功!"
        success_list+=("$patch")
    else
        echo "  ❌ 失败!"
        failed_list+=("$patch")
    fi
    echo "------------------------------------------"
done

# 打印最终报告汇总
echo ""
echo "=================== 报告汇总 ==================="
echo "📊 发现补丁总数: ${#patches[@]} 个"
echo "✅ 成功应用数量: ${#success_list[@]} 个"
echo "❌ 应用失败数量: ${#failed_list[@]} 个"
echo "==============================================="

if [ ${#success_list[@]} -gt 0 ]; then
    echo -e "\n[成功应用列表]:"
    for p in "${success_list[@]}"; do
        echo "  - $p"
    done
fi

if [ ${#failed_list[@]} -gt 0 ]; then
    echo -e "\n[应用失败列表]:"
    for p in "${failed_list[@]}"; do
        echo "  - $p"
    done
    echo -e "\n💡 提示: 针对同一功能如果同时存在 m (minus) 和 p (plus) 两个版本的补丁（例如 sys_reboot-3.11m 和 3.11p），其中一个失败属于正常现象。"
fi

# 确保以 exit code 0 退出
exit 0
