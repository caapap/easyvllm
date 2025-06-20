#!/bin/bash

# Qwen3 API 综合测试脚本 - 专业版
# 本脚本测试 vLLM Qwen3 服务的各种复杂场景

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

# 配置
QWEN3_BASE_URL="http://0.0.0.0:$QWEN3_PORT"

# 创建测试结果目录
CURRENT_DIR=$(pwd)
TEST_OUTPUT_DIR="$CURRENT_DIR/test_results"
PORT_OUTPUT_DIR="$TEST_OUTPUT_DIR/port_${QWEN3_PORT}"
mkdir -p "$PORT_OUTPUT_DIR"

# 尝试检测模型名称
MODEL_NAME=$(curl -s "$QWEN3_BASE_URL/v1/models" 2>/dev/null | jq -r '.data[0].id // "Qwen3-32B"' 2>/dev/null)
if [ "$MODEL_NAME" = "null" ] || [ -z "$MODEL_NAME" ]; then
    MODEL_NAME="Qwen3-32B"
fi

echo "🧪 Qwen3 API 综合测试 - 专业版"
echo "=================================================================================="
echo "📍 测试服务: $QWEN3_BASE_URL"
echo "🏷️  模型名称: $MODEL_NAME"
echo "📁 结果目录: $PORT_OUTPUT_DIR"
echo "=================================================================================="

# 颜色输出定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 输出函数
print_status() {
    echo -e "${BLUE}[信息]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

# 端点测试函数
test_endpoint() {
    local url=$1
    local description=$2
    
    print_status "测试: $description"
    response=$(curl -s -w "%{http_code}" -o /tmp/curl_response.json "$url")
    http_code="${response: -3}"
    
    if [ "$http_code" -eq 200 ]; then
        print_success "端点可访问 (HTTP $http_code)"
        return 0
    else
        print_error "端点失败 (HTTP $http_code)"
        return 1
    fi
}

# 测试 1: 健康检查
echo "================================="
echo "🏥 健康检查测试"
echo "================================="

test_endpoint "$QWEN3_BASE_URL/health" "Qwen3 健康检查 (端口 $QWEN3_PORT)"

# 测试 2: 模型列表
echo ""
echo "================================="
echo "📋 模型列表测试"
echo "================================="

print_status "从端口 $QWEN3_PORT 获取可用模型列表..."
curl -s -X GET "$QWEN3_BASE_URL/v1/models" \
  -H "Content-Type: application/json" | jq '.' > "$PORT_OUTPUT_DIR/models_list.json" || echo "端口 $QWEN3_PORT 服务未就绪"

if [ -f "$PORT_OUTPUT_DIR/models_list.json" ]; then
    print_success "模型列表已保存到: $PORT_OUTPUT_DIR/models_list.json"
fi

# 测试 3: 复杂推理任务
echo ""
echo "================================="
echo "🧠 复杂推理测试"
echo "================================="

print_status "使用 $MODEL_NAME 在端口 $QWEN3_PORT 进行复杂多步推理测试..."

REASONING_PROMPT='你是一位资深的数据科学家，正在进行一个复杂的机器学习项目。场景：一家科技公司想要为其电商平台构建推荐系统。他们拥有以下数据：1000万用户的人口统计信息，100万种商品涵盖50个类别，过去3年的5亿条历史购买记录，实时用户行为数据，商品元数据等。需求：系统必须支持10万+并发用户，推荐必须实时更新，必须解决冷启动问题，系统需要可解释性，必须符合隐私法规。你的任务：设计一个全面的解决方案架构，包括数据预处理管道、模型选择和集成策略、实时推理架构、A/B测试框架、监控和维护策略。请提供详细的技术规格、权衡考虑和实施时间表。'

curl -s -X POST "$QWEN3_BASE_URL/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-token" \
  -d "{
    \"model\": \"$MODEL_NAME\",
    \"messages\": [
      {
        \"role\": \"system\",
        \"content\": \"你是一位拥有15年以上经验的专业AI系统架构师和数据科学家，专门构建大规模机器学习系统。请提供详细、实用且符合行业标准的解决方案。\"
      },
      {
        \"role\": \"user\",
        \"content\": \"$REASONING_PROMPT\"
      }
    ],
    \"max_tokens\": 4000,
    \"temperature\": 0.7,
    \"top_p\": 0.9,
    \"frequency_penalty\": 0.1,
    \"presence_penalty\": 0.1,
    \"stream\": false,
    \"reasoning\": true
  }" > "$PORT_OUTPUT_DIR/complex_reasoning_test.json"

if [ $? -eq 0 ]; then
    print_success "复杂推理测试完成"
    echo "响应已保存到: $PORT_OUTPUT_DIR/complex_reasoning_test.json"
    # 提取并显示关键指标
    if command -v jq &> /dev/null; then
        echo "响应预览:"
        jq -r '.choices[0].message.content' "$PORT_OUTPUT_DIR/complex_reasoning_test.json" | head -20
        echo "..."
        echo "完整响应在 $PORT_OUTPUT_DIR/complex_reasoning_test.json"
    fi
else
    print_error "复杂推理测试失败"
fi

# 测试 4: 流式响应测试
echo ""
echo "================================="
echo "🌊 流式响应测试"
echo "================================="

print_status "在端口 $QWEN3_PORT 测试流式响应能力..."

curl -s -X POST "$QWEN3_BASE_URL/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL_NAME\",
    \"messages\": [
      {
        \"role\": \"user\",
        \"content\": \"写一篇关于使用Kubernetes实现微服务架构的详细技术博客文章，包括代码示例和最佳实践。要求内容全面且实用。\"
      }
    ],
    \"max_tokens\": 2000,
    \"temperature\": 0.7,
    \"stream\": true
  }" > "$PORT_OUTPUT_DIR/streaming_response_test.txt"

