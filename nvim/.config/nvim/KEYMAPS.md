# Keymaps

## Diagnostics

| Keymap | Action |
|---|---|
| `]d` / `[d` | next / previous diagnostic, with a popup |
| `]e` / `[e` | next / previous error only, skipping warnings |
| `gl` | full message for the current line in a popup |
| `<leader>ca` | code action / quick fix (also works on a selection) |
| `<leader>fd` | diagnostics in the current file (picker) |
| `<leader>fD` | diagnostics in the whole project (picker) |
| `<leader>q` | file diagnostics to the location list |

Built into nvim 0.12: `<C-w>d` popup, `gra` code action, `grn` rename.

## Formatting

| Keymap | Action |
|---|---|
| `<leader>cf` | format buffer (also runs on save) |

C/C++ use `clang-format`; without a `.clang-format` file the LLVM style applies.
