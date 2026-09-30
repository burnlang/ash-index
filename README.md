<p align="center">
    <img src="https://raw.githubusercontent.com/burnlang/burn/master/assets/logo.svg" alt="Burn logo" width="128">
</p>

# ash index

The list of packages that `ash search` finds.

Any git repository with a `burn.toml` is a package and can be installed with `ash install <name>` without being
listed here. The index only makes packages easy to find.

## Adding a package

1. Make sure the project is ready: `ash publish --tag` checks it and tags the version.
2. [Open an "Add a package" issue](../../issues/new?template=add-package.yml) and paste the git URL, for example
   `https://github.com/you/colors`.

A check runs right away. It clones the repository and confirms that:

- the repository is public and has a `burn.toml` at the top
- the `name` in `burn.toml` is where it is hosted (`github.com/you/colors` for the URL above), so
  `ash install github.com/you/colors` works
- `kind` is `"app"` or `"lib"` and the `main` file exists
- there is a description, from the issue or from `burn.toml`

When everything passes, the burnt bot opens a pull request with the entry, merges it and closes the issue. When
something is missing, the bot explains what in the issue; fix it and edit the issue to check again. An entry
that is already listed can only be changed by the package's owner or a maintainer of the index.

## Entries

Each package is one file, `packages/<domain>/<owner>/<project>.toml`:

```toml
name = "github.com/you/colors"
description = "Colored terminal output"
kind = "lib"
keywords = ["terminal", "color"]
```

| Key | Meaning |
| --- | --- |
| `name` | the package name, the same as the path of the file |
| `description` | one line about what it does |
| `kind` | `"lib"` for libraries, `"app"` for programs installed with `ash install -g` |
| `keywords` | words that `ash search` matches |

Pull requests that add entries by hand are checked the same way. Check entries locally with
`sh scripts/check.sh [files...]`, or a repository with `sh scripts/validate.sh <git-url>`.

## Maintaining

The `Add package` workflow needs the burnt bot, a GitHub App installed on this repository with read and write
access to contents, issues and pull requests. Its app ID is the repository variable `BURNT_APP_ID` and its
private key the secret `BURNT_PRIVATE_KEY`.

## License

[GNU General Public License v3.0](LICENSE)
