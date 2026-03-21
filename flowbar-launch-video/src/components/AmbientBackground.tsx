import React from "react";
import { AbsoluteFill, staticFile, useCurrentFrame, useVideoConfig, interpolate } from "remotion";
import { Video } from "@remotion/media";
import { THEME } from "../theme";

/**
 * Recreates the website's ambient background:
 * Looping nature video + dual gradient overlay.
 * Constant across the entire video — grounding visual.
 */
export const AmbientBackground: React.FC<{
  /** 0 = fully visible, 1 = fully darkened */
  darken?: number;
}> = ({ darken = 0 }) => {
  const overlayExtra = interpolate(darken, [0, 1], [0, 0.6], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill>
      {/* Nature loop video — full bleed */}
      <Video
        src={staticFile("nature-loop.mp4")}
        muted
        loop
        style={{
          width: "100%",
          height: "100%",
          objectFit: "cover",
        }}
      />

      {/* Dual gradient overlay — matching website exactly */}
      <AbsoluteFill
        style={{
          background: [
            `radial-gradient(ellipse 80% 60% at 50% 40%, rgba(12,15,13,${0.2 + overlayExtra}) 30%, rgba(12,15,13,${0.6 + overlayExtra}) 100%)`,
            `linear-gradient(to bottom, rgba(12,15,13,${0.25 + overlayExtra}) 0%, rgba(12,15,13,${0.2 + overlayExtra}) 50%, rgba(12,15,13,${0.85 + overlayExtra * 0.15}) 85%, ${THEME.bg} 100%)`,
          ].join(", "),
        }}
      />
    </AbsoluteFill>
  );
};

/**
 * Subtle film grain overlay for texture.
 * Uses CSS noise pattern — no external assets needed.
 */
export const FilmGrain: React.FC<{ opacity?: number }> = ({
  opacity = 0.04,
}) => {
  const frame = useCurrentFrame();

  // Shift the grain pattern each frame for realistic feel
  const offsetX = (frame * 17) % 200;
  const offsetY = (frame * 13) % 200;

  return (
    <AbsoluteFill
      style={{
        opacity,
        mixBlendMode: "overlay",
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E")`,
        backgroundPosition: `${offsetX}px ${offsetY}px`,
        backgroundSize: "200px 200px",
        pointerEvents: "none",
      }}
    />
  );
};
