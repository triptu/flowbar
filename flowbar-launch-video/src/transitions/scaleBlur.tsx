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
    ? interpolate(presentationProgress, [0, 1], [0, 5])
    : interpolate(presentationProgress, [0, 1], [5, 0]);

  const opacity = isExiting
    ? interpolate(presentationProgress, [0, 0.7], [1, 0], {
        extrapolateRight: "clamp",
      })
    : interpolate(presentationProgress, [0.2, 1], [0, 1], {
        extrapolateLeft: "clamp",
      });

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
