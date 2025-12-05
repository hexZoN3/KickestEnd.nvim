# KickestEnd.nvim

## Neovim Custom Keymaps

A collection of custom keymaps and configurations for Neovim aimed at improved buffer handling, window management and clipboard management. These keymaps are written in Lua for Neovim ≥0.7 and include enhanced smart buffer/file handling and more.

---

## Features

### Navigation

- Smooth scrolling with centered cursor: `<leader>j` / `<leader>k`
- Enhanced search: `n` / `N` keeps cursor centered
- Move lines visually: `J` / `K` in visual mode
- Switch between splits quickly: `<leader><Tab>` / `<Tab>`

### Buffer Management

- Smart buffer switch using Telescope: `<leader><leader>`
- Better buffer handling with Neotree and Telescope pickers:
  - Open files in new tabs by default.
  - Open file in split mode by pressing `h` or `v` on the file.
- Create new empty buffers in splits or tabs:
  - Horizontal: `<leader>sv`
  - Vertical: `<leader>sh`
  - New tab: `<leader>e`
- Better visual editor like saving:
  - `<leader>w` — Save current buffer (prompts if new)
  - `<leader>W` — Save As (prompts if new)
- Better safe closing:
- `<leader>qy` — Save and quit
  - `<leader>qn` — Quit without saving

### Clipboard & Copying

- Copy current line: `Y` (normal mode)
- Copy selection: `Y` (visual mode, trims extra newlines)
- Select all and copy: `<leader>lY` (entire buffer without trailing newline)
- Paste from clipboard: `<leader>P` (at cursor, or over selection without yanking it)
- Paste over selection without yanking replaced text: `<leader>p`

### Pastebin

- Use :Pastebin command to upload the filetext to a server and get a URL to it (check lua/pastebin.lua)

### Diagnostics

- `[d` / `]d` — Navigate diagnostics
- `<leader>de` — Open diagnostic floating window
- `<leader>dq` — Set location list for diagnostics

---

## Keymaps Overview

### Normal Mode Keymaps

| Key                | Action              | Description                                                      |
| ------------------ | ------------------- | ---------------------------------------------------------------- |
| `J`                | Join line           | Join current line with next without moving cursor                |
| `<leader>j`        | Scroll down         | `<C-d>` + center cursor                                          |
| `<leader>k`        | Scroll up           | `<C-u>` + center cursor                                          |
| `n` / `N`          | Search              | Keep cursor centered on matches                                  |
| `Y`                | Copy line           | Copy current line to system clipboard                            |
| `<leader>lY`       | Copy all            | Select entire buffer and copy to clipboard (no trailing newline) |
| `<leader>w`        | Save                | Save current buffer (prompts if new)                             |
| `<leader>q`        | Quit                | Close buffer (prompts if modified)                               |
| `<leader>qy`       | Save & quit         | Save and close buffer                                            |
| `<leader>qn`       | Quit without saving | Discard changes and close buffer                                 |
| `<leader><leader>` | Smart buffer switch | Open Telescope buffer switcher                                   |
| `gf`               | Smart file open     | Open file under cursor in current/new tab                        |

### Visual Mode Keymaps

| Key         | Action         | Description                                               |
| ----------- | -------------- | --------------------------------------------------------- |
| `J` / `K`   | Move selection | Move selected lines up or down                            |
| `Y`         | Copy selection | Copy selected text to system clipboard (no extra newline) |
| `<leader>p` | Paste          | Paste over selection without yanking replaced text        |
| `<leader>P` | Paste          | Paste from clipboard without replacing selection          |

### Split/Window Management

| Key             | Action           | Description                    |
| --------------- | ---------------- | ------------------------------ |
| `<leader>sv`    | Horizontal split | New empty buffer below current |
| `<leader>sh`    | Vertical split   | New empty buffer to the right  |
| `<leader>t`     | New terminal     | Open terminal in new tab       |
| `<leader><Tab>` | Switch splits    | Switch to next window          |
| `<Tab>`         | Switch splits    | Switch to previous window      |

### Diagnostics Keymaps

| Key          | Action        | Description                                |
| ------------ | ------------- | ------------------------------------------ |
| `[d` / `]d`  | Previous/Next | Go to previous/next diagnostic             |
| `<leader>de` | Float         | Show diagnostic message in floating window |
| `<leader>dq` | Location list | Set location list for diagnostics          |

---

## Contributing

Contributions, bug reports, and suggestions are welcome. Please open an issue or submit a pull request if you have improvements for keymaps, new features, or optimizations.

## License

MIT License — feel free to use and modify these keymaps in your own Neovim setup.

