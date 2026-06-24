<p align="center">
  <img src=".github/nem-icon.svg" alt="nem logo" width="110" height="110">
</p>

<h1 align="center">nem-catalog</h1>

<p align="center">
  The default package catalog for <a href="https://github.com/vi-dev/nem">nem</a>.
</p>

<p align="center">
  <a href="https://github.com/vi-dev/nem-catalog/actions/workflows/ci.yml"><img src="https://github.com/vi-dev/nem-catalog/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="pkgs/"><img src="https://img.shields.io/github/directory-file-count/vi-dev/nem-catalog/pkgs?type=dir&label=packages&color=d8843a" alt="Packages"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/vi-dev/nem-catalog?color=blue" alt="License: MIT"></a>
</p>

<p align="center">
  <b><a href="https://vi-dev.org/nem/">nem docs</a></b>&nbsp; &nbsp;•&nbsp; &nbsp;<a href="https://github.com/vi-dev/nem">nem CLI</a>&nbsp; &nbsp;•&nbsp; &nbsp;<a href="https://vi-dev.org/nem/docs/reference/catalog/">pkg.yaml schema</a>&nbsp; &nbsp;•&nbsp; &nbsp;<a href="https://vi-dev.org/nem/docs/authoring/">Authoring guide</a>
</p>

The default public package catalog for [`nem`](https://github.com/vi-dev/nem),
a CLI for managing per-directory developer environments.

This repository contains only `pkg.yaml` package manifests under [`pkgs/`](pkgs/).
It carries no code — the manifest schema and all install behaviour are defined by
`nem` itself (see the [catalog reference](https://vi-dev.org/nem/docs/reference/catalog/)).
The catalog is published as an OCI image index to
**`ghcr.io/vi-dev/nem-catalog`** on every change to `main`.

## Using this catalog

This catalog is `nem`'s built-in default. Once `nem` is installed (see the
[nem README](https://github.com/vi-dev/nem)), it is available out of the box —
no `nem catalog add` step. Just start using packages:

```sh
# Find and use packages in the current directory's environment.
nem search kubectl
nem use kubectl
nem package info helm
```

> [!TIP]
> For reproducible setups, pin to an immutable date tag (`vYYYY.MM.DD-<sha>`) or
> a digest (`@sha256:…`) instead of the moving `v1`. Reuse the name `default` to
> shadow the built-in entry with your pinned version:
>
> ```sh
> nem catalog add oci default ghcr.io/vi-dev/nem-catalog:vYYYY.MM.DD-<sha>
> ```

To opt out of the built-in default entirely, set `NEM_USE_DEFAULT_CATALOG=0`
(or `use-default-catalog: false` in `~/.nem/config.yaml`).

## Contributing a package

Each package is a single manifest at `pkgs/<name>/pkg.yaml`. The schema —
fetchers, verification, install steps, and templating — is documented in
[`nem`'s catalog reference](https://vi-dev.org/nem/docs/reference/catalog/).

Validate a manifest before opening a pull request:

```sh
# Structural checks for every manifest.
nem author lint pkgs

# Full check for one package: fetch, sandboxed install, and run its tests.
nem author lint pkgs/<name> --install
```

Every pull request runs these in CI: all manifests are linted offline, and any
package you add or change is installed and tested on Linux and macOS.

## Publishing

Merges to `main` that touch `pkgs/**` are published automatically by
[`.github/workflows/publish.yml`](.github/workflows/publish.yml):

- the catalog index is pushed to `ghcr.io/vi-dev/nem-catalog`, tagged
  with an immutable `vYYYY.MM.DD-<sha>` plus the moving `v1` and `latest` tags;
- the index digest is signed with cosign (keyless) and a build-provenance
  attestation is pushed alongside it.

The major tag (`v1`) tracks the catalog schema generation and only advances on a
schema migration.

## License

[MIT](LICENSE)
