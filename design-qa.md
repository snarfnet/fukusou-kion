**Findings**
- No actionable P0/P1/P2 findings remain.

**Source Visual Truth**
- Path: `qa/source-option-2.png`
- Source: selected Image Gen option 2, doctor-first heatstroke prevention mobile UI.

**Implementation Evidence**
- Local URL: `http://127.0.0.1:5173/`
- Screenshot path: `qa/implementation-390x844.png`
- Comparison path: `qa/comparison-source-implementation.png`
- Viewport: `390 x 844`
- State: home tab, default outdoor-work mode, no symptoms selected.

**Full-View Comparison Evidence**
- The comparison image places the selected visual target on the left and the implementation on the right.
- The implementation preserves the doctor-led clinical header, WBGT risk summary, hourly WBGT strip, activity chips, action-plan rows, and bottom navigation.
- The implementation adds a discreet AdMob placeholder lower in the scroll flow as requested for the future free app model.

**Focused Region Comparison Evidence**
- Header: doctor portrait, monitoring badge, physician name, and short advice copy are present. The image crop differs slightly from the mock but keeps the same medical guidance role.
- Risk panel: red WBGT tile, large danger label, and three immediate actions match the source hierarchy.
- Action plan: timers, toggles, and quick logging actions are implemented. Density is slightly taller than the source because the coded version exposes interactive controls.
- Bottom nav: five-item navigation and active home state match the source structure.

**Required Fidelity Surfaces**
- Fonts and typography: Japanese system sans-serif stack is readable and close to the mock's healthcare UI style. Weights, hierarchy, and line wrapping are stable at 390px.
- Spacing and layout rhythm: section order and density follow the source. Header height was reduced after QA so more of the plan appears in the first viewport.
- Colors and visual tokens: white clinical surface, medical blue, red danger, amber warning, green safe states, and light gray borders map to the source palette.
- Image quality and asset fidelity: a generated doctor portrait is used as a real raster asset, not CSS art or placeholder UI. Crop is acceptable and sharp.
- Copy and content: Japanese app text reflects heatstroke prevention, WBGT, hydration, rest, symptoms, SOS, and future ad placement.

**Patches Made Since Previous QA Pass**
- Reduced header height and tightened content spacing.
- Adjusted doctor image crop so the face remains visible without pushing risk content too far down.
- Rebuilt after CSS changes.
- Added `AdMobBanner` with placement id `home-after-safety-actions`.
- Moved ad messaging into a low-priority banner after symptom check and SOS guidance.
- Added settings copy that states ads are free-version only and do not overlap danger, symptoms, or SOS.

**Implementation Checklist**
- Build passed with `npm run build`.
- Browser check passed at `390 x 844`.
- Activity mode switch updates WBGT and risk text.
- Symptom selection shows a warning after multiple symptoms.
- Emergency modal opens and closes.
- Settings bottom navigation opens its panel.
- Ad placement verified: banner is below safety actions, not in the first critical decision area.
- Console errors: none observed.

**Follow-up Polish**
- The implementation shows slightly less lower-page content in the first viewport than the generated mock because quick-log buttons and future ad placement add real interaction weight. This is acceptable for the prototype and can be tuned after product priorities settle.

final result: passed
