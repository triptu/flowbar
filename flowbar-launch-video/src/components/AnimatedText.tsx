import React from "react";
import {
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
  Easing,
} from "remotion";
import { FONT_BODY, FONT_SERIF } from "../fonts";
import { SPRINGS } from "../theme";

/**
 * Word-by-word stagger reveal with clip-path mask.
 * Each word slides up and unclips — the premium text entrance.
 */
export const WordReveal: React.FC<{
  text: string;
  fontSize?: number;
  fontWeight?: string;
  color?: string;
  delay?: number;
  serif?: boolean;
  staggerFrames?: number;
  style?: React.CSSProperties;
}> = ({
  text,
  fontSize = 48,
  fontWeight = "600",
  color = "#ede9df",
  delay = 0,
  serif = false,
  staggerFrames = 3,
  style,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const words = text.split(" ");

  return (
    <div
      style={{
        fontFamily: serif ? FONT_SERIF : FONT_BODY,
        fontSize,
        fontWeight: serif ? "400" : fontWeight,
        color,
        textAlign: "center",
        lineHeight: 1.3,
        display: "flex",
        flexWrap: "wrap",
        justifyContent: "center",
        gap: `0 ${fontSize * 0.28}px`,
        ...style,
      }}
    >
      {words.map((word, i) => {
        const wordDelay = delay + i * staggerFrames;
        const progress = spring({
          frame: frame - wordDelay,
          fps,
          config: SPRINGS.smooth,
        });

        const y = interpolate(progress, [0, 1], [20, 0]);
        const clipProgress = interpolate(progress, [0, 1], [0, 100]);

        return (
          <span
            key={i}
            style={{
              display: "inline-block",
              transform: `translateY(${y}px)`,
              clipPath: `inset(0 0 ${100 - clipProgress}% 0)`,
            }}
          >
            {word}
          </span>
        );
      })}
    </div>
  );
};

/**
 * Single line reveal with mask — for small text / labels.
 */
export const MaskReveal: React.FC<{
  text: string;
  fontSize?: number;
  fontWeight?: string;
  color?: string;
  delay?: number;
  serif?: boolean;
  style?: React.CSSProperties;
}> = ({
  text,
  fontSize = 28,
  fontWeight = "500",
  color = "#ede9df",
  delay = 0,
  serif = false,
  style,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const progress = spring({
    frame: frame - delay,
    fps,
    config: SPRINGS.smooth,
  });

  const y = interpolate(progress, [0, 1], [24, 0]);
  const clipProgress = interpolate(progress, [0, 1], [0, 100]);

  return (
    <div
      style={{
        fontFamily: serif ? FONT_SERIF : FONT_BODY,
        fontSize,
        fontWeight: serif ? "400" : fontWeight,
        color,
        textAlign: "center",
        clipPath: `inset(0 0 ${100 - clipProgress}% 0)`,
        transform: `translateY(${y}px)`,
        ...style,
      }}
    >
      {text}
    </div>
  );
};

/**
 * Scale-up entrance — for the hero "Meet Flowbar" moment.
 */
export const ScaleReveal: React.FC<{
  text: string;
  fontSize?: number;
  color?: string;
  delay?: number;
  serif?: boolean;
}> = ({ text, fontSize = 96, color = "#ede9df", delay = 0, serif = true }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const progress = spring({
    frame: frame - delay,
    fps,
    config: SPRINGS.heavy,
  });

  const scale = interpolate(progress, [0, 1], [0.8, 1]);
  const opacity = interpolate(progress, [0, 1], [0, 1]);
  // Blur-to-sharp: starts blurred, ends crisp
  const blur = interpolate(progress, [0, 1], [8, 0]);

  return (
    <div
      style={{
        fontFamily: serif ? FONT_SERIF : FONT_BODY,
        fontSize,
        fontWeight: serif ? "400" : "700",
        color,
        opacity,
        transform: `scale(${scale})`,
        filter: `blur(${blur}px)`,
        textAlign: "center",
        letterSpacing: "-0.02em",
      }}
    >
      {text}
    </div>
  );
};
