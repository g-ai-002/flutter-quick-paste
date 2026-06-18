# 快速粘贴工具 — 项目规划

## 长期目标
- 跨 Windows + Android 双平台的快速粘贴工具
- 快捷键弹出预置文本列表，双击自动粘贴到当前光标处
- 精美克制的界面，操作与主流 App 一致
- 持续可演进：每个版本可独立交付，可观测、可回滚

## 中期目标
- [ ] 预置文本分组/分类管理
- [ ] 文本搜索过滤
- [ ] 导入/导出预置文本
- [ ] Android 版本（手机+折叠屏+平板自适应）
- [ ] 云同步预置文本

## 短期目标
- 持续按 prompt.md 的版本节奏：新功能 → patch 修复 → patch 重构

---

## 版本历史

### v0.1.1 (PATCH)
- **状态**: 已发布 ✅
- **目标**: 重构优化存量代码，统一服务层单例模式，消除硬编码
- **任务**:
  - [x] 统一服务层单例模式 (LogService/StorageService/PasteService/FileSystemService)
  - [x] 修复 SettingsPage 硬编码版本号 → 使用 AppConstants.version
  - [x] 移除 HomePage 中重复的日志记录
  - [x] 提取 _ScaleAnimation 到 widgets 目录
  - [x] 移除 FileSystemService 中未使用的 getAppDir 方法
  - [x] 改进 LogService 缓冲区管理
  - [x] 更新版本号到 0.1.1

### v0.1.0 (MINOR)
- **状态**: 已发布 ✅
- **目标**: 首个版本：Windows 快速粘贴工具最小可用集
- **任务**:
  - [x] 项目脚手架（pubspec/analysis_options/.gitignore）
  - [x] 数据模型 PresetText
  - [x] 服务层：日志、文件系统、存储、粘贴
  - [x] 状态层：PresetProvider / SettingsProvider
  - [x] 主题（Material 3 浅/深色、Microsoft YaHei UI）
  - [x] 界面：首页预置文本列表 / 设置页
  - [x] 双击预置文本自动粘贴到当前光标处
  - [x] 预置文本增删改
  - [x] 单元测试
  - [x] GitHub Actions：lint + 单测 + Windows EXE + tag 自动 release
  - [x] README/plan

---

## 设计原则
- **离线优先**：所有数据存储在本地，不联网。
- **简洁高效**：窗口小巧，操作路径最短。
- **可观测**：所有关键操作写入日志文件，方便排障。
- **包体克制**：依赖成熟稳定的纯 Dart / Flutter 插件。

## 依赖与版本基线
- Flutter: 3.44.1
- window_manager: 0.5.1
- provider: 6.1.5+1
- shared_preferences: 2.5.5
- path_provider: 2.1.5
- path: 1.9.1
