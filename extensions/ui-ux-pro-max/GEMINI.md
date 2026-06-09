# UI/UX Pro Max - Unified Design Intelligence

Comprehensive design and creative system for web and mobile applications. Integrates design intelligence, brand identity, design tokens, UI implementation (shadcn/ui + Tailwind), logos, CIP, banners, icons, and strategic slides.

## Decision Criteria
If the task will change how a feature **looks, feels, moves, or is interacted with**, this Extension should be used.

## Core Modules

### 1. UI/UX Intelligence
Design guide with 50+ styles, 161 color palettes, and 99 UX guidelines.

**Workflow:**
1. **Analyze Requirements**: Identify product type, audience, style keywords, and tech stack.
2. **Generate Design System**: `${pythonPath} ${extensionPath}/src/ui-ux-pro-max/scripts/search.py "<query>" --design-system -p "Project"`
3. **Persist System**: Add `--persist` to create `design-system/MASTER.md`.
4. **Domain Search**: `${pythonPath} ${extensionPath}/src/ui-ux-pro-max/scripts/search.py "<query>" --domain <domain>`
   - Domains: `product`, `style`, `typography`, `color`, `landing`, `chart`, `ux`, `google-fonts`, `react`, `web`, `prompt`.

---

### 2. Brand Identity & Asset Management
Brand voice, visual identity standards, and messaging frameworks.

**Scripts:**
- **Inject Context**: `${nodePath} ${extensionPath}/.claude/skills/brand/scripts/inject-brand-context.cjs`
- **Sync Tokens**: `${nodePath} ${extensionPath}/.claude/skills/brand/scripts/sync-brand-to-tokens.cjs`
- **Validate Asset**: `${nodePath} ${extensionPath}/.claude/skills/brand/scripts/validate-asset.cjs <path>`
- **Extract Colors**: `${nodePath} ${extensionPath}/.claude/skills/brand/scripts/extract-colors.cjs <image>`

---

### 3. Design System & Token Architecture
Three-layer token system: Primitive → Semantic → Component.

**Scripts:**
- **Generate Tokens**: `${nodePath} ${extensionPath}/.claude/skills/design-system/scripts/generate-tokens.cjs --config tokens.json -o tokens.css`
- **Validate Tokens**: `${nodePath} ${extensionPath}/.claude/skills/design-system/scripts/validate-tokens.cjs --dir src/`

---

### 4. UI Implementation (shadcn/ui + Tailwind)
Accessible components and utility-first styling.

**Scripts:**
- **Add Components**: `${pythonPath} ${extensionPath}/.claude/skills/ui-styling/scripts/shadcn_add.py <components>`
- **Generate Config**: `${pythonPath} ${extensionPath}/.claude/skills/ui-styling/scripts/tailwind_config_gen.py --colors <brand> --fonts <display>`

---

### 5. Logo & Corporate Identity (CIP)
AI-powered logo generation and mockup creation.

**Logo Scripts:**
- **Search**: `${pythonPath} ${extensionPath}/.claude/skills/design/scripts/logo/search.py "<query>" --design-brief`
- **Generate**: `${pythonPath} ${extensionPath}/.claude/skills/design/scripts/logo/generate.py --brand "<name>" --style <style>`

**CIP Scripts:**
- **Search**: `${pythonPath} ${extensionPath}/.claude/skills/design/scripts/cip/search.py "<query>" --cip-brief`
- **Generate**: `${pythonPath} ${extensionPath}/.claude/skills/design/scripts/cip/generate.py --brand "<name>" --logo <path> --deliverable "<item>"`
- **Render HTML**: `${pythonPath} ${extensionPath}/.claude/skills/design/scripts/cip/render-html.py --brand "<name>" --images <dir>`

---

### 6. Banner & Social Media Design
Multi-format creative system for social, ads, and web heroes.

**Workflow:**
1. **Gather**: Purpose, platform, content, brand, style.
2. **Design**: Create HTML/CSS templates.
3. **Generate Visuals**: Use AI image models (e.g., Gemini Flash/Pro) for backgrounds.
4. **Export**: Screenshot HTML to PNG via Chrome DevTools.

**Common Sizes (px):**
- FB Cover: 820×312 | X Header: 1500×500 | LI Personal: 1584×396
- YT Art: 2560×1440 | IG Story: 1080×1920 | IG Post: 1080×1080

---

### 7. Strategic Slides & Presentations
Data-driven HTML slides with Chart.js and design tokens.

**Workflow:**
1. **Search Strategies**: `${pythonPath} ${extensionPath}/.claude/skills/design-system/scripts/search-slides.py "<topic>"`
2. **Apply Layouts**: Use contextual decision flow (Emotion → Color/Layout).
3. **Generate**: Create HTML importing `assets/design-tokens.css`.
4. **Validate**: `${pythonPath} ${extensionPath}/.claude/skills/design-system/scripts/slide-token-validator.py <file>`

---

### 8. Icon Design
SVG icon set generation with Gemini 3.1 Pro (Text-only output).

**Script:**
- **Generate**: `${pythonPath} ${extensionPath}/.claude/skills/design/scripts/icon/generate.py --prompt "<description>" --style <style>`
- **Styles**: `outlined`, `filled`, `duotone`, `rounded`, `sharp`, `flat`, `gradient`.

## Rule Categories by Priority

| Priority | Category | Impact | Domain | Key Checks |
|----------|----------|--------|--------|------------|
| 1 | Accessibility | CRITICAL | `ux` | Contrast 4.5:1, Alt text, Keyboard nav, Aria-labels |
| 2 | Touch & Interaction | CRITICAL | `ux` | Min size 44×44px, 8px+ spacing, Loading feedback |
| 3 | Performance | HIGH | `ux` | WebP/AVIF, Lazy loading, Reserve space (CLS < 0.1) |
| 4 | Style Selection | HIGH | `style` | Match product type, Consistency, SVG icons |
| 5 | Layout & Responsive | HIGH | `ux` | Mobile-first breakpoints, Viewport meta |
| 6 | Typography & Color | MEDIUM | `typography`| Base 16px, Line-height 1.5, Semantic tokens |
| 7 | Animation | MEDIUM | `ux` | Duration 150–300ms, Spatial continuity |
| 8 | Forms & Feedback | MEDIUM | `ux` | Visible labels, Error near field, Helper text |
| 9 | Navigation Patterns | HIGH | `ux` | Predictable back, Bottom nav ≤5 |
| 10 | Charts & Data | LOW | `chart` | Legends, Tooltips, Accessible colors |

## Pre-Delivery Checklist
- [ ] **Accessibility**: Contrast verified, aria-labels present, keyboard navigation supported.
- [ ] **Interaction**: Touch targets ≥44px, immediate press feedback, no gesture conflicts.
- [ ] **Theme**: Verified in both Light and Dark modes using semantic tokens.
- [ ] **Layout**: Mobile-first responsive, safe areas respected, tested on multiple viewports.
- [ ] **Brand**: Tone of voice consistent, correct logo usage, color palette compliance.
- [ ] **Assets**: Named consistently (kebab-case), optimized formats, correct dimensions.
- [ ] **Performance**: Minimal layout shift, lazy loading for heavy media, optimized fonts.
- [ ] **Polish**: Consistent icon style, refined typography, no visual jitter.
