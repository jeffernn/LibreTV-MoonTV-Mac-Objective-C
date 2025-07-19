---
## 🎬  Jeffern影视平台（LibreTV/MoonTV/已内置影视资源/内置免费Emby站）MAC端 -（Objective-C版）

- Jeffern观影平台是一款基于 macOS 原生开发（Objective-C + Cocoa） 的桌面端影视播放平台，可将影视站打包成独立的Mac应用，支持自定义影视源,内置了一些影视资源  
- 本软件旨在提高为[LibreTV](https://github.com/jeffernn/LibreTV),[MoonTV](https://github.com/senshinya/MoonTV)项目在Macos上的观影便捷性，同时为不会部署或无条件部署的用户提供一些内置影视资源
- 运行效率极高，文件大小极小，原生应用，影视站打开速度取决于你的影视站速度及其网速
- 此版本运行效率及其软件包大小优于Python版本且已修复Python版本已知的两个BUG [LibreTV-Mac-Python](https://github.com/jeffernn/LibreTV-Mac-Python)
- python版已不再维护，如果需要使用其他端（windows/安卓）[LibreTV-Mac-Python](https://github.com/jeffernn/LibreTV-Mac-Python)
- 🎉🎉🎉本软件内置了一些影视源，可点击顶部状态栏中的内置影视切换观看（内置影视可能因为网络环境问题加载慢或无法加载切换即可）

---
## ✨  用户指南

- 首次会弹出窗口可选择添加你所自建的[LibreTV](https://github.com/jeffernn/LibreTV)/[MoonTV](https://github.com/senshinya/MoonTV)网址后按✨✨✨确认或回车，也可选择内置影视源
- 点击顶部菜单栏清除缓存即可删除本软件的本地所有缓存内容(重新设置自建的LibreTV/MoonTV)
- 点击顶部菜单栏中的内置影视可观看免费的内置影视内容（无需搭建LibreTV/MoonTV）
- 点击二级菜单中的BACK->✨可回到设置的LibreTV/MoonTV
- 内置免费Emby站（公益服务，为了持续大家都可以享受到，请勿滥用！）

<p align="center">
 <img width="194" height="170" alt="image" src="https://github.com/user-attachments/assets/3104afb9-94d5-445a-8689-0be89c875231" />


</p>
 <p align="center">
  <img width="279" height="238" alt="image" src="https://github.com/user-attachments/assets/7dfb38eb-8079-4df1-a92e-c3952f85d11a" />


  <img width="1680" height="1050" alt="image" src="https://github.com/user-attachments/assets/0b0f0a8c-8532-42df-9976-bae181cdd34a" />




   </p>
 <p align="center">
<img width="1680" height="1050" alt="image" src="https://github.com/user-attachments/assets/9e6d8f56-26ef-49bd-8dd1-2ff59a1e4d70" />
<img width="1680" height="1050" alt="image" src="https://github.com/user-attachments/assets/cdb5b01e-5b4d-44eb-8e28-896766d31034" />
<img width="1680" height="1049" alt="image" src="https://github.com/user-attachments/assets/b8286672-8514-40a0-97a8-87c9709fee30" />
<img width="1680" height="1050" alt="image" src="https://github.com/user-attachments/assets/7b11277e-e22f-4690-82ae-9b6ef4ac39be" />
<img width="1680" height="1050" alt="image" src="https://github.com/user-attachments/assets/e7fa0ac2-bec3-4b61-ba4c-95f4ed6e7016" />




</p>
<p align="center">
  <img width="1680" height="1050" alt="image" src="https://github.com/user-attachments/assets/aaa76898-bd32-4b2d-989c-90cb26f41b0b" />

  <img width="1680" height="1050" alt="image" src="https://github.com/user-attachments/assets/49f3d6b2-92bb-4660-8370-5811576957d9" />

</p>

---
## ‼️‼️‼️ 如何放大/缩小内置影视视频

- 内置影视视频因影视站不支持等因素无法放大（现注入一个新的放大/缩小按钮，使用流程如下）
- ①将鼠标移动至网站的最右侧（此时会出现红色➕按钮）点击红色加号按钮即可放大/缩小视频（不是播放器内的红色按钮）。
- ②红色加号按钮默认不显示将鼠标移动至网页最右侧后即显示，同时鼠标停留在按钮超过1S后也会自动隐藏，需再次放大/缩小请将鼠标移动至任意位置后再移动到最右侧，出现红色加号按钮后点击即可。
<img width="1680" height="1050" alt="image" src="https://github.com/user-attachments/assets/c29bb079-d143-4827-9318-8c2f214ef957" />
<img width="1679" height="1049" alt="image" src="https://github.com/user-attachments/assets/ec75cb57-1c91-4a0f-bcf7-07057efe17ff" />

---
## ‼️ 重置LibreTV/MoonTV自建影视站网址

- ①点击菜单栏中的清除缓存后软件会自动重启
- ②在弹出的窗口中点击✨✨✨即可重新设置
  
---
## ‼️应用(app)无法打开：

- ①通过系统偏好设置“仍要打开”
- ②打开“系统偏好设置”，然后点击“安全性与隐私”.
- ③在“通用”选项卡下，如果看到“已阻止使用，因为...”，点击“仍要打开”按钮.
- ④系统会再次提示，再次点击“打开”即可.
  
---
## ‼️双击app出现提示"文件已损坏，打不开"等提示。

- ①解决方法：请在终端输入以下代码，并输入电脑密码，再次打开app文件即可。
  
`sudo spctl --master-disable`

---
## ‼️提示需要安装FlashPlayer才能播放。

- ①请先安装FlashPlayer及允许。

---

## ✨  功能简介

- ✨ 支持自定义视频源网址（LibreTV/MoonTV）
- ✨ 支持全屏播放（LibreTV/MoonTV使用播放器中的网页全屏，内置影视请看以上教学）
- ✨ 点击顶部菜单栏清除缓存可清除所有缓存（重新设置LibreTV/MoonTV自建网址）
- ✨ 点击内置影视可观看免费的内置影视（会持续更新）
- ✨ 自带拦截影视站视频源恶意广告（影视源中途的插片广告）
- ✨ 无需复杂的部署过程，直接下载安装包(请在Releases处下载最新版本)即可使用，告别配置烦恼
- ✨ 项目完全开源，代码透明，无任何跟踪或广告

---

## 🛠️  技术栈

- **Objective-C**
- **Cocoa（AppKit）**
- **WebKit**（用于网页内容嵌入与播放）
- **Xcode 工程**

---

## 🏗️  自行打包攻略

- 使用github action打包
- 使用本地打包
  
1. **环境要求**
   - macOS 10.12 及以上（M芯片及通用类型打包需高于macos12）
   - Xcode 10 及以上

2. **打包为独立应用**
   - 在 Xcode 菜单栏选择 `Product` -> `Archive` 进行归档后Build为独立应用
---

## ⚙️  软件缓存文件说明

- 缓存文件路径：  
  `~/Library/Application Support/JeffernMovie/config.json`
- 用于保存自定义视频源网址、用户偏好设置、影视站cookies、影视站缓存等

---

## 📁  主要代码结构

```
JeffernMovie/                # 主程序代码
├── Home/                # 主界面与窗口控制器
├── Addition/            # NSURLProtocol、字符串处理等扩展
├── Helper/              # 正则匹配、JSON 解析等工具类
├── Assets.xcassets/     # 应用图标与资源
└── Base.lproj/          # 界面 Storyboard 文件
```

---

## ✨  将LibreTV封装成iPad端桌面级应用

①点击Safari分享按钮

![IMG_1818](https://github.com/user-attachments/assets/6e7eaa6f-ff33-4e14-99e6-c91cbbeaf06a)


②点击添加到主屏幕

![IMG_1819](https://github.com/user-attachments/assets/91202b83-b066-41ba-b209-96efbad30626)

③设置应用名字

![IMG_1820](https://github.com/user-attachments/assets/da951eb9-652a-4fa8-9fc9-5feacd1311e4)

④打开应用

<img width="2360" height="1640" alt="IMG_1821" src="https://github.com/user-attachments/assets/98b181f1-745a-444a-b41d-786b7febe5d7" />


---
### 🚨 重要声明

- 本项目仅供学习和个人使用
- 请勿用于商业用途或公开服务（**禁止用于任何商业用途**）
- 如因公开分享导致的任何法律问题，用户需自行承担责任
- 项目开发者不对用户的使用行为承担任何法律责任
- 如有问题或建议，欢迎提交 Issue
- 如需分支项目请引用本项目地址
- 其他端（安卓、windows、TV）的部署可参考[LibreTV-Mac-Python](https://github.com/jeffernn/LibreTV-Mac-Python)版本进行修改后自行打包
- 喜欢的话欢迎 Star🌟🌟🌟～


---
## ⚠️ 免责声明

JeffernMovie 仅作为视频搜索工具，不存储、上传或分发任何视频内容。所有视频均来自第三方影视站提供的搜索结果。如有侵权内容，请联系相应的内容提供方。

本项目开发者不对使用本项目产生的任何后果负责。使用本项目时，您必须遵守当地的法律法规。
 
