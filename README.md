# SheepAI HUD — 小羊桌面看板

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2014%2B-blue" alt="macOS 14+">
  <img src="https://img.shields.io/badge/swift-5.9%2B-orange" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License">
</p>

<p align="center">
  <b>小羊AI中转站</b>的 macOS 原生桌面面板。<br>
  通过应用程序和桌面小组件，直观查看用户信息、余额和 API 令牌使用情况。
</p>

---

## ✨ 功能

- **📊 用户总览** — 显示用户名、邮箱、余额（美元）、已用额度、请求次数、令牌数量
- **🔑 令牌管理** — 完整令牌列表表格，点击查看详情，支持无限量/有限额状态
- **🖥️ 桌面小组件** — 3 种原生 WidgetKit 小组件，在通知中心即可查看：
  - 用户总览（小号）— 用户信息和用量一览
  - 令牌总览（小号）— 令牌数量和总用量摘要
  - 令牌监视（中号）— 实时监视单个令牌的使用情况
- **🔐 安全存储** — 凭证存储在 macOS App Group 中，通过系统令牌调用 API
- **🔄 自动刷新** — 应用前台自动刷新数据，小组件每 15 分钟自动更新

## 📦 安装

### 前提条件

- macOS 14.0 (Sonoma) 或更高版本
- Xcode 16.0 或更高版本
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) 用于生成项目

```bash
# 安装 XcodeGen（如未安装）
brew install xcodegen
```

### 构建

```bash
# 1. 克隆仓库
git clone https://github.com/你的用户名/sheepai-hud.git
cd sheepai-hud

# 2. 生成 Xcode 项目
xcodegen generate --spec project.yml

# 3. 打开并构建
open SheepAI.xcodeproj
```

在 Xcode 中选择 **SheepAI** Scheme，按 `⌘R` 运行。

### 导出为独立应用

1. 在 Xcode 中：菜单栏 **Product → Archive**
2. 在 Organizer 中：选择 Archive → **Distribute App → Copy App**
3. 将导出的 `SheepAI.app` 拖到「应用程序」文件夹

## 🚀 使用

### 1. 填写凭证

启动应用后，在侧边栏选择 **「设置」**，输入：
- **用户 ID**：你的小羊AI平台账户 ID（对应 `new-api-user` 请求头）
- **系统令牌**：你的小羊AI平台系统令牌（对应 `Authorization` 请求头）

点击「保存凭证」。

### 2. 查看数据

切换到 **「用户总览」** 查看个人信息和用量，或 **「令牌列表」** 浏览所有 API 令牌。

### 3. 添加桌面小组件

1. 打开通知中心（触控板双指从右边缘左滑，或点击菜单栏时间）
2. 点击底部的「编辑小组件」
3. 搜索 **SheepAI**
4. 拖入你想添加的小组件
5. 点击「完成」

> 💡 **令牌监视小组件**需要先在 App 的「令牌列表」中点击一个令牌来选择监视目标。

## 🏗️ 架构

```
sheepai-hud/
├── Shared/                        # 共享代码（App + 小组件）
│   ├── Constants.swift            # API URL、App Group ID、换算比例
│   ├── Models.swift               # Codable 数据模型 + WidgetHelper
│   ├── AppGroupStorage.swift      # App Group UserDefaults 读写
│   └── SheepAPIClient.swift       # URLSession API 客户端
├── SheepAI/                       # 宿主应用
│   ├── SheepAIApp.swift           # @main 应用入口
│   ├── ContentView.swift          # 三栏导航布局
│   ├── ViewModels/
│   │   └── AppViewModel.swift     # ObservableObject 状态管理
│   └── Views/
│       ├── SettingsView.swift     # 凭证输入
│       ├── UserOverviewView.swift # 用户仪表盘
│       └── TokenListView.swift    # 令牌表格 + 详情
├── Widgets/                       # WidgetKit 小组件
│   ├── WidgetsBundle.swift        # 小组件注册
│   ├── UserOverviewWidget.swift   # 用户总览 (systemSmall)
│   ├── TokenOverviewWidget.swift  # 令牌总览 (systemSmall)
│   └── TokenMonitorWidget.swift   # 令牌监视 (systemMedium)
└── project.yml                    # XcodeGen 项目配置
```

### 数据流

```
Host App (URLSession) ──写入缓存──▶ App Group UserDefaults ──读取──▶ WidgetKit 小组件
```

- 用户填写凭证后，宿主 App 调用小羊AI API 获取数据
- 响应数据缓存到 App Group 共享存储
- 小组件从 App Group 读取缓存数据，每 15 分钟自动刷新
- 点击小组件可打开 App 触发即时刷新

## 🔗 API

所有 API 请求发往 `https://www.sheepai.top`：

| API | 用途 | 认证请求头 |
|-----|------|------|
| `GET /api/user/self` | 获取账号信息 | `new-api-user`、`Authorization` |
| `GET /api/token/` | 获取令牌列表 | `new-api-user`、`Authorization` |
| `GET /api/usage/token/` | 获取令牌使用情况 | `Authorization: Bearer <令牌>` |

余额换算：**500,000 系统单位 = 1 美元**

## 🛠️ 技术栈

- **[SwiftUI](https://developer.apple.com/xcode/swiftui/)** — 应用界面
- **[WidgetKit](https://developer.apple.com/documentation/widgetkit)** — 桌面小组件
- **[XcodeGen](https://github.com/yonaskolb/XcodeGen)** — 项目生成
- **纯原生，零第三方依赖**

## 📄 许可证

[MIT License](LICENSE)

---

<p align="center">
  <sub>Built with ❤️ for the SheepAI community</sub>
</p>
