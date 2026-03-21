import React from "react";
import {
  AbsoluteFill,
  Sequence,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
} from "remotion";
import { WordReveal, MaskReveal } from "../components/AnimatedText";
import { THEME, SPRINGS } from "../theme";

/**
 * ACT 1: THE PROBLEM (0:00 – 0:05)
 * Two punchy pain points, text only. Transparent — nature loop shows through.
 * 2.5s per card.
 */
export const ProblemScene: React.FC = () => {
  const { fps } = useVideoConfig();
  const CARD = Math.round(2.5 * fps); // 75 frames per card

  return (
    <AbsoluteFill>
      {/* Extra darken layer for text legibility over nature bg */}
      <AbsoluteFill style={{ backgroundColor: "rgba(12,15,13,0.35)" }} />

      {/* Pain 1: Friction */}
      <Sequence durationInFrames={CARD}>
        <PainCard
          line1="Opening your notes and todos app"
          accent="shouldn't feel like a context switch."
        />
      </Sequence>

      {/* Pain 2: Focus */}
      <Sequence from={CARD} durationInFrames={CARD}>
        <PainCard
          line1="You sit down to focus."
          accent="Ten minutes later, you forgot what you were doing."
        />
      </Sequence>
    </AbsoluteFill>
  );
};

const PainCard: React.FC<{ line1: string; accent: string }> = ({
  line1,
  accent,
}) => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();

  // Exit: quick fade+scale
  const exitStart = durationInFrames - 6;
  const exitProgress = interpolate(
    frame,
    [exitStart, durationInFrames],
    [1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );
  const exitScale = interpolate(
    frame,
    [exitStart, durationInFrames],
    [1, 0.97],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );

  return (
    <AbsoluteFill
      style={{
        justifyContent: "center",
        alignItems: "center",
        opacity: exitProgress,
        transform: `scale(${exitScale})`,
      }}
    >
      <div style={{ maxWidth: 750, textAlign: "center", padding: "0 40px" }}>
        <MaskReveal
          text={line1}
          fontSize={34}
          fontWeight="400"
          color={THEME.muted}
          delay={0}
        />
        <div style={{ marginTop: 10 }}>
          <WordReveal
            text={accent}
            fontSize={44}
            color={THEME.text}
            delay={Math.round(0.25 * fps)}
            serif
            staggerFrames={3}
          />
        </div>
      </div>
    </AbsoluteFill>
  );
};
