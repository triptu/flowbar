export interface Annotation {
    title: string;
    body: string;
}

export const ANNOTATIONS: Record<string, Record<number, Annotation>> = {
    "App/FlowbarApp.swift": {
        3: {
            title: "@main",
            body: "Marks the entry point of the application. Swift looks for this attribute to know where to start. It replaces the traditional <code>main.swift</code> file. The struct conforming to <code>App</code> becomes the root of the entire app lifecycle.",
        },
        5: {
            title: "@NSApplicationDelegateAdaptor",
            body: "Bridges SwiftUI's <code>App</code> lifecycle to AppKit's <code>NSApplicationDelegate</code>. This property wrapper creates the AppDelegate instance and connects it to the app's lifecycle. Without it, <code>applicationDidFinishLaunching</code> would never fire.",
        },
    },
    "App/AppDelegate.swift": {
        10: {
            title: "Implicitly Unwrapped Optional (!)",
            body: "The <code>!</code> after the type means this is an implicitly unwrapped optional. It starts as <code>nil</code> but will be set in <code>applicationDidFinishLaunching</code> before anyone uses it. After that, you can use it without <code>if let</code> unwrapping. Dangerous if used before initialization!",
        },
        40: {
            title: "Global + Local Event Monitors",
            body: "Two separate event monitors ensure double-Fn works everywhere. The <em>global</em> monitor (<code>addGlobalMonitorForEvents</code>) fires when another app is focused. The <em>local</em> monitor (<code>addLocalMonitorForEvents</code>) fires when Flowbar itself is focused.",
        },
        42: {
            title: "[weak self]",
            body: "Prevents a <em>retain cycle</em> (memory leak). Closures capture variables by strong reference by default. Since this closure is stored in <code>globalFnMonitor</code>, which is owned by <code>self</code>, a strong capture would create a cycle: self &rarr; monitor &rarr; closure &rarr; self. <code>[weak self]</code> breaks this cycle.",
        },
        43: {
            title: "DispatchQueue.main.async",
            body: "Global event monitors fire on a background thread. Since <code>handleFnEvent</code> accesses <code>@MainActor</code>-isolated state, the call is dispatched to the main thread. The local monitor already runs on the main thread, so it calls <code>handleFnEvent</code> directly.",
        },
    },
    "App/AppState.swift": {
        19: {
            title: "@Observable macro",
            body: "Automatically tracks which properties each view reads, so only views that actually use a changed property re-render. Any stored property is automatically observable.",
        },
        22: {
            title: "Coordinator Pattern",
            body: "AppState owns three sub-state objects (<code>SettingsState</code>, <code>SidebarState</code>, <code>EditorState</code>). It provides cross-cutting methods that touch multiple sub-states &mdash; like <code>selectFile</code> which updates both sidebar and editor. Views access sub-state via <code>appState.settings</code>, <code>appState.sidebar</code>, <code>appState.editor</code>.",
        },
        26: {
            title: "Injectable defaults",
            body: "The <code>defaults</code> parameter defaults to <code>.standard</code> but can be overridden. Tests pass a throwaway <code>UserDefaults(suiteName:)</code> so they don't pollute the real app's settings.",
        },
        43: {
            title: "guard ... else { return }",
            body: "The <code>guard</code> statement ensures a condition is true before proceeding. If it fails, you must exit the scope (return, throw, break). This pattern keeps functions flat and readable.",
        },
        55: {
            title: "Trailing Closure Syntax",
            body: "When the last parameter of a function is a closure, Swift lets you write it outside the parentheses. <code>.map { NoteFile(url: $0) }</code> is short for <code>.map({ NoteFile(url: $0) })</code>. The <code>$0</code> is a shorthand for the first closure parameter.",
        },
        57: {
            title: "[weak self] + Task { @MainActor }",
            body: "A common Swift concurrency pattern. The <code>[weak self]</code> prevents retain cycles. <code>Task { @MainActor in ... }</code> creates an async task that runs on the main thread.",
        },
        69: {
            title: "selectFile crosses sub-states",
            body: "This method touches both <code>sidebar</code> (to set the active panel) and <code>editor</code> (to load file content and set up a watcher). Cross-cutting methods like this are why AppState exists as a coordinator.",
        },
    },
    "App/SettingsState.swift": {
        11: {
            title: "@ObservationIgnored let defaults",
            body: "Excludes this property from observation tracking. The <code>defaults</code> reference never changes after init, so views don't need to re-render when it's accessed.",
        },
        14: {
            title: "UserDefaults with didSet",
            body: "With <code>@Observable</code>, you can't use <code>@AppStorage</code>. Instead, reads happen in <code>init()</code> and writes happen in <code>didSet</code>. Same persistence, just explicit.",
        },
        27: {
            title: "Reactive computed property",
            body: "<code>var accent: Color { accentColor.color }</code> derives the SwiftUI Color from the stored enum. The <code>@Observable</code> macro tracks access, so views reading <code>settings.accent</code> re-render when <code>accentColor</code> changes.",
        },
        43: {
            title: "static let (shared constant)",
            body: "<code>static let defaultWindowSize</code> is a type-level constant shared by all instances. Used by WindowManager when creating a panel for a Space with no saved frame.",
        },
    },
    "App/EditorState.swift": {
        12: {
            title: "@Observable tracked properties",
            body: "Both <code>editorContent</code> and <code>isEditing</code> are tracked by the observation system. When either changes, only views that read that specific property re-render. All other properties are marked <code>@ObservationIgnored</code>.",
        },
        36: {
            title: "Debounced save with DispatchWorkItem",
            body: "Instead of saving on every keystroke, the save is delayed by 0.5 seconds. Each new change cancels the previous pending save. <code>DispatchWorkItem</code> is cancellable, making it ideal for debouncing.",
        },
        44: {
            title: "Background write + main thread callback",
            body: "File writing happens on a background queue (<code>.global(qos: .utility)</code>) to avoid blocking the UI. After the write completes, it hops back to the main thread to re-arm the file watcher.",
        },
        71: {
            title: "Suppress count pattern",
            body: "After an explicit mutation (create, rename, trash), the directory watcher would fire and cause a redundant reload. The suppress count skips that event. It's a counter (not a boolean) to handle rapid successive mutations correctly.",
        },
    },
    "App/SidebarState.swift": {
        17: {
            title: "oldValue guard in didSet",
            body: "<code>if sidebarVisible != oldValue</code> prevents writing to UserDefaults when the value hasn't actually changed. <code>oldValue</code> is an implicit parameter available inside any <code>didSet</code> observer.",
        },
        27: {
            title: "Computed Property + Pattern Matching",
            body: "<code>var selectedFile</code> derives its value from <code>activePanel</code>. <code>if case .file(let f) = activePanel</code> extracts the associated <code>NoteFile</code> from the enum. This is how you work with enums that carry data.",
        },
        62: {
            title: "withAnimation",
            body: "Wrapping a state change in <code>withAnimation</code> tells SwiftUI to animate the resulting UI transition. Here the sidebar slides in/out with a 0.2s ease-in-out curve.",
        },
    },
    "Models/NoteFile.swift": {
        5: {
            title: "struct + Protocols",
            body: "A <code>struct</code> is a value type &mdash; it's copied when passed around. <code>Identifiable</code> requires an <code>id</code> property (needed for SwiftUI lists). <code>Hashable</code> lets it be used in sets and as dictionary keys.",
        },
        8: {
            title: "Computed property (name)",
            body: "<code>var name: String { id }</code> is a computed property that just returns <code>id</code>. Keeps the interface clean: callers read <code>file.name</code> without knowing it's just the filename.",
        },
        10: {
            title: "Custom initializer",
            body: "A custom initializer that computes <code>id</code> from the URL. <code>self.url = url</code> distinguishes the property from the parameter.",
        },
    },
    "Services/FileWatcher.swift": {
        15: {
            title: "@escaping closure",
            body: "<code>@escaping</code> means this closure will outlive the function call. It's stored in a property and called later when a file changes. The compiler requires you to be explicit about escaping closures.",
        },
        20: {
            title: "deinit",
            body: "Called when an object is about to be freed. Here it cancels the dispatch source to stop watching and close the file descriptor.",
        },
        29: {
            title: "DispatchSource for file monitoring",
            body: "A low-level GCD API that watches file system events. The <code>eventMask</code> specifies which changes to watch: writes, renames, deletes, and attribute changes. This is how Flowbar live-reloads when you edit a file in Obsidian.",
        },
        34: {
            title: "[weak self] in closure",
            body: "The event handler closure captures <code>self</code> weakly. Since <code>source</code> owns this closure and <code>self</code> owns <code>source</code>, a strong capture would create a retain cycle.",
        },
    },
    "Services/MarkdownParser.swift": {
        4: {
            title: "enum with associated values",
            body: "<code>MarkdownBlock</code> uses associated values to attach data to each case. A <code>.heading</code> carries its level and text, a <code>.todo</code> carries its done state, text, line index, and indent. The compiler ensures you handle every case in a <code>switch</code>.",
        },
        21: {
            title: "enum with no cases (namespace)",
            body: "An enum with only static methods and no cases acts as a <em>namespace</em>. You can't create an instance of it. This is the Swift equivalent of a static utility class.",
        },
        31: {
            title: ".enumerated()",
            body: "Iterates over a collection while providing both the index and the element. The tuple <code>(index, line)</code> is destructured automatically.",
        },
        105: {
            title: "toggleTodoLine — single-responsibility helper",
            body: "A pure function that toggles one line's checkbox state and returns the result (or <code>nil</code> if the line isn't a todo). Used by both the file-based <code>toggleTodo</code> and the in-memory <code>NoteContentView.toggleTodoInContent</code>.",
        },
        150: {
            title: "toggleTodoIfMatches — guard stacking",
            body: "Multiple <code>guard</code> clauses on one statement. All conditions must pass, or the function returns early. This is a common Swift pattern for validating preconditions without nested <code>if</code> blocks.",
        },
    },
    "Services/TimerService.swift": {
        10: {
            title: "@Observable + @MainActor",
            body: "Like AppState, TimerService uses the <code>@Observable</code> macro for automatic change tracking. The <code>@MainActor</code> guarantees all property access happens on the main thread.",
        },
        13: {
            title: "Nested enum (Screen)",
            body: "An enum nested inside a class scopes it to that type. <code>TimerService.Screen</code> has two cases: <code>.todos</code> and <code>.home</code>. The service owns routing state so views stay dumb.",
        },
        15: {
            title: "Plain var (auto-observed)",
            body: "With <code>@Observable</code>, plain <code>var</code> properties are automatically tracked. When <code>isRunning</code> changes, only views that actually read <code>isRunning</code> re-render.",
        },
        23: {
            title: "Computed Property (hasActiveSession)",
            body: "<code>var hasActiveSession: Bool { isRunning || isPaused }</code> is a computed property with no setter. Derives its value from other state.",
        },
        32: {
            title: "Injectable dependency with default",
            body: "<code>init(db: DatabaseService = .shared)</code> uses the shared singleton by default but lets tests inject a custom instance (like an in-memory DB). This makes the service fully testable without mocks.",
        },
        113: {
            title: "@discardableResult",
            body: "Tells the compiler it's OK to ignore the return value. Without this, calling <code>complete()</code> without using the returned tuple would produce a warning.",
        },
        114: {
            title: "Named Tuple Return",
            body: "<code>-> (todoText: String, sourceFile: String)?</code> returns a named tuple (or nil). Tuples are lightweight ways to return multiple values without defining a struct.",
        },
        126: {
            title: "Compound intent pattern",
            body: "<code>startTodo</code> absorbs view-layer logic into the service: it checks if the todo is already tracked (toggle play/pause), un-marks done todos, and starts a new session. Views just call one method instead of orchestrating multiple state changes.",
        },
        147: {
            title: "completeAndMarkDone — multi-step intent",
            body: "Completes the timer session and marks the todo done in the markdown file. Tries the fast path (<code>toggleTodoIfMatches</code> with saved line index) first, falling back to a text search if the file was edited.",
        },
        186: {
            title: "Timer.scheduledTimer",
            body: "Creates a repeating timer that fires every second. The closure uses <code>[weak self]</code> to avoid retaining the TimerService. <code>Task { @MainActor in ... }</code> ensures UI updates happen on the main thread.",
        },
        210: {
            title: "nonisolated static func",
            body: "Opts this method out of <code>@MainActor</code> isolation. Since <code>formatTime</code> is a pure function that doesn't access mutable state, it can be called from any context without <code>await</code>.",
        },
    },
    "Views/MainView.swift": {
        8: {
            title: "@Environment(Type.self)",
            body: "Reads an <code>@Observable</code> object injected via <code>.environment()</code>. Replaces the older <code>@EnvironmentObject</code>. If no matching object exists, the app crashes.",
        },
        10: {
            title: "var body: some View",
            body: "Every SwiftUI view must have a <code>body</code> property that returns <code>some View</code>. The <code>some View</code> opaque return type lets you return any combination of views without specifying the complex nested generic type.",
        },
        12: {
            title: "Sub-state access pattern",
            body: "Views access state through the coordinator: <code>appState.sidebar.sidebarVisible</code>. This makes dependencies explicit &mdash; you can see exactly which slice of state each view reads.",
        },
        21: {
            title: "switch in ViewBuilder",
            body: "SwiftUI's <code>@ViewBuilder</code> supports <code>switch</code> statements to conditionally show different views. Each case returns a different view type.",
        },
        42: {
            title: "Hidden keyboard shortcuts",
            body: "Hidden <code>Button</code>s with <code>.keyboardShortcut()</code> register app-wide shortcuts without visible UI. The <code>.hidden()</code> modifier makes them invisible but still responsive to keyboard input.",
        },
        37: {
            title: ".preferredColorScheme",
            body: "Applies the user's theme preference. <code>appState.settings.preferredColorScheme</code> returns <code>.light</code>, <code>.dark</code>, or <code>nil</code> (system default). SwiftUI propagates this to all child views.",
        },
    },
    "Window/WindowManager.swift": {
        21: {
            title: "NSObject + @Observable",
            body: "Inherits from <code>NSObject</code> (required for Objective-C interop, like <code>@objc</code> methods and <code>NSStatusBar</code>) and uses the <code>@Observable</code> macro for SwiftUI reactivity.",
        },
        29: {
            title: "isHiding flag",
            body: "A guard flag that prevents <code>togglePanel()</code> from re-triggering during the fade-out animation. Without it, a rapid double-click could try to show the panel while it's still animating closed.",
        },
        36: {
            title: "super.init()",
            body: "Calls the parent class initializer. In Swift, you must initialize all your own properties BEFORE calling <code>super.init()</code>. This is stricter than most languages.",
        },
        53: {
            title: "Right-click via local event monitor",
            body: "A local event monitor intercepts right-clicks on the status item. It checks whether the click landed inside the button using <code>convert(_:from:)</code> and <code>bounds.contains()</code>, then temporarily attaches the menu.",
        },
        88: {
            title: "Per-Space window frames",
            body: "Loads a saved frame for the current desktop Space, or centers with the default size. The panel remembers its position separately on each Space.",
        },
        112: {
            title: "Closure-based onClose",
            body: "Instead of the panel knowing about AppState, it takes an <code>onClose</code> closure. This decouples FloatingPanel from the state layer.",
        },
        120: {
            title: "Native title bar setup",
            body: "After setting the SwiftUI content, adds native AppKit controls to the title bar: a sidebar toggle button and an active task label. These are added directly to the title bar's view hierarchy (via <code>standardWindowButton(.closeButton).superview</code>) so they receive mouse events that the title bar would otherwise consume for window dragging.",
        },
        136: {
            title: "NSAnimationContext",
            body: "AppKit's animation API. <code>runAnimationGroup</code> takes a setup closure (duration) and a completion closure. Fades the panel to zero opacity, then closes it.",
        },
        147: {
            title: "Static factory method + NSImage",
            body: "Draws a custom menu bar icon programmatically using <code>NSBezierPath</code>. Marked <code>isTemplate = true</code> so macOS auto-colors it to match the system appearance.",
        },
    },
    "Window/FloatingPanel.swift": {
        10: {
            title: "class inheritance",
            body: "<code>FloatingPanel: NSPanel</code> inherits from <code>NSPanel</code>, which is itself a subclass of <code>NSWindow</code>. Class inheritance lets you override behavior while reusing the parent's functionality.",
        },
        18: {
            title: "Closure callback (onClose)",
            body: "Instead of holding a reference to AppState, the panel takes an <code>onClose</code> closure. This is the <em>dependency inversion</em> pattern &mdash; the panel reports events without knowing who handles them.",
        },
        31: {
            title: ".fullSizeContentView",
            body: "Lets the content extend behind the title bar for a seamless look. Combined with <code>titlebarAppearsTransparent</code> and <code>titleVisibility = .hidden</code>, the window looks borderless but keeps standard window buttons.",
        },
        39: {
            title: "hidesOnDeactivate = false",
            body: "By default, floating panels hide when the app loses focus. Setting this to <code>false</code> keeps the overlay visible when you click behind it.",
        },
        57: {
            title: "addSidebarToggle — native NSButton in title bar",
            body: "Adds an NSButton directly to the title bar's view hierarchy (accessed via <code>standardWindowButton(.closeButton).superview</code>). This is necessary because the native title bar intercepts mouse events for window dragging before they reach SwiftUI content. By adding the button as a sibling of the traffic lights, it receives clicks naturally.",
        },
        82: {
            title: "addActiveTaskLabel — NSHostingView in title bar",
            body: "Embeds a SwiftUI view (TitleBarLabel) as an <code>NSHostingView</code> centered in the native title bar using Auto Layout constraints. This gives reactive SwiftUI content (timer updates) while living in the AppKit title bar hierarchy.",
        },
        102: {
            title: "repositionTrafficLights",
            body: "Moves the standard close/minimize/zoom buttons to align with the sidebar. Uses <code>standardWindowButton()</code> and <code>setFrameOrigin()</code>.",
        },
        113: {
            title: "override func close()",
            body: "Overrides the parent's <code>close()</code> to fire the <code>onClose</code> callback with the current frame and Space ID. <code>super.close()</code> calls the original.",
        },
        118: {
            title: "override var (computed)",
            body: "Overrides a parent's computed property. <code>canBecomeKey</code> returns <code>true</code> to allow keyboard input. Panels default to <code>false</code>.",
        },
        123: {
            title: "TitleBarButton — closure-based NSButton",
            body: "A custom <code>NSButton</code> subclass that fires a closure on click and overrides <code>mouseDownCanMoveWindow</code> to <code>false</code>. Without this override, clicks on the button would be consumed by the title bar's window-dragging behavior instead of triggering the button action.",
        },
        140: {
            title: "mouseDownCanMoveWindow = false",
            body: "The native title bar uses <code>mouseDown</code> events for window dragging. This override tells AppKit that clicks on this button should NOT initiate a window drag, allowing the button's action to fire instead.",
        },
    },
    "Views/NoteContentView.swift": {
        11: {
            title: "Edit/preview toggle",
            body: "<code>if appState.editor.isEditing</code> switches between <code>MarkdownEditorView</code> (raw text editor) and <code>MarkdownPreviewView</code> (rendered preview with clickable checkboxes). The state lives in <code>EditorState</code> so it persists across note switches.",
        },
        13: {
            title: "Manual Binding creation",
            body: "Creates a <code>Binding</code> from explicit get/set closures. Needed because <code>@Environment</code> doesn't project bindings directly &mdash; you can't write <code>$appState.editor.editorContent</code>. This is an alternative to <code>@Bindable</code>.",
        },
        33: {
            title: "In-memory todo toggle",
            body: "Toggles a checkbox in the in-memory editor content (not the file). Uses <code>MarkdownParser.toggleTodoLine</code> to flip one line, updates <code>editorContent</code>, then triggers a debounced save. This keeps the preview responsive without waiting for disk I/O.",
        },
    },
    "Views/MarkdownEditorView.swift": {
        9: {
            title: "NSViewRepresentable",
            body: "The bridge protocol for wrapping AppKit views in SwiftUI. Requires <code>makeNSView</code> (create the view), <code>updateNSView</code> (sync SwiftUI state to AppKit), and optionally <code>makeCoordinator</code> (for delegates and callbacks).",
        },
        14: {
            title: "makeCoordinator()",
            body: "Creates a <code>Coordinator</code> object that acts as the <code>NSTextViewDelegate</code>. The coordinator lives for the view's lifetime and handles two-way communication between SwiftUI bindings and the AppKit text view.",
        },
        51: {
            title: "Coordinator — NSObject + delegate",
            body: "A nested class conforming to <code>NSTextViewDelegate</code>. The <code>isUpdating</code> flag prevents infinite loops: when SwiftUI pushes new text to the NSTextView, the delegate fires <code>textDidChange</code>, which would push text back to SwiftUI without this guard.",
        },
        68: {
            title: "doCommandBy — intercepting key commands",
            body: "Called before the text view handles a key command. Returning <code>true</code> means &ldquo;I handled it.&rdquo; Here it intercepts Return to auto-continue bullets and todos, or to remove empty bullet prefixes.",
        },
    },
    "Views/MarkdownPreviewView.swift": {
        13: {
            title: "ForEach with enumerated blocks",
            body: "Parses markdown into blocks, enumerates them, and uses the array offset as the identity. Each block maps to a different SwiftUI view via the <code>blockView</code> method.",
        },
        25: {
            title: "@ViewBuilder switch — exhaustive rendering",
            body: "A <code>switch</code> over every <code>MarkdownBlock</code> case. The compiler ensures all cases are handled. Each arm returns a different view type, enabled by <code>@ViewBuilder</code>'s type-erasing support.",
        },
        136: {
            title: "AttributedString(markdown:)",
            body: "Swift's built-in Markdown &rarr; <code>AttributedString</code> conversion. <code>inlineOnlyPreservingWhitespace</code> handles bold, italic, code, and links without treating the text as block-level markdown. Falls back to plain <code>Text</code> if parsing fails.",
        },
    },
    "Views/TitleBarView.swift": {
        5: {
            title: "TitleBarLabel — hosted in native title bar",
            body: "A SwiftUI view embedded as an <code>NSHostingView</code> in the native title bar by <code>FloatingPanel.addActiveTaskLabel()</code>. Reads both <code>TimerService</code> and <code>AppState</code> from the environment to display the active task, elapsed time, and a screen toggle button.",
        },
        9: {
            title: "Computed property with pattern matching",
            body: "<code>if case .timer = appState.sidebar.activePanel</code> checks whether the active panel is the timer screen. This computed property controls whether the todo list toggle button appears in the title bar.",
        },
        20: {
            title: ".monospacedDigit()",
            body: "Uses fixed-width digits so the timer display doesn't shift horizontally as numbers change. Without this, the width of the text would jitter as digits like '1' (narrow) and '0' (wide) alternate.",
        },
        33: {
            title: ".onTapGesture — navigation from title bar",
            body: "Tapping the active task label navigates to the timer panel. <code>.contentShape(Rectangle())</code> ensures the entire area is tappable, not just the text.",
        },
        36: {
            title: "Conditional title bar button",
            body: "The todo list toggle button only appears when the timer panel is active. It calls <code>timerService.toggleScreen()</code> to switch between the timer home and todos list views.",
        },
    },
};
