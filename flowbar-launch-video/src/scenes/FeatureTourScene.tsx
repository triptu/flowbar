import React from "react";
import {
  AbsoluteFill,
  Sequence,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  staticFile,
} from "remotion";
import { Video } from "@remotion/media";
import { MaskReveal } from "../components/AnimatedText";
import { THEME } from "../theme";

/**
 * ACT 3: FEATURE TOUR (16s)
 *
 * ONE continuous screen recording. Labels swap at the top.
 * No entrance animation — fade transition handles scene entrance.
 */

const LABELS = [
  { text: "Write in markdown. Your files stay yours.", startSec: 0 },
  {
    text: "Todos from every note. One place to check them off.",
    startSec: 3.5,
  },
  { text: "Start a timer. Know where your day went.", startSec: 7 },
  { text: "⌘K to find anything. Instantly.", startSec: 10.5 },
  { text: "Always there. Never in the way.", startSec: 13 },
];

export const FeatureTourScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();

  return (
    <AbsoluteFill>
      {/* Single continuous product recording — always visible */}
      <AbsoluteFill style={{ padding: "80px 24px 24px 24px" }}>
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

      {/* Top gradient for label legibility */}
      <AbsoluteFill
        style={{
          background:
            "linear-gradient(rgba(12,15,13,0.9) 0%, rgba(12,15,13,0.6) 8%, transparent 22%)",
          pointerEvents: "none",
        }}
      />

      {/* Swapping labels at TOP */}
      {LABELS.map((label, i) => {
        const startFrame = Math.round(label.startSec * fps);
        const nextStart =
          i < LABELS.length - 1
            ? Math.round(LABELS[i + 1].startSec * fps)
            : durationInFrames;
        const duration = nextStart - startFrame;

        return (
          <Sequence key={i} from={startFrame} durationInFrames={duration}>
            <LabelCard text={label.text} />
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};

const LabelCard: React.FC<{ text: string }> = ({ text }) => {
  return (
    <AbsoluteFill
      style={{
        justifyContent: "flex-start",
        alignItems: "center",
        paddingTop: 28,
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
