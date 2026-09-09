<p align="center">
  <img src=".github/nem-icon.svg" alt="nem logo" width="110" height="110">
</p>

<h1 align="center">nem-catalog</h1>

<p align="center">
  The official package catalog for <a href="https://github.com/vi-dev/nem">nem</a>.
</p>

<p align="center">
  <a href="https://github.com/vi-dev/nem-catalog/actions/workflows/publish.yml"><img src="https://github.com/vi-dev/nem-catalog/actions/workflows/publish.yml/badge.svg" alt="Publish"></a>
  <a href="pkgs/"><img src="https://img.shields.io/github/directory-file-count/vi-dev/nem-catalog/pkgs?type=dir&label=packages&color=d8843a" alt="Packages"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/vi-dev/nem-catalog?color=blue" alt="License: MIT"></a>
</p>

> [!IMPORTANT]
> Like [`nem`](https://github.com/vi-dev/nem) itself, this catalog is in
> active development and is provided **as is**, without warranty of any kind.
> Packages may change or disappear without notice.

The official public package catalog for
[`nem`](https://github.com/vi-dev/nem), a CLI for managing per-directory
developer environments.

## Using this catalog

`nem` configures this catalog on first run, under the name `official`.
Start using packages right away:

```sh
nem search kubectl
nem use kubectl
```

To add this catalog under a different name, run:

```sh
nem catalog add <name> ghcr.io/vi-dev/nem-catalog:v2
```

> [!TIP]
> The `:v2` tag moves with every release. For reproducible setups, pin the
> catalog to a digest instead:
>
> ```sh
> nem catalog remove official
> nem catalog add official ghcr.io/vi-dev/nem-catalog@sha256:…
> ```

To opt out of the official catalog entirely, run
`nem catalog disable official` (or `nem catalog remove official`).

## License

[MIT](LICENSE)
