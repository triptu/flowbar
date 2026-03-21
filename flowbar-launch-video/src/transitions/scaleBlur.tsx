import React from "react";
import type {
  TransitionPresentation,
  TransitionPresentationComponentProps,
} from "@remotion/transitions";
import { AbsoluteFill, interpolate } from "remotion";

const ScaleBlurPresentation: React.FC<
  TransitionPresentationComponentProps<Record<string, unknown>>
> = ({ children, presentationDirection, presentationProgress }) => {
  const isExiting = presentationDirection === "exiting";

  const scale = isExiting
    ? interpolate(presentationProgress, [0, 1], [1, 1.04])
    : interpolate(presentationProgress, [0, 1], [0.96, 1]);

  const blur = isExiting
    ? interpolate(presentationProgress, [0, 1], [0, 8])
    : interpolate(presentationProgress, [0, 1], [8, 0]);

  // Only fade out the exiting scene — entering scene relies on blur alone.
  // This avoids double-opacity flicker when scene elements also animate opacity.
  const opacity = isExiting
    ? interpolate(presentationProgress, [0, 0.6], [1, 0], {
        extrapolateRight: "clamp",
      })
    : 1;

  return (
    <AbsoluteFill
      style={{
        transform: `scale(${scale})`,
        filter: `blur(${blur}px)`,
        opacity,
      }}
    >
      {children}
    </AbsoluteFill>
  );
};

export const scaleBlur = (): TransitionPresentation<
  Record<string, unknown>
> => ({
  component: ScaleBlurPresentation,
  props: {},
});
