---
## 🎬 Jeffern影视平台（LibreTV/MoonTV）MAC端 -（Objective-C版）

- Jeffern观影平台是一款基于 macOS 原生开发（Objective-C + Cocoa） 的桌面端影视播放器，可将影视站打包成独立的Mac应用，支持自定义影视源。  
- 本软件旨在提高为[LibreTV](https://github.com/jeffernn/LibreTV),[MoonTV](https://github.com/senshinya/MoonTV)项目在Macos上的观影便捷性。
- 本人并非[LibreTV](https://github.com/jeffernn/LibreTV),[MoonTV](https://github.com/senshinya/MoonTV)项目相关制作人员，制作本软件的初心即方便本人自用。
- 此版本运行效率及其软件包大小优于Python版本且已修复Python版本已知的两个BUG [LibreTV-Mac-Python](https://github.com/jeffernn/LibreTV-Mac-Python)
- 注意：python版已不再维护，其他端（windows/安卓）使用可移步python版。
- 运行效率极高，文件大小极小，原生应用，影视站打开速度取决于你的影视站速度及其网速。
- 🎉🎉🎉本软件内置了一些影视源，可点击顶部状态栏中的内置影视切换观看（内置影视可能因为网络环境问题加载慢或无法加载切换即可）。

---
## ✨ 使用流程
- 首次会弹出窗口可选择添加你所自建的[LibreTV](https://github.com/jeffernn/LibreTV)/[MoonTV](https://github.com/senshinya/MoonTV)后按✨✨✨确认或回车，也可选择内置影视源（随机打开，可在菜单栏中切换，二次打开应用默认加载✨中设置的影视站，若无设置影视站二次打开会再次弹窗提示）或者打开软件后在顶部菜单栏点击 ✨ 设置影视站/视频源/网站源
- 点击顶部菜单栏清除缓存即可删除本软件的本地所有缓存内容
- 点击顶部菜单栏中的内置影视可观看免费的内置影视内容（无需搭建LibreTV/MoonTV）
- 点击二级菜单中的✨可回到✨设置的LibreTV/MoonTV

<p align="center">
 <img width="198" height="182" alt="image" src="https://github.com/user-attachments/assets/efe17045-89f5-42ae-8d3b-2b8500cdcc4a" />
</p>
 <p align="center">
  <img width="286" height="230" alt="image" src="https://github.com/user-attachments/assets/e62abf45-37c9-4be5-908f-2acf96dfbc40" />
  <img width="1680" height="1050" alt="image" src="https://github.com/user-attachments/assets/0b0f0a8c-8532-42df-9976-bae181cdd34a" />




   </p>
 <p align="center">
<img width="1680" height="1050" alt="image" src="https://github.com/user-attachments/assets/c844d158-c639-4b79-8077-07f0ff56f002" />


</p>
<p align="center">
  <img width="1680" height="1050" alt="image" src="https://github.com/user-attachments/assets/aaa76898-bd32-4b2d-989c-90cb26f41b0b" />

  <img width="1680" height="1050" alt="image" src="https://github.com/user-attachments/assets/49f3d6b2-92bb-4660-8370-5811576957d9" />

</p>

---
## ⚠️⚠️⚠️温馨提示
- ‼️若应用(app)无法打开：
- 通过系统偏好设置“仍要打开”
- 打开“系统偏好设置”，然后点击“安全性与隐私”.
- 在“通用”选项卡下，如果看到“已阻止使用，因为...”，点击“仍要打开”按钮.
- 系统会再次提示，再次点击“打开”即可.
- ‼️如果双击app出现提示"文件已损坏，打不开"等提示。
- 解决方法：请在终端输入以下代码，并输入电脑密码，再次打开app文件即可。
`sudo spctl --master-disable`
- ‼️如果提示需要安装FlashPlayer才能播放。请先安装FlashPlayer及允许。
- ‼️‼️‼️必看：如何放大/缩小内置影视视频
- 内置影视因影视站因素无法放大，请将鼠标移动到网站的最右侧点击红色加号按钮即可放大/缩小（不是播放器内的红色按钮）
- 右侧红色加号按钮默认不显示但是鼠标移动到网页最右侧后显示，同时鼠标停留在按钮超过1S后也会自动隐藏，需再次放大/缩小请将鼠标移动至任意位置后再移动到最右侧出现红色加号按钮后点击即可。
<img width="1680" height="1050" alt="image" src="https://github.com/user-attachments/assets/c29bb079-d143-4827-9318-8c2f214ef957" />
<img width="1679" height="1049" alt="image" src="https://github.com/user-attachments/assets/ec75cb57-1c91-4a0f-bcf7-07057efe17ff" />




---

## ✨ 功能简介

- ✨ 支持自定义视频源网址
- ✨ 支持全屏播放（仅播放器中的网页全屏）
- ✨ 首次打开软件请在顶部菜单栏点击 ✨ 设置影视站/视频源/网站源
- ✨ 重置点击顶部菜单栏清除缓存
- ✨ 点击内置影视可观看免费的内置影视
- ✨ 自带拦截影视站视频源恶意广告
- ✨ 无需复杂的部署过程，直接下载安装包即可使用，告别配置烦恼
- ✨ 项目完全开源，代码透明，无任何跟踪或广告

---

## 🛠️ 技术栈


- **Objective-C**
- **Cocoa（AppKit）**
- **WebKit**（用于网页内容嵌入与播放）
- **Xcode 工程**

---

## 🏗️ 自行打包攻略
- 使用github action打包
- 使用本地打包
1. **环境要求**
   - macOS 10.12 及以上（M芯片及通用类型打包需高于macos12）
   - Xcode 10 及以上

2. **打包为独立应用**
   - 在 Xcode 菜单栏选择 `Product` -> `Archive` 进行归档后Build为独立应用
---

## ⚙️ 软件缓存文件说明

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
- 其他端（安卓、windows、TV）的部署可参考[LibreTV-Mac-Python](https://github.com/jeffernn/LibreTV-Mac-Python)版本进行修改后自行打包。
- 喜欢的话欢迎 Star🌟🌟🌟～

---

