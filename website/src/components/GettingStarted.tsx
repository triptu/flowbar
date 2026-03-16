import { h, JSX, ComponentChildren } from "preact";

function Step({ n, children }: { n: number; children: JSX.Element | string }) {
    return (
        <div class="flex items-start gap-1 mb-1.5">
            <span class="inline-flex items-center justify-center w-[22px] h-[22px] rounded-full bg-sage text-bg text-[11px] font-bold mr-2 align-middle shrink-0 mt-0.5">
                {n}
            </span>
            <span class="text-[13px] text-text-dim leading-[1.7]">{children}</span>
        </div>
    );
}

function ExtLink({ href, children }: { href: string; children: string }) {
    return (
        <a
            href={href}
            target="_blank"
            rel="noopener"
            class="text-sage underline underline-offset-2 hover:text-[#9dae7d] transition-colors"
        >
            {children}
        </a>
    );
}

function Code({ children }: { children: ComponentChildren }) {
    return <code class="font-mono text-[11.5px] bg-bg-code px-1 rounded text-sage">{children}</code>;
}

function Card({ title, children }: { title: string; children: JSX.Element | JSX.Element[] }) {
    return (
        <div class="bg-bg-card border border-border rounded-xl p-6 hover:border-sage-dim transition-colors">
            <h3 class="font-mono text-[15px] text-sage mb-2">{title}</h3>
            {children}
        </div>
    );
}

function WhatToInstall() {
    return (
        <Card title="What to Install">
            <p class="text-[13px] text-text-dim leading-[1.7] mb-3">
                Everything starts with Xcode — Apple's IDE that includes the Swift compiler, simulators, and Interface Builder.
            </p>
            <Step n={1}>
                <span>
                    Install{" "}
                    <ExtLink href="https://apps.apple.com/us/app/xcode/id497799835">Xcode from the Mac App Store</ExtLink>
                    {" "}(free, ~12 GB)
                </span>
            </Step>
            <Step n={2}>
                <span>
                    Open Xcode once to install additional components
                </span>
            </Step>
            <Step n={3}>
                <span>
                    Install Command Line Tools: <Code>xcode-select --install</Code>
                </span>
            </Step>
        </Card>
    );
}

function EmptyFolderToApp() {
    return (
        <Card title="From Empty Folder to Running App">
            <p class="text-[13px] text-text-dim leading-[1.7] mb-3">
                Create your first macOS app in under a minute.
            </p>
            <Step n={1}>
                <span>Open Xcode {"\u2192"} File {"\u2192"} New {"\u2192"} Project</span>
            </Step>
            <Step n={2}>
                <span>Choose <strong class="text-text">macOS {"\u2192"} App</strong></span>
            </Step>
            <Step n={3}>
                <span>Pick a name, set language to <strong class="text-text">Swift</strong>, interface to <strong class="text-text">SwiftUI</strong></span>
            </Step>
            <Step n={4}>
                <span>Click <strong class="text-text">Run</strong> (or <Code>{"\u2318"}R</Code>) {"\u2014"} you have a working app</span>
            </Step>
        </Card>
    );
}

function WhatIsAppDelegate() {
    return (
        <Card title="What is AppDelegate?">
            <p class="text-[13px] text-text-dim leading-[1.7] mb-3">
                The <Code>AppDelegate</Code> is your app's entry point on macOS. The system calls it when your app launches, goes to background, or terminates.
            </p>
            <div class="flex items-center gap-2 flex-wrap my-4">
                <span class="px-3.5 py-1.5 rounded-md font-mono text-[11px] bg-sage-glow border border-sage-dim text-sage">macOS</span>
                <span class="text-text-muted text-sm">{"\u2192"}</span>
                <span class="px-3.5 py-1.5 rounded-md font-mono text-[11px] bg-bg-code border border-border text-orange">AppDelegate</span>
                <span class="text-text-muted text-sm">{"\u2192"}</span>
                <span class="px-3.5 py-1.5 rounded-md font-mono text-[11px] bg-bg-code border border-border text-orange">your setup code</span>
            </div>
            <p class="text-[13px] text-text-dim leading-[1.7]">
                Think of it as the "main()" of your macOS app {"\u2014"} the first code that runs when your app starts.
            </p>
        </Card>
    );
}

