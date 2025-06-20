# Qwen3 vLLM Service Scripts

这个目录包含了用于启动和管理 Qwen3-32B vLLM 服务的脚本集合，支持自定义端口配置。

## 📁 文件说明

### 🚀 启动脚本

- **`run_qwen3_service.sh [端口]`** - 标准 Qwen3-32B 服务 (默认端口 8010)
- **`run_qwen3_service_long_context.sh [端口]`** - 长上下文 Qwen3-32B 服务 (默认端口 8011，支持 131K tokens)

### 🛠️ 管理脚本

- **`view_logs.sh`** - 查看实时日志
- **`check_status.sh`** - 检查所有服务状态（自动检测端口）
- **`test_qwen3_api.sh [端口]`** - API 测试脚本（支持端口参数或自动检测）
- **`complex_curl_example.sh [端口]`** - 复杂 curl 测试示例
- **`clean_test_results.sh`** - 测试结果清理工具

### 📄 日志文件

- **`qwen3.log`** - 服务运行日志

## 🚀 快速开始

### 1. 启动标准服务

```bash
cd /iflytek/server/vllm/run-qwen3

# 使用默认端口 8010
./run_qwen3_service.sh

# 使用自定义端口
./run_qwen3_service.sh 8020
```

### 2. 启动长上下文服务

```bash
# 使用默认端口 8011
./run_qwen3_service_long_context.sh

# 使用自定义端口
./run_qwen3_service_long_context.sh 8021
```

### 3. 同时运行多个服务

```bash
# 启动多个不同端口的服务实例
./run_qwen3_service.sh 8010 &
./run_qwen3_service.sh 8012 &
./run_qwen3_service_long_context.sh 8011 &
```

## 📋 使用说明

### 启动服务

1. 执行启动脚本后，会显示服务信息和启动日志
2. 日志会实时显示在终端，同时保存到 `qwen3.log` 文件
3. **按 `Ctrl+C` 退出日志查看，服务会继续在后台运行**
4. 服务启动完成后会显示 "Application startup complete." 消息
5. 容器名称会包含端口号，如：`qwen3-32b-service-8010`

### 端口参数说明

- **端口范围**：1024-65535
- **自动验证**：脚本会验证端口号的有效性
- **容器命名**：容器名称包含端口号以避免冲突
- **自动检测**：测试脚本可以自动检测运行中的服务端口

### 查看日志

```bash
# 查看实时日志
./view_logs.sh

# 或者使用 tail 命令
tail -f qwen3.log
```

### 检查服务状态

```bash
# 检查所有运行中的服务
./check_status.sh
```

### 测试 API

```bash
# 自动检测端口并测试
./test_qwen3_api.sh

# 测试指定端口
./test_qwen3_api.sh 8010

# 复杂测试示例
./complex_curl_example.sh 8010

# 清理测试结果
./clean_test_results.sh
```

### 测试结果管理

- **测试文件位置**: `test_results/port_{端口号}/`
- **文件类型**: JSON响应文件、性能指标、流式响应等
- **自动分类**: 按端口号分目录存储，避免混乱
- **定期清理**: 使用清理脚本管理磁盘空间

## 🔧 服务管理

### 停止服务

```bash
# 停止指定端口的服务
docker stop qwen3-32b-service-8010
docker stop qwen3-32b-long-service-8011

# 停止所有 qwen3 服务
docker stop $(docker ps -q --filter name=qwen3)
```

### 重启服务

```bash
# 停止并删除指定容器
docker stop qwen3-32b-service-8010
docker rm qwen3-32b-service-8010

# 重新运行启动脚本
./run_qwen3_service.sh 8010
```

### 查看 Docker 容器

```bash
# 查看所有 qwen3 容器
docker ps -a | grep qwen3

# 查看运行中的容器
docker ps | grep qwen3
```

## 📊 服务信息

### 标准服务

- **默认端口**: 8010
- **容器名**: qwen3-32b-service-{端口}
- **上下文长度**: 32,768 tokens
- **GPU**: 5,6
- **内存利用率**: 85%

### 长上下文服务

- **默认端口**: 8011
- **容器名**: qwen3-32b-long-service-{端口}
- **上下文长度**: 131,072 tokens (YaRN 扩展)
- **GPU**: 5,6
- **内存利用率**: 80%

## 🌐 API 访问

### 动态端口访问

```bash
# 健康检查
curl http://0.0.0.0:{端口}/health

# 模型列表
curl http://0.0.0.0:{端口}/v1/models

# 聊天完成
curl -X POST http://0.0.0.0:{端口}/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "Qwen3-32B", "messages": [{"role": "user", "content": "Hello"}]}'
```

## 🔍 故障排除

### 1. 端口冲突

- 使用不同端口启动服务：`./run_qwen3_service.sh 8012`
- 检查端口占用：`netstat -tlnp | grep 8010`
- 查看当前使用的端口：`./check_status.sh`

### 2. 容器启动失败

- 检查 GPU 是否可用：`nvidia-smi`
- 查看详细错误：`docker logs qwen3-32b-service-{端口}`
- 确保端口未被占用

### 3. API 不响应

- 等待服务完全启动（通常需要 3-5 分钟）
- 检查服务状态：`./check_status.sh`
- 查看日志：`./view_logs.sh`
- 验证端口是否正确

### 4. 内存不足

- 降低 `GPU_MEMORY_UTILIZATION` 参数
- 减少 `max-num-seqs` 或 `max-num-batched-tokens`
- 避免同时运行过多服务实例

## 📝 注意事项

1. **端口管理**：确保每个服务使用不同的端口
2. **容器命名**：容器名称包含端口号以避免冲突
3. **资源分配**：多个服务会共享 GPU 资源，注意内存分配
4. **首次启动**：模型加载需要 3-5 分钟时间
5. **GPU 要求**：需要两张 GPU（ID: 5,6）
6. **内存要求**：每张 GPU 至少 24GB 显存
7. **日志文件**：所有服务共享同一个 `qwen3.log` 文件
8. **测试结果**：测试脚本会在 `test_results/` 目录生成文件，定期清理以节省空间

## 💡 最佳实践

### 多服务部署

```bash
# 生产环境建议使用不同端口运行多个实例
./run_qwen3_service.sh 8010        # 主服务
./run_qwen3_service.sh 8012        # 备用服务
./run_qwen3_service_long_context.sh 8011  # 长上下文服务
```

### 负载均衡

- 使用 nginx 或其他负载均衡器分发请求到不同端口
- 配置健康检查：`/health` 端点
- 监控各服务的响应时间和吞吐量

### 监控脚本

```bash
# 定期检查服务状态
watch -n 30 ./check_status.sh

# 持续监控日志
./view_logs.sh
```

### 测试结果管理

```bash
# 定期清理测试结果（建议每周执行）
./clean_test_results.sh

# 查看测试结果目录大小
du -sh test_results/

# 备份重要测试结果
cp -r test_results/port_8010/ backup_$(date +%Y%m%d)/
```

## 🔗 相关链接

- [vLLM 官方文档](https://docs.vllm.ai/)
- [Qwen 模型文档](https://github.com/QwenLM/Qwen)
- [OpenAI API 兼容性](https://docs.vllm.ai/en/latest/serving/openai_compatible_server.html) #
