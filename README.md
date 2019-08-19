# zig-lsp
Language Server Protocol for Zig

## Setup
```sh
git clone https://github.com/andersfr/zig-flat-hash.git
zig build-exe --single-threaded --release-fast parser.zig
zig build-exe --single-threaded --release-fast server.zig
```

#### Vim
Configuration for 'prabirshrestha/vim-lsp'

```vim
if executable('zig-lsp')
  au User lsp_setup call lsp#register_server({
        \ 'name': 'zig-lsp',
        \ 'cmd': {server_info->['FULL_PATH_TO_SERVER_EXECUTABLE']},
        \ 'whitelist': ['zig'],
        \ })
```

#### VSCode
Download zig-0.1.0.vsix from this repo: https://github.com/andersfr/vscode-zig
Install the extension

Note: The extension assumes that `zig-lsp` is in your path. This corresponds to the `server` component of this project.

Credits: This is a fork from https://github.com/gernest/vscode-zig with minimal additions.

#### Atom IDE
Will be posted once a proper language-zig package exists.

## Implemented
- [x] LSP server
- [x] Lexer diagnostics
- [x] Parser diagnostics
- [ ] Imported files
- [ ] Semantic diagnostics
- [ ] Symbol information
- [ ] Symbol renaming
- [ ] Completion
- [ ] Signature help
- [ ] References
- [ ] Go to implementation

#### How does it work
The grammars are written in LALR using a custom tool that converts the `ziglang.zig` and `jsonlang.zig` definition files into the `*_grammar.*.zig` files. Textual representations of the LALR rules are in `zig_grammar.txt` and `json_grammar.txt`.

The Zig parser has a best-effort recovery mechanism. Currently it has severe limitations on unmatched braces, brackets, and parentheses. Fortunately most editors will automatically close these tokens and circumvent the problem. This is planned to be fixed in future versions.
