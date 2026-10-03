# RollCaller

[English](README.md) · **中文 (简体)**

一个基于 Qt/QML 的桌面随机点名工具 —— 从 Excel 导入名单，通过滚动动画或抽签方式抽取名字。使用 C++17 与 Qt Quick 构建。

> 一个小工具项目 —— 专注把一件事做好，而非完整的课堂管理套件。

## 功能

- **Excel 名单导入** —— 从表格加载学生或成员名单
- **滚动抽取** —— `FloatingRollWindow` 在名字间滚动后定格
- **抽签展示** —— `DrawWindow` 在独立视图中展示抽中的名字
- **名单管理** —— `RosterPage` 用于查看与维护名单
- **主题配色** —— `ThemePalette.qml` 统一管理界面配色
- **中文本地化** —— 项目内置 `RollCaller_zh_CN.ts`
- **打包字体** —— 通过 `font.qrc` 打包字体资源

## 界面一览

模块 | 文件
---|---
主窗口 | `MainWindow.qml`
主页 | `HomePage.qml`
侧边栏 | `Sidebar.qml`
名单页 | `RosterPage.qml`
设置页 | `SettingsPage.qml`
滚动抽取窗口 | `FloatingRollWindow.qml`
抽签展示窗口 | `DrawWindow.qml`
Excel 导入窗口 | `ExcelImportWindow.qml`

## 快速开始

1. 安装 Qt 5.15 或 Qt 6.x，需包含 Qt Quick / QML 模块。
2. 克隆仓库：

   ```bash
   git clone https://github.com/CodeJeek/RollCaller.git
   cd RollCaller
   ```

3. 使用 CMake 配置并构建：

   ```bash
   cmake -B build -DCMAKE_BUILD_TYPE=Release
   cmake --build build
   ```

4. 运行 `build/` 目录下的可执行文件。

> 具体可执行文件名与最低 Qt 版本以 `CMakeLists.txt` 为准。

## 项目结构

    RollCaller/
    ├── main.cpp                  # 程序入口
    ├── main.qml                  # QML 入口
    ├── MainWindow.qml            # 主窗口
    ├── HomePage.qml              # 主页
    ├── RosterPage.qml            # 名单页
    ├── SettingsPage.qml          # 设置页
    ├── Sidebar.qml               # 侧边栏
    ├── DrawWindow.qml            # 抽签展示窗口
    ├── FloatingRollWindow.qml    # 滚动抽取窗口
    ├── ExcelImportWindow.qml     # Excel 导入窗口
    ├── ThemePalette.qml          # 主题配色
    ├── rostercontroller.h/.cpp   # 名单控制器
    ├── RollCaller_zh_CN.ts       # 简体中文翻译
    ├── qml.qrc / font.qrc        # 资源文件
    ├── resources/fonts/          # 字体资源
    └── CMakeLists.txt

## 许可证

[GPL-3.0](LICENSE)