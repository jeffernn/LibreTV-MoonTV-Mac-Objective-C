---
## 🎬 Jeffern影视平台（LibreTV）MAC端 -（Objective-C版）

- Jeffern观影平台是一款基于 macOS 原生开发（Objective-C + Cocoa） 的桌面端影视播放器，可将网站打包成独立的Mac应用，支持自定义影视源。  
- 本软件旨在提高为[LibreTV](https://github.com/jeffernn/LibreTV)项目在Macos上的观影便捷性。
- 本人并非[LibreTV](https://github.com/jeffernn/LibreTV)项目相关制作人员，制作本软件的初心即方便本人自用。
- 此版本运行效率极其软件包大小优于Python版本且已修复Python版本已知的两个BUG[LibreTV-Mac-Python](https://github.com/jeffernn/LibreTV-Mac-Python)，请首选此版本。
- 运行效率极高，文件大小最优，媲美原生应用，影视站打开速度取决于你的影视站速度及其网速

---
## ✨ 使用流程
- 首次打开软件请在顶部菜单栏点击 🚀🚀🚀 设置影视站/视频源/网站源
- 重置点击顶部菜单栏🚀🚀🚀后弹出的输入框不输入内容直接回车即可，软件会自动关闭，手动重启后即重置成功

<p align="center">
  <img width="252" height="119" alt="设置页2" src="https://github.com/user-attachments/assets/17fa188e-bee2-4b3c-8239-d2eca895507b" />
  <img width="971" height="743" alt="设置页1" src="https://github.com/user-attachments/assets/97f8150c-ebee-49f4-b840-d2abededa313" />
</p>
 
<p align="center">
  <img width="979" height="726" alt="主界面" src="https://github.com/user-attachments/assets/8852f23b-9b07-49f5-9bc5-327685e1f845" />
</p>

---

## ✨ 功能简介

- 支持自定义视频源网址
- 支持全屏播放（仅播放器中的网页全屏）
- 首次打开软件请在顶部菜单栏点击 🚀🚀🚀 设置影视站/视频源/网站源
- 重置点击顶部菜单栏🚀🚀🚀后弹出的输入框不输入内容直接回车即可，软件会自动关闭，手动重启后即重置成功

---

## 🛠️ 依赖与环境

本项目为 macOS 原生应用，主要基于以下技术栈：

- **Objective-C**
- **Cocoa（AppKit）**
- **WebKit**（用于网页内容嵌入与播放）
- **Xcode 工程**

---

## 🏗️ 编译与打包
- 使用github action打包
- 使用本地打包
1. **环境要求**
   - macOS 10.12 及以上（M芯片及通用类型打包需高于macos12）
   - Xcode 10 及以上

2. **打包为独立应用**
   - 在 Xcode 菜单栏选择 `Product` -> `Archive` 进行归档
   - 通过 `Organizer` 导出 `.app` 应用包
---

## ⚙️ 缓存文件说明

- 缓存文件路径：  
  `~/Library/Application Support/VipVideo/config.json`
- 用于保存自定义视频源网址、用户偏好设置、影视站cookies、影视站缓存等

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

## 💡 其他说明

- 本项目仅供学习与交流，**禁止用于任何商业用途**。
- 如有问题或建议，欢迎提交 Issue。
- 若要分支项目请注明本项目出处
- 喜欢的话欢迎 Star🌟🌟🌟 支持～

---

