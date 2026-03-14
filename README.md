# Flowbar

A native macOS menu bar app for quick access to a folder of markdown notes. Built for people who use Obsidian but want something lighter always within reach — no need to open the full app just to check a todo or jot something down.

Click the Flowbar icon in your menu bar, your notes are right there. Edit them, check off todos, track time on tasks. Close the popover, it's gone. Double-tap Fn to bring it back from anywhere.

You can also use this repo as a reference to learn Swift, checkout [learn-swift](docs/learn-swift.html) for an interactive guide to the Swift concepts and patterns used in Flowbar.

## What it does

- **Menu bar popover** — opens right under the menu bar icon
- **Sidebar + editor** — all your .md files listed on the left, raw markdown editor on the right
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

## Keyboard shortcuts

- **Double-tap Fn** — toggle the popover from anywhere
- **⌘B** — toggle sidebar

## Contributing

This is a personal project, but if you find a bug or want to suggest an improvement, feel free to open an issue or submit a pull request. I'm happy to review and merge contributions that align with the minimalist design and core functionality.

If using claude code, use this command - "/flowbar-dev [the change you want to make]" for ease of development and consistency.
