#!/bin/bash

# 清理测试结果脚本
# 用于清理或管理测试生成的文件

echo "🧹 Qwen3 测试结果清理工具"
echo "=================================================================================="

CURRENT_DIR=$(pwd)
TEST_OUTPUT_DIR="$CURRENT_DIR/test_results"

# 检查测试结果目录是否存在
if [ ! -d "$TEST_OUTPUT_DIR" ]; then
    echo "📁 测试结果目录不存在: $TEST_OUTPUT_DIR"
    echo "✅ 无需清理"
    exit 0
fi

# 显示当前测试结果
echo "📊 当前测试结果目录结构:"
echo "────────────────────────────────────────────────────────────────"
find "$TEST_OUTPUT_DIR" -type f -exec ls -lh {} \; | awk '{print $5, $9}' | sort -k2
echo "────────────────────────────────────────────────────────────────"

# 计算总大小
TOTAL_SIZE=$(du -sh "$TEST_OUTPUT_DIR" 2>/dev/null | cut -f1)
FILE_COUNT=$(find "$TEST_OUTPUT_DIR" -type f | wc -l)

echo ""
echo "📈 统计信息:"
echo "   总大小: $TOTAL_SIZE"
echo "   文件数量: $FILE_COUNT"
echo ""

# 提供清理选项
echo "🗑️  清理选项:"
echo "   1) 清理所有测试结果"
echo "   2) 清理指定端口的测试结果"
echo "   3) 清理超过N天的测试结果"
echo "   4) 只显示统计信息（不清理）"
echo "   5) 退出"
echo ""

read -p "请选择操作 (1-5): " choice

case $choice in
    1)
        echo ""
        read -p "⚠️  确认删除所有测试结果？ (y/N): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            rm -rf "$TEST_OUTPUT_DIR"
            echo "✅ 已清理所有测试结果"
        else
            echo "❌ 取消清理操作"
        fi
        ;;
    2)
        echo ""
        echo "📋 可用的端口目录:"
        ls -1 "$TEST_OUTPUT_DIR" | grep "port_" | sed 's/port_/  - 端口: /'
        echo ""
        read -p "请输入要清理的端口号: " port
        
        PORT_DIR="$TEST_OUTPUT_DIR/port_$port"
        if [ -d "$PORT_DIR" ]; then
            echo ""
            echo "📁 端口 $port 的测试文件:"
            ls -la "$PORT_DIR"
            echo ""
            read -p "⚠️  确认删除端口 $port 的测试结果？ (y/N): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                rm -rf "$PORT_DIR"
                echo "✅ 已清理端口 $port 的测试结果"
                
                # 如果test_results目录为空，删除它
                if [ -z "$(ls -A "$TEST_OUTPUT_DIR" 2>/dev/null)" ]; then
                    rmdir "$TEST_OUTPUT_DIR"
                    echo "✅ 已删除空的测试结果目录"
                fi
            else
                echo "❌ 取消清理操作"
            fi
        else
            echo "❌ 端口 $port 的测试结果目录不存在"
        fi
        ;;
    3)
        echo ""
        read -p "清理超过多少天的文件 (默认7天): " days
        days=${days:-7}
        
        echo ""
        echo "🔍 查找超过 $days 天的文件..."
        OLD_FILES=$(find "$TEST_OUTPUT_DIR" -type f -mtime +$days)
        
        if [ -z "$OLD_FILES" ]; then
            echo "✅ 没有找到超过 $days 天的文件"
        else
            echo "📋 找到以下超过 $days 天的文件:"
            echo "$OLD_FILES" | while read -r file; do
                echo "  - $(ls -lh "$file" | awk '{print $5, $6, $7, $8, $9}')"
            done
            echo ""
            read -p "⚠️  确认删除这些文件？ (y/N): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                find "$TEST_OUTPUT_DIR" -type f -mtime +$days -delete
                # 删除空目录
                find "$TEST_OUTPUT_DIR" -type d -empty -delete 2>/dev/null
                echo "✅ 已清理超过 $days 天的文件"
            else
                echo "❌ 取消清理操作"
            fi
        fi
        ;;
    4)
        echo ""
        echo "📊 详细统计信息:"
        echo "────────────────────────────────────────────────────────────────"
        
        # 按端口统计
        for port_dir in "$TEST_OUTPUT_DIR"/port_*; do
            if [ -d "$port_dir" ]; then
                port=$(basename "$port_dir" | sed 's/port_//')
                size=$(du -sh "$port_dir" 2>/dev/null | cut -f1)
                files=$(find "$port_dir" -type f | wc -l)
                echo "端口 $port: $size, $files 个文件"
            fi
        done
        
        echo "────────────────────────────────────────────────────────────────"
        echo "总计: $TOTAL_SIZE, $FILE_COUNT 个文件"
        ;;
    5)
        echo "👋 退出清理工具"
        exit 0
        ;;
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac

echo ""
echo "🎯 清理完成！"
echo ""
echo "💡 提示:"
echo "   - 定期清理测试结果可以节省磁盘空间"
echo "   - 重要的测试结果请及时备份"
echo "   - 可以将此脚本加入定时任务自动清理" 