if [ $? -eq 0 ]; then
    print_success "流式响应测试完成"
    echo "流式响应已保存到: $PORT_OUTPUT_DIR/streaming_response_test.txt"
    echo "流式响应前几行预览:"
    head -10 "$PORT_OUTPUT_DIR/streaming_response_test.txt"
else
    print_error "流式响应测试失败"
fi

# 测试 5: 批量处理测试
echo ""
echo "================================="
echo "📦 批量处理测试"
echo "================================="

print_status "在端口 $QWEN3_PORT 进行多请求批量处理测试..."

# 创建批量请求
for i in {1..3}; do
    curl -s -X POST "$QWEN3_BASE_URL/v1/chat/completions" \
      -H "Content-Type: application/json" \
      -d "{
        \"model\": \"$MODEL_NAME\",
        \"messages\": [
          {
            \"role\": \"user\",
            \"content\": \"逐步解决这个复杂问题：一家公司有$i个部门，每个部门都有不同的预算分配和绩效指标。设计一个优化算法，在保持预算约束的同时最大化公司整体绩效。请提供详细的算法设计和实施方案。\"
          }
        ],
        \"max_tokens\": 1500,
        \"temperature\": 0.5
      }" > "$PORT_OUTPUT_DIR/batch_test_${i}.json" &
done

# 等待所有后台作业完成
wait

print_success "批量处理测试完成"
echo "结果已保存到: $PORT_OUTPUT_DIR/batch_test_1.json, batch_test_2.json, batch_test_3.json"

# 测试 6: 性能指标测试
echo ""
echo "================================="
echo "⚡ 性能指标测试"
echo "================================="

print_status "在端口 $QWEN3_PORT 测量响应时间和吞吐量..."

# 计时一个简单请求
start_time=$(date +%s.%N)
curl -s -X POST "$QWEN3_BASE_URL/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL_NAME\",
    \"messages\": [
      {
        \"role\": \"user\",
        \"content\": \"用简单的语言解释量子计算。\"
      }
    ],
    \"max_tokens\": 500,
    \"temperature\": 0.7
  }" > "$PORT_OUTPUT_DIR/performance_test.json"

end_time=$(date +%s.%N)
response_time=$(echo "$end_time - $start_time" | bc)

if [ $? -eq 0 ]; then
    print_success "性能测试完成"
    echo "响应时间: ${response_time} 秒"
    
    if command -v jq &> /dev/null; then
        tokens=$(jq -r '.usage.total_tokens // "N/A"' "$PORT_OUTPUT_DIR/performance_test.json")
        echo "总令牌数: $tokens"
        if [ "$tokens" != "N/A" ] && [ "$tokens" != "null" ]; then
            throughput=$(echo "scale=2; $tokens / $response_time" | bc)
            echo "吞吐量: ${throughput} 令牌/秒"
        fi
    fi
    
    # 保存性能指标
    echo "{\"response_time\": $response_time, \"port\": $QWEN3_PORT, \"timestamp\": \"$(date -Iseconds)\"}" > "$PORT_OUTPUT_DIR/performance_metrics.json"
else
    print_error "性能测试失败"
fi

# 测试 7: 中文对话能力测试
echo ""
echo "================================="
echo "🇨🇳 中文对话能力测试"
echo "================================="

print_status "测试中文对话和理解能力..."

curl -s -X POST "$QWEN3_BASE_URL/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL_NAME\",
    \"messages\": [
      {
        \"role\": \"system\",
        \"content\": \"你是一位专业的中文AI助手，能够进行流畅的中文对话，理解中国文化背景，并提供准确、有用的信息。\"
      },
      {
        \"role\": \"user\",
        \"content\": \"请详细介绍一下中国传统节日春节的由来、习俗和现代庆祝方式，以及它在中华文化中的重要意义。\"
      }
    ],
    \"max_tokens\": 2000,
    \"temperature\": 0.6
  }" > "$PORT_OUTPUT_DIR/chinese_dialogue_test.json"

if [ $? -eq 0 ]; then
    print_success "中文对话测试完成"
    echo "响应已保存到: $PORT_OUTPUT_DIR/chinese_dialogue_test.json"
    if command -v jq &> /dev/null; then
        echo "中文回答预览:"
        jq -r '.choices[0].message.content' "$PORT_OUTPUT_DIR/chinese_dialogue_test.json" | head -10
        echo "..."
    fi
else
    print_error "中文对话测试失败"
fi

# 汇总
echo ""
echo "================================="
echo "📊 测试汇总"
echo "================================="

echo "测试服务: $QWEN3_BASE_URL"
echo "模型名称: $MODEL_NAME"
echo "结果目录: $PORT_OUTPUT_DIR"
echo ""
echo "生成的测试文件:"
echo "- models_list.json (模型列表)"
echo "- complex_reasoning_test.json (复杂推理测试)"
echo "- streaming_response_test.txt (流式响应测试)"  
echo "- batch_test_*.json (批量处理测试)"
echo "- performance_test.json (性能测试)"
echo "- performance_metrics.json (性能指标)"
echo "- chinese_dialogue_test.json (中文对话测试)"

echo ""
print_success "所有测试完成！请查看生成的文件了解详细结果。"
echo ""
echo "📋 后续步骤:"
echo "1. 查看生成的JSON文件了解响应质量"
echo "2. 监控 qwen3.log 文件检查服务问题"
echo "3. 使用 'docker stats' 检查资源利用率"
echo "4. 根据性能结果需要时扩展服务"
echo ""
echo "📁 测试结果位置: $PORT_OUTPUT_DIR"
echo "🔍 查看详细结果: ls -la $PORT_OUTPUT_DIR" 