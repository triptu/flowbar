export function highlightSwift(code: string): string {
  // Escape HTML first
  let html = code.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

  // Comments (// and ///) — must be done first
  html = html.replace(/(\/\/\/?.*)$/gm, '<span class="cmt">$1</span>');

  // Multi-line strings (""") — simplified
  html = html.replace(/("""[\s\S]*?""")/g, '<span class="str">$1</span>');

  // Strings
  html = html.replace(/("(?:[^"\\]|\\.)*?")/g, function (m, _p1, offset, str) {
    if (m.indexOf('class="') !== -1 || m.indexOf("span") !== -1) return m;
    // Skip HTML attribute values (inside an unclosed tag)
    const before = str.substring(Math.max(0, offset - 60), offset);
    if (before.match(/<[^>]*$/)) return m;
    return '<span class="str">' + m + "</span>";
  });

  // Property wrappers
  html = html.replace(
    /(@(?:MainActor|Observable|ObservationIgnored|Published|AppStorage|Environment|EnvironmentObject|Bindable|State|Binding|ViewBuilder|GestureState|objc|main|discardableResult|NSApplicationDelegateAdaptor|escaping|nonisolated))/g,
    '<span class="pw">$1</span>',
  );

  // Keywords
  const kwList = [
    "import",
    "struct",
    "class",
    "enum",
    "func",
    "var",
    "let",
    "if",
    "else",
    "guard",
    "switch",
    "case",
    "return",
    "for",
    "in",
    "private",
    "static",
    "final",
    "override",
    "some",
    "self",
    "super",
    "nil",
    "true",
    "false",
    "try",
    "catch",
    "do",
    "throw",
    "throws",
    "where",
    "as",
    "is",
    "init",
    "deinit",
    "defer",
    "protocol",
    "extension",
    "typealias",
    "weak",
    "nonisolated",
    "mutating",
  ];
  const kwRe = new RegExp("\\b(" + kwList.join("|") + ")\\b", "g");
  html = html.replace(kwRe, function (m, kw, offset, str) {
    // Don't highlight inside HTML tags or already-tagged span content
    const before = str.substring(Math.max(0, offset - 60), offset);
    if (before.match(/<[^>]*$/) || before.match(/<span[^>]*>(?:[^<]*)$/)) return m;
    return '<span class="kw">' + kw + "</span>";
  });

  // Types (capitalized words that look like types)
  const typeList = [
    "String",
    "Int",
    "Int32",
    "Int64",
    "Bool",
    "URL",
    "Date",
    "Double",
    "CGFloat",
    "Any",
    "Void",
    "TimeInterval",
    "View",
    "Scene",
    "App",
    "NSObject",
    "NSApplicationDelegate",
    "ObservableObject",
    "Equatable",
    "Hashable",
    "Identifiable",
    "CaseIterable",
    "RawRepresentable",
    "NoteFile",
    "AppState",
    "SettingsState",
    "EditorState",
    "SidebarState",
    "TimerService",
    "WindowManager",
    "FloatingPanel",
    "FileWatcher",
    "DatabaseService",
    "TodoItem",
    "MarkdownParser",
    "MarkdownBlock",
    "MarkdownEditorView",
    "MarkdownPreviewView",
    "TitleBarLabel",
    "FlowbarColors",
    "AccentColor",
    "TypographySize",
    "AppTheme",
    "ActivePanel",
    "MainView",
    "SidebarView",
    "NoteContentView",
    "SettingsView",
    "TimerContainerView",
    "SidebarDivider",
    "SidebarToggleButton",
    "NSStatusItem",
    "NSTextView",
    "NSScrollView",
    "NSFont",
    "NSViewRepresentable",
    "NSTextViewDelegate",
    "NSResponder",
    "NSString",
    "NSRange",
    "Coordinator",
    "AttributedString",
    "ScrollView",
    "Button",
    "Divider",
    "Spacer",
    "RoundedRectangle",
    "ForEach",
    "ObsidianIcon",
    "TimerHomeView",
    "TimerTodosView",
    "TodoRow",
    "NSPanel",
    "NSWindow",
    "NSSize",
    "NSPoint",
    "NSRect",
    "NSScreen",
    "NSEvent",
    "NSImage",
    "NSApp",
    "NSWorkspace",
    "NSHostingController",
    "NSHostingView",
    "NSStatusBar",
    "NSMenu",
    "NSMenuItem",
    "NSBezierPath",
    "NSAffineTransform",
    "NSColor",
    "NSAnimationContext",
    "CAMediaTimingFunction",
    "ColorScheme",
    "Color",
    "HStack",
    "VStack",
    "Group",
    "Text",
    "Image",
    "EmptyView",
    "Settings",
    "DispatchWorkItem",
    "DispatchQueue",
    "DispatchSource",
    "DispatchSourceFileSystemObject",
    "Timer",
    "FileManager",
    "Scanner",
    "CharacterSet",
    "Notification",
    "Combine",
    "Observation",
    "UserDefaults",
    "OpaquePointer",
    "ModifierFlags",
  ];
  const tyRe = new RegExp("\\b(" + typeList.join("|") + ")\\b", "g");
  html = html.replace(tyRe, function (m, ty, offset, str) {
    const before = str.substring(Math.max(0, offset - 60), offset);
    if (before.match(/<[^>]*$/) || before.match(/<span[^>]*>(?:[^<]*)$/)) return m;
    return '<span class="ty">' + ty + "</span>";
  });

  // Numbers
  html = html.replace(/\b(\d+\.?\d*)\b/g, function (m, num, offset, str) {
    const before = str.substring(Math.max(0, offset - 60), offset);
    if (before.match(/<[^>]*$/) || before.match(/<span[^>]*>(?:[^<]*)$/)) return m;
    return '<span class="num">' + num + "</span>";
  });

  return html;
}
