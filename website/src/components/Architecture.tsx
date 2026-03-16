import { h } from "preact";
import { useState } from "preact/hooks";
import { EDGES, NODE_TOOLTIPS, FILE_MAP } from "../data/architecture";

interface Props {
    onSelectFile?: (path: string) => void;
}

// Collect all nodes connected to a given node via shared edges
function getConnectedNodes(name: string): string[] {
    const edgeIds = EDGES[name] || [];
    const connected: string[] = [];
    for (const [node, edges] of Object.entries(EDGES)) {
        if (node === name) continue;
        if (edges.some((e) => edgeIds.includes(e))) {
            connected.push(node);
        }
    }
    return connected;
}

export function Architecture({ onSelectFile }: Props) {
    const [hoveredNode, setHoveredNode] = useState<string | null>(null);
    const [tooltipPos, setTooltipPos] = useState<{ x: number; y: number }>({ x: 0, y: 0 });

    const highlightedEdges = hoveredNode ? EDGES[hoveredNode] || [] : [];
    const connectedNodes = hoveredNode ? getConnectedNodes(hoveredNode) : [];

    function hoverNode(name: string, e: MouseEvent) {
        setHoveredNode(name);
        setTooltipPos({ x: e.clientX + 14, y: e.clientY - 10 });
    }

    function unhoverNode() {
        setHoveredNode(null);
    }

    function clickNode(name: string) {
        if (FILE_MAP[name] && onSelectFile) {
            onSelectFile(FILE_MAP[name]);
            const el = document.getElementById("explorer");
            if (el) el.scrollIntoView({ behavior: "smooth" });
        }
    }

    function nodeFilter(name: string): string | undefined {
        if (!hoveredNode) return undefined;
        if (name === hoveredNode) return "brightness(1.3) drop-shadow(0 0 6px #8B9A6B)";
        if (connectedNodes.includes(name)) return "brightness(1.15) drop-shadow(0 0 4px #8B9A6B88)";
        return undefined;
    }

    function edgeStroke(id: string, defaultStroke: string): string {
        if (highlightedEdges.includes(id)) return "#8B9A6B";
        return defaultStroke;
    }

    function edgeOpacity(id: string): number | undefined {
        if (highlightedEdges.includes(id)) return 1;
        return undefined;
    }

    function edgeMarker(id: string): string {
        if (highlightedEdges.includes(id)) return "url(#arrowhead-hl)";
        return "url(#arrowhead)";
    }

    function nodeHandlers(name: string) {
        return {
            onMouseEnter: (e: MouseEvent) => hoverNode(name, e),
            onMouseLeave: unhoverNode,
            onClick: () => clickNode(name),
            style: { cursor: FILE_MAP[name] ? "pointer" : "default" },
        };
    }

    return (
        <section id="architecture" class="py-[100px] px-12 max-w-[1280px] mx-auto">
            <h2 class="font-heading text-4xl font-normal text-text mb-6">
                <span class="text-sage">Architecture</span>
            </h2>

            {/* Why it's built this way */}
            <div class="bg-bg-card border border-border rounded-xl p-5 mb-5">
                <p class="text-[13px] text-text-dim leading-[1.7] mb-2">
                    <span class="font-bold text-text">AppDelegate, not pure SwiftUI</span> — SwiftUI can't do menu bar icons, floating overlay panels, or global hotkeys. That needs AppKit.
                </p>
                <p class="text-[13px] text-text-dim leading-[1.7] mb-2">
                    <span class="font-bold text-text">SQLite, not Core Data or flat files</span> — Timer sessions need real queries. Core Data is too heavy for one table. JSON files can't do{" "}
                    <code class="font-mono text-[11.5px] bg-bg-code px-1 rounded text-sage">GROUP BY</code> +{" "}
                    <code class="font-mono text-[11.5px] bg-bg-code px-1 rounded text-sage">SUM</code>.
                </p>
                <p class="text-[13px] text-text-dim leading-[1.7] mb-2">
                    <span class="font-bold text-text">@Observable + split state</span> — AppState coordinates three sub-states:{" "}
                    <code class="font-mono text-[11.5px] bg-bg-code px-1 rounded text-sage">SettingsState</code>,{" "}
                    <code class="font-mono text-[11.5px] bg-bg-code px-1 rounded text-sage">SidebarState</code>,{" "}
                    <code class="font-mono text-[11.5px] bg-bg-code px-1 rounded text-sage">EditorState</code>. Cross-cutting methods like{" "}
                    <code class="font-mono text-[11.5px] bg-bg-code px-1 rounded text-sage">selectFile</code> live on AppState.
                </p>
                <p class="text-[13px] text-text-dim leading-[1.7] mb-2">
                    <span class="font-bold text-text">GCD file watchers, not polling</span> — DispatchSource watches the filesystem instead of checking on a timer.
                </p>
            </div>

            {/* SVG Architecture Diagram */}
            <div class="bg-bg-card border border-border rounded-2xl p-8 mt-6 overflow-x-auto">
                <svg id="archSvg" width="1100" height="620" viewBox="0 0 1100 620">
                    <defs>
                        <marker id="arrowhead" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
                            <polygon points="0 0, 8 3, 0 6" fill="#8B9A6B88" />
                        </marker>
                        <marker id="arrowhead-hl" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
                            <polygon points="0 0, 8 3, 0 6" fill="#8B9A6B" />
                        </marker>
                    </defs>

                    {/* Edges */}
                    {/* AppDelegate -> AppState */}
                    <path id="e-ad-as" d="M200,80 C200,120 300,120 340,160" fill="none" stroke={edgeStroke("e-ad-as", "#8B9A6B44")} stroke-width="1.5" stroke-opacity={edgeOpacity("e-ad-as")} marker-end={edgeMarker("e-ad-as")} />
                    <text x="238" y="115" text-anchor="middle" font-size="9" fill="#8B9A6B88">creates</text>

                    {/* AppDelegate -> TimerService */}
                    <path id="e-ad-ts" d="M200,80 C200,130 560,100 600,160" fill="none" stroke={edgeStroke("e-ad-ts", "#8B9A6B44")} stroke-width="1.5" stroke-opacity={edgeOpacity("e-ad-ts")} marker-end={edgeMarker("e-ad-ts")} />
                    <text x="400" y="105" text-anchor="middle" font-size="9" fill="#8B9A6B88">creates</text>

                    {/* AppDelegate -> WindowManager */}
                    <path id="e-ad-pm" d="M200,80 C200,130 830,100 870,160" fill="none" stroke={edgeStroke("e-ad-pm", "#8B9A6B44")} stroke-width="1.5" stroke-opacity={edgeOpacity("e-ad-pm")} marker-end={edgeMarker("e-ad-pm")} />
                    <text x="530" y="88" text-anchor="middle" font-size="9" fill="#8B9A6B88">creates</text>

                    {/* WindowManager -> FloatingPanel */}
                    <path id="e-pm-fp" d="M890,210 C890,250 890,260 890,280" fill="none" stroke={edgeStroke("e-pm-fp", "#b088d444")} stroke-width="1.5" stroke-opacity={edgeOpacity("e-pm-fp")} marker-end={edgeMarker("e-pm-fp")} />
                    <text x="898" y="252" text-anchor="middle" font-size="9" fill="#8B9A6B88">manages</text>

                    {/* AppState -> NoteFile[] */}
                    <path id="e-as-nf" d="M340,210 L240,280" fill="none" stroke={edgeStroke("e-as-nf", "#d4a57444")} stroke-width="1.5" stroke-opacity={edgeOpacity("e-as-nf")} marker-end={edgeMarker("e-as-nf")} />
                    <text x="268" y="248" text-anchor="middle" font-size="9" fill="#8B9A6B88">owns</text>

                    {/* AppState -> FileWatcher */}
                    <path id="e-as-fw" d="M420,210 L440,280" fill="none" stroke={edgeStroke("e-as-fw", "#d4a57444")} stroke-width="1.5" stroke-opacity={edgeOpacity("e-as-fw")} marker-end={edgeMarker("e-as-fw")} />
                    <text x="410" y="248" text-anchor="middle" font-size="9" fill="#8B9A6B88">owns</text>

                    {/* TimerService -> DatabaseService */}
                    <path id="e-ts-db" d="M620,210 L620,280" fill="none" stroke={edgeStroke("e-ts-db", "#7eb8c944")} stroke-width="1.5" stroke-opacity={edgeOpacity("e-ts-db")} marker-end={edgeMarker("e-ts-db")} />
                    <text x="628" y="248" text-anchor="middle" font-size="9" fill="#8B9A6B88">uses</text>

                    {/* MainView -> AppState */}
                    <path id="e-mv-as" d="M200,420 C200,360 340,320 380,210" fill="none" stroke={edgeStroke("e-mv-as", "#8B9A6B22")} stroke-width="1.5" stroke-opacity={edgeOpacity("e-mv-as")} marker-end={edgeMarker("e-mv-as")} />
                    <text x="260" y="340" text-anchor="middle" font-size="9" fill="#8B9A6B88">reads</text>

                    {/* MainView -> WindowManager */}
                    <path id="e-mv-pm" d="M260,410 C400,360 800,300 880,210" fill="none" stroke={edgeStroke("e-mv-pm", "#8B9A6B22")} stroke-width="1.5" stroke-opacity={edgeOpacity("e-mv-pm")} marker-end={edgeMarker("e-mv-pm")} />

                    {/* MainView -> children */}
                    <path id="e-mv-sb" d="M140,460 L60,510" fill="none" stroke={edgeStroke("e-mv-sb", "#c4b46e44")} stroke-width="1.5" stroke-opacity={edgeOpacity("e-mv-sb")} marker-end={edgeMarker("e-mv-sb")} />
                    <path id="e-mv-nc" d="M180,460 L180,510" fill="none" stroke={edgeStroke("e-mv-nc", "#c4b46e44")} stroke-width="1.5" stroke-opacity={edgeOpacity("e-mv-nc")} marker-end={edgeMarker("e-mv-nc")} />
                    <path id="e-mv-sv" d="M220,460 L300,510" fill="none" stroke={edgeStroke("e-mv-sv", "#c4b46e44")} stroke-width="1.5" stroke-opacity={edgeOpacity("e-mv-sv")} marker-end={edgeMarker("e-mv-sv")} />
                    <path id="e-mv-tc" d="M260,460 L440,510" fill="none" stroke={edgeStroke("e-mv-tc", "#c4b46e44")} stroke-width="1.5" stroke-opacity={edgeOpacity("e-mv-tc")} marker-end={edgeMarker("e-mv-tc")} />

                    {/* TimerContainerView -> children */}
                    <path id="e-tc-th" d="M420,560 L380,590" fill="none" stroke={edgeStroke("e-tc-th", "#c4b46e44")} stroke-width="1.5" stroke-opacity={edgeOpacity("e-tc-th")} marker-end={edgeMarker("e-tc-th")} />
                    <path id="e-tc-tt" d="M480,560 L540,590" fill="none" stroke={edgeStroke("e-tc-tt", "#c4b46e44")} stroke-width="1.5" stroke-opacity={edgeOpacity("e-tc-tt")} marker-end={edgeMarker("e-tc-tt")} />

                    {/* TimerTodosView -> TodoRow */}
                    <path id="e-tt-tr" d="M580,590 C620,590 680,585 700,590" fill="none" stroke={edgeStroke("e-tt-tr", "#c4b46e44")} stroke-width="1.5" stroke-opacity={edgeOpacity("e-tt-tr")} marker-end={edgeMarker("e-tt-tr")} />

                    {/* MarkdownParser -> usage */}
                    <path id="e-mp-tt" d="M900,540 C780,560 640,580 580,590" fill="none" stroke={edgeStroke("e-mp-tt", "#d4a57422")} stroke-width="1.5" stroke-opacity={edgeOpacity("e-mp-tt")} marker-end={edgeMarker("e-mp-tt")} />
                    <text x="740" y="555" text-anchor="middle" font-size="9" fill="#8B9A6B88">used by</text>
                    <path id="e-mp-th" d="M880,540 C700,560 440,585 400,595" fill="none" stroke={edgeStroke("e-mp-th", "#d4a57422")} stroke-width="1.5" stroke-opacity={edgeOpacity("e-mp-th")} marker-end={edgeMarker("e-mp-th")} />

                    {/* Nodes */}
                    {/* AppDelegate */}
                    <g data-node="AppDelegate" {...nodeHandlers("AppDelegate")} filter={nodeFilter("AppDelegate")}>
                        <rect x="100" y="40" width="200" height="42" rx="6" fill="#2a2e26" stroke="#8B9A6B" stroke-width="1.5" />
                        <text x="200" y="66" text-anchor="middle" font-size="12" font-weight="600" fill="#e8e4dc">AppDelegate</text>
                    </g>

                    {/* AppState */}
                    <g data-node="AppState" {...nodeHandlers("AppState")} filter={nodeFilter("AppState")}>
                        <rect x="280" y="160" width="200" height="50" rx="6" fill="#2a2e26" stroke="#d4a574" stroke-width="1.5" />
                        <text x="380" y="182" text-anchor="middle" font-size="12" font-weight="600" fill="#e8e4dc">AppState</text>
                        <text x="380" y="198" text-anchor="middle" font-size="9" fill="#a09d94">@Observable</text>
                    </g>

                    {/* TimerService */}
                    <g data-node="TimerService" {...nodeHandlers("TimerService")} filter={nodeFilter("TimerService")}>
                        <rect x="540" y="160" width="180" height="50" rx="6" fill="#2a2e26" stroke="#7eb8c9" stroke-width="1.5" />
                        <text x="630" y="182" text-anchor="middle" font-size="12" font-weight="600" fill="#e8e4dc">TimerService</text>
                        <text x="630" y="198" text-anchor="middle" font-size="9" fill="#a09d94">@Observable</text>
                    </g>

                    {/* WindowManager */}
                    <g data-node="WindowManager" {...nodeHandlers("WindowManager")} filter={nodeFilter("WindowManager")}>
                        <rect x="790" y="160" width="200" height="50" rx="6" fill="#2a2e26" stroke="#b088d4" stroke-width="1.5" />
                        <text x="890" y="182" text-anchor="middle" font-size="12" font-weight="600" fill="#e8e4dc">WindowManager</text>
                        <text x="890" y="198" text-anchor="middle" font-size="9" fill="#a09d94">NSObject, @Observable</text>
                    </g>

                    {/* NoteFile[] */}
                    <g data-node="NoteFile" {...nodeHandlers("NoteFile")} filter={nodeFilter("NoteFile")}>
                        <rect x="160" y="280" width="140" height="36" rx="6" fill="#22261f" stroke="#d4a57488" stroke-width="1.5" />
                        <text x="230" y="303" text-anchor="middle" font-size="11" fill="#e8e4dc">NoteFile[]</text>
                    </g>

                    {/* FileWatcher */}
                    <g data-node="FileWatcher" {...nodeHandlers("FileWatcher")} filter={nodeFilter("FileWatcher")}>
                        <rect x="370" y="280" width="140" height="36" rx="6" fill="#22261f" stroke="#d4a57488" stroke-width="1.5" />
                        <text x="440" y="303" text-anchor="middle" font-size="11" fill="#e8e4dc">FileWatcher</text>
                    </g>

                    {/* DatabaseService */}
                    <g data-node="DatabaseService" {...nodeHandlers("DatabaseService")} filter={nodeFilter("DatabaseService")}>
                        <rect x="550" y="280" width="160" height="36" rx="6" fill="#22261f" stroke="#7eb8c988" stroke-width="1.5" />
                        <text x="630" y="303" text-anchor="middle" font-size="11" fill="#e8e4dc">DatabaseService</text>
                    </g>

                    {/* FloatingPanel */}
                    <g data-node="FloatingPanel" {...nodeHandlers("FloatingPanel")} filter={nodeFilter("FloatingPanel")}>
                        <rect x="820" y="280" width="140" height="36" rx="6" fill="#22261f" stroke="#b088d488" stroke-width="1.5" />
                        <text x="890" y="303" text-anchor="middle" font-size="11" fill="#e8e4dc">FloatingPanel</text>
                    </g>

                    {/* MainView */}
                    <g data-node="MainView" {...nodeHandlers("MainView")} filter={nodeFilter("MainView")}>
                        <rect x="100" y="410" width="200" height="50" rx="6" fill="#2a2e26" stroke="#c4b46e" stroke-width="1.5" />
                        <text x="200" y="432" text-anchor="middle" font-size="12" font-weight="600" fill="#e8e4dc">MainView</text>
                        <text x="200" y="448" text-anchor="middle" font-size="9" fill="#a09d94">SwiftUI View</text>
                    </g>

                    {/* SidebarView */}
                    <g data-node="SidebarView" {...nodeHandlers("SidebarView")} filter={nodeFilter("SidebarView")}>
                        <rect x="10" y="510" width="120" height="32" rx="6" fill="#22261f" stroke="#c4b46e88" stroke-width="1.5" />
                        <text x="70" y="530" text-anchor="middle" font-size="10" fill="#e8e4dc">SidebarView</text>
                    </g>

                    {/* NoteContentView */}
                    <g data-node="NoteContentView" {...nodeHandlers("NoteContentView")} filter={nodeFilter("NoteContentView")}>
                        <rect x="120" y="510" width="140" height="32" rx="6" fill="#22261f" stroke="#c4b46e88" stroke-width="1.5" />
                        <text x="190" y="530" text-anchor="middle" font-size="10" fill="#e8e4dc">NoteContentView</text>
                    </g>

                    {/* SettingsView */}
                    <g data-node="SettingsView" {...nodeHandlers("SettingsView")} filter={nodeFilter("SettingsView")}>
                        <rect x="250" y="510" width="120" height="32" rx="6" fill="#22261f" stroke="#c4b46e88" stroke-width="1.5" />
                        <text x="310" y="530" text-anchor="middle" font-size="10" fill="#e8e4dc">SettingsView</text>
                    </g>

                    {/* TimerContainerView */}
                    <g data-node="TimerContainerView" {...nodeHandlers("TimerContainerView")} filter={nodeFilter("TimerContainerView")}>
                        <rect x="380" y="510" width="160" height="50" rx="6" fill="#22261f" stroke="#c4b46e88" stroke-width="1.5" />
                        <text x="460" y="530" text-anchor="middle" font-size="10" fill="#e8e4dc">TimerContainerView</text>
                        <text x="460" y="545" text-anchor="middle" font-size="8" fill="#a09d94">SwiftUI View</text>
                    </g>

                    {/* TimerHomeView */}
                    <g data-node="TimerHomeView" {...nodeHandlers("TimerHomeView")} filter={nodeFilter("TimerHomeView")}>
                        <rect x="320" y="585" width="130" height="28" rx="6" fill="#1e221c" stroke="#c4b46e55" stroke-width="1.5" />
                        <text x="385" y="603" text-anchor="middle" font-size="9" fill="#e8e4dc">TimerHomeView</text>
                    </g>

                    {/* TimerTodosView */}
                    <g data-node="TimerTodosView" {...nodeHandlers("TimerTodosView")} filter={nodeFilter("TimerTodosView")}>
                        <rect x="480" y="585" width="130" height="28" rx="6" fill="#1e221c" stroke="#c4b46e55" stroke-width="1.5" />
                        <text x="545" y="603" text-anchor="middle" font-size="9" fill="#e8e4dc">TimerTodosView</text>
                    </g>

                    {/* TodoRow */}
                    <g data-node="TodoRow" {...nodeHandlers("TodoRow")} filter={nodeFilter("TodoRow")}>
                        <rect x="640" y="585" width="100" height="28" rx="6" fill="#1e221c" stroke="#c4b46e55" stroke-width="1.5" />
                        <text x="690" y="603" text-anchor="middle" font-size="9" fill="#e8e4dc">TodoRow</text>
                    </g>

                    {/* MarkdownParser */}
                    <g data-node="MarkdownParser" {...nodeHandlers("MarkdownParser")} filter={nodeFilter("MarkdownParser")}>
                        <rect x="830" y="510" width="160" height="36" rx="6" fill="#22261f" stroke="#d4a57488" stroke-width="1.5" />
                        <text x="910" y="533" text-anchor="middle" font-size="11" fill="#e8e4dc">MarkdownParser</text>
                    </g>
                </svg>

                {/* Legend */}
                <div class="flex items-center gap-6 mt-5 text-xs text-text-dim flex-wrap">
                    <span class="flex items-center gap-1.5">
                        <span class="inline-block w-3 h-3 rounded-sm" style={{ background: "#8B9A6B" }} />
                        App Core
                    </span>
                    <span class="flex items-center gap-1.5">
                        <span class="inline-block w-3 h-3 rounded-sm" style={{ background: "#d4a574" }} />
                        Models / Data
                    </span>
                    <span class="flex items-center gap-1.5">
                        <span class="inline-block w-3 h-3 rounded-sm" style={{ background: "#7eb8c9" }} />
                        Services
                    </span>
                    <span class="flex items-center gap-1.5">
                        <span class="inline-block w-3 h-3 rounded-sm" style={{ background: "#b088d4" }} />
                        Window Management
                    </span>
                    <span class="flex items-center gap-1.5">
                        <span class="inline-block w-3 h-3 rounded-sm" style={{ background: "#c4b46e" }} />
                        Views
                    </span>
                </div>
            </div>

            {/* Tooltip */}
            {hoveredNode && NODE_TOOLTIPS[hoveredNode] && (
                <div
                    class="fixed z-[2000] bg-bg-card border border-sage-dim rounded-[10px] p-3 px-4 max-w-[300px] shadow-[0_8px_30px_#00000088] pointer-events-none animate-pop-in"
                    style={{ left: tooltipPos.x, top: tooltipPos.y }}
                >
                    <div class="font-mono text-xs text-sage mb-1">{hoveredNode}</div>
                    <div class="text-xs text-text-dim leading-[1.5]">{NODE_TOOLTIPS[hoveredNode]}</div>
                    {FILE_MAP[hoveredNode] && (
                        <div class="text-[10px] text-text-muted mt-1.5 italic">Click to view source code</div>
                    )}
                </div>
            )}
        </section>
    );
}
