#!/bin/bash

# 复杂的 Qwen3 API 测试 - 专业版本
# 这个脚本展示了如何使用复杂的 prompt 测试 Qwen3 服务

# 检查端口参数
if [ $# -eq 1 ]; then
    CUSTOM_PORT=$1
    # 验证端口号是否为有效数字
    if ! [[ "$CUSTOM_PORT" =~ ^[0-9]+$ ]] || [ "$CUSTOM_PORT" -lt 1024 ] || [ "$CUSTOM_PORT" -gt 65535 ]; then
        echo "❌ 错误: 端口号必须是 1024-65535 之间的数字"
        echo "💡 使用方法: $0 [端口号]"
        echo "📋 示例: $0 8010"
        exit 1
    fi
    QWEN3_PORT=$CUSTOM_PORT
else
    # 自动检测运行中的服务端口
    RUNNING_PORTS=$(docker ps --format "{{.Ports}}" | grep -o "0.0.0.0:[0-9]*" | cut -d: -f2 | head -1)
    if [ -n "$RUNNING_PORTS" ]; then
        QWEN3_PORT=$RUNNING_PORTS
        echo "🔍 自动检测到运行中的服务端口: $QWEN3_PORT"
    else
        QWEN3_PORT=8010  # 默认端口
        echo "⚠️  未检测到运行中的服务，使用默认端口: $QWEN3_PORT"
    fi
fi

echo "🧠 复杂 Qwen3 API 测试 - 专业版本"
echo "=================================================================================="
echo "📍 测试服务端口: $QWEN3_PORT"

# 配置
QWEN3_URL="http://0.0.0.0:$QWEN3_PORT"

# 创建测试结果目录
CURRENT_DIR=$(pwd)
TEST_OUTPUT_DIR="$CURRENT_DIR/test_results"
PORT_OUTPUT_DIR="$TEST_OUTPUT_DIR/port_${QWEN3_PORT}"
mkdir -p "$PORT_OUTPUT_DIR"

# 尝试检测模型名称
MODEL_NAME=$(curl -s "$QWEN3_URL/v1/models" 2>/dev/null | jq -r '.data[0].id // "Qwen3-32B"' 2>/dev/null)
if [ "$MODEL_NAME" = "null" ] || [ -z "$MODEL_NAME" ]; then
    MODEL_NAME="Qwen3-32B"
fi

echo "🏷️  模型名称: $MODEL_NAME"
echo "📁 结果目录: $PORT_OUTPUT_DIR"
echo "=================================================================================="

# 复杂的系统架构设计 prompt
COMPLEX_PROMPT='你是一位资深的系统架构师和技术专家，拥有15年以上的大型分布式系统设计经验。任务背景：某大型电商公司需要重新设计其核心交易系统。业务规模：日活用户5000万+，日订单量2000万+，峰值QPS50万+，商品SKU1亿+，商家数量500万+，全球业务覆盖50+国家。技术挑战：高并发处理、数据一致性、跨境合规、实时性要求、容灾能力。现有技术栈限制：遗留系统单体应用、技术债务、数据孤岛、运维复杂。设计要求：请设计一个完整的技术解决方案，包括整体架构设计、核心技术选型、性能优化方案、可靠性保障、监控运维体系、安全防护、实施路径等。请提供详细的技术方案，包括具体的技术选型理由、架构图描述、关键代码示例、性能指标预估等。'

echo "📝 发送复杂架构设计请求..."
echo "🎯 Prompt 长度: $(echo "$COMPLEX_PROMPT" | wc -c) 字符"
echo "⏱️  预计响应时间: 30-60秒"
echo ""

# 执行复杂的 curl 请求
curl -X POST "$QWEN3_URL/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-dummy-key-for-testing" \
  -H "User-Agent: QwenAPI-Test/1.0" \
  -H "X-Request-ID: complex-test-$(date +%s)" \
  -d "{
    \"model\": \"$MODEL_NAME\",
    \"messages\": [
      {
        \"role\": \"system\",
        \"content\": \"你是一位世界顶级的系统架构师，曾在Google、Amazon、阿里巴巴等公司担任首席架构师。你精通大规模分布式系统设计，在高并发、高可用、高性能系统架构方面有丰富经验。请用专业、详细、实用的方式回答问题，提供具体的技术方案和最佳实践。\"
      },
      {
        \"role\": \"user\",
        \"content\": \"$COMPLEX_PROMPT\"
      }
    ],
    \"max_tokens\": 4096,
    \"temperature\": 0.3,
    \"top_p\": 0.9,
    \"top_k\": 40,
    \"frequency_penalty\": 0.1,
    \"presence_penalty\": 0.1,
    \"stream\": false,
    \"reasoning\": true,
    \"stop\": null,
    \"logit_bias\": {},
    \"user\": \"system-architect-test\"
  }" \
  --max-time 120 \
  --retry 3 \
  --retry-delay 5 \
  --compressed \
  --silent \
  --show-error \
  --write-out "\n\n📊 响应信息:\n   HTTP状态: %{http_code}\n   总耗时: %{time_total}秒\n   响应大小: %{size_download} 字节\n" \
  --output "$PORT_OUTPUT_DIR/complex_architecture_response.json"

