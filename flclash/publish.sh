#!/bin/bash
set -e

# 配置部分
OSS_BUCKET="wall-api"
OSS_PATH="config"
LOCAL_TOOLS="./tools/ossutil"

echo "=== 🚀 开始发布流程 ==="

# 1. 执行自动签名
echo "1. 正再生成签名..."
dart scripts/sign_config.dart --auto

if [ ! -f "signed_config.json" ]; then
    echo "❌ 签名失败：未找到 signed_config.json"
    exit 1
fi

echo "✅ 签名文件已生成: signed_config.json"

# 2. 上传到 OSS
echo "2.正在上传到 OSS ($OSS_BUCKET/$OSS_PATH)..."

if [ ! -f "$LOCAL_TOOLS" ]; then
    echo "❌ 错误：未找到 ossutil 工具，请检查 tools 目录"
    exit 1
fi

$LOCAL_TOOLS cp signed_config.json oss://$OSS_BUCKET/$OSS_PATH -f

echo "✅ 发布成功！🎉"
echo "您的配置已安全更新并受数字签名保护。"
