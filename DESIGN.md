# Design System Strategy: Urban Art Drop Finder
 
## 1. Overview & Creative North Star
**Creative North Star: "The Neon Cartographer"**
 
This design system moves away from the sterile, brightly lit interfaces of generic mapping apps. Instead, it positions the user as an explorer in a living, nocturnal gallery. We leverage a "Gritty Editorial" approach—merging the raw, high-contrast energy of street art with the precision of a high-end tactical navigation tool.
 
To break the "template" look, the system relies on **intentional asymmetry**. Map markers might overflow their containers, and typography scales are pushed to extremes—very large display headers juxtaposed with tiny, technical monospace coordinates. This creates a rhythmic, high-fashion cadence that feels more like a curated magazine than a database.
 
---
 
## 2. Colors
Our palette is rooted in the "Deepest Dark," using a tiered black-to-grey foundation to make our vibrant accents—Neon Green (`primary`) and Electric Blue (`secondary`)—feel like glowing light sources.
 
### The "No-Line" Rule
Designers are strictly prohibited from using 1px solid borders to section content. Visual separation must be achieved through **Tonal Shifting**. A card does not have an outline; it is simply a `surface-container-high` block resting on a `surface` background.
 
### Surface Hierarchy & Nesting
Treat the UI as a series of physical, stacked layers.
- **Base Layer:** `surface` (#0e0e0e)
- **Primary Containers:** `surface-container` (#1a1a1a)
- **Floating/Active Elements:** `surface-bright` (#2c2c2c)
- **Nesting Logic:** When placing a child element inside a container, use a step-up approach. An inner search bar inside a navigation panel should move from `surface-container` to `surface-container-high` to create depth without visual noise.
 
### The "Glass & Gradient" Rule
For floating action buttons or high-priority overlays, use **Glassmorphism**. Apply `surface-variant` with a 60% opacity and a 16px-24px backdrop blur. 
- **Signature Texture:** Major CTAs should not be flat. Use a subtle linear gradient from `primary` (#f3ffca) to `primary-container` (#cafd00) at a 135-degree angle to give the neon a "charged" feel.
 
---
 
## 3. Typography
The system uses a dual-font strategy to balance artistic expression with technical utility.
 
*   **Headlines (Space Grotesk):** This bold, idiosyncratic sans-serif carries the brand's "Street" soul. Use `display-lg` for hero headlines with tight letter-spacing (-0.02em) to mimic the impact of a stencil.
*   **Body (Inter):** A clean, neutral workhorse that ensures readability against dark backgrounds.
*   **The Technical Layer:** All coordinates, IDs, and metadata must use the monospace traits of the label scales. This creates a "premium navigation" aesthetic, suggesting precision amidst the urban grit.
 
---
 
## 4. Elevation & Depth
In this design system, light is an ingredient, not just a decoration.
 
*   **The Layering Principle:** Avoid shadows for static layout components. Rely entirely on the `surface-container` tiers. Use `surface-container-lowest` (#000000) for inset elements like input fields to create "carved" depth.
*   **Ambient Shadows:** For high-floating elements (e.g., a detail modal for a graffiti piece), use a diffused shadow.
    *   *Shadow:* `0px 20px 40px rgba(0, 0, 0, 0.4)`
    *   *Tint:* Add a 4% `surface-tint` to the shadow color to ensure it feels like it belongs to the dark environment.
*   **The "Ghost Border" Fallback:** If accessibility requires a container boundary, use the `outline-variant` (#484847) at **15% opacity**. It should be felt, not seen.
*   **Gritty Depth:** Use `secondary-container` with glassmorphism for map-based controls (zoom, GPS) to make them look like glowing HUD elements projected onto the glass of the device.
 
---
 
## 5. Components
 
### Buttons
*   **Primary:** Gradient of `primary` to `primary-container`. `on-primary` text. `full` roundedness. No shadow.
*   **Secondary:** Ghost style. Transparent background with a "Ghost Border" (15% `outline`). `secondary` text.
*   **Tertiary:** `surface-container-highest` background, no border. Subtle and integrated.
 
### Cards & Discovery Lists
*   **Rule:** Absolutely no divider lines. 
*   **Style:** Use `md` (0.75rem) or `lg` (1rem) rounded corners. Group related info using vertical white space. 
*   **Street Art Preview:** Images should have a subtle inner glow (`inset 0 0 20px rgba(0,0,0,0.5)`) to blend the photo into the dark UI.
 
### Navigation HUD (Custom Component)
Instead of a standard bottom bar, use a floating dock style. 
*   **Background:** `surface-container-high` at 80% opacity with a 20px backdrop blur.
*   **Active State:** Use a `primary` glow (4px blur) under the active icon, rather than a solid box.
 
### Input Fields
*   **Base:** `surface-container-lowest` (pure black).
*   **Focus State:** A 1px `primary` ghost border (40% opacity). The text cursor should be `secondary` (Electric Blue).
 
---
 
## 6. Do's and Don'ts
 
### Do
*   **DO** use extreme typographic contrast. A `display-lg` headline can sit right next to a `label-sm` coordinate.
*   **DO** let images of art be the hero. Use the UI as a dark, quiet frame.
*   **DO** use the `full` roundedness scale for interactive chips to create a "capsule" feel that mimics high-end GPS hardware.
 
### Don't
*   **DON'T** use pure white (#ffffff) for long-form body text. Use `on-surface-variant` (#adaaaa) to reduce eye strain in dark mode.
*   **DON'T** use traditional Material Design 2dp shadows. They look "cheap" in a premium dark mode. Use tonal shifts or large, blurry ambient shadows only.
*   **DON'T** use 1px dividers. If you need to separate content, use an 8px or 16px gap of empty `surface` space.