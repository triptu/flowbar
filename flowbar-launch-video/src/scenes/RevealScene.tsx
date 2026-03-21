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
import { MaskReveal } from "../components/AnimatedText";
import { THEME, SPRINGS } from "../theme";

/**
 * ACT 2: THE REVEAL (6s)
 *
 * Hero shot: desktop → Fn → Flowbar appears.
 * No entrance animation on the video — the fade transition handles it.
 * "Meet Flowbar." appears via MaskReveal at 1.5s, tagline replaces at 4s.
 */
export const RevealScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Text timing — sequential, NOT overlapping
  const TITLE_IN = Math.round(1.5 * fps);
  const TITLE_OUT = Math.round(3.5 * fps);
  const TAGLINE_IN = Math.round(4.0 * fps);

  // Title visibility window (clipPath handles the entrance, this handles the exit)
  const titleVisible = frame >= TITLE_IN && frame < TITLE_OUT + 8;

  // Title exit: quick fade out
  const titleOpacity =
    frame >= TITLE_OUT
      ? interpolate(frame, [TITLE_OUT, TITLE_OUT + 8], [1, 0], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        })
      : 1;

  // Tagline visibility
  const taglineVisible = frame >= TAGLINE_IN;

  return (
    <AbsoluteFill>
      {/* Screen recording — always visible, transition handles entrance */}
      <AbsoluteFill style={{ padding: 16 }}>
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
        {/* "Meet Flowbar." */}
        {titleVisible && (
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
            <MaskReveal
              text="Meet Flowbar."
              fontSize={64}
              color={THEME.text}
              delay={TITLE_IN}
              serif
            />
          </div>
        )}

        {/* Tagline — replaces title */}
        {taglineVisible && (
          <div style={{ position: "absolute", bottom: 36 }}>
            <MaskReveal
              text="Your notes. One keystroke away."
              fontSize={28}
              fontWeight="500"
              color={THEME.accent2}
              delay={TAGLINE_IN}
            />
          </div>
        )}
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