function SwiftUIVsAppDelegate() {
    return (
        <Card title="SwiftUI App vs AppDelegate">
            <p class="text-[13px] text-text-dim leading-[1.7] mb-3">
                Modern SwiftUI apps use <Code>@main struct MyApp: App</Code> as the entry point.
                But Flowbar uses <strong class="text-text">both</strong> {"\u2014"} an <Code>AppDelegate</Code> plus SwiftUI views.
            </p>
            <p class="text-[13px] text-text-dim leading-[1.7]">
                <strong class="text-text">Why?</strong> Menu bar apps need <Code>NSStatusBar</Code>, popover management, and
                global keyboard shortcuts {"\u2014"} all AppKit APIs that require an <Code>AppDelegate</Code>.
                SwiftUI handles the UI inside the popover.
            </p>
        </Card>
    );
}

function WhatsInAProject() {
    return (
        <Card title="What's in a Swift Project?">
            <p class="text-[13px] text-text-dim leading-[1.7] mb-3">
                A typical Xcode project contains these key files:
            </p>
            <ul class="space-y-2 text-[13px] text-text-dim leading-[1.7]">
                <li>
                    <Code>.xcodeproj</Code> {"\u2014"} The project file Xcode uses to track build settings, targets, and file references
                </li>
                <li>
                    <Code>.swift</Code> {"\u2014"} Your source files. Each file can contain structs, classes, enums, and functions
                </li>
                <li>
                    <Code>Info.plist</Code> {"\u2014"} App metadata: name, version, permissions, and capabilities
                </li>
                <li>
                    <Code>Assets.xcassets</Code> {"\u2014"} App icons, images, and color assets organized in a catalog
                </li>
            </ul>
        </Card>
    );
}

function QuickReferenceLinks() {
    return (
        <Card title="Quick Reference Links">
            <p class="text-[13px] text-text-dim leading-[1.7] mb-3">
                Bookmark these for your Swift journey:
            </p>
            <ul class="space-y-1.5 text-[13px] leading-[1.7]">
                <li>
                    <ExtLink href="https://docs.swift.org/swift-book/documentation/the-swift-programming-language/">
                        The Swift Programming Language (official book)
                    </ExtLink>
                </li>
                <li>
                    <ExtLink href="https://developer.apple.com/tutorials/develop-in-swift/">
                        Apple Swift Tutorials
                    </ExtLink>
                </li>
                <li>
                    <ExtLink href="https://developer.apple.com/tutorials/develop-in-swift/hello-swiftui">
                        Apple SwiftUI Tutorials
                    </ExtLink>
                </li>
                <li>
                    <ExtLink href="https://developer.apple.com/documentation/appkit">
                        AppKit Documentation
                    </ExtLink>
                </li>
                <li>
                    <ExtLink href="https://developer.apple.com/documentation/swiftui">
                        SwiftUI Framework Reference
                    </ExtLink>
                </li>
                <li>
                    <ExtLink href="https://www.hackingwithswift.com/100/swiftui">
                        100 Days of SwiftUI (free course)
                    </ExtLink>
                </li>
            </ul>
        </Card>
    );
}

export function GettingStarted() {
    return (
        <section id="getting-started" class="max-w-[1200px] mx-auto px-6 py-16">
            <h2 class="font-heading text-[36px] text-text mb-2">Getting Started</h2>
            <p class="text-text-dim text-[15px] mb-8 max-w-[600px]">
                Everything you need before diving into the Flowbar codebase.
            </p>
            <div class="grid grid-cols-[repeat(auto-fill,minmax(300px,1fr))] gap-5">
                <WhatToInstall />
                <EmptyFolderToApp />
                <WhatIsAppDelegate />
                <SwiftUIVsAppDelegate />
                <WhatsInAProject />
                <QuickReferenceLinks />
            </div>
        </section>
    );
}
