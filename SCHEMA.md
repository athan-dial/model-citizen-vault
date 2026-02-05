# Model Citizen Vault Schema

This document defines the folder structure, frontmatter schema, and workflow rules for the Model Citizen vault.

## Folder Taxonomy

The vault uses **workflow-based folders** (not topic categories). Notes move through folders as they progress from raw capture to published content.

### Workflow Stages

| Folder | Status Value | Description | Automation Writes | Human Reviews |
|--------|--------------|-------------|-------------------|---------------|
| `inbox/` | `inbox` | Raw captures, unprocessed | Yes | Weekly |
| `sources/` | `inbox` | Normalized source notes | Yes | As needed |
| `enriched/` | `enriched` | Notes with summaries, tags, quotes | Yes | As needed |
| `ideas/` | `idea` | Blog angles, outlines | Yes | Weekly |
| `drafts/` | `draft` | First outlines and full drafts | Yes | Before publish |
| `publish_queue/` | `publish` | Approved for publishing | No | Explicit approval |
| `published/` | `published` | Archive after publishing | No | Reference only |

### Folder Rules

1. **Automation writes to:** inbox/, sources/, enriched/, ideas/, drafts/
2. **Human explicitly moves to:** publish_queue/
3. **Archive (optional):** published/ (for removed content or historical reference)
4. **Nothing auto-publishes:** Human must move note to publish_queue/ OR set `status: publish`

## Frontmatter Schema

All notes MUST have YAML frontmatter with required fields.

### Required Fields (All Notes)

```yaml
---
title: "Note title"                    # Human-readable title
date: 2026-02-05                       # Creation date (YYYY-MM-DD)
status: "inbox"                        # Workflow state (see below)
tags: ["tag1", "tag2"]                 # Array of lowercase-kebab-case tags
---
```

### Status Values

| Status | Meaning | Folder |
|--------|---------|--------|
| `inbox` | Unprocessed raw capture | inbox/, sources/ |
| `enriched` | Has summary, tags, quotes | enriched/ |
| `idea` | Blog angle or outline | ideas/ |
| `draft` | In progress draft | drafts/ |
| `publish` | Approved for publication | publish_queue/ |
| `published` | Already published, archived | published/ |

### Source Notes (Additional Fields)

For notes in `sources/` folder (captured from external sources):

```yaml
---
title: "Note title"
date: 2026-02-05
status: "inbox"
tags: []
source: ""                             # Source type: YouTube | Email | Web | Manual
source_url: ""                         # Original source URL
---
```

### Enriched Notes (Additional Fields)

For notes in `enriched/` folder (processed by Claude):

```yaml
---
title: "Note title"
date: 2026-02-05
status: "enriched"
tags: ["topic-1", "topic-2"]
source: "YouTube"
source_url: "https://..."
summary: "1-2 sentence summary of the content"
---
```

### Idea Cards (Additional Fields)

For notes in `ideas/` folder (blog angles and outlines):

```yaml
---
title: "Idea: Blog Post Title"
date: 2026-02-05
status: "idea"
tags: ["topic-1", "topic-2"]
idea_angles:                           # Array of potential blog angles
  - "Angle 1: How to..."
  - "Angle 2: Why..."
related:                               # Array of wikilinks to source notes
  - "[[source-note-1]]"
  - "[[source-note-2]]"
---
```

### Draft Posts (Additional Fields)

For notes in `drafts/` folder (actual post content):

```yaml
---
title: "Draft: Blog Post Title"
date: 2026-02-05
status: "draft"
tags: ["topic-1", "topic-2"]
summary: "1-2 sentence summary for preview"
related:
  - "[[idea-card]]"
  - "[[source-note-1]]"
---
```

### Publish Queue (Minimal Changes)

Notes moved to `publish_queue/` should have:

```yaml
---
title: "Final Post Title"              # Clean title (no "Draft:" prefix)
date: 2026-02-05
status: "publish"                      # REQUIRED for Quartz to include
tags: ["topic-1", "topic-2"]
summary: "Preview text for listings"
---
```

## Tag Conventions

- **Format:** lowercase-kebab-case (e.g., `ml-systems`, `decision-frameworks`)
- **No spaces:** Use hyphens, not spaces or underscores
- **Consistent vocabulary:** Check existing tags before creating new ones
- **Hierarchy via prefix:** `product-strategy`, `product-metrics` (not nested folders)

### Common Tags

| Tag | Use For |
|-----|---------|
| `ml-systems` | Machine learning infrastructure, ML ops |
| `decision-frameworks` | Decision-making processes, frameworks |
| `product-strategy` | Product direction, roadmaps |
| `data-quality` | Data validation, integrity |
| `team-leadership` | Management, team dynamics |

## Publishing Rules

Content becomes public on the Quartz site if **BOTH** conditions are true:

1. Note is in `publish_queue/` folder
2. Frontmatter has `status: publish`

### Safety Guardrails

- **ignorePatterns in Quartz:** Folders inbox/, sources/, enriched/, ideas/, drafts/ are excluded from Quartz build
- **ExplicitPublish plugin:** Only notes with `status: publish` are rendered
- **No auto-publish:** Automation can move notes through workflow but NEVER to publish_queue/

### Publishing Checklist

Before moving a note to `publish_queue/`:

- [ ] Title is clean (no "Draft:" prefix)
- [ ] Status is set to `publish`
- [ ] Summary is written (used in listings)
- [ ] Tags are accurate and follow conventions
- [ ] Content is proofread
- [ ] All wikilinks resolve (or are removed)

## File Naming

- **Format:** lowercase-kebab-case (e.g., `understanding-metric-theater.md`)
- **No spaces:** Use hyphens, not spaces
- **No dates in filename:** Date is in frontmatter, not filename
- **Descriptive:** Filename should hint at content

### Examples

| Good | Bad |
|------|-----|
| `understanding-metric-theater.md` | `2026-02-05-metrics.md` |
| `claude-code-ssh-integration.md` | `Claude Code SSH Integration.md` |
| `idea-decision-velocity-blog.md` | `idea_decision_velocity_blog.md` |

## Wikilinks

- **Internal links:** Use Obsidian wikilinks: `[[note-name]]`
- **Display text:** Use pipe syntax: `[[note-name|Display Text]]`
- **Headings:** Link to headings: `[[note-name#Section]]`
- **External links:** Standard markdown: `[text](https://...)`

### Link Resolution

Quartz resolves wikilinks using "shortest" mode. This means:
- `[[metric-theater]]` resolves to `publish_queue/metric-theater.md`
- No need for full paths in wikilinks
- Duplicate filenames across folders may cause issues (avoid)

---

*Schema version: 1.0*
*Last updated: 2026-02-05*
