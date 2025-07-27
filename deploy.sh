#!/bin/bash

# n8n 汉化版一键部署脚本
# 作者: Lingma (灵码)
# 日期: 2025-07-27

set -e  # 遇到错误时停止执行

echo "========================================="
echo "🚀 开始部署 n8n 汉化版"
echo "========================================="

# 镜像源选择
echo "🌐 镜像源选择:"
echo "1) GitHub (默认)"
echo "2) 国内镜像加速 (gh.llkk.cc)"
echo "3) 自定义镜像源"
echo "4) 不使用镜像加速"
echo ""
echo "请输入选项 (1-4)，或直接按回车使用默认源: "
read -r mirror_choice

case $mirror_choice in
    2)
        MIRROR_URL="https://gh.llkk.cc/"
        echo "✅ 已选择国内镜像加速"
        ;;
    3)
        echo "请输入自定义镜像源地址 (以http://或https://开头): "
        read -r custom_mirror
        if [[ $custom_mirror =~ ^https?:// ]]; then
            MIRROR_URL="$custom_mirror"
            echo "✅ 已设置自定义镜像源: $MIRROR_URL"
        else
            echo "❌ 无效的镜像源地址，使用默认源"
            MIRROR_URL=""
        fi
        ;;
    4)
        MIRROR_URL=""
        echo "✅ 已选择不使用镜像加速"
        ;;
    *)
        MIRROR_URL=""
        echo "✅ 已选择 GitHub 默认源"
        ;;
esac

# 汉化包版本选择
echo ""
echo "<translation> 汉化包版本选择:"
echo "1) 最新发行版 (默认)"
echo "2) 指定版本"
echo ""
echo "请输入选项 (1-2)，或直接按回车使用最新发行版: "
read -r version_choice

case $version_choice in
    2)
        echo "请输入指定的汉化包版本 (例如: 1.99.1): "
        read -r custom_version
        if [ ! -z "$custom_version" ]; then
            TRANSLATION_VERSION="$custom_version"
            echo "✅ 已指定汉化包版本: $TRANSLATION_VERSION"
        else
            TRANSLATION_VERSION="1.99.1"
            echo "ℹ️  版本号不能为空，使用默认版本: $TRANSLATION_VERSION"
        fi
        ;;
    *)
        TRANSLATION_VERSION="latest"
        echo "✅ 已选择最新发行版"
        ;;
esac

echo ""
echo "🔍 配置摘要:"
echo "   镜像源: ${MIRROR_URL:-"GitHub 默认源"}"
echo "   汉化包版本: $TRANSLATION_VERSION"
echo ""

# 检查是否安装了 Docker 和 Docker Compose
echo "🔍 检查 Docker 环境..."
if ! command -v docker &> /dev/null
then
    echo "❌ 未找到 Docker，请先安装 Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null
then
    echo "❌ 未找到 Docker Compose，请先安装 Docker Compose"
    exit 1
fi

echo "✅ Docker 环境检查通过"

# 创建必要的目录
echo "📁 创建项目目录结构..."
mkdir -p n8n-data
mkdir -p data
mkdir -p editor-ui-dist

echo "✅ 目录创建完成"

# 下载并解压汉化包
echo "🌐 下载汉化包..."
cd editor-ui-dist

