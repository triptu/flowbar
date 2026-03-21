---
name: launch-video
description: Edit, extend, and render the Flowbar launch video built with Remotion. Use this skill when working on the product launch video — adding scenes, changing timing, updating copy, re-recording clips, or rendering. Triggers on "launch video", "product video", "render video", "update the video"
---

# Flowbar Launch Video

Remotion project at `flowbar-launch-video/` producing a ~28s product launch video for Social and website embed.

## Quick Commands

```bash
cd flowbar-launch-video

# Preview in browser
npm run studio            # opens http://localhost:3000

# Render high-quality (social)
npx remotion render FlowbarLaunchVideo out/flowbar-launch-hq.mp4 --codec h264 --crf 18

# Compress for web (faststart for streaming)
ffmpeg -i out/flowbar-launch-hq.mp4 -c:v libx264 -crf 28 -preset slow -c:a aac -b:a 128k -movflags +faststart out/flowbar-launch-web.mp4 -y
```

## Architecture

```
flowbar-launch-video/
├── public/                     # Static assets (videos, audio)
│   ├── nature-loop.mp4         # Ambient background (loops globally)
│   ├── the-reveal.mp4          # Hero shot: desktop → Fn → Flowbar appears (5.9s)
│   ├── product-tour.mp4        # Single continuous screen recording (15.6s)
│   └── audio.mp3               # Background music
├── src/
│   ├── Root.tsx                # Composition definition (fps, duration, dimensions)
│   ├── FlowbarLaunchVideo.tsx  # Main composition — layers bg, audio, scenes, grain
│   ├── theme.ts                # Colors (matches website), spring presets
│   ├── fonts.ts                # Instrument Serif + DM Sans (Google Fonts)
│   ├── scenes/
│   │   ├── ProblemScene.tsx    # ACT 1: Two text-only pain cards
│   │   ├── RevealScene.tsx     # ACT 2: Hero shot with "Meet Flowbar" overlay
│   │   ├── FeatureTourScene.tsx# ACT 3: Continuous product demo + swapping labels
│   │   └── ClosingScene.tsx    # ACT 4: Logo, tagline, URL
│   ├── components/
│   │   ├── AmbientBackground.tsx  # Nature loop + gradient overlay + FilmGrain
│   │   └── AnimatedText.tsx       # WordReveal, MaskReveal, ScaleReveal
│   └── transitions/
│       └── scaleBlur.tsx       # Custom transition: scale+blur (not fade!)
└── out/                        # Rendered outputs
```

## Video Structure & Timing

Duration is calculated in `Root.tsx`: `(5 + 6 + 16 + 5) * 30fps - 45 (transitions) - 60 (trim) = 855 frames ≈ 28.5s`

| Act | Scene | Duration | Content |
|-----|-------|----------|---------|
| 1 | ProblemScene | 5s | Two text cards over nature bg. Word-by-word reveals. |
| 2 | RevealScene | 6s | `the-reveal.mp4` + "Meet Flowbar." at bottom + tagline |
| 3 | FeatureTourScene | 16s | `product-tour.mp4` continuous + 5 labels at top |
| 4 | ClosingScene | 5s | Logo + wordmark + description + URL |

Transitions between acts use `scaleBlur()` with `springTiming({ damping: 18, stiffness: 120 })`.

## Design System

### Colors (from `theme.ts`, matches flowbar.tushar.ai)
- Background: `#0c0f0d`
- Text: `#ede9df`
- Muted: `#9a9488`
- Accent: `#c99b6d` / `#ddb88a`

### Spring Presets (from `theme.ts`)
- `SPRINGS.smooth` — `{ damping: 200 }` — text reveals, subtle entrances
- `SPRINGS.snappy` — `{ damping: 20, stiffness: 200 }` — UI elements
- `SPRINGS.heavy` — `{ damping: 15, stiffness: 80, mass: 2 }` — hero moments, logo
- `SPRINGS.bouncy` — `{ damping: 12 }` — playful accents

