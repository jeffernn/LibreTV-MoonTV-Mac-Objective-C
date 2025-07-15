---
🎬 Jeffern影视平台（LibreTV）MAC端 -（Objective-C版）

> **Jeffern观影平台** 是一款基于 **macOS 原生开发（Objective-C + Cocoa）** 的桌面端影视聚合播放器，支持自定义视频源，界面简洁美观，操作便捷。  
> 本软件旨在为用户提供便捷的多平台影视内容聚合体验，支持多种主流视频网站的内容解析与播放。  
> 软件主要为 LibreTV 项目制作（本人并非引用项目相关制作人员，制作本软件的初心是方便本人使用）。  
> 本版本已修复 Python 版本已知的两个 BUG：[LibreTV-Mac-Python](https://github.com/jeffernn/LibreTV-Mac-Python)

---

## 🖼️ 软件截图

**设置页：**  
<p align="center">
  <img width="971" height="743" alt="设置页1" src="https://github.com/user-attachments/assets/97f8150c-ebee-49f4-b840-d2abededa313" />
  <img width="252" height="119" alt="设置页2" src="https://github.com/user-attachments/assets/17fa188e-bee2-4b3c-8239-d2eca895507b" />
</p>

**主界面：**  
<p align="center">
  <img width="979" height="726" alt="主界面" src="https://github.com/user-attachments/assets/8852f23b-9b07-49f5-9bc5-327685e1f845" />
</p>

---

## ✨ 功能简介

- 支持自定义视频源网址（如自建 LibreTV、腾讯、爱奇艺、优酷、B站、芒果TV 等主流视频网站）
- 顶部菜单栏点击 🚀 可一键重置视频源
- 简洁易用的原生桌面端体验
- 支持全屏播放、窗口居中、菜单自定义等 macOS 原生特性

---

## 🛠️ 依赖与环境

本项目为 macOS 原生应用，主要基于以下技术栈：

- **Objective-C**
- **Cocoa（AppKit）**
- **WebKit**（用于网页内容嵌入与播放）
- **Xcode 工程**

---

## 🏗️ 编译与打包

1. **环境要求**
   - macOS 10.12 及以上
   - Xcode 10 及以上

2. **编译步骤**
   - 使用 Xcode 打开 `VipVideo.xcodeproj` 工程文件
   - 选择目标设备（My Mac）
   - 点击“运行”或“构建”即可生成应用

3. **打包为独立应用**
   - 在 Xcode 菜单栏选择 `Product` -> `Archive` 进行归档
   - 通过 `Organizer` 导出 `.app` 应用包

---

## ⚙️ 配置文件说明

- 配置文件路径：  
  `~/Library/Application Support/VipVideo/config.json`
- 用于保存自定义视频源网址、用户偏好设置等

---

## 📁 主要代码结构

```
VipVideo/                # 主程序代码
├── Home/                # 主界面与窗口控制器
├── Addition/            # NSURLProtocol、字符串处理等扩展
├── Helper/              # 正则匹配、JSON 解析等工具类
├── Assets.xcassets/     # 应用图标与资源
└── Base.lproj/          # 界面 Storyboard 文件
```

---

## 📜 开源协议

本项目基于 MIT License 开源，详见 [LICENSE](./LICENSE)。

---

## 💡 其他说明

- 本项目仅供学习与交流，**禁止用于任何商业用途**。
- 如有问题或建议，欢迎提交 Issue。
- 若要分支项目请注明本项目出处，喜欢的话欢迎 Star 支持～

---

