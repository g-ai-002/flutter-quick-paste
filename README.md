# 快速粘贴 (Quick Paste)

快捷键弹出预置文本列表，双击自动粘贴到当前输入框光标处。

## 功能

- 📋 预置文本管理：添加、编辑、删除、拖拽排序
- 🔍 文本搜索过滤：按标题或内容快速查找
- ⌨️ 双击预置文本自动粘贴到当前光标处
- 🌓 浅色/深色主题切换
- 🪟 Windows 10+ 原生支持
- 📝 完整日志系统，方便排障

## 系统要求

- Windows 10 或更高版本

## 下载

前往 [GitHub Releases](https://github.com/g-ai-002/flutter-quick-paste/releases) 下载最新版本。

## 开发

```bash
# 安装依赖
flutter pub get

# 运行
flutter run -d windows

# 测试
flutter test

# 构建
flutter build windows --release
```

## 技术栈

- Flutter 3.44.1
- Provider 状态管理
- Material 3 设计
- win32 API 粘贴

## 许可证

MIT License

## 版本历史

### v0.2.1
- 全局热键 Ctrl+Shift+V 显示/隐藏窗口
- 启动时自动隐藏到系统托盘区域
- 粘贴后自动隐藏窗口

### v0.2.0
- 文本搜索过滤：按标题或内容快速查找预置文本
- 搜索栏集成到 AppBar，点击搜索图标展开

### v0.1.1
- 统一服务层单例模式
- 修复设置页硬编码版本号
- 提取 ScaleAnimation 组件
- 移除未使用的代码

### v0.1.0
- 首个版本：Windows 快速粘贴工具最小可用集
- 预置文本增删改、拖拽排序
- 双击自动粘贴到当前光标处
- 浅色/深色主题切换
- Material 3 设计
