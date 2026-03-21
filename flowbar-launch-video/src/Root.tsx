import React from "react";
import { Composition } from "remotion";
import { FlowbarLaunchVideo } from "./FlowbarLaunchVideo";

const FPS = 30;
// 5+6+16+5 = 32s gross. springTiming transitions (~15 frames each, 3 transitions = ~45 frames). Trim 2s from end.
const DURATION_FRAMES = (5 + 6 + 16 + 5) * FPS - 45 - 60;

export const RemotionRoot: React.FC = () => {
  return (
    <Composition
      id="FlowbarLaunchVideo"
      component={FlowbarLaunchVideo}
      durationInFrames={DURATION_FRAMES}
      fps={FPS}
      width={1920}
      height={1080}
    />
  );
};
