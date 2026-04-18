# App UI Kit — Rlabs Studio

Product dashboard. Operators deploy, observe, and audit agents.

## Components

- `Sidebar.jsx` — fixed left nav with section list + user block
- `TopBar.jsx` — section header with search and primary CTA
- `Overview.jsx` — metric cards + throughput bar chart
- `Agents.jsx` — agent list table with status badges
- `Transactions.jsx` — transaction stream with hashes, chains, status

## Usage

Open `index.html`. The sidebar is interactive — click between sections (overview, agents, transactions) to see different views.

## Notes

- Dark-first to match operator workflows.
- Tables use hairline dividers instead of shadows. Rows hover-lighten.
- Tabular numerics (`font-variant-numeric: tabular-nums`) everywhere numbers appear.
- Model names and chains are in mono type; agent names are body type.
