# oz.nvim

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/luxluth/oz.nvim/lint-test.yml?branch=main&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

A neovim plugin for the oz programming language

> It's not a complete implementation but it can do the job for now

## Configuration

Default configuration options

```lua
opts = {
  ozengine_path = "ozengine",
  show_compiler_output = true,
  linter = false,
  keymaps = {
    feed_selection_mapping = "<C-r>",
  },
}
```

## Commands

Some available commands:

- `OzEnginePath` to get the current ozengine path
- `OzFeedFile` to feed the current oz buffer to the engine
- `OzEngineRestart` to restart the engine

## Dependencies

The plugin depends on the `socat` command to send code to the ozengine. The plugin is only
tested on linux for the moment.

## TODOs

- [x] simple connection to the ozengine
- [x] code feeding
- [ ] linting
- [ ] compiler output into a different buffer
- [ ] more platform support

## Contributing

Feel free to send a pr.

---

Licence: MIT
