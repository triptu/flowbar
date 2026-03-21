// Matches the website exactly: warm earthy tones
export const THEME = {
  bg: "#0c0f0d",
  bg2: "#131714",
  bg3: "#1a1e1b",
  text: "#ede9df",
  muted: "#9a9488",
  dim: "#5e5a52",
  accent: "#c99b6d",
  accent2: "#ddb88a",
  accentGlow: "rgba(201, 155, 109, 0.25)",
};

// Spring configs — consistent motion language
export const SPRINGS = {
  smooth: { damping: 200 }, // Smooth, no bounce — reveals
  snappy: { damping: 20, stiffness: 200 }, // Snappy — UI elements
  heavy: { damping: 15, stiffness: 80, mass: 2 }, // Heavy, cinematic — hero moments
  bouncy: { damping: 12 }, // Slight bounce — playful
};
