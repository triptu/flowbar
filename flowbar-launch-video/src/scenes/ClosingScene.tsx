import React from "react";
import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
} from "remotion";
import { MaskReveal } from "../components/AnimatedText";
import { THEME, SPRINGS } from "../theme";
import { FONT_BODY, FONT_SERIF } from "../fonts";

/**
 * ACT 4: THE CLOSER (5s)
 *
 * Logo + name, description, URL.
 * No opacity-based entrance animations — fade transition handles scene entrance.
 * Only MaskReveal (clipPath-based) for text stagger.
 */
export const ClosingScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  return (
    <AbsoluteFill>
      {/* Heavy darken — push the nature bg way back */}
      <AbsoluteFill style={{ backgroundColor: "rgba(12,15,13,0.7)" }} />

      {/* Warm spotlight glow — always visible, no entrance animation */}
      <WarmGlow />

      <AbsoluteFill
        style={{
          justifyContent: "center",
          alignItems: "center",
        }}
      >
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            zIndex: 1,
          }}
        >
          {/* Logo + wordmark — always visible */}
          <LogoWordmark />

          {/* Description */}
          <div style={{ marginTop: 28 }}>
            <MaskReveal
              text="Notes, todos & time tracking in your menu bar."
              fontSize={28}
              fontWeight="400"
              color={THEME.muted}
              delay={Math.round(0.4 * fps)}
            />
          </div>

          {/* Meta */}
          <div style={{ marginTop: 12 }}>
            <MaskReveal
              text="Free & open source · macOS"
              fontSize={18}
              fontWeight="400"
              color={THEME.dim}
              delay={Math.round(0.65 * fps)}
            />
          </div>

          {/* URL */}
          <div style={{ marginTop: 48 }}>
            <MaskReveal
              text="flowbar.tushar.ai"
              fontSize={40}
              fontWeight="600"
              color={THEME.accent2}
              delay={Math.round(0.9 * fps)}
            />
          </div>
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

const LogoWordmark: React.FC = () => {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 24,
      }}
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 24 24"
        width={88}
        height={88}
        fill={THEME.accent2}
        style={{
          filter: `drop-shadow(0 4px 30px ${THEME.accentGlow})`,
        }}
      >
        <path
          fillRule="evenodd"
          clipRule="evenodd"
          d="M12 2.5C7 2.5 2.5 7 2.5 12C2.5 17 7 21.5 12 21.5C17 21.5 21.5 17 21.5 12C21.5 7 17 2.5 12 2.5ZM3.8 11.2Q7 8.8 10.5 10.8Q12 11.8 13.5 12.2Q17 13 20.2 10.8L20.2 12.8Q17 15 13.5 14.2Q12 13.8 10.5 12.8Q7 10.8 3.8 13.2Z"
        />
      </svg>

      <span
        style={{
          fontFamily: FONT_SERIF,
          fontSize: 120,
          color: THEME.text,
          letterSpacing: "-0.02em",
          lineHeight: 1,
        }}
      >
        Flowbar
      </span>
    </div>
  );
};

const WarmGlow: React.FC = () => {
  return (
    <div
      style={{
        position: "absolute",
        top: "50%",
        left: "50%",
        width: 1000,
        height: 600,
        marginLeft: -500,
        marginTop: -300,
        borderRadius: "50%",
        background: `radial-gradient(ellipse, rgba(201,155,109,0.22) 0%, rgba(201,155,109,0.08) 35%, transparent 65%)`,
        filter: "blur(40px)",
        pointerEvents: "none",
      }}
    />
  );
};
