# Zed OpenTofu

An [OpenTofu](https://www.opentofu.org/) extension for [Zed](https://zed.dev).
Forked and adapted from the official [Terraform extension](https://github.com/zed-extensions/terraform).

## Installation and language server resolution

The extension resolves `tofu-ls` in this order:

1. A `tofu-ls` binary already available on your `PATH`
2. A previously downloaded `tofu-ls` binary cached by the extension
3. The latest compatible `tofu-ls` release from GitHub

This means the extension now works offline **after** `tofu-ls` has been installed once, either manually on your `PATH` or by letting Zed download it while online.

A first-time install still requires internet access unless you already have `tofu-ls` installed yourself.

## File association conflicts

In order to automatically use the OpenTofu extension and language server when editing `.tf`, `.tofu`, and `.tfvars` files, either uninstall the Terraform extension or add this to your `settings.json`:

```jsonc
"file_types": {
  "OpenTofu": ["tf", "tofu"],
  "OpenTofu Vars": ["tfvars"]
},
```

## Configuration

The extension forwards Zed LSP settings to `tofu-ls` under `lsp.tofu-ls.settings`.

Example:

```jsonc
"lsp": {
  "tofu-ls": {
    "settings": {
      "tofu": {
        "path": "/usr/local/bin/tofu",
        "timeout": "30s"
      },
      "indexing": {
        "ignoreDirectoryNames": ["vendor"]
      }
    }
  }
},
```

For the full list of supported `tofu-ls` settings, see the upstream docs:

- [OpenTofu language server usage](https://github.com/opentofu/tofu-ls/blob/main/docs/USAGE.md)
- [OpenTofu language server settings](https://github.com/opentofu/tofu-ls/blob/main/docs/SETTINGS.md)
- [OpenTofu language server installation](https://github.com/opentofu/tofu-ls/blob/main/docs/installation.md)

## Development

To develop this extension, see the [Developing Extensions](https://zed.dev/docs/extensions/developing-extensions) section of the Zed docs.
