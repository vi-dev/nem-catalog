# nem-catalog

The default public package catalog for [`nem`](https://github.com/vi-dev/nem),
a CLI for managing per-directory developer environments.

This repository contains only `pkg.yaml` package manifests under [`pkgs/`](pkgs/).
It carries no code — the manifest schema and all install behaviour are defined by
`nem` itself (see [`nem`'s catalog reference](https://github.com/vi-dev/nem/blob/main/docs/catalog.md)).
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

You can still add it explicitly to pin a specific version. For reproducible
setups, pin to an immutable date tag (`vYYYY.MM.DD-<sha>`) or a digest
(`@sha256:…`) instead of the moving `v1`:

```sh
nem catalog add oci official ghcr.io/vi-dev/nem-catalog:vYYYY.MM.DD-<sha>
```

To opt out of the built-in default entirely, set `NEM_NO_DEFAULT_CATALOG=1`.

## Contributing a package

Each package is a single manifest at `pkgs/<name>/pkg.yaml`. The schema —
fetchers, verification, install steps, and templating — is documented in
[`nem`'s catalog reference](https://github.com/vi-dev/nem/blob/main/docs/catalog.md).

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
