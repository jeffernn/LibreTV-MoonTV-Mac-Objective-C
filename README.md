---
## 🎬 Jeffern影视平台（LibreTV）MAC端 -（Objective-C版）

- Jeffern观影平台是一款基于 macOS 原生开发（Objective-C + Cocoa） 的桌面端影视播放器，可将网站打包成独立的Mac应用，支持自定义影视源。  
- 本软件旨在提高为[LibreTV](https://github.com/jeffernn/LibreTV)项目在Macos上的观影便捷性。
- 本人并非[LibreTV](https://github.com/jeffernn/LibreTV)项目相关制作人员，制作本软件的初心即方便本人自用。
- 此版本运行效率极其软件包大小优于Python版本且已修复Python版本已知的两个BUG[LibreTV-Mac-Python](https://github.com/jeffernn/LibreTV-Mac-Python)，请首选此版本。
- 运行效率极高，文件大小极小，原生应用，影视站打开速度取决于你的影视站速度及其网速。
- 本软件内置了一些影视源，可点击顶部状态栏中的内置影视切换观看（内置影视需无梯环境访问/规则代理直连）。

---
## ✨ 使用流程
- 首次打开软件请在顶部菜单栏点击 ✨ 设置影视站/视频源/网站源
- 重置点击顶部菜单栏清除缓存即可删除本软件的本地所有缓存内容
- 点击顶部菜单栏中的内置影视可观看免费的内置影视内容（无需搭建LibreTV）

<p align="center">
  <img width="179" height="168" alt="image" src="https://github.com/user-attachments/assets/27f17f8b-c317-47a0-af2f-e8d7e799ccc2" />
</p>
 <p align="center">
  <img width="275" height="193" alt="image" src="https://github.com/user-attachments/assets/476631f7-8dbd-428c-bb61-035d976b58ff" />
</p>
<p align="center">
  <img width="1680" height="1050" alt="image" src="https://github.com/user-attachments/assets/aaa76898-bd32-4b2d-989c-90cb26f41b0b" />

  <img width="1680" height="1050" alt="image" src="https://github.com/user-attachments/assets/49f3d6b2-92bb-4660-8370-5811576957d9" />

</p>

---
## ⚠️⚠️⚠️温馨提示

- 若应用无法打开：
- 通过系统偏好设置“仍要打开”
- 打开“系统偏好设置”，然后点击“安全性与隐私”.
- 在“通用”选项卡下，如果看到“已阻止使用，因为...”，点击“仍要打开”按钮.
- 系统会再次提示，再次点击“打开”即可.
- 内置影视因网站现在无法放大，请将鼠标移动到网站的最右侧点击红色按钮即可放大缩小（不是播放器内的红色按钮）
- 内置影视站放大按钮持续时间为3s自动隐藏，需重新缩小或放大请将鼠标放至最右侧即可再次显示
<img width="1680" height="1048" alt="image" src="https://github.com/user-attachments/assets/ee8c4016-1fea-4f87-9794-8056b899c41d" />
<img width="1680" height="1049" alt="image" src="https://github.com/user-attachments/assets/c97ceac9-8124-4d73-b06c-711400e1f0cc" />



---

## ✨ 功能简介

- 支持自定义视频源网址
- 支持全屏播放（仅播放器中的网页全屏）
- 首次打开软件请在顶部菜单栏点击 ✨ 设置影视站/视频源/网站源
- 重置点击顶部菜单栏清除缓存
- 点击内置影视可观看免费的内置影视
- 🚀 开箱即用: 无需复杂的部署过程，直接下载安装包即可使用，告别配置烦恼
- 🔐 开源与安全: 项目完全开源，代码透明，无任何跟踪或广告

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
  `~/Library/Application Support/JeffernMovie/config.json`
- 用于保存自定义视频源网址、用户偏好设置、影视站cookies、影视站缓存等

---

## 📁 主要代码结构

```
JeffernMovie/                # 主程序代码
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
- 其他端（安卓、windows、TV）的部署可参考[LibreTV-Mac-Python](https://github.com/jeffernn/LibreTV-Mac-Python)版本进行修改后自行打包。

---

