# Troubleshooting

## Inspect the installed CLI

```bash
./scripts/gog.sh --version
./scripts/gog.sh schema gmail --json
./scripts/gog.sh gmail --help
```

Do not guess unsupported flags; use the installed binary's schema.

## Authentication errors

```bash
./scripts/gog.sh auth list --check --json --no-input
./scripts/gog.sh auth doctor --check --json --no-input
```

Exit code 4 indicates missing or unusable authentication. Exit code 10 indicates incomplete local configuration. Avoid reauthorizing until diagnostics show that credentials, rather than the agent process environment, are the problem.

## Headless keyring errors

A command working in a login shell does not prove that the agent process has the same environment. For an encrypted file keyring, the process invoking `gog` needs the appropriate `GOG_KEYRING_BACKEND`, `GOG_KEYRING_PASSWORD`, `GOG_HOME`, and `HOME` values. Never print the password while diagnosing this.

## Gmail API is disabled

If Google reports `accessNotConfigured`, enable Gmail API in the same Cloud project that owns the OAuth client, wait for propagation, and retry.

## Binary installation

The wrapper installs the pinned release to `${GOG_INSTALL_DIR:-${XDG_BIN_HOME:-$HOME/.local/bin}}/gog`.

Explicit reinstall or update:

```bash
GOG_VERSION=v0.34.0 ./scripts/install-gog.sh --replace
./scripts/install-gog.sh --version v0.34.0 --replace
```

The installer supports macOS/Linux on amd64/arm64 and verifies the release archive against upstream `checksums.txt`.

## Automation exit codes

Common `gog` exit statuses:

- `0`: success
- `2`: invalid usage
- `3`: empty results when requested as an error
- `4`: authentication required
- `5`: not found
- `6`: permission denied
- `7`: rate limited
- `8`: retryable/transient failure
- `10`: local configuration problem

Branch on status codes rather than parsing human-readable stderr.
