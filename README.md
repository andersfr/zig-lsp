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
