# Beadspace v2

A drop-in dashboard for [Beads](https://github.com/steveyegge/beads) issue tracking. One HTML file, zero build tools, works on GitHub Pages.

> Fork of [cameronsjo/beadspace](https://github.com/cameronsjo/beadspace) with dependency graph visualization, analytics, and keyboard-driven navigation.

![Dashboard](https://img.shields.io/badge/zero_dependencies-pure_HTML%2FCSS%2FJS-6366f1)

## What You Get

### 5 Views

- **Dashboard**: Stats, triage suggestions (auto-flags cascade unblocks, misprioritized items), active issues sorted by impact score, SVG donut chart, priority/type bars, epic progress
- **Issues Table**: Search, filter by status, sort by any column, vim-style j/k navigation
- **Dependency Graph**: Force-directed canvas visualization with pan/zoom/drag, search highlighting, status filters, critical path overlay, arrowheads
- **Epics**: Collapsible epic cards with child issue lists and progress bars
- **Insights**: Graph health metrics, critical path visualization, top bottlenecks, cascade unblock analysis, impact ranking

### Keyboard-First

| Key | Action |
|-----|--------|
| `1-5` | Switch views |
| `j / k` | Navigate issues table |
| `Enter` | Open selected issue |
| `Cmd+K` | Quick-jump palette (fuzzy search) |
| `/` | Focus search |
| `f` | Fit graph to view |
| `l` | Toggle graph labels |
| `t` | Toggle theme |
| `?` | Keyboard shortcuts help |

### Analytics

- **PageRank**: Identifies most important issues in the dependency graph
- **Impact Score**: Weighted composite (PageRank + blocker ratio + dependency complexity + staleness + priority)
- **Critical Path**: Longest blocking chain — the bottleneck sequence
- **Cascade Unblock**: "If I close this issue, how many others become unblocked?"
- **Blocked Chain Depth**: How deep is the dependency chain blocking each issue?

### Other Features

- **Detail drawer**: Full issue view with description, dependencies, comments, metrics, clickable navigation between linked issues
- **URL deep-linking**: `#issue/winzy.ai-xxx` opens the drawer directly, browser back/forward works
- **Light & dark mode**: OS preference + manual toggle with localStorage persistence
- **Animated counters**: Stat values, bar fills, and donut segments animate on load
- **Fully dynamic**: Reads JSON at page load, no build step to change the UI

## Quick Start (Local)

```bash
# Generate the data files
bd export | jq -s '.' > issues.json
echo '[]' > deps.json   # Optional: dependency data
echo '[]' > events.json  # Optional: event data

# Serve locally (fetch won't work from file://)
python3 -m http.server 8080
# Open http://localhost:8080
```

The dashboard works with just `issues.json`. Dependencies (`deps.json`) and events (`events.json`) are optional — the graph, epics, and insights views light up when dependency data is available.

## Install

```bash
curl -sL https://raw.githubusercontent.com/Gabko14/beadspace/main/install.sh | bash
```

This creates `.beadspace/` with the dashboard, adds the GitHub Actions workflow, and generates data files from your `.beads/` directory.

Custom directory:

```bash
BEADSPACE_DIR=docs/dashboard curl -sL https://raw.githubusercontent.com/Gabko14/beadspace/main/install.sh | bash
```

After install, enable GitHub Pages:

```bash
gh api repos/{owner}/{repo}/pages -X POST -f "build_type=workflow"
```

Or: Settings > Pages > Source: **"GitHub Actions"** (not "Deploy from a branch").

Your dashboard will be at `https://{owner}.github.io/{repo}/`.

## How It Works

```
.beads/issues.jsonl              ──(GH Action)──>  .beadspace/issues.json
.beads/backup/dependencies.jsonl ──(GH Action)──>  .beadspace/deps.json     ──(fetch)──>  index.html
.beads/backup/events.jsonl       ──(GH Action)──>  .beadspace/events.json                 (dashboard)
```

- `index.html` is a static file — all logic runs client-side in vanilla JS
- `issues.json` is required (same schema as `bd export` JSONL, wrapped in `[]`)
- `deps.json` and `events.json` are optional — the dashboard degrades gracefully without them
- The GitHub Action reads from `.beads/` directly — no `bd`/`br` CLI needed in CI

## Triage Suggestions

The dashboard auto-flags items that need attention:

| Severity | Pattern | Example |
|----------|---------|---------|
| Alert | Cascade unblock >= 2 | Closing this issue unblocks 3 others |
| Alert | P0/P1 open > 3 days | Critical bug sitting untouched |
| Alert | Blocks 3+ tasks | High-impact bottleneck |
| Warning | Bug at P3+ | Bugs that probably need promotion |
| Info | Non-backlog open > 7 days | Stale items that need attention or demotion |

## Customization

Edit `index.html` directly — it's self-contained.

### CSS Variables

All colors, fonts, and spacing are controlled by CSS custom properties in `:root`. Change the theme by editing those values.

### Adding Views

The navigation system is data-driven. To add a view:

1. Add a `<button class="nav-tab" data-view="myview">` to the nav
2. Create a render function that returns HTML for `<div id="view-myview" class="view">`
3. Call it in the bootstrap `init()` function

## Attribution

Forked from [cameronsjo/beadspace](https://github.com/cameronsjo/beadspace). Original concept inspired by [beads-viz-prototype](https://github.com/mattbeane/beads-viz-prototype) by [@mattbeane](https://github.com/mattbeane).

## License

MIT
