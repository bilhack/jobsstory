# JobsStory — Visual Design Brief for Google AI Studio (Gemini)

> Use this to get a **design-only** output: colors, typography, icon placement and layout rules.
> Paste the last section (**MASTER PROMPT**) into AI Studio, or upload this whole file as context.
> The app is **Arabic-first (RTL)**. Output must be a design system guide, NOT code.

---

## 1) What the app is

**JobsStory**: a TikTok-style, video-first job platform. Job seekers publish a 60-second video story instead of a CV; recruiters watch those stories in a vertical feed, save candidates, post jobs and review applicants. It must look bold, modern, playful but trustworthy — **"TikTok energy with a purpose"** — and gorgeous in Arabic RTL.

Two personas:
- **Seeker (باحث عن عمل)** — records a 60s story, browses jobs, applies with their story, tracks status.
- **Recruiter (مسؤول توظيف)** — browses stories, saves candidates, posts jobs, reviews applicants.

---

## 2) Current brand foundation (keep the vibe, upgrade the craft)

Existing palette (this is the starting point — keep these hues, refine their role/hierarchy):

| Token | Hex | Role today |
|---|---|---|
| Deep violet | `#7C4DFF` | Primary / actions / hero |
| Hot pink | `#FF2D78` | Secondary / accent CTA / love |
| Electric blue | `#23B5FF` | Tertiary accent (saves, links) |
| Amber | `#FFB300` | Warning / highlights |
| Red | `#FF5252` | Danger / unlike / report |
| Mint | `#2ED6A1` | Success |
| Gold | `#FFC24B` | Premium highlight |
| Near-black violet | `#0F0F1A` | App background |
| Card surface | `#1A1A2E` | Surface, cards, sheets |
| Surface light | `#232338` | Raised surfaces, borders |
| Text primary | `#FFFFFF` | Headings / body |
| Text muted | `#B8B8CC` | Secondary text |
| Glass | `0xB3000000` | Overlaid on video/media |

Gradient DNA: `hero = #2B0A5E → #7C4DFF → #FF2D78` (diagonal), secondary gradient `#FF2D78 → #7C4DFF` for buttons.

Mood words: confident · warm · electric · premium · playful without being childish.

---

## 3) What I need from you (deliverable — DESIGN ONLY)

Return a **visual design system guide** (markdown), covering only these five areas:

### A. Color system
- Refined palette: primary/secondary/success/warning/danger + semantic roles (info, success, error), surface hierarchy (bg/surface/raised/overlay), text contrast ladder.
- **Usage rules**: where violet vs pink vs blue should appear (CTAs, selection, links, "liked/saved" states), what never uses which color, gradients on hero vs buttons vs tiles.
- Accessibility: contrast-safe muted text, red-green independence (don't rely on color alone).
- Optional light-theme variant mapped from the same tokens.

### B. Typography
- Font families: one Latin + one **Arabic** pairing that feels premium and lightens at heavy weights (e.g. suggestions — you propose). No heavy serifs.
- Type scale: display / headline / title / body / caption with sizes + weights + line-height, **in RTL-first thinking** (no left-aligned assumptions), rules for Arabic letter-spacing (usually 0 / negative tracking).
- Numerals/time (e.g. "0:45", counters) — mono-optional recommendation.

### C. Iconography
- One icon family (outlined vs rounded — pick and justify), stroke weight, consistent corner/optical size.
- **Placement map**: for each area list which icon, in what size (dp), where (top-right? bottom-right rail? labels?), and hit-target size (min 44px).
  - Welcome / Onboarding role cards, Login (social), Home dashboard tiles, Explore feed action rail (like/save/share/report + sound, position counter), Studio (record, close, flip, flash, effects, retake, publish), My Stories (delete), Jobs (post, detail, applicants, contact), empty states, app bar actions, tab/nav bar.
- Do/don't: never nest two same-size icons, avoid icon + button overload on the feed rail, etc.

### D. Spacing, shape & depth
- Spacing scale (4/8 basis) with rhythm rules.
- Radii scale and where each applies (buttons 28, cards 24, fields 16, pills 30).
- Elevation/shadow language: when to use soft color glows vs flat surfaces (dark UI); hairline borders on raised surfaces.

### E. Motion & micro-interactions
- Durations/curves for: page enter, tap feedback, like-burst (exists), tab switch, shimmer/loading, sheet open, toast.
- Keep motion modest in serious surfaces (jobs, applications), playful in media surfaces (feed, studio).

---

## 4) Constraints

- Arabic-first RTL: everything mirrors; design rules must assume RTL default.
- Output is a **style guide** (markdown/tables), quick sketches allowed but text-first.
- Do NOT write Flutter code, routes, or components in this task — design direction only.
- Keep the existing hues (section 2) as the genetic code; refine, don't replace the brand.

---

## 5) MASTER PROMPT (copy-paste into AI Studio)

```
Act as a senior brand & product designer. I run "JobsStory", a TikTok-style
video-first job platform (candidates upload 60-second video stories instead of
CVs; recruiters browse a vertical story feed, save candidates, post jobs,
review applicants). The app is Arabic-first and RTL. I need a pure VISUAL
DESIGN GUIDE — NOT code.

Current brand seed (keep these hues, refine their roles/hierarchy):
deep violet #7C4DFF, hot pink #FF2D78, electric blue #23B5FF, amber #FFB300,
red #FF5252, mint #2ED6A1, gold #FFC24B on near-black violet #0F0F1A with card
surfaces #1A1A2E/#232338, white text, muted #B8B8CC. Gradient DNA:
#2B0A5E→#7C4DFF→#FF2D78 (hero, diagonal) and #FF2D78→#7C4DFF (buttons).

Mood: confident, warm, electric, premium, playful-but-trustworthy — "TikTok
energy with a purpose". Must look stunning in Arabic RTL.

Produce a markdown design system covering exactly:
A) COLOR — semantic palette + hierarchy + exact usage rules (which color for
   CTAs, selection, liked/saved states, gradients, success/error/surface text),
   plus an optional mapped light variant. Keep accessibility + not color-only.
B) TYPOGRAPHY — one Latin + one premium Arabic font pairing, full type scale
   (sizes/weights/line-height), RTL-first (Arabic letter-spacing guidance).
C) ICONOGRAPHY — one icon family choice with justification; per-screen icon
   PLACEMENT MAP (icon, size in dp, exact position) for: welcome, onboarding
   role cards, login, home dashboard tiles, explore feed screen (right action
   rail: like/save/share/report + sound toggle + position counter; bottom-left
   creator info), studio capture (record, close, flip, flash, effects, retake,
   publish), my-stories (delete), jobs screens (post/detail/applicants/
   contact), empty states, app bar, nav bar; min 44px targets.
D) SPACING/SHAPE/DEPTH — 4/8 spacing scale, radii where used, color-glow
   shadow language for dark UI, hairline borders.
E) MOTION — durations/curves for enter, tap, like-burst, tab switch, shimmer,
   sheet, toast; playful on media surfaces, restrained on serious ones.

Constraints: Arabic-first RTL by default; markdown/tables; text-first, no
Flutter code. Keep the brand hues as the genetic code — refine roles, don't
rebrand.
```