import { h } from "preact";

const navLinks = [
    { label: "Getting Started", href: "#getting-started" },
    { label: "Architecture", href: "#architecture" },
    { label: "Explorer", href: "#explorer" },
    { label: "Concepts", href: "#concepts" },
    { label: "Data Flow", href: "#dataflow" },
];

export function Nav() {
    return (
        <nav class="fixed top-0 left-0 right-0 z-50 h-[52px] flex items-center backdrop-blur-md bg-bg/80 border-b border-border">
            <div class="max-w-[1200px] w-full mx-auto px-6 flex items-center justify-between">
                <a href="./index.html" class="flex items-center gap-2 no-underline">
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-5 h-5 text-sage">
                        <path fill-rule="evenodd" clip-rule="evenodd" d="M12 2.5C7 2.5 2.5 7 2.5 12C2.5 17 7 21.5 12 21.5C17 21.5 21.5 17 21.5 12C21.5 7 17 2.5 12 2.5ZM3.8 11.2Q7 8.8 10.5 10.8Q12 11.8 13.5 12.2Q17 13 20.2 10.8L20.2 12.8Q17 15 13.5 14.2Q12 13.8 10.5 12.8Q7 10.8 3.8 13.2Z" />
                    </svg>
                    <span class="font-heading text-[22px] text-sage">Flowbar</span>
                </a>
                <div class="flex items-center gap-6">
                    {navLinks.map((link) => (
                        <a
                            key={link.label}
                            href={link.href}
                            class="text-text-dim text-[13px] font-medium hover:text-sage transition-colors no-underline"
                        >
                            {link.label}
                        </a>
                    ))}
                </div>
            </div>
        </nav>
    );
}
