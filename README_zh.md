
<p align="center">
  <img src="assets/app_icon_ios_1024.png" alt="Ollama App Logo" width="150"/>
</p>

<h1 align="center">Ollama App iOS</h1>

<p align="center">
  <a href="README.md"><strong>English</strong></a> /
  <a href="README_zh.md"><strong>中文</strong></a> 
<!-- </p> -->
<br/>

## 支持

[Ollama App](https://github.com/JHubi1/ollama-app) 的 iOS 客户端, 本存储库仅支持 iOS 平台，其他平台请访问 [Ollama App](https://github.com/JHubi1/ollama-app)。


## 声明

- 由于 "Ollama" 以及 "羊驼图标" 属于注册商标, 我们使用 "GetOAI" 以及 "GetOAI 图标" 上架 App Store.

- 上架 App Store 以及维护开发者账号相比其他平台需要更高的成本, 为了此项目的健康发展, 应用采用付费下载.

- 此应用不是 Ollama 官方客户端.

## 安装

App Store 搜索 GetOAI

## 开发启动

### 准备 macOS 环境

- 必须有 Mac + Xcode（因为苹果规定 iOS 构建只能在 macOS 下完成）。

- 安装 Xcode（App Store 下载）。

- 安装 CocoaPods（iOS 依赖管理工具）：

    ```bash
    sudo gem install cocoapods
    ```

### 配置 Flutter 环境

- 在 macOS 下安装 Flutter SDK。

- 检查环境：

    ```bash
    flutter doctor
    ```

确保以下项目都显示 ✅：

- iOS toolchain

- Xcode

- CocoaPods

### 运行 iOS 项目

- 在项目根目录执行：

    ```bash
    flutter run
    ```

- 选择使用模拟器或者真机运行

