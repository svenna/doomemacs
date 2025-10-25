# Doom Emacs Configuration

My personal Doom Emacs configuration.

## Structure

```
.
├── config.el              # Main configuration file
├── init.el                # Doom modules selection
├── packages.el            # Package declarations
└── modules/               # Custom modules
    └── markdown-preview.el # Markdown preview with Mermaid support
```

## Features

### Markdown Preview
- **Dark theme** preview with proper contrast
- **Mermaid diagram** support
- **Live preview** in Chrome (`SPC m p`)
- Uses Pandoc for conversion

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
   ```
4. Sync Doom:
   ```bash
   ~/.config/emacs/bin/doom sync
   ```
5. Restart Emacs

## Requirements

- Pandoc (for markdown conversion)
- Google Chrome (for preview)
- tidy (for HTML validation)

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
