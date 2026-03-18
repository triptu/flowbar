import { h } from "preact";
import { useState, useEffect } from "preact/hooks";
import { FILES } from "../data/files";
import { ANNOTATIONS } from "../data/annotations";
import { highlightSwift } from "../lib/highlight";

interface FileExplorerProps {
  initialFile?: string;
  selectedFile?: string;
}

const FOLDER_ORDER = ["App", "Models", "Services", "Views", "Window"];

function buildFolderStructure(): Record<string, string[]> {
  const folders: Record<string, string[]> = {};
  for (const path of Object.keys(FILES)) {
    const slash = path.indexOf("/");
    const folder = slash !== -1 ? path.substring(0, slash) : "";
    if (!folders[folder]) folders[folder] = [];
    folders[folder].push(path);
  }
  return folders;
}

export function FileExplorer({
  initialFile = "App/FlowbarApp.swift",
  selectedFile,
}: FileExplorerProps) {
  const [activeFile, setActiveFile] = useState(initialFile);
  const [popup, setPopup] = useState<{ title: string; body: string; x: number; y: number } | null>(
    null,
  );
  useEffect(() => {
    if (selectedFile) setActiveFile(selectedFile);
  }, [selectedFile]);

  const folders = buildFolderStructure();

  function selectFile(path: string) {
    setActiveFile(path);
    setPopup(null);
  }

  function showAnnotation(e: MouseEvent, filePath: string, lineNum: number) {
    const anno = ANNOTATIONS[filePath]?.[lineNum];
    if (!anno) return;
    const rect = (e.target as HTMLElement).getBoundingClientRect();
    let left = rect.right + 12;
    let top = rect.top - 10;
    if (left + 400 > window.innerWidth) left = rect.left - 412;
    if (top + 200 > window.innerHeight) top = window.innerHeight - 220;
    if (top < 60) top = 60;
    setPopup({ title: anno.title, body: anno.body, x: left, y: top });
  }

  function renderCode(path: string) {
    const source = FILES[path];
    if (!source) return null;
    const lines = source.split("\n");
    const highlighted = highlightSwift(source);
    const highlightedLines = highlighted.split("\n");
    const fileAnnotations = ANNOTATIONS[path] || {};

    let annotationCounter = 0;
    const annotationNumbers: Record<number, number> = {};
    for (const lineNum of Object.keys(fileAnnotations)
      .map(Number)
      .sort((a, b) => a - b)) {
      annotationCounter++;
      annotationNumbers[lineNum] = annotationCounter;
    }

    return (
      <pre class="m-0 p-5 px-6 font-mono text-[13px] leading-[1.7] text-text tab-[2] relative overflow-x-auto">
        {highlightedLines.map((html, i) => {
          const lineNum = i + 1;
          const hasAnno = annotationNumbers[lineNum] != null;
          return (
            <div key={i} class="relative pl-12 min-h-[1.7em] whitespace-pre hover:bg-white/[0.02]">
              <span class="absolute left-0 w-9 text-right text-text-muted opacity-40 text-[13px] select-none">
                {lineNum}
              </span>
              <span dangerouslySetInnerHTML={{ __html: html }} />
              {hasAnno && (
                <span
                  class="inline-flex items-center justify-center w-[18px] h-[18px] rounded-full bg-sage text-bg text-[9px] font-bold font-body cursor-default ml-2 align-middle relative transition-transform hover:scale-[1.2] hover:shadow-[0_0_10px_var(--color-sage-dim)]"
                  onMouseEnter={(e) => showAnnotation(e as unknown as MouseEvent, path, lineNum)}
                  onMouseLeave={() => setPopup(null)}
                >
                  {annotationNumbers[lineNum]}
                </span>
              )}
            </div>
          );
        })}
      </pre>
    );
  }

  return (
    <section class="py-[100px] px-12 max-w-[1280px] mx-auto" id="explorer">
      <h2 class="font-heading text-4xl font-normal text-text mb-6">
        <span class="text-sage">File</span> Explorer
      </h2>
      <p class="text-[17px] text-text-dim max-w-[640px] leading-[1.8]">
        Browse the complete source code. Numbered markers highlight key Swift concepts — hover or
        click them for explanations.
      </p>

      <div class="flex bg-bg-card border border-border rounded-2xl overflow-hidden h-[680px] mt-6">
        {/* Sidebar */}
        <div class="w-60 min-w-[240px] bg-bg-sidebar border-r border-border overflow-y-auto py-4">
          {FOLDER_ORDER.map((folder) => {
            const files = folders[folder];
            if (!files) return null;
            return (
              <div key={folder}>
                <div class="text-[11px] font-semibold text-text-muted uppercase tracking-[1px] px-5 pt-3 pb-1.5">
                  {folder}
                </div>
                {files.map((path) => {
                  const fileName = path.substring(path.indexOf("/") + 1);
                  const isActive = path === activeFile;
                  return (
                    <div
                      key={path}
                      class={`py-[7px] px-5 pl-8 text-[13px] font-mono text-text-dim cursor-default transition-all border-l-2 border-transparent whitespace-nowrap hover:bg-sage-glow hover:text-text ${isActive ? "text-sage bg-sage-glow !border-l-sage" : ""}`}
                      onClick={() => selectFile(path)}
                    >
                      {fileName}
                    </div>
                  );
                })}
              </div>
            );
          })}
        </div>

        {/* Code area */}
        <div class="flex-1 overflow-auto relative cursor-default">
          <div class="sticky top-0 bg-bg-card border-b border-border py-2.5 px-6 font-mono text-xs text-text-muted z-[5]">
            {activeFile}
          </div>
          {renderCode(activeFile)}
        </div>
      </div>

      {/* Annotation popup */}
      {popup && (
        <div
          class="fixed z-[2000] bg-bg-card border border-sage-dim rounded-xl p-4 px-5 max-w-[400px] shadow-[0_12px_40px_#00000088] animate-pop-in pointer-events-none"
          style={{ left: `${popup.x}px`, top: `${popup.y}px` }}
        >
          <div class="font-mono text-[13px] text-sage mb-2">{popup.title}</div>
          <div
            class="text-[13px] text-text-dim leading-[1.7]"
            dangerouslySetInnerHTML={{ __html: popup.body }}
          />
        </div>
      )}
    </section>
  );
}
