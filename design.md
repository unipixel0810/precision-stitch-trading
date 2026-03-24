# Design System Strategy: The Precision Stitch

## 1. Overview & Creative North Star
**The Creative North Star: "The Digital Loom"**
This design system moves away from the generic "FinTech box" and toward a high-end editorial experience that mirrors the precision of a bespoke suit. We treat financial data not as a spreadsheet, but as a living textile where every data point is "stitched" into a cohesive, high-tech tapestry.

To break the "template" look, we utilize **intentional asymmetry**. For example, a primary portfolio card may feature a `display-sm` value offset against a wide, low-density chart, creating a sense of sophisticated breathing room. We replace rigid, 100% width grids with layered "modular stacks," using overlapping elements and high-contrast typography scales to guide the eye toward critical market movements.

---

## 2. Colors & Surface Architecture
The color palette is rooted in `surface` (#131313) to provide a canvas of absolute depth, allowing the `primary-container` (#00E5FF) to vibrate with digital energy.

* **The "No-Line" Rule:** Prohibit the use of standard 1px solid borders for sectioning. Boundaries must be defined through background color shifts. Use `surface-container-low` for large section backgrounds sitting on a `surface` base.
* **Surface Hierarchy & Nesting:** Treat the UI as physical layers.
* *Base Level:* `surface` (#131313)
* *Section Level:* `surface-container-low` (#1C1B1B)
* *Interactive Card Level:* `surface-container-high` (#2A2A2A)
* **The "Glass & Gradient" Rule:** Floating modals and high-priority overlays must use Glassmorphism. Apply a `surface-variant` color at 60% opacity with a `20px` backdrop-blur.
* **Signature Textures:** For main Action Buttons, do not use flat hex codes. Apply a linear gradient from `primary` (#C3F5FF) to `primary-container` (#00E5FF) at a 135-degree angle to provide a "machined" metallic sheen.

---

## 3. Typography: The Editorial Edge
We employ a dual-type system to balance authoritative headers with technical legibility.

* **Display & Headlines (Manrope):** Used for "The Big Picture"—portfolio totals, stock symbols, and major market shifts. The wide tracking and geometric forms of Manrope convey a sense of modern institutional power.
* **Body & Labels (Inter):** Used for the "Fine Print"—ticker data, execution prices, and timestamped logs. Inter’s high x-height ensures that even `label-sm` (0.6875rem) remains legible during high-volatility trading.
* **Contrast as Hierarchy:** Pair a `headline-lg` price with a `label-md` percentage change. The drastic scale jump removes the need for bold colors to denote importance; the size differential does the work.

---

## 4. Elevation & Depth: Tonal Layering
Traditional drop shadows are forbidden. We define depth through light physics and tonal shifts.

* **The Layering Principle:** To lift a "Trade Execution" module, place a `surface-container-highest` card atop a `surface-container-low` background. The delta in luminance creates a natural, soft lift.
* **Ambient Shadows:** For floating elements (e.g., Tooltips), use an ultra-diffused shadow: `offset: 0 12px`, `blur: 32px`, `color: rgba(0, 0, 0, 0.45)`.
* **The "Ghost Border" Fallback:** In high-density data tables where separation is critical, use a "Ghost Border." Apply `outline-variant` (#3B494C) at 15% opacity. It should feel like a suggestion of a line, not a physical barrier.
* **Stitched Accents:** To honor the "Stitch-Trader" identity, use a `1px` dashed stroke of `primary` (#00E5FF) at 30% opacity solely on the *left* or *top* edge of a container to denote "active" or "focused" states.

---

## 5. Components

### Buttons
* **Primary:** Linear gradient (`primary` to `primary-container`), `md` (0.375rem) corner radius, `title-sm` uppercase text with `0.05em` letter spacing.
* **Secondary:** Ghost style. No background, `outline` (#849396) border at 20% opacity. On hover, background shifts to `surface-bright`.

### Cards & Modular Blocks
* **The Rule:** Forbid divider lines.
* **Implementation:** Use `Spacing-8` (1.75rem) of vertical white space to separate content blocks. Group related data using a `surface-container-lowest` inner well within a `surface-container` card.

### Input Fields
* **State Styling:** Default state is `surface-container-highest` with no border. On focus, the bottom edge gains a `2px` solid `primary-container` "stitch," and the background glows slightly with a 5% `primary` tint.

### Data Visualization (The Ticker Tape)
* **Relevant Component:** A horizontal, auto-scrolling "Silk Ribbon" using `surface-container-lowest`. Stock changes are highlighted using `tertiary-container` (#FEC931) for neutral/watch items and `primary-container` for gains.

---

## 6. Do’s and Don’ts

### Do:
* **Do** use `Spacing-10` and `Spacing-12` for layout margins to create a "gallery" feel.
* **Do** use `on-surface-variant` (#BAC9CC) for all secondary metadata to maintain a high-tech, low-glare environment.
* **Do** apply `lg` (0.5rem) roundedness only to outer containers; use `sm` (0.125rem) for internal elements like chips and buttons to create "nested" geometry.

### Don’t:
* **Don’t** use pure white (#FFFFFF). It creates "halation" (glowing) against the dark background, causing eye strain. Use `on-background` (#E5E2E1) instead.
* **Don’t** use standard 8px grids blindly. Lean into the custom spacing scale (e.g., `Spacing-3.5`) to create the "tight" feel of a precision instrument.
* **Don’t** use red for losses if it clashes with the brand. Use `error_container` (#93000A) to keep the "Dark Mode" tonal integrity without blowing out the user's retinas.
