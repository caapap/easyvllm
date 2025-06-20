#!/bin/bash

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
    export PORT=$CUSTOM_PORT
else
    export PORT=8010  # 默认端口
fi

# Set environment variables
export MODEL_PATH="/iflytek/models/qwen/Qwen3-32B"
export HOST="0.0.0.0"
export TENSOR_PARALLEL_SIZE=2  # Adjust based on your GPU count
export GPU_MEMORY_UTILIZATION=0.85  # Optimized for Qwen3-32B
export MAX_MODEL_LEN=32768  # Native context length for Qwen3-32B (can extend to 131072 with YaRN)
export SERVED_MODEL_NAME="Qwen3-32B"  # Clean model name for API calls

# Set OpenBLAS environment variables to fix the threading issue
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1
export MKL_NUM_THREADS=1

# Get the current directory for log file
CURRENT_DIR=$(pwd)
LOG_FILE="$CURRENT_DIR/qwen3.log"
CONTAINER_NAME="qwen3-32b-service-${PORT}"

echo "🚀 Starting Qwen3-32B service..."
echo "📄 Log file: $LOG_FILE"
echo "📍 Server will be available at: http://$HOST:$PORT"
echo "🏷️  Model name: $SERVED_MODEL_NAME"
echo "🔧 Container name: $CONTAINER_NAME"
echo ""

# Remove existing container if it exists
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1

# Clear previous log file
> "$LOG_FILE"

# Run the Docker container with optimized parameters for Qwen3-32B in background
# Use --gpus '"device=5,6"' to specify GPU IDs 5 and 6
echo "🐳 Starting Docker container..."
docker run -d --name "$CONTAINER_NAME" --gpus '"device=5,6"' \
  --privileged \
  --shm-size=4g \
  --ulimit memlock=-1 \
  --ulimit stack=67108864 \
  -v /iflytek/models:/models \
  -e MODEL=/models/qwen/Qwen3-32B \
  -e HOST=$HOST \
  -e PORT=$PORT \
  -e TENSOR_PARALLEL_SIZE=$TENSOR_PARALLEL_SIZE \
  -e GPU_MEMORY_UTILIZATION=$GPU_MEMORY_UTILIZATION \
  -e CUDA_VISIBLE_DEVICES=5,6 \
  -e OPENBLAS_NUM_THREADS=1 \
  -e OMP_NUM_THREADS=1 \
  -e NUMEXPR_NUM_THREADS=1 \
  -e MKL_NUM_THREADS=1 \
  -p $PORT:$PORT \
  vllm-openai:v0.8.5.post1 \
  --model /models/qwen/Qwen3-32B \
  --served-model-name $SERVED_MODEL_NAME \
  --host $HOST \
  --port $PORT \
  --tensor-parallel-size $TENSOR_PARALLEL_SIZE \
  --gpu-memory-utilization $GPU_MEMORY_UTILIZATION \
  --max-model-len $MAX_MODEL_LEN \
  --enable-reasoning \
  --reasoning-parser deepseek_r1 \
  --max-num-seqs 128 \
  --max-num-batched-tokens 16384

# Check if container started successfully
if [ $? -eq 0 ]; then
    echo "✅ Docker container started successfully!"
    echo ""
    echo "📋 Service Information:"
    echo "   📍 URL: http://$HOST:$PORT"
    echo "   🏷️  Model: $SERVED_MODEL_NAME"
    echo "   📏 Context: $MAX_MODEL_LEN tokens"
    echo "   🧠 Reasoning: enabled (deepseek_r1)"
    echo "   🔧 Container: $CONTAINER_NAME"
    echo ""
    echo "📄 Logs are being written to: $LOG_FILE"
    echo ""
    echo "🔍 Showing startup logs (Press Ctrl+C to exit log view, service will continue running):"
    echo "=================================================================================="
    
    # Setup trap to handle Ctrl+C gracefully
    trap "echo -e \"\n\n🚪 Exiting log view...\"; echo \"✅ Service is still running in background\"; echo \"📄 To view logs: tail -f $LOG_FILE\"; echo \"🛑 To stop service: docker stop $CONTAINER_NAME\"; echo \"📊 To check status: docker ps | grep $CONTAINER_NAME\"; exit 0" INT
    
    # Follow logs and save to file simultaneously
    docker logs -f "$CONTAINER_NAME" 2>&1 | tee -a "$LOG_FILE"
    
else
    echo "❌ Failed to start Docker container"
    exit 1
fi
