# NutriNutri Landing Page

This is the official landing page for NutriNutri, built with Astro and styled with Vanilla CSS (Glassmorphism design).

## Structure
- `src/pages/index.astro`: Main landing page components.
- `src/layouts/Layout.astro`: Global styles, fonts, and layout.
- `public/img/`: SVG placeholders for screenshots and logo.

## Development

1. Install dependencies:
   ```bash
   bun install
   ```

2. Start local server:
   ```bash
   bun run dev
   ```

## Deployment on Cloudflare Pages

1. **Connect Repository**: Link your GitHub repository to Cloudflare Pages.
2. **Build Configuration**:
   - **Framework Preset**: Astro
   - **Build Command**: `bun run build` (or `npm run build`)
   - **Build Output Directory**: `dist`
3. **Environment**:
   - Ensure you select a Node.js version compatible with Astro if not using Bun on CI (Node 20+ recommended). Cloudflare Pages usually detects Astro automatically.

## Customization

- Replace images in `public/img/` with actual screenshots.
  - `desktop-placeholder.svg` -> Desktop screenshot (16:9)
  - `mobile-placeholder-1.svg` -> Mobile screenshot (9:19.5)
- Update links in `src/pages/index.astro` to point to the correct release URLs when live.
