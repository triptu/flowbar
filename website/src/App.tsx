import { useState } from "preact/hooks";
import { Nav } from "./components/Nav";
import { Hero } from "./components/Hero";
import { SectionDivider } from "./components/SectionDivider";
import { GettingStarted } from "./components/GettingStarted";
import { Architecture } from "./components/Architecture";
import { FileExplorer } from "./components/FileExplorer";
import ConceptsReference from "./components/ConceptsReference";

export function App() {
  const [selectedFile, setSelectedFile] = useState<string | undefined>();

  return (
    <>
      <Nav />
      <Hero />
      <SectionDivider />
      <GettingStarted />
      <SectionDivider />
      <Architecture onSelectFile={setSelectedFile} />
      <SectionDivider />
      <FileExplorer selectedFile={selectedFile} />
      <SectionDivider />
      <ConceptsReference />
      <SectionDivider />
      <div class="h-20" />
    </>
  );
}
