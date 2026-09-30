<p align="center">
    <img src="https://raw.githubusercontent.com/burnlang/burn/master/assets/logo.svg" alt="Burn logo" width="128">
</p>

# ash index

The list of packages that `ash search` finds.

Any git repository with a `burn.toml` is a package and can be installed with `ash install <name>` without being
listed here. The index only makes packages easy to find.

## Adding a package

1. Make sure the project is ready: `ash publish --tag` checks it and tags the version.
2. Add a file named after the package, `packages/<domain>/<owner>/<project>.toml`:

   ```toml
   name = "github.com/you/colors"
   description = "Colored terminal output"
   kind = "lib"
   keywords = ["terminal", "color"]
   ```

3. Open a pull request. The check clones the repository and confirms that it is a Burn project whose
   `burn.toml` has the same name and kind.

| Key | Meaning |
| --- | --- |
| `name` | the package name, the same as the path of the file |
| `description` | one line about what it does |
| `kind` | `"lib"` for libraries, `"app"` for programs installed with `ash install -g` |
| `keywords` | words that `ash search` matches |

Check entries locally with `sh scripts/check.sh [files...]`.

## License

[MIT License](LICENSE)
