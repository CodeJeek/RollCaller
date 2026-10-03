# RollCaller

**English** · [中文 (简体)](README.zh-CN.md)

A Qt/QML desktop app for random roll call — import a roster from Excel and draw names with either a rolling animation or a lottery-style reveal. Built with C++17 and Qt Quick.

> A small utility project — focused on doing one thing well, not a full classroom management suite.

## What's in it

- **Excel roster import** — load students or members from a spreadsheet
- **Rolling draw** — `FloatingRollWindow` scrolls through names before settling on one
- **Lottery reveal** — `DrawWindow` presents the drawn name in a dedicated view
- **Roster management** — `RosterPage` for viewing and maintaining the name list
- **Theme palette** — `ThemePalette.qml` centralizes all UI colors
- **Chinese localization** — `RollCaller_zh_CN.ts` ships with the project
- **Bundled fonts** — font resources packed via `font.qrc`

## UI overview

Module | File
---|---
Main window | `MainWindow.qml`
Home page | `HomePage.qml`
Sidebar | `Sidebar.qml`
Roster page | `RosterPage.qml`
Settings page | `SettingsPage.qml`
Rolling draw window | `FloatingRollWindow.qml`
Lottery reveal window | `DrawWindow.qml`
Excel import window | `ExcelImportWindow.qml`

## Getting started

1. Install Qt 5.15 or Qt 6.x with the Qt Quick / QML modules.
2. Clone the repo:

   ```bash
   git clone https://github.com/CodeJeek/RollCaller.git
   cd RollCaller
   ```

3. Configure and build with CMake:

   ```bash
   cmake -B build -DCMAKE_BUILD_TYPE=Release
   cmake --build build
   ```

4. Run the executable from `build/`.

> The exact executable name and minimum Qt version are subject to `CMakeLists.txt`.

## Structure

    RollCaller/
    ├── main.cpp                  # Entry point
    ├── main.qml                  # QML entry
    ├── MainWindow.qml            # Main window
    ├── HomePage.qml              # Home page
    ├── RosterPage.qml            # Roster page
    ├── SettingsPage.qml          # Settings page
    ├── Sidebar.qml               # Sidebar
    ├── DrawWindow.qml            # Lottery reveal window
    ├── FloatingRollWindow.qml    # Rolling draw window
    ├── ExcelImportWindow.qml     # Excel import window
    ├── ThemePalette.qml          # Theme colors
    ├── rostercontroller.h/.cpp   # Roster controller
    ├── RollCaller_zh_CN.ts       # Simplified Chinese translation
    ├── qml.qrc / font.qrc        # Resource files
    ├── resources/fonts/          # Font resources
    └── CMakeLists.txt

## License

[GPL-3.0](LICENSE)