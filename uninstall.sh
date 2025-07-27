#!/bin/bash

# n8n 汉化版卸载脚本
# 作者: Lingma (灵码)
# 日期: 2025-07-27

echo "========================================="
echo "🗑️  开始卸载 n8n 汉化版"
echo "========================================="

# 停止并删除容器
echo "⏹️  停止并删除 n8n 容器..."

# 检查是否有一个正在运行的 n8n 容器
container_name="n8n"
container_id=$(docker ps -f "name=$container_name" --format "{{.ID}}")

if [ -n "$container_id" ]; then
    echo "ℹ️  发现正在运行的 n8n 容器 ($container_id)，正在停止..."
    docker stop "$container_id"
    echo "ℹ️  正在删除 n8n 容器..."
    docker rm "$container_id"
    echo "✅ 容器已停止并删除"
else
    echo "ℹ️  未找到正在运行的 n8n 容器"
    
    # 检查是否有停止的 n8n 容器
    stopped_container_id=$(docker ps -a -f "name=$container_name" --format "{{.ID}}")
    if [ -n "$stopped_container_id" ]; then
        echo "ℹ️  发现停止的 n8n 容器 ($stopped_container_id)，正在删除..."
        docker rm "$stopped_container_id"
        echo "✅ n8n 容器已删除"
    fi
fi

# 询问是否删除数据
echo ""
echo "❓ 是否删除数据目录？(y/N)"
read -r delete_data

if [[ "$delete_data" =~ ^[Yy]$ ]]; then
    echo "🗑️  删除数据目录..."
    rm -rf n8n-data
    rm -rf data
    rm -rf editor-ui-dist
    echo "✅ 数据目录已删除"
else
    echo "ℹ️  保留数据目录"
fi

echo ""
echo "========================================="
echo "✅ n8n 汉化版卸载完成！"
echo "========================================="