import React from "react";
import {
  AbsoluteFill,
  Sequence,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
  staticFile,
} from "remotion";
import { Video } from "@remotion/media";
import { MaskReveal } from "../components/AnimatedText";
import { THEME, SPRINGS } from "../theme";
import { FONT_SERIF } from "../fonts";

/**
 * ACT 3: FEATURE TOUR
 *
 * ONE continuous screen recording plays the entire time.
 * Text labels swap at the TOP to narrate what's being shown.
 * Product floats over global nature bg.
 *
 * product-tour.mp4 = 15.6s, scene = 16s
 */

const LABELS = [
  { text: "Write in markdown. Preview instantly.", startSec: 0 },
  { text: "All your todos, pulled from every note.", startSec: 3.5 },
  { text: "Track time against any task.", startSec: 7 },
  { text: "Find anything with \u2318K.", startSec: 10.5 },
  { text: "Always there. Never in the way.", startSec: 13 },
];

export const FeatureTourScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();

  // Video entrance: scale+blur on first appearance
  const enterSpring = spring({
    frame,
    fps,
    config: SPRINGS.snappy,
  });
  const videoScale = interpolate(enterSpring, [0, 1], [0.94, 1]);
  const videoBlur = interpolate(enterSpring, [0, 1], [4, 0]);
  const videoOpacity = interpolate(enterSpring, [0, 1], [0, 1]);

  return (
    <AbsoluteFill>
      {/* Single continuous product recording */}
      <AbsoluteFill
        style={{
          padding: "80px 24px 24px 24px",
          opacity: videoOpacity,
          transform: `scale(${videoScale})`,
          filter: `blur(${videoBlur}px)`,
        }}
      >
        <div
          style={{
            width: "100%",
            height: "100%",
            borderRadius: 12,
            overflow: "hidden",
            boxShadow: `0 24px 64px rgba(0,0,0,0.5), 0 0 0 1px rgba(255,255,255,0.04)`,
          }}
        >
          <Video
            src={staticFile("product-tour.mp4")}
            muted

            style={{
              width: "100%",
              height: "100%",
              objectFit: "contain",
              backgroundColor: THEME.bg,
            }}
          />
        </div>
      </AbsoluteFill>

      {/* Top gradient for label legibility — renders above video */}
      <AbsoluteFill
        style={{
          background:
            "linear-gradient(rgba(12,15,13,0.9) 0%, rgba(12,15,13,0.6) 8%, transparent 22%)",
          pointerEvents: "none",
        }}
      />

      {/* Swapping labels at TOP — renders above everything */}
      {LABELS.map((label, i) => {
        const startFrame = Math.round(label.startSec * fps);
        const nextStart =
          i < LABELS.length - 1
            ? Math.round(LABELS[i + 1].startSec * fps)
            : durationInFrames;
        const duration = nextStart - startFrame;

        return (
          <Sequence key={i} from={startFrame} durationInFrames={duration}>
            <LabelCard text={label.text} isLast={i === LABELS.length - 1} />
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};

const LabelCard: React.FC<{ text: string; isLast?: boolean }> = ({ text, isLast }) => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();

  // Exit: quick fade (skip for last label — hold it)
  const exitStart = durationInFrames - 5;
  const exitOpacity = isLast
    ? 1
    : interpolate(
        frame,
        [exitStart, durationInFrames],
        [1, 0],
        { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
      );

  return (
    <AbsoluteFill
      style={{
        justifyContent: "flex-start",
        alignItems: "center",
        paddingTop: 28,
        opacity: exitOpacity,
      }}
    >
      <MaskReveal
        text={text}
        fontSize={40}
        color={THEME.text}
        delay={2}
        serif
      />
    </AbsoluteFill>
  );
};
