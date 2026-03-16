export type ConceptCategory = "types" | "memory" | "swiftui" | "concurrency" | "patterns";

export interface Concept {
    cat: ConceptCategory;
    title: string;
    desc: string;
    code: string;
}

export const CONCEPTS: Concept[] = [
    {
        cat: "types",
        title: "struct",
        desc: "Value types that are copied on assignment. Preferred for data models in Swift. They're stack-allocated and don't need reference counting.",
        code: '<span class="kw">struct</span> <span class="ty">NoteFile</span>: <span class="ty">Identifiable</span>, <span class="ty">Hashable</span> {\n    <span class="kw">let</span> id: <span class="ty">String</span>\n    <span class="kw">let</span> url: <span class="ty">URL</span>\n    <span class="kw">let</span> name: <span class="ty">String</span>\n}',
    },
    {
        cat: "types",
        title: "class",
        desc: "Reference types passed by pointer. Used when you need identity, inheritance, or a single shared instance (like AppDelegate, AppState).",
        code: '<span class="pw">@Observable</span>\n<span class="pw">@MainActor</span>\n<span class="kw">final class</span> <span class="ty">AppState</span> {\n    <span class="kw">let</span> settings: <span class="ty">SettingsState</span>\n    <span class="kw">let</span> sidebar: <span class="ty">SidebarState</span>\n    <span class="kw">let</span> editor: <span class="ty">EditorState</span>\n}',
    },
    {
        cat: "types",
        title: "enum with associated values",
        desc: "Like tagged unions. Each case can carry different data. The compiler enforces exhaustive handling via switch.",
        code: '<span class="kw">enum</span> <span class="ty">ActivePanel</span>: <span class="ty">Equatable</span> {\n    <span class="kw">case</span> file(<span class="ty">NoteFile</span>)\n    <span class="kw">case</span> settings\n    <span class="kw">case</span> timer\n    <span class="kw">case</span> empty\n}',
    },
    {
        cat: "types",
        title: "protocol",
        desc: 'Defines a contract (like an interface). Types "conform" to protocols by implementing required properties and methods. Protocols enable polymorphism without inheritance.',
        code: '<span class="cmt">// Identifiable requires an `id` property</span>\n<span class="kw">struct</span> <span class="ty">NoteFile</span>: <span class="ty">Identifiable</span> {\n    <span class="kw">let</span> id: <span class="ty">String</span>  <span class="cmt">// satisfies the protocol</span>\n}',
    },
    {
        cat: "memory",
        title: "ARC (Automatic Reference Counting)",
        desc: "Swift automatically tracks how many references point to each class instance. When the count reaches zero, the object is deallocated. No garbage collector needed.",
        code: '<span class="cmt">// Each variable pointing to an object increments its count</span>\n<span class="kw">var</span> a = <span class="ty">AppState</span>()  <span class="cmt">// refcount = 1</span>\n<span class="kw">var</span> b = a             <span class="cmt">// refcount = 2</span>\nb = <span class="kw">nil</span>               <span class="cmt">// refcount = 1</span>\na = <span class="kw">nil</span>               <span class="cmt">// refcount = 0 → deallocated</span>',
    },
    {
        cat: "memory",
        title: "[weak self]",
        desc: "Prevents retain cycles in closures. A weak reference doesn't increment the reference count, so the object can be deallocated even if the closure still exists.",
        code: '<span class="cmt">// Without [weak self]: closure → self → closure (leak!)</span>\nfnMonitor = <span class="ty">NSEvent</span>.addGlobalMonitor... { [<span class="kw">weak self</span>] event <span class="kw">in</span>\n    <span class="kw">guard let self else</span> { <span class="kw">return</span> }\n    <span class="cmt">// safe to use self here</span>\n}',
    },
    {
        cat: "memory",
        title: "deinit",
        desc: "Called when an object is about to be freed. Used for cleanup like closing database connections or removing observers.",
        code: '<span class="kw">final class</span> <span class="ty">DatabaseService</span> {\n    <span class="kw">private var</span> db: <span class="ty">OpaquePointer</span>?\n    <span class="kw">deinit</span> { sqlite3_close(db) }\n}',
    },
    {
        cat: "swiftui",
        title: "View protocol + body",
        desc: "Every SwiftUI view is a struct conforming to View. The body property returns the view's content, called by SwiftUI whenever state changes.",
        code: '<span class="kw">struct</span> <span class="ty">MainView</span>: <span class="ty">View</span> {\n    <span class="kw">var</span> body: <span class="kw">some</span> <span class="ty">View</span> {\n        <span class="ty">HStack</span>(spacing: <span class="num">0</span>) {\n            <span class="ty">SidebarView</span>()\n            <span class="ty">NoteContentView</span>()\n        }\n    }\n}',
    },
    {
        cat: "swiftui",
        title: "@State & @Binding",
        desc: "@State creates local view state (owned by the view). @Binding creates a two-way reference to state owned elsewhere. The $ prefix creates a binding.",
        code: '<span class="cmt">// Parent owns the state</span>\n<span class="pw">@State</span> <span class="kw">var</span> text = <span class="str">"Hello"</span>\n<span class="ty">TextField</span>(<span class="str">"Edit"</span>, text: <span class="kw">$</span>text)\n\n<span class="cmt">// Child receives a binding</span>\n<span class="pw">@Binding</span> <span class="kw">var</span> width: <span class="ty">Double</span>',
    },
    {
        cat: "swiftui",
        title: "@Bindable",
        desc: "Creates bindings to @Observable properties. With @Environment, you first create @Bindable var x = x, then $x.prop gives you a Binding. Required because @Environment doesn't project bindings directly.",
        code: '<span class="kw">var</span> body: <span class="kw">some</span> <span class="ty">View</span> {\n    <span class="pw">@Bindable</span> <span class="kw">var</span> settings = appState.settings\n    <span class="ty">TextField</span>(<span class="str">"Path"</span>, text: <span class="kw">$</span>settings.folderPath)\n}',
    },
    {
        cat: "swiftui",
        title: "@Environment + @Observable",
        desc: "Reads an @Observable object injected by an ancestor view via .environment().",
        code: '<span class="cmt">// Inject in parent:</span>\n<span class="ty">MainView</span>()\n    .environment(appState)\n\n<span class="cmt">// Read in any descendant:</span>\n<span class="pw">@Environment</span>(<span class="ty">AppState</span>.<span class="kw">self</span>) <span class="kw">var</span> appState',
    },
    {
        cat: "swiftui",
        title: "@ObservationIgnored",
        desc: "Excludes a property from @Observable tracking. Use it for internal state (watchers, timers, flags) that shouldn't trigger view re-renders.",
        code: '<span class="pw">@Observable</span>\n<span class="kw">final class</span> <span class="ty">EditorState</span> {\n    <span class="kw">var</span> editorContent: <span class="ty">String</span> = <span class="str">""</span>  <span class="cmt">// tracked</span>\n    <span class="pw">@ObservationIgnored</span> <span class="kw">private var</span> fileWatcher: <span class="ty">FileWatcher</span>?  <span class="cmt">// not tracked</span>\n}',
    },
    {
        cat: "swiftui",
        title: "View Modifiers",
        desc: "Methods chained onto views to modify appearance or behavior. Each modifier returns a new view wrapping the original.",
        code: '<span class="ty">SidebarView</span>()\n    .frame(width: <span class="ty">CGFloat</span>(appState.sidebarWidth))\n    .transition(.move(edge: .leading)\n        .combined(with: .opacity))',
    },
    {
        cat: "concurrency",
        title: "@MainActor",
        desc: "A global actor that ensures code runs on the main thread. Required for UI updates. Applied to entire classes or individual functions. In Swift 6 strict concurrency, the compiler enforces this at compile time.",
        code: '<span class="pw">@Observable</span>\n<span class="pw">@MainActor</span>\n<span class="kw">final class</span> <span class="ty">AppState</span> {\n    <span class="cmt">// All properties and methods here</span>\n    <span class="cmt">// are guaranteed to run on main thread</span>\n}',
    },
    {
        cat: "concurrency",
        title: "Task { @MainActor in }",
        desc: "Creates an async task pinned to the main thread. Used to hop back to the main thread from a background context.",
        code: '<span class="ty">FileWatcher</span>(url: url) { [<span class="kw">weak self</span>] <span class="kw">in</span>\n    <span class="ty">Task</span> { <span class="pw">@MainActor</span> <span class="kw">in</span>\n        <span class="kw">self</span>?.loadFiles()\n    }\n}',
    },
    {
        cat: "concurrency",
        title: "DispatchQueue",
        desc: "GCD (Grand Central Dispatch) queues for scheduling work. .main is the UI thread, .global() is for background work.",
        code: '<span class="ty">DispatchQueue</span>.main.asyncAfter(\n    deadline: .now() + <span class="num">0.5</span>\n) { [<span class="kw">weak self</span>] <span class="kw">in</span>\n    <span class="kw">self</span>?.saveContent()\n}',
    },
    {
        cat: "concurrency",
        title: "Timer.scheduledTimer",
        desc: "Creates a repeating timer on the current run loop. Used for the focus timer's 1-second ticks.",
        code: 'timer = <span class="ty">Timer</span>.scheduledTimer(\n    withTimeInterval: <span class="num">1.0</span>,\n    repeats: <span class="kw">true</span>\n) { [<span class="kw">weak self</span>] _ <span class="kw">in</span>\n    <span class="ty">Task</span> { <span class="pw">@MainActor</span> <span class="kw">in</span>\n        <span class="kw">self</span>?.elapsed = ...\n    }\n}',
    },
    {
        cat: "concurrency",
        title: "nonisolated",
        desc: "Opts a method out of its class's actor isolation. Useful for pure functions that don't access mutable state, so they can be called from any context without await.",
        code: '<span class="pw">@MainActor</span>\n<span class="kw">final class</span> <span class="ty">TimerService</span> {\n    <span class="cmt">// Can be called from anywhere, no await needed</span>\n    <span class="kw">nonisolated static func</span> formatTime(\n        _ seconds: <span class="ty">TimeInterval</span>\n    ) -> <span class="ty">String</span> { ... }\n}',
    },
    {
        cat: "patterns",
        title: "guard let (early return)",
        desc: "Ensures a condition is met before proceeding. The else clause must exit the scope. Keeps code flat by handling failures first.",
        code: '<span class="kw">func</span> saveFileContent() {\n    <span class="kw">guard let</span> file = selectedFile <span class="kw">else</span> { <span class="kw">return</span> }\n    <span class="cmt">// file is now safely unwrapped here</span>\n    <span class="cmt">// no nesting needed!</span>\n}',
    },
    {
        cat: "patterns",
        title: "if let (optional binding)",
        desc: "Safely unwraps an optional. The bound variable is only available inside the if block.",
        code: '<span class="kw">if let</span> content = <span class="kw">try</span>? <span class="ty">String</span>(contentsOf: file.url) {\n    editorContent = content\n}\n<span class="cmt">// content is not available here</span>',
    },
    {
        cat: "patterns",
        title: "Optional chaining (?)",
        desc: "Safely accesses properties/methods on an optional. If any link in the chain is nil, the whole expression returns nil.",
        code: '<span class="kw">let</span> name = file?.url.lastPathComponent\n<span class="cmt">// type is String? (optional)</span>\n<span class="cmt">// if file is nil, name is nil (no crash)</span>',
    },
    {
        cat: "patterns",
        title: "Trailing closure syntax",
        desc: "When the last argument is a closure, it can be written after the parentheses. This makes DSL-like code possible.",
        code: '<span class="cmt">// Full syntax:</span>\ncontents.filter({ $0.pathExtension == <span class="str">"md"</span> })\n\n<span class="cmt">// Trailing closure (idiomatic):</span>\ncontents.filter { $0.pathExtension == <span class="str">"md"</span> }',
    },
    {
        cat: "patterns",
        title: "$ prefix (Binding projection)",
        desc: 'The $ prefix on a property wrapper accesses its "projected value". For @State, @Published, and @AppStorage, this creates a Binding for two-way data flow.',
        code: '<span class="cmt">// $appState.sidebarWidth is a Binding&lt;Double&gt;</span>\n<span class="ty">SidebarDivider</span>(width: <span class="kw">$</span>appState.sidebarWidth)\n\n<span class="cmt">// The divider can now read AND write the width</span>',
    },
];