### Text Components (from `AnimatedText.tsx`)
- `WordReveal` — word-by-word stagger with clip-path mask. Use for impactful lines.
- `MaskReveal` — single line clip-path reveal. Use for labels, descriptions.
- `ScaleReveal` — scale + blur-to-sharp. Use for hero text ("Meet Flowbar.").

### Layers (bottom to top)
1. `THEME.bg` solid color
2. `AmbientBackground` — nature-loop.mp4 + gradient overlay (darken prop: 0-1)
3. Scene content (TransitionSeries)
4. `FilmGrain` — 0.035 opacity, shifts per frame

## Key Learnings & Gotchas

### Motion Design
- **No fades.** Use `scaleBlur` transition or spring-based entrances. Fades look like PowerPoint.
- **Springs need real physics.** `{ damping: 200 }` is critically overdamped (no visible spring). Use the presets.
- **Text: mask reveals > fade+slide.** `clipPath: inset()` with `translateY` looks 10x better than opacity+translate.
- **Exits should be fast.** Enter with spring physics (12-18 frames), exit with quick linear (5-8 frames).
- **Last label in a series: skip exit fade.** Pass `isLast` flag to hold the final label through scene end.

### Video Handling
- Use `objectFit: "contain"` (not "cover") to show full recording including menubar. Fill bg with `THEME.bg`.
- `pauseWhenBuffering` is not available in this Remotion version — don't use it.
- Scene duration must be >= video duration or the video gets cut off. Check with `ffprobe -v error -show_entries format=duration -of csv=p=0 file.mp4`.
- When video is shorter than scene, the last frame freezes — this is desired behavior.

### Background
- Nature loop runs GLOBALLY behind all scenes (in FlowbarLaunchVideo.tsx, not per-scene).
- Scenes are transparent — they overlay on top.
- Closing scene adds its own `rgba(12,15,13,0.7)` darken layer to push the bg back for text legibility.
- Problem scene adds `rgba(12,15,13,0.35)` darken.

### Audio
- File: `public/audio.mp3`. Referenced via `staticFile("audio.mp3")`.
- Volume: fades in over 1s (0→0.5), fades out over last 2s (0.5→0).
- Generate with Gemini or Suno. Prompt: warm minimal electronic, soft analog pads, 88bpm, ~35-40s, no vocals.

### Rendering
- HQ: `--crf 18` → ~14MB (social media)
- Web: re-encode with `ffmpeg -crf 28 -preset slow -movflags +faststart` → ~3MB (website embed, instant streaming)
- Always render HQ first, then compress — don't render twice.

## How to Add a New Scene

1. Create `src/scenes/NewScene.tsx` — export a React component using `AbsoluteFill`
2. Keep background transparent (the global nature bg shows through)
3. Add darken overlay if text needs legibility: `<AbsoluteFill style={{ backgroundColor: "rgba(12,15,13,0.X)" }} />`
4. Use `WordReveal`/`MaskReveal`/`ScaleReveal` for text, `SPRINGS.*` for animations
5. Add to `FlowbarLaunchVideo.tsx` as a `TransitionSeries.Sequence` with `scaleBlur()` transition
6. Update duration math in both `FlowbarLaunchVideo.tsx` and `Root.tsx`

## How to Re-record a Clip

1. Use Screen Studio with: minimal padding, auto-zoom 120%, smooth cursor, dark mode, 1920x1080 30fps
2. Record just the Flowbar window (not desktop bg — we have the nature loop)
3. Export as high-quality MP4, drop in `public/`
4. Check duration: `ffprobe -v error -show_entries format=duration -of csv=p=0 public/clip.mp4`
5. Update the corresponding scene's `durationInFrames` to match (round up to nearest second × fps)
6. Update `Root.tsx` duration calculation

## How to Change Feature Tour Labels

Edit the `LABELS` array in `FeatureTourScene.tsx`:
```tsx
const LABELS = [
  { text: "Write in markdown. Your files stay yours.", startSec: 0 },
  { text: "Todos from every note. One place to check them off.", startSec: 3.5 },
  // ...
];
```
`startSec` is relative to the feature tour scene start (not the whole video). Time them to match what's happening in `product-tour.mp4`.
