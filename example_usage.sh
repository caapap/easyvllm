#!/bin/bash

# Qwen3 服务端口管理示例脚本
# 演示如何使用自定义端口功能

echo "🎯 Qwen3 服务端口管理示例"
echo "=================================================================================="

# 检查是否提供了操作参数
if [ $# -eq 0 ]; then
    echo "💡 使用方法:"
    echo "   $0 start    - 启动示例服务"
    echo "   $0 test     - 测试已启动的服务"
    echo "   $0 stop     - 停止示例服务"
    echo "   $0 status   - 查看服务状态"
    echo ""
    echo "📋 示例:"
    echo "   $0 start    # 启动多个端口的服务"
    echo "   $0 test     # 测试所有服务"
    echo "   $0 stop     # 停止所有服务"
    exit 1
fi

OPERATION=$1

case $OPERATION in
    "start")
        echo "🚀 启动多端口 Qwen3 服务示例..."
        echo ""
        
        echo "📍 启动标准服务 (端口 8010)..."
        ./run_qwen3_service.sh 8010 &
        STANDARD_PID=$!
        
        sleep 5
        
        echo "📍 启动备用服务 (端口 8012)..."
        ./run_qwen3_service.sh 8012 &
        BACKUP_PID=$!
        
        sleep 5
        
        echo "📍 启动长上下文服务 (端口 8011)..."
        ./run_qwen3_service_long_context.sh 8011 &
        LONG_PID=$!
        
        echo ""
        echo "✅ 所有服务启动命令已执行！"
        echo "📋 启动的服务:"
        echo "   - 标准服务: 端口 8010"
        echo "   - 备用服务: 端口 8012"
        echo "   - 长上下文服务: 端口 8011"
        echo ""
        echo "⏱️  请等待 3-5 分钟让服务完全启动..."
        echo "🔍 使用 '$0 status' 检查启动状态"
        echo "🧪 使用 '$0 test' 测试服务"
        ;;
        
    "test")
        echo "🧪 测试所有运行中的 Qwen3 服务..."
        echo ""
        
        # 获取所有运行中的端口
        RUNNING_PORTS=$(docker ps --format "{{.Ports}}" | grep -o "0.0.0.0:[0-9]*" | cut -d: -f2 | sort -n)
        
        if [ -z "$RUNNING_PORTS" ]; then
            echo "❌ 没有发现运行中的服务"
            echo "💡 请先使用 '$0 start' 启动服务"
            exit 1
        fi
        
        echo "🔍 发现运行中的端口: $(echo $RUNNING_PORTS | tr '\n' ' ')"
        echo ""
        
        for port in $RUNNING_PORTS; do
            echo "────────────────────────────────────────────────────────────────"
            echo "🧪 测试端口 $port 的服务..."
            
            # 健康检查
            if curl -s -f "http://0.0.0.0:$port/health" >/dev/null 2>&1; then
                echo "✅ 健康检查通过"
                
                # 获取模型信息
                MODEL_INFO=$(curl -s "http://0.0.0.0:$port/v1/models" 2>/dev/null | jq -r '.data[0].id // "Unknown"' 2>/dev/null)
                echo "🏷️  模型: $MODEL_INFO"
                
                # 简单对话测试
                echo "💬 执行简单对话测试..."
                RESPONSE=$(curl -s -X POST "http://0.0.0.0:$port/v1/chat/completions" \
                    -H "Content-Type: application/json" \
                    -d '{
                        "model": "'$MODEL_INFO'",
                        "messages": [{"role": "user", "content": "你好，请简单介绍一下你自己。"}],
                        "max_tokens": 100,
                        "temperature": 0.7
                    }' 2>/dev/null)
                
                if [ $? -eq 0 ] && echo "$RESPONSE" | jq -e '.choices[0].message.content' >/dev/null 2>&1; then
                    echo "✅ 对话测试成功"
                    CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content' | head -c 100)
                    echo "📝 响应预览: $CONTENT..."
                else
                    echo "⚠️  对话测试失败"
                fi
            else
                echo "❌ 健康检查失败 - 服务可能还在启动中"
            fi
            echo ""
        done
        
        echo "📊 测试完成！"
        echo "🔍 详细测试请使用: ./test_qwen3_api.sh [端口]"
        ;;
        
    "stop")
        echo "🛑 停止所有 Qwen3 服务..."
        echo ""
        
        # 获取所有 qwen3 容器
        QWEN3_CONTAINERS=$(docker ps -q --filter name=qwen3)
        
        if [ -z "$QWEN3_CONTAINERS" ]; then
            echo "ℹ️  没有发现运行中的 Qwen3 服务"
        else
            echo "🔍 发现以下运行中的容器:"
            docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}" | grep qwen3
            echo ""
            
            echo "🛑 停止所有容器..."
            docker stop $QWEN3_CONTAINERS
            
            echo "🗑️  删除停止的容器..."
            docker rm $QWEN3_CONTAINERS
            
            echo "✅ 所有 Qwen3 服务已停止并清理"
        fi
        ;;
        
    "status")
        echo "📊 检查 Qwen3 服务状态..."
        echo ""
        ./check_status.sh
        ;;
        
    *)
        echo "❌ 未知操作: $OPERATION"
        echo "💡 支持的操作: start, test, stop, status"
        exit 1
        ;;
esac

echo ""
echo "🛠️  其他有用命令:"
echo "   ./check_status.sh                    # 检查服务状态"
echo "   ./view_logs.sh                       # 查看日志"
echo "   ./test_qwen3_api.sh [端口]           # 完整API测试"
echo "   ./complex_curl_example.sh [端口]     # 复杂测试示例"
echo "   docker ps | grep qwen3               # 查看容器状态" 