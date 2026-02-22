#!/bin/bash

# 简单的 Flutter APK 打包脚本，用于测试
# 使用 debug 模式打包

echo "开始打包 Flutter APK (debug 模式)..."

# 清理项目
flutter clean

# 获取依赖
flutter pub get

# 打包 APK
flutter build apk --debug

# 检查是否成功
if [ $? -eq 0 ]; then
    echo "APK 打包成功！"
    echo "APK 文件位置: build/app/outputs/flutter-apk/app-debug.apk"
else
    echo "APK 打包失败！"
    exit 1
fi
