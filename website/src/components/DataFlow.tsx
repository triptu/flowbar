interface FlowStep {
    label: string;
    desc: preact.ComponentChildren;
}

function FlowCard({ title, steps }: { title: string; steps: FlowStep[] }) {
    return (
        <div class="bg-bg-card border border-border rounded-2xl p-7">
            <h3 class="font-heading text-2xl font-normal text-sage mb-5">{title}</h3>
            {steps.map((step, i) => (
                <div class="flex items-start gap-4 relative" key={i}>
                    <div class="w-2.5 h-2.5 rounded-full bg-sage mt-1.5 shrink-0 relative z-[1]" />
                    {i < steps.length - 1 && (
                        <div class="absolute left-[4px] top-4 w-0.5 h-[calc(100%+4px)] bg-border" />
                    )}
                    <div class="flex-1 pb-5">
                        <div class="font-mono text-xs text-sage mb-0.5">{step.label}</div>
                        <div class="text-[13px] text-text-dim leading-[1.5]">{step.desc}</div>
                    </div>
                </div>
            ))}
        </div>
    );
}

const C = ({ children }: { children: string }) => (
    <code class="font-mono text-[11.5px] bg-bg-code px-1 rounded text-sage">{children}</code>
);

const noteSteps: FlowStep[] = [
    {
        label: "User clicks a file in SidebarView",
        desc: <>Calls <C>appState.selectFile(file)</C> on the coordinator.</>
    },
    {
        label: "AppState.selectFile()",
        desc: <>Sets <C>sidebar.activePanel = .file(file)</C>, then tells <C>editor.loadFileContent(file)</C> to read the file.</>
    },
    {
        label: "EditorState.loadFileContent()",
        desc: <>Reads the <C>.md</C> file from disk via <C>String(contentsOf:)</C>.</>
    },
    {
        label: "editorContent updates",
        desc: <>The <C>@Observable</C> macro detects the property change. SwiftUI re-renders only views that read <C>editorContent</C>.</>
    },
    {
        label: "NoteContentView re-renders",
        desc: <>If in edit mode, <C>MarkdownEditorView</C> shows the raw text. In preview mode, <C>MarkdownPreviewView</C> renders styled blocks with clickable checkboxes. Toggle with <C>Cmd+E</C>.</>
    }
];

const timerSteps: FlowStep[] = [
    {
        label: "User clicks play on a TodoRow",
        desc: <>Calls <C>timerService.start(todoText:, sourceFile:)</C>.</>
    },
    {
        label: "TimerService.start()",
        desc: <>Inserts a new session into SQLite via <C>DatabaseService.startSession()</C>.</>
    },
    {
        label: "Timer ticks every second",
        desc: <>A <C>Timer.scheduledTimer</C> fires, updating <C>elapsed</C> each tick.</>
    },
    {
        label: "elapsed property updates",
        desc: <>The <C>@Observable</C> macro tracks access — only views reading <C>timerService.elapsed</C> re-render.</>
    },
    {
        label: "User clicks complete",
        desc: <><C>timerService.complete()</C> ends the DB session, returns the todo info.</>
    },
    {
        label: "MarkdownParser marks done",
        desc: <><C>MarkdownParser.markTodoDone()</C> toggles <C>- [ ]</C> to <C>- [x]</C> in the file.</>
    }
];

export default function DataFlow() {
    return (
        <section id="dataflow" class="py-[100px] px-12 max-w-[1280px] mx-auto">
            <h2 class="font-heading text-4xl font-normal text-text mb-6">
                <span class="text-sage">Data Flow</span> Diagrams
            </h2>
            <p class="text-[17px] text-text-dim max-w-[640px] leading-[1.8]">
                Follow the path of data through Flowbar — from user action to screen update — with no hidden magic.
            </p>
            <div class="grid md:grid-cols-2 grid-cols-1 gap-6 mt-6">
                <FlowCard title="How a Note Gets Loaded" steps={noteSteps} />
                <FlowCard title="How the Timer Works" steps={timerSteps} />
            </div>
        </section>
    );
}
