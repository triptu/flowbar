import { useState } from "preact/hooks";
import { CONCEPTS, type ConceptCategory } from "../data/concepts";

const TABS: { label: string; value: ConceptCategory | "all" }[] = [
  { label: "All", value: "all" },
  { label: "Types", value: "types" },
  { label: "Memory", value: "memory" },
  { label: "SwiftUI", value: "swiftui" },
  { label: "Concurrency", value: "concurrency" },
  { label: "Patterns", value: "patterns" },
];

const TAG_COLORS: Record<ConceptCategory, string> = {
  types: "bg-orange text-bg",
  memory: "bg-red text-bg",
  swiftui: "bg-purple text-bg",
  concurrency: "bg-blue text-bg",
  patterns: "bg-sage text-bg",
};

export default function ConceptsReference() {
  const [active, setActive] = useState<ConceptCategory | "all">("all");

  const filtered = active === "all" ? CONCEPTS : CONCEPTS.filter((c) => c.cat === active);

  return (
    <section id="concepts" class="py-[100px] px-12 max-w-[1280px] mx-auto">
      <h2 class="font-heading text-4xl font-normal text-text mb-6">
        Swift <span class="text-sage">Concepts</span> Reference
      </h2>
      <p class="text-[17px] text-text-dim max-w-[640px] leading-[1.8] mb-5">
        Key Swift and SwiftUI concepts used throughout Flowbar, explained with real examples from
        the codebase.
      </p>

      <div class="flex gap-2.5 mb-5 flex-wrap">
        {TABS.map((tab) => (
          <button
            key={tab.value}
            onClick={() => setActive(tab.value)}
            class={`py-[7px] px-[18px] rounded-full text-[13px] font-medium cursor-default border transition-all ${
              active === tab.value
                ? "bg-sage text-bg border-sage"
                : "border-border text-text-dim hover:border-sage-dim hover:text-text bg-transparent"
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      <div class="grid grid-cols-[repeat(auto-fill,minmax(360px,1fr))] gap-5 mt-6">
        {filtered.map((concept) => (
          <div
            key={concept.title}
            class="bg-bg-card border border-border rounded-xl p-6 transition-colors hover:border-sage-dim"
          >
            <span
              class={`inline-block text-[10px] font-semibold uppercase tracking-[0.8px] px-2.5 py-[3px] rounded-full mb-3 ${TAG_COLORS[concept.cat]}`}
            >
              {concept.cat}
            </span>
            <h3 class="font-mono text-[15px] text-text mb-2">{concept.title}</h3>
            <p class="text-[13px] text-text-dim mb-3 leading-[1.6]">{concept.desc}</p>
            <pre
              class="bg-bg-code rounded-lg p-3 px-4 font-mono text-[11.5px] leading-[1.7] overflow-x-auto text-text"
              dangerouslySetInnerHTML={{ __html: concept.code }}
            />
          </div>
        ))}
      </div>
    </section>
  );
}
