# Paper MCP preflight

The Paper MCP supplies the canvas tools. This skill names them by short name (`get_basic_info`, `write_html`, `update_styles`, `duplicate_nodes`, `get_screenshot`); the prefix depends on how Paper is installed.

Before the first canvas call in a session:

1. Load Paper's guide with `get_guide` (topic `paper-mcp-instructions`). It carries the server's current rules for writing HTML to the canvas.
2. Call `get_basic_info` to learn the file, its artboards and the fonts it lists.
3. Call `get_font_family_info` before the first typographic styling, and prefer fonts listed in `get_basic_info`. Check that a chosen font exists in Paper; a font that is not available falls back silently and ruins the typography.

While working:

- One visual group per `write_html` call. Prefer `duplicate_nodes` with `update_styles` and `set_text_content` over rewriting HTML.
- Review with `get_screenshot` after meaningful changes. Take exact sizes and colours from `get_jsx` and `get_computed_styles`, never from a screenshot.
- Paper's HTML import is reliable with flex layout and `gap`; use those for structure.
- When a batch of edits is finished, call `finish_working_on_nodes`.
- Refer to artboards by name when talking to the user. Raw node IDs mean nothing to them; keep IDs for the Canvas Map in `DESIGN_SYSTEM.md`.

If no Paper tools are available, stop and say the Paper MCP is not connected. This skill's output is the canvas, and a markdown-only design system is not what was asked for. Offer `--system-only` if the user wants just `DESIGN_SYSTEM.md`.
