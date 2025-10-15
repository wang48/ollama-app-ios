<p align="center">
  <img src="assets/app_icon_ios_1024.png" alt="Ollama App Logo" width="150"/>
</p>

<h1 align="center">Ollama App iOS</h1>

<p align="center">
  <a href="README.md"><strong>English</strong></a> /
  <a href="README_zh.md"><strong>中文</strong></a> 
<!-- </p> -->
<br/>


## Project Description

This project is an open-source project based on [Ollama App](https://github.com/JHubi1/ollama-app), with secondary development and modifications.

- Only supports the iOS platform. For other platforms, please visit [Ollama App](https://github.com/JHubi1/ollama-app).

- Since "Ollama" and the "Ollama Icon" are registered trademarks, we use "GetOAI" and the "GetOAI Icon" for publication on the App Store.

- This project is not an official Ollama project.


## App Store

> Search for **GetOAI** on the App Store

[![Download on the App Store](https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg)](https://apps.apple.com/us/app/getoai/id6752573799)


## Main characteristics

1. Support the inference process of printing inference models

2. Support generating dialogue titles that match the user's language

3. Highlight active conversations

4. Fix permission issues on the iOS platform

5. Optimize the user experience


## Development Setup

### Prepare macOS Environment

- You must have a Mac + Xcode (because Apple requires iOS builds to be done on macOS).

- Install Xcode (download from the App Store).

- Install CocoaPods (iOS dependency manager):

    ```bash
    sudo gem install cocoapods
    ```

### Configure Flutter Environment

- Install Flutter SDK on macOS.

- Check your environment:

    ```bash
    flutter doctor
    ```

Ensure the following items show ✅:

- iOS toolchain  
- Xcode  
- CocoaPods  

### Run the iOS Project

- Execute in the project root directory:

    ```bash
    flutter run
    ```

- Choose to run on **simulator** or **physical device**.

## Known Issues

> Due to differences in iOS permission mechanisms, for compatibility reasons, the following issues may not be fixed.

- On first launch, you need to go to **Settings** -> **Host Address**, enter any domain, and save it. Only then will the network permission prompt appear. For example: `http://example.com:11434`

- There is a delay in inference model output, causing the opening `<think>` tag to be missing, while the closing `</think>` tag will be output directly.

- Microphone permission cannot be obtained.

- Images for multimodal models are currently unavailable.