# 构建下载URL
if [ "$TRANSLATION_VERSION" = "latest" ]; then
    # 获取最新版本
    echo "🔄 正在获取最新汉化包版本信息..."
    LATEST_RELEASE=$(curl -s https://api.github.com/repos/other-blowsnow/n8n-i18n-chinese/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ ! -z "$LATEST_RELEASE" ]; then
        TRANSLATION_VERSION=$LATEST_RELEASE
        echo "✅ 检测到最新版本: $TRANSLATION_VERSION"
    else
        TRANSLATION_VERSION="1.99.1"
        echo "⚠️  无法获取最新版本信息，使用默认版本: $TRANSLATION_VERSION"
    fi
fi

# 构建正确的下载URL
# 移除版本号中的"n8n@"前缀，因为GitHub Release标签通常不包含这个前缀
CLEAN_VERSION=$(echo "$TRANSLATION_VERSION" | sed 's/n8n@//')

# 对版本号进行URL编码，将@符号转换为%40
ENCODED_VERSION=$(echo "$TRANSLATION_VERSION" | sed 's/@/%40/g')

if [ ! -z "$MIRROR_URL" ]; then
    # 使用镜像源，对于gh.llkk.cc需要特殊处理URL格式
    DOWNLOAD_URL="${MIRROR_URL}https://github.com/other-blowsnow/n8n-i18n-chinese/releases/download/n8n@${CLEAN_VERSION}/editor-ui.tar.gz"
else
    # 直接使用GitHub
    DOWNLOAD_URL="https://github.com/other-blowsnow/n8n-i18n-chinese/releases/download/n8n@${CLEAN_VERSION}/editor-ui.tar.gz"
fi

if [ ! -f "editor-ui.tar.gz" ]; then
    echo "⬇️  正在从以下地址下载汉化包:"
    echo "   $DOWNLOAD_URL"
    
    # 对于gh.llkk.cc，需要将URL中的特殊字符进行处理
    if [ ! -z "$MIRROR_URL" ] && [[ "$MIRROR_URL" == *"gh.llkk.cc"* ]]; then
        # gh.llkk.cc需要将GitHub原始URL作为参数传递
        PROXY_URL="${MIRROR_URL}https://github.com/other-blowsnow/n8n-i18n-chinese/releases/download/n8n@${CLEAN_VERSION}/editor-ui.tar.gz"
        echo "使用镜像源: $PROXY_URL"
        if ! curl -L "$PROXY_URL" -o editor-ui.tar.gz; then
            echo "❌ 下载失败，尝试使用备用链接..."
            # 尝试编码后的版本
            PROXY_URL="${MIRROR_URL}https://github.com/other-blowsnow/n8n-i18n-chinese/releases/download/${ENCODED_VERSION}/editor-ui.tar.gz"
            echo "🔄 尝试备用链接: $PROXY_URL"
            curl -L "$PROXY_URL" -o editor-ui.tar.gz || {
                echo "❌ 备用链接也下载失败，尝试直接下载..."
                DIRECT_URL="https://github.com/other-blowsnow/n8n-i18n-chinese/releases/download/n8n@${CLEAN_VERSION}/editor-ui.tar.gz"
                curl -L "$DIRECT_URL" -o editor-ui.tar.gz
            }
        fi
    else
        # 直接下载
        if ! curl -L "$DOWNLOAD_URL" -o editor-ui.tar.gz; then
            echo "❌ 下载失败，尝试使用备用链接..."
            # 尝试编码后的版本
            if [ ! -z "$MIRROR_URL" ]; then
                BACKUP_URL="${MIRROR_URL}https://github.com/other-blowsnow/n8n-i18n-chinese/releases/download/${ENCODED_VERSION}/editor-ui.tar.gz"
            else
                BACKUP_URL="https://github.com/other-blowsnow/n8n-i18n-chinese/releases/download/${ENCODED_VERSION}/editor-ui.tar.gz"
            fi
            echo "🔄 尝试备用链接: $BACKUP_URL"
            curl -L "$BACKUP_URL" -o editor-ui.tar.gz || {
                echo "❌ 备用链接也下载失败"
                exit 1
            }
        fi
    fi
fi

echo "📦 解压汉化包..."
tar -zxvf editor-ui.tar.gz
rm -f editor-ui.tar.gz
cd ..

echo "✅ 汉化包准备完成"

# 创建 docker-compose.yml 文件
echo "⚙️  创建 docker-compose.yml 配置文件..."

cat > docker-compose.yml << 'EOF'
services:
  n8n-zh:
    image: n8nio/n8n:latest
    container_name: n8n-zh
    ports:
      - "5678:5678"
    environment:
      - N8N_DEFAULT_LOCALE=zh-CN
      - N8N_SECURE_COOKIE=false
      - N8N_HOST=0.0.0.0
      - N8N_RUNNERS_ENABLED=true
    volumes:
      - ./editor-ui-dist/dist:/usr/local/lib/node_modules/n8n/node_modules/n8n-editor-ui/dist
      - ./n8n-data:/home/node/.n8n
      - ./data:/data
    stdin_open: true
    tty: true
    restart: unless-stopped
EOF

echo "✅ docker-compose.yml 配置文件创建完成"

# 启动服务
echo "🚀 启动 n8n 服务..."
docker-compose up -d

echo "✅ n8n 服务启动完成"

# 显示服务状态
echo "📋 服务状态:"
docker-compose ps

echo ""
echo "========================================="
echo "🎉 n8n 汉化版部署完成！"
echo "🌐 访问地址: http://localhost:5678"
echo "📂 数据持久化目录: ./n8n-data"
echo "📂 自定义文件目录: ./data"
echo "========================================="