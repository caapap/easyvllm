#!/bin/bash

# Get the current directory for log file
CURRENT_DIR=$(pwd)
LOG_FILE="$CURRENT_DIR/qwen3.log"

echo "📄 Qwen3 Service Log Viewer"
echo "=================================================================================="

# Check if log file exists
if [ ! -f "$LOG_FILE" ]; then
    echo "❌ Log file not found: $LOG_FILE"
    echo "💡 Make sure you have started the Qwen3 service first."
    exit 1
fi

echo "📍 Log file: $LOG_FILE"
echo "📊 Log file size: $(du -h "$LOG_FILE" | cut -f1)"
echo "📅 Last modified: $(date -r "$LOG_FILE" '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "🔍 Press Ctrl+C to exit log view"
echo "=================================================================================="

# Setup trap to handle Ctrl+C gracefully
trap 'echo -e "\n\n🚪 Exiting log viewer..."; exit 0' INT

# Follow the log file
tail -f "$LOG_FILE" 