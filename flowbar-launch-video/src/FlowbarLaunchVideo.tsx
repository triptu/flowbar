import React from "react";
import {
  AbsoluteFill,
  useVideoConfig,
  useCurrentFrame,
  interpolate,
  staticFile,
} from "remotion";
import { Audio } from "@remotion/media";
import { TransitionSeries, springTiming } from "@remotion/transitions";

import { ProblemScene } from "./scenes/ProblemScene";
import { RevealScene } from "./scenes/RevealScene";
import { FeatureTourScene } from "./scenes/FeatureTourScene";
import { ClosingScene } from "./scenes/ClosingScene";
import { AmbientBackground, FilmGrain } from "./components/AmbientBackground";
import { scaleBlur } from "./transitions/scaleBlur";
import { THEME } from "./theme";

/**
 * Flowbar Launch Video — ~32 seconds. Breathes. Every frame earns its place.
 *
 * ACT 1: Problem (text)          0:00 – 0:05   = 150 frames
 * ACT 2: Reveal (hero shot)      0:05 – 0:11   = 180 frames  (video: 5.9s)
 * ACT 3: Feature Tour (1 clip)   0:11 – 0:27   = 480 frames  (video: 15.6s)
 * ACT 4: Closing card            0:27 – 0:33   = 180 frames
 *
 * Background: Nature loop runs GLOBALLY behind everything.
 * Scenes are transparent — product floats over nature.
 */
export const FlowbarLaunchVideo: React.FC = () => {
  const { fps, durationInFrames } = useVideoConfig();

  return (
    <AbsoluteFill style={{ backgroundColor: THEME.bg }}>
      {/* GLOBAL ambient background — constant, behind all scenes */}
      <AmbientBackground darken={0.15} />

      {/* Background music */}
      <Audio
        src={staticFile("audio.mp3")}
        volume={(f) => {
          const fadeIn = interpolate(f, [0, fps], [0, 0.5], {
            extrapolateRight: "clamp",
          });
          const fadeOut = interpolate(
            f,
            [durationInFrames - 2 * fps, durationInFrames],
            [0.5, 0],
            { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
          );
          return Math.min(fadeIn, fadeOut);
        }}
      />

      <TransitionSeries>
        {/* ACT 1: The Problem — 5s */}
        <TransitionSeries.Sequence durationInFrames={5 * fps}>
          <ProblemScene />
        </TransitionSeries.Sequence>

        <TransitionSeries.Transition
          presentation={scaleBlur()}
          timing={springTiming({ config: { damping: 18, stiffness: 120 } })}
        />

        {/* ACT 2: The Reveal — 6s (video is 5.9s) */}
        <TransitionSeries.Sequence durationInFrames={6 * fps}>
          <RevealScene />
        </TransitionSeries.Sequence>

        <TransitionSeries.Transition
          presentation={scaleBlur()}
          timing={springTiming({ config: { damping: 18, stiffness: 120 } })}
        />

        {/* ACT 3: Feature Tour — 16s (video is 15.6s) */}
        <TransitionSeries.Sequence durationInFrames={16 * fps}>
          <FeatureTourScene />
        </TransitionSeries.Sequence>

        <TransitionSeries.Transition
          presentation={scaleBlur()}
          timing={springTiming({ config: { damping: 18, stiffness: 120 } })}
        />

        {/* ACT 4: The Closer — 5s */}
        <TransitionSeries.Sequence durationInFrames={5 * fps}>
          <ClosingScene />
        </TransitionSeries.Sequence>
      </TransitionSeries>

      {/* Film grain — constant subtle texture */}
      <FilmGrain opacity={0.035} />
    </AbsoluteFill>
  );
};
