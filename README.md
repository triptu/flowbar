# Flowbar

A native macOS menu bar app for quick access to a folder of markdown notes and todos with integrated time tracking to help you focus. I use Obsidian but want something lighter so I can check/edit todos and notes without opening the full app.

Click the Flowbar icon in your menu bar and a floating overlay appears with your notes right there. Edit them, check off todos, track time on tasks. Click the icon again or double-tap Fn to toggle it from anywhere.

You can also use this repo as a reference to learn Swift, checkout [learn-swift](https://flowbar.tushar.ai/learn-swift) for a guide to the Swift concepts and patterns used in Flowbar.

## What it does

- **Floating overlay panel** — toggle from the menu bar icon or double-tap Fn
- **Sidebar + editor** — all your .md files listed on the left, raw markdown editor on the right
- **File management** — right-click for context menu: new file, rename (inline), reveal in Finder, open in Obsidian, trash
- **Timer** — stopwatch to track time on todos, extracted from all your markdown files
- **Settings** — folder path, dark/light/system theme, font size, keyboard shortcut

## How to build & run

You need Xcode installed (tested on Xcode 16+, macOS 14+).

```bash
# Generate the Xcode project (only needed once, or after changing project.yml)
cd Flowbar
xcodegen generate

# Build
xcodebuild -project Flowbar.xcodeproj -scheme Flowbar -configuration Debug build

# Run the app
open ~/Library/Developer/Xcode/DerivedData/Flowbar-*/Build/Products/Debug/Flowbar.app
```

Or just open `Flowbar.xcodeproj` in Xcode and hit Run.

First launch: click the Flowbar icon in your menu bar, go to Settings, and point it at your Obsidian vault folder (or any folder with .md files).

## Contributing

This is a personal project, but if you find a bug or want to suggest an improvement, feel free to open an issue or submit a pull request. I'm happy to review and merge contributions that align with the minimalist design and core functionality.

If using claude code, use this command - "/flowbar-dev [the change you want to make]" for ease of development and consistency.
