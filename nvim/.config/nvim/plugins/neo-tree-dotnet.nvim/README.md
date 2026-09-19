# neo-tree-dotnet.nvim

A .NET solution source for [Neo-tree](https://github.com/nvim-neo-tree/neo-tree.nvim).
Switch between the ordinary file explorer and a logical C# solution tree in the same sidebar.

Polski przewodnik po kodzie, Neovimie i Neo-tree: [JAK_TO_DZIALA.md](JAK_TO_DZIALA.md).

Supports `.sln`, `.slnx`, nested solution folders, solution items, multiple-solution selection,
lazy directory loading, file/split/tab opening, refresh, and revealing files by their physical path.
Project content can come from the filesystem or asynchronous MSBuild evaluation.

## Requirements

- Neovim 0.10+.
- Neo-tree v3.x and its normal dependencies (`nui.nvim`, `plenary.nvim`).
- .NET SDK 8+ only for `project_files = "msbuild"`.
- A Nerd Font for the optional icons.

## Install with lazy.nvim

Keep this directory in a stable location. Add it as a **local dependency** of your existing
Neo-tree spec and merge the configuration below into your existing setup:

```lua
return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
    { dir = "/absolute/path/to/neo-tree-dotnet.nvim", name = "neo-tree-dotnet.nvim" },
  },
  opts = {
    sources = { "filesystem", "buffers", "git_status", "dotnet_solution" },
    source_selector = {
      winbar = true,
      sources = {
        { source = "filesystem", display_name = " Files " },
        { source = "dotnet_solution", display_name = " Solution " },
      },
    },
    dotnet_solution = {
      project_files = "filesystem",
      -- window = { position = "right" },
      -- solution = "/absolute/path/MyApp.slnx", -- optional fixed solution
    },
  },
  keys = {
    { "<leader>e", function() require("neo-tree-dotnet").toggle_panel() end,
      desc = "Toggle Neo-tree panel (remember view)" },
    { "<leader>E", function() require("neo-tree-dotnet").toggle() end,
      desc = "Neo-tree: files / .NET solution" },
  },
}
```

If your spec already has a `config = function() require("neo-tree").setup(...) end`,
add these options to that `setup` table instead of adding a separate `opts` table.
There is no separate `require("neo-tree-dotnet").setup()` call.

## Use

- `:NeotreeDotnetToggle` — switch between `filesystem` and `dotnet_solution`.
- `:NeotreeDotnetPanelToggle` — hide/show the panel, preserving its source and side per tab.
- `:Neotree dotnet_solution` or `:NeotreeDotnet` — open the solution source.
- `:NeotreeDotnet /absolute/path/MyApp.slnx` — pin a specific solution for this tab.
- `:Neotree filesystem` — ordinary file explorer.

Discovery searches the current tree root and then its ancestors. If several solutions
exist at the nearest matching level, a picker appears. Canceling leaves the panel open;
press `gs` to choose again. Discovery does not recursively scan subdirectories.
The filesystem source retains its normal Neo-tree settings, including `bind_to_cwd`.

| Key in solution view | Action |
| --- | --- |
| `Enter`, `o`, double-click | Expand a folder/project or open a file |
| `Space` | Expand/collapse |
| `s`, `S`, `t` | Open file in vertical split, split, tab |
| `O` | Open selected `.sln`/`.slnx` or `.csproj` definition |
| `R` | Reload solution and previously loaded project folders |
| `gs` | Choose solution |
| `gf` | Switch to filesystem |
| `<`, `>` | Neo-tree previous/next source |
| `?` | Help |

Writes in Neovim trigger a debounced refresh. Use `R` after external changes.
Loaded folder expansion is preserved across refreshes and source switches.
The solution view follows the current editor file automatically: it loads missing
ancestors, expands the path, and selects the file without taking editor focus.
Hidden panels stay hidden; reopening reveals the latest file. Files outside the
selected solution do not change its root or selection. Disable with
`dotnet_solution.follow_current_file = { enabled = false }`.
Use `require("neo-tree-dotnet").toggle_panel()` or `:NeotreeDotnetPanelToggle`
to hide/show without switching the source. It remembers the actually displayed view
and panel side independently in each Neovim tab, including native selector clicks
and automatic closing after opening a file. This memory lasts for the current Neovim
session; it is not saved to disk. Plain `:Neotree toggle` targets the default source,
while Neo-tree's `last` tracks the last command globally across tabs.
File creation, deletion, moving, and renaming belong to the ordinary filesystem view.
Virtual solution folders must not be treated as physical directories.

To reveal an existing file in the logical tree:

```lua
require("neo-tree.command").execute({
  source = "dotnet_solution",
  reveal_file = vim.api.nvim_buf_get_name(0),
})
```

## Project content modes

`filesystem` (default) is fast, works without .NET, and scans one project directory at
a time. It shows physical files, including files excluded from compilation, and omits
`bin`, `obj`, `.git`, `.vs`, and `node_modules`. It does not add external linked files.

`msbuild` requests evaluated items using `dotnet msbuild -getItem:... -getProperty:...`.
It accounts for imported properties, conditions, globs, `Compile Remove`, and `Link`
metadata. It also adds a Dependencies node with evaluated package/project references.
No build or restore target is invoked; the referenced SDK/imports must be installed.
Evaluation runs only when a project is expanded or a file is revealed.

```lua
dotnet_solution = {
  project_files = "msbuild",
  dotnet_command = "dotnet",
  msbuild_timeout = 30000,
  msbuild_properties = {
    Configuration = "Debug",
    -- TargetFramework = "net8.0",
  },
}
```

For multi-target projects, the first `TargetFrameworks` entry is used unless
`TargetFramework` is explicitly configured. Package versions are declared/evaluated
versions, not a complete transitive NuGet dependency graph. MSBuild failures appear
in the tree and a notification; `R` retries. The plugin does not silently substitute
physical files for an unsuccessful evaluation.

Not included: `.slnf`, automatic external filesystem watching, refactoring/namespace
updates, generated files created only during a build, or full Visual Studio project
system parity. XML DTDs and external entities are intentionally unsupported.

## Tests

The Neo-tree source handles editor events and solution selection; `view.lua` owns
the model and lazy rendering lifecycle. `project.lua` converts filesystem/MSBuild
content into nodes, while `msbuild.lua` owns only the external process and JSON.
Defaults live in `sources/dotnet_solution/defaults.lua`. Public commands and mappings
continue to use `require("neo-tree-dotnet")`.

```sh
make test
# If dependencies are outside stdpath("data")/lazy:
NEOTREE_TEST_DEPS=/path/to/dependency-parent make test
```

Tests run headless Neovim with real Neo-tree/Nui and the installed .NET SDK. Fixtures
cover solution parsing, physical/logical mapping, source switching, expansion state,
linked/excluded files, multiple solutions, and delayed evaluation after switching views.
The example package in the fixture is evaluated only and is never downloaded.
