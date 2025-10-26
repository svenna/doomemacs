# Doom Emacs Configuration

My personal Doom Emacs configuration.

## Structure

```
.
├── config.el              # Main configuration file
├── init.el                # Doom modules selection
├── packages.el            # Package declarations
└── modules/               # Custom modules
    ├── markdown-preview.el # Markdown preview with Mermaid support
    └── claude.el          # Claude Code integration
```

## Features

### Claude Code Integration
- **AI-assisted development** with Claude directly in Emacs
- **IDE protocol** support via Monet (selections, diagnostics, diffs)
- **Terminal integration** with eat backend
- **Custom namespace**: `SPC k` for custom apps, `SPC k c` for Claude commands
- Full transient menu with all Claude commands

**Key bindings:**
- `SPC k c` - Open Claude command menu
  - Commands available: send region/buffer, fix errors, quick questions, etc.
- `SPC k m` - Monet server management
  - `SPC k m s` - Start monet server
  - `SPC k m k` - Stop monet server
  - `SPC k m l` - List active sessions

**Usage:**
1. Start monet server: `SPC k m s`
2. In your terminal, run `claude` and use `/ide` command to connect to Emacs
3. Select text in Emacs (visual mode `v` or mouse highlight)
4. Claude can now see your selections, diagnostics, and show diffs
5. Use `SPC k c` to send commands to Claude from Emacs

### Markdown Preview
- **Dark theme** preview with proper contrast
- **Mermaid diagram** support in markdown files
- **Standalone Mermaid** preview for `.mmd` files
- **Live preview** in Chrome (`SPC m p`)
- Uses Pandoc for markdown conversion
- Direct Mermaid.js rendering for `.mmd` files

### Editor Enhancements
- **X11 Primary Selection**: Mouse highlight + middle-click paste
- Tree-sitter support for TypeScript/TSX

## Installation

1. Install [Doom Emacs](https://github.com/doomemacs/doomemacs)
2. Clone this repo to `~/.config/doom`:
   ```bash
   git clone https://github.com/svenna/doomemacs.git ~/.config/doom
   ```
3. Install dependencies:
   ```bash
   # For markdown preview
   sudo apt install pandoc tidy

   # For Claude Code integration
   npm install -g @anthropic-ai/claude-code
   ```
4. Sync Doom:
   ```bash
   ~/.config/emacs/bin/doom sync
   ```
5. Restart Emacs

## Requirements

**For Markdown Preview:**
- Pandoc (for markdown conversion)
- Google Chrome (for preview)
- tidy (for HTML validation)

**For Claude Code:**
- [Claude Code CLI](https://github.com/anthropics/claude-code) (`npm install -g @anthropic-ai/claude-code`)
- Emacs 30.0+ (for claude-code.el and monet)

## Modules

Enabled Doom modules (see `init.el`):
- **Completion**: Corfu + Vertico
- **UI**: Treemacs, Doom modeline, VC-gutter
- **Editor**: Evil, Format on save, Snippets
- **Tools**: LSP, Magit, Tree-sitter
- **Lang**: Markdown (+grip), JavaScript, TypeScript, Python, Org, and more

## Customization Journey

This config is a work in progress. New features and tweaks are added as needed.

## License

MIT