# 检查响应
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 请求成功完成！"
    echo ""
    
    # 如果有 jq，解析响应
    if command -v jq &> /dev/null; then
        echo "📋 响应摘要："
        echo "   模型: $(jq -r '.model // "N/A"' "$PORT_OUTPUT_DIR/complex_architecture_response.json")"
        echo "   完成原因: $(jq -r '.choices[0].finish_reason // "N/A"' "$PORT_OUTPUT_DIR/complex_architecture_response.json")"
        echo "   输入令牌: $(jq -r '.usage.prompt_tokens // "N/A"' "$PORT_OUTPUT_DIR/complex_architecture_response.json")"
        echo "   输出令牌: $(jq -r '.usage.completion_tokens // "N/A"' "$PORT_OUTPUT_DIR/complex_architecture_response.json")"
        echo "   总令牌: $(jq -r '.usage.total_tokens // "N/A"' "$PORT_OUTPUT_DIR/complex_architecture_response.json")"
        echo ""
        echo "📄 响应内容预览（前500字符）："
        echo "────────────────────────────────────────────────────────────────"
        jq -r '.choices[0].message.content' "$PORT_OUTPUT_DIR/complex_architecture_response.json" | head -c 500
        echo ""
        echo "..."
        echo "────────────────────────────────────────────────────────────────"
        echo ""
        echo "📁 完整响应已保存到: $PORT_OUTPUT_DIR/complex_architecture_response.json"
        echo "🔍 查看完整响应: cat $PORT_OUTPUT_DIR/complex_architecture_response.json | jq -r '.choices[0].message.content'"
    else
        echo "📁 响应已保存到: $PORT_OUTPUT_DIR/complex_architecture_response.json"
        echo "💡 安装 jq 来更好地解析JSON响应: yum install jq 或 apt install jq"
    fi
else
    echo ""
    echo "❌ 请求失败！"
    echo "🔍 请检查："
    echo "   1. Qwen3 服务是否正在运行: ./check_status.sh"
    echo "   2. 网络连接是否正常"
    echo "   3. 服务是否已完全启动（可能需要3-5分钟）"
    echo "   4. 端口 $QWEN3_PORT 是否正确"
fi

echo ""
echo "🛠️  其他测试命令："
echo "   简单测试: curl $QWEN3_URL/health"
echo "   模型列表: curl $QWEN3_URL/v1/models"
echo "   完整测试: ./test_qwen3_api.sh $QWEN3_PORT"
echo "   状态检查: ./check_status.sh"
echo ""
echo "📁 测试结果位置: $PORT_OUTPUT_DIR"
echo "🔍 查看所有结果: ls -la $PORT_OUTPUT_DIR" 