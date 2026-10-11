# Component Library artboard

Read in Phase 2b. Build a separate artboard named "Component Library" showing every reusable component in all its states, one component group per `write_html` call:

1. Buttons: Primary, Secondary, Ghost, Destructive in default, hover, active, disabled, loading
2. Inputs: Text, Password, Textarea, Select in default, focus, filled, error, disabled
3. Form elements: Checkbox, Radio, Toggle in on, off, disabled
4. Cards: default, hover, selected, with and without image, compact
5. Badges and tags: success, warning, error, info, neutral
6. Avatars: sm, md, lg; image, initials, status indicator
7. Navigation items: default, hover, active, with icon, with badge count
8. Modals and dialogs: confirmation, form, alert (the chrome only)
9. Toasts: success, error, warning, info
10. Empty states: illustration placeholder, message, call to action

Put a label with the component name and state above each. Group states horizontally, component types vertically.

Toggles: Paper renders HTML statically, so `justify-content: flex-end` may not put the knob on the right. Build "off" and "on" as explicit layouts (knob on the left, knob on the right, e.g. a fixed-width spacer before it) and check with a screenshot.

Dark variant: duplicate the artboard, rename it "Component Library / Dark" and apply the dark tokens (backgrounds, text, borders, lighter shadows). Prefer Paper tokens (`create_tokens` / `set_tokens`) for the light and dark pair so dark variants are a mode switch rather than a rewrite; fall back to `update_styles` per node if tokens are unavailable. Screenshot both.
