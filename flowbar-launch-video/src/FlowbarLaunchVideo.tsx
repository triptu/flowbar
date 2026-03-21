import React from "react";
import {
  AbsoluteFill,
  useVideoConfig,
  useCurrentFrame,
  interpolate,
  staticFile,
} from "remotion";
import { Audio } from "@remotion/media";
import { TransitionSeries, linearTiming } from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";

import { ProblemScene } from "./scenes/ProblemScene";
import { RevealScene } from "./scenes/RevealScene";
import { FeatureTourScene } from "./scenes/FeatureTourScene";
import { ClosingScene } from "./scenes/ClosingScene";
import { AmbientBackground, FilmGrain } from "./components/AmbientBackground";
import { THEME } from "./theme";

export const FlowbarLaunchVideo: React.FC = () => {
  const { fps, durationInFrames } = useVideoConfig();

  return (
    <AbsoluteFill style={{ backgroundColor: THEME.bg }}>
      <AmbientBackground darken={0.15} />

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
        <TransitionSeries.Sequence durationInFrames={5 * fps}>
          <ProblemScene />
        </TransitionSeries.Sequence>

        <TransitionSeries.Transition
          presentation={fade()}
          timing={linearTiming({ durationInFrames: 15 })}
        />

        <TransitionSeries.Sequence durationInFrames={6 * fps}>
          <RevealScene />
        </TransitionSeries.Sequence>

        <TransitionSeries.Transition
          presentation={fade()}
          timing={linearTiming({ durationInFrames: 15 })}
        />

        <TransitionSeries.Sequence durationInFrames={16 * fps}>
          <FeatureTourScene />
        </TransitionSeries.Sequence>

        <TransitionSeries.Transition
          presentation={fade()}
          timing={linearTiming({ durationInFrames: 15 })}
        />

        <TransitionSeries.Sequence durationInFrames={5 * fps}>
          <ClosingScene />
        </TransitionSeries.Sequence>
      </TransitionSeries>

      <FilmGrain opacity={0.035} />
    </AbsoluteFill>
  );
};
