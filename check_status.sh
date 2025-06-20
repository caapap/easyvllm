#!/bin/bash

echo "🔍 Qwen3 Service Status Checker"
echo "=================================================================================="

# 检查所有运行中的 Qwen3 容器
echo "📋 Running Qwen3 Services:"

# 查找所有 qwen3 相关的容器
QWEN3_CONTAINERS=$(docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}" | grep qwen3)

if [ -z "$QWEN3_CONTAINERS" ]; then
    echo "   ❌ No Qwen3 containers are running"
else
    echo "$QWEN3_CONTAINERS" | while IFS=$'\t' read -r name ports status; do
        if [ "$name" != "NAMES" ]; then
            echo ""
            echo "   📦 Container: $name"
            echo "   🔗 Ports: $ports"
            echo "   📊 Status: $status"
            
            # 提取端口号
            if [[ "$ports" =~ 0\.0\.0\.0:([0-9]+) ]]; then
                PORT="${BASH_REMATCH[1]}"
                echo "   🌐 Testing API on port $PORT..."
                
                # 检查健康状态
                if curl -s -f "http://0.0.0.0:$PORT/health" >/dev/null 2>&1; then
                    echo "   ✅ API: Accessible"
                    echo "   📍 URL: http://0.0.0.0:$PORT"
                    
                    # 获取模型信息
                    MODEL_INFO=$(curl -s "http://0.0.0.0:$PORT/v1/models" 2>/dev/null | jq -r '.data[0].id // "Unknown"' 2>/dev/null)
                    if [ "$MODEL_INFO" != "Unknown" ] && [ "$MODEL_INFO" != "null" ] && [ -n "$MODEL_INFO" ]; then
                        echo "   🏷️  Model: $MODEL_INFO"
                    fi
                else
                    echo "   ⚠️  API: Not ready yet (still starting up)"
                fi
            fi
        fi
    done
fi

echo ""
echo "=================================================================================="

# 检查所有停止的 qwen3 容器
STOPPED_CONTAINERS=$(docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep qwen3 | grep -v "Up")
if [ -n "$STOPPED_CONTAINERS" ]; then
    echo "🛑 Stopped Qwen3 Containers:"
    echo "$STOPPED_CONTAINERS"
    echo ""
fi

# 检查日志文件
CURRENT_DIR=$(pwd)
LOG_FILE="$CURRENT_DIR/qwen3.log"

echo "📄 Log File Status:"
if [ -f "$LOG_FILE" ]; then
    echo "   ✅ Log file exists: $LOG_FILE"
    echo "   📊 Size: $(du -h "$LOG_FILE" | cut -f1)"
    echo "   📅 Last modified: $(date -r "$LOG_FILE" '+%Y-%m-%d %H:%M:%S')"
    echo "   📝 Last 3 lines:"
    echo "   ────────────────────────────────────────────────────────────────"
    tail -3 "$LOG_FILE" | sed 's/^/   /'
    echo "   ────────────────────────────────────────────────────────────────"
else
    echo "   ❌ Log file not found: $LOG_FILE"
fi

echo ""
echo "🛠️  Management Commands:"
echo "   📄 View logs: ./view_logs.sh"
echo "   🚀 Start standard service: ./run_qwen3_service.sh [port]"
echo "   🚀 Start long context service: ./run_qwen3_service_long_context.sh [port]"
echo "   🛑 Stop specific service: docker stop <container-name>"
echo "   🛑 Stop all qwen3 services: docker stop \$(docker ps -q --filter name=qwen3)"
echo "   🗑️  Remove stopped containers: docker rm \$(docker ps -aq --filter name=qwen3)"
echo "   📊 List all qwen3 containers: docker ps -a | grep qwen3"

# 显示端口使用情况
echo ""
echo "🔌 Port Usage Summary:"
USED_PORTS=$(docker ps --format "{{.Ports}}" | grep -o "0.0.0.0:[0-9]*" | cut -d: -f2 | sort -n)
if [ -n "$USED_PORTS" ]; then
    echo "   📍 Currently used ports: $(echo $USED_PORTS | tr '\n' ' ')"
    echo "   💡 Available suggested ports: 8010, 8011, 8012, 8013, 8014, 8015"
else
    echo "   📍 No ports currently in use by Docker containers"
fi 