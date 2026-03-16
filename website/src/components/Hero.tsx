import { h } from "preact";

export function Hero() {
    return (
        <section class="min-h-[60vh] flex flex-col items-center justify-center text-center px-6 pt-[52px]">
            <span class="inline-block uppercase text-[11px] font-semibold tracking-[0.12em] text-sage border border-sage-dim bg-sage-glow px-3 py-1 rounded-full mb-6">
                Interactive Learning Guide
            </span>

            <h1 class="font-heading text-[56px] leading-[1.1] text-text mb-5">
                Learning Swift
                <br />
                through <em class="text-sage">Flowbar</em>
            </h1>

            <p class="text-text-dim text-[16px] leading-[1.7] max-w-[600px] mb-8">
                A hands-on guide to understanding Swift, SwiftUI, and macOS development
                by reading a real codebase — a menu bar app for Obsidian notes.
            </p>

            <div class="flex items-center gap-4">
                <a
                    href="#explorer"
                    class="inline-flex items-center px-5 py-2.5 rounded-lg bg-sage text-bg text-[14px] font-semibold no-underline hover:opacity-90 transition-opacity"
                >
                    Explore the Code
                </a>
                <a
                    href="#architecture"
                    class="inline-flex items-center px-5 py-2.5 rounded-lg border border-border text-text-dim text-[14px] font-semibold no-underline hover:border-sage-dim hover:text-sage transition-colors"
                >
                    See the Architecture
                </a>
            </div>
        </section>
    );
}
