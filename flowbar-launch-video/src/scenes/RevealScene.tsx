import React from "react";
import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
  staticFile,
} from "remotion";
import { Video } from "@remotion/media";
import { ScaleReveal, MaskReveal } from "../components/AnimatedText";
import { THEME, SPRINGS } from "../theme";
import { FONT_SERIF } from "../fonts";

/**
 * ACT 2: THE REVEAL (0:06 – 0:12)
 *
 * The hero shot. Clean desktop → double-tap Fn → Flowbar slides in.
 *
 * Motion design:
 * - Video scales up from 0.92 with a heavy spring (cinematic entrance)
 * - Starts blurred, sharpens as it scales
 * - "Meet Flowbar." scale-reveals at 2s (with blur-to-sharp)
 * - Tagline mask-reveals at 4s, replacing the title (no overlap!)
 */
export const RevealScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Video entrance: scale up from slightly smaller, blur to sharp
  const videoSpring = spring({
    frame,
    fps,
    config: SPRINGS.heavy,
  });

  // const videoScale = interpolate(videoSpring, [0, 1], [0.92, 1]);
  const videoBlur = interpolate(videoSpring, [0, 1], [6, 0]);
  const videoOpacity = interpolate(videoSpring, [0, 1], [0, 1]);

  // Text timing — sequential, NOT overlapping (6s scene)
  const TITLE_IN = Math.round(1.5 * fps);
  const TITLE_OUT = Math.round(3.5 * fps);
  const TAGLINE_IN = Math.round(4.0 * fps);

  // Title: "Meet Flowbar." — appears then fades
  const titleOpacity = interpolate(
    frame,
    [TITLE_IN, TITLE_IN + 10, TITLE_OUT, TITLE_OUT + 8],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );

  // Tagline: fades in after title is gone
  const taglineSpring = spring({
    frame: frame - TAGLINE_IN,
    fps,
    config: SPRINGS.smooth,
  });

  return (
    <AbsoluteFill>
      {/* Screen recording — cinematic entrance */}
      <AbsoluteFill
        style={{
          opacity: videoOpacity,
          // transform: `scale(${videoScale})`,
          filter: `blur(${videoBlur}px)`,
          padding: 16,
        }}
      >
        <div
          style={{
            width: "100%",
            height: "100%",
            borderRadius: 12,
            overflow: "hidden",
            boxShadow: `0 30px 80px rgba(0,0,0,0.6), 0 0 0 1px rgba(255,255,255,0.04)`,
          }}
        >
          <Video
            src={staticFile("the-reveal.mp4")}
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

      {/* Bottom gradient for text legibility */}
      <AbsoluteFill
        style={{
          background:
            "linear-gradient(transparent 55%, rgba(12,15,13,0.8) 82%, rgba(12,15,13,0.95) 100%)",
          pointerEvents: "none",
        }}
      />

      {/* Text layer — bottom center */}
      <AbsoluteFill
        style={{
          justifyContent: "flex-end",
          alignItems: "center",
          paddingBottom: 36,
        }}
      >
        {/* "Meet Flowbar." — scale+blur reveal, bottom */}
        <div
          style={{
            opacity: titleOpacity,
            padding: "18px 28px",
            borderRadius: 20,
            background: "rgba(12, 15, 13, 0.34)",
            backdropFilter: "blur(18px)",
            WebkitBackdropFilter: "blur(18px)",
            boxShadow:
              "0 18px 50px rgba(0,0,0,0.28), inset 0 1px 0 rgba(255,255,255,0.06)",
            border: "1px solid rgba(255,255,255,0.08)",
          }}
        >
          <ScaleReveal
            text="Meet Flowbar."
            fontSize={64}
            color={THEME.text}
            delay={TITLE_IN}
            serif
          />
        </div>

        {/* Tagline — mask reveal, replaces title at same position */}
        <div
          style={{
            position: "absolute",
            bottom: 36,
            opacity: interpolate(taglineSpring, [0, 1], [0, 1]),
          }}
        >
          <MaskReveal
            text="Your notes. One keystroke away."
            fontSize={28}
            fontWeight="500"
            color={THEME.accent2}
            delay={TAGLINE_IN}
          />
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